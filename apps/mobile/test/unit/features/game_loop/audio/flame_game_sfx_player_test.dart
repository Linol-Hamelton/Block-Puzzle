import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_puzzle_mobile/core/audio/music_controller.dart';
import 'package:block_puzzle_mobile/core/audio/music_playlist_manager.dart';
import 'package:block_puzzle_mobile/core/logging/app_logger.dart';
import 'package:block_puzzle_mobile/features/game_loop/audio/flame_game_sfx_player.dart';

class _SilentLogger implements AppLogger {
  @override
  void info(String message) {}
  @override
  void warn(String message) {}
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}

class _FakeAudioPlayer extends AudioPlayer {
  _FakeAudioPlayer();

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {}

  @override
  Future<void> setAudioContext(AudioContext context) async {}
}

class _SpyMusicController extends MusicController {
  _SpyMusicController()
      : super(
          logger: _SilentLogger(),
          playlistManager: MusicPlaylistManager(
            logger: _SilentLogger(),
            playerA: _FakeAudioPlayer(),
            playerB: _FakeAudioPlayer(),
          ),
        );

  int duckCallCount = 0;
  Duration? lastDuckDuration;
  double? lastDuckFactor;

  @override
  void duck({
    Duration duration = MusicPlaylistManager.kDefaultDuckDuration,
    double factor = MusicPlaylistManager.kDuckFactorMinus3dB,
  }) {
    duckCallCount++;
    lastDuckDuration = duration;
    lastDuckFactor = factor;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      return ByteData.sublistView(Uint8List(44));
    });
  });

  group('FlameGameSfxPlayer - Step 4a Combo Ladder & Reset', () {
    late DateTime currentTime;
    late FlameGameSfxPlayer player;

    setUp(() {
      currentTime = DateTime.utc(2026, 9, 16, 12, 0, 0);
      player = FlameGameSfxPlayer(
        logger: _SilentLogger(),
        nowUtcProvider: () => currentTime,
      );
      // Disable audio playback to test ladder logic in headless environment without native audio pools
      player.isEnabled = false;
    });

    test('consecutive combos advance from step 1 to 7 and saturate at 7', () async {
      // Step 1: initial combo
      final int step1 = player.resolveComboStep(comboStreak: 1, now: currentTime);
      expect(step1, 1);

      // Step 2..7: rapid combos (500 ms apart, well within 2.5s window)
      for (int streak = 2; streak <= 7; streak++) {
        currentTime = currentTime.add(const Duration(milliseconds: 500));
        final int step = player.resolveComboStep(comboStreak: streak, now: currentTime);
        expect(step, streak, reason: 'Streak $streak should resolve to step $streak');
      }

      // Beyond step 7: saturates at step 7
      currentTime = currentTime.add(const Duration(milliseconds: 500));
      final int step8 = player.resolveComboStep(comboStreak: 8, now: currentTime);
      expect(step8, 7, reason: 'Streak 8 should saturate at step 7');

      currentTime = currentTime.add(const Duration(milliseconds: 500));
      final int step12 = player.resolveComboStep(comboStreak: 12, now: currentTime);
      expect(step12, 7, reason: 'Streak 12 should saturate at step 7');
    });

    test('pause of 2.5s resets ladder back to step 1', () async {
      // Build up streak to step 4
      player.resolveComboStep(comboStreak: 1, now: currentTime);
      currentTime = currentTime.add(const Duration(milliseconds: 400));
      player.resolveComboStep(comboStreak: 2, now: currentTime);
      currentTime = currentTime.add(const Duration(milliseconds: 400));
      player.resolveComboStep(comboStreak: 3, now: currentTime);
      currentTime = currentTime.add(const Duration(milliseconds: 400));
      final int step4 = player.resolveComboStep(comboStreak: 4, now: currentTime);
      expect(step4, 4);

      // Advance by exactly 2.5s (2500 ms)
      currentTime = currentTime.add(const Duration(milliseconds: 2500));

      // Next combo with high streak still returns to step 1
      final int stepReset = player.resolveComboStep(comboStreak: 5, now: currentTime);
      expect(stepReset, 1, reason: 'After >= 2.5s pause without combo, ladder must reset to step 1');
    });

    test('pause of 2.4s does NOT reset ladder - boundary check', () async {
      // Build up streak to step 3
      player.resolveComboStep(comboStreak: 1, now: currentTime);
      currentTime = currentTime.add(const Duration(milliseconds: 400));
      player.resolveComboStep(comboStreak: 2, now: currentTime);
      currentTime = currentTime.add(const Duration(milliseconds: 400));
      final int step3 = player.resolveComboStep(comboStreak: 3, now: currentTime);
      expect(step3, 3);

      // Advance by 2.4s (2400 ms) - boundary check below 2.5s threshold
      currentTime = currentTime.add(const Duration(milliseconds: 2400));

      // Next combo continues to step 4 (does NOT reset to 1)
      final int stepNotReset = player.resolveComboStep(comboStreak: 4, now: currentTime);
      expect(stepNotReset, 4, reason: 'After 2.4s pause (< 2.5s threshold), ladder must not reset');
    });

    test('playCombo updates lastComboStep through injected clock', () async {
      await player.playCombo(comboStreak: 1);
      expect(player.lastComboStep, 1);

      currentTime = currentTime.add(const Duration(milliseconds: 600));
      await player.playCombo(comboStreak: 2);
      expect(player.lastComboStep, 2);

      // 2.5s pause
      currentTime = currentTime.add(const Duration(milliseconds: 2500));
      await player.playCombo(comboStreak: 3);
      expect(player.lastComboStep, 1);
    });
  });

  group('FlameGameSfxPlayer - Step 4c Music Ducking Triggers', () {
    late _SpyMusicController musicSpy;
    late FlameGameSfxPlayer player;

    setUp(() {
      musicSpy = _SpyMusicController();
      player = FlameGameSfxPlayer(
        logger: _SilentLogger(),
        musicController: musicSpy,
      );
      player.isEnabled = false; // Headless test without audio pool
    });

    test('line clear ducks music only on 2 or more cleared lines', () async {
      await player.playLineClear(clearedLines: 1);
      expect(musicSpy.duckCallCount, 0, reason: 'Single line clear should not duck music');

      await player.playLineClear(clearedLines: 2);
      expect(musicSpy.duckCallCount, 1);
      expect(musicSpy.lastDuckDuration, const Duration(milliseconds: 150));

      await player.playLineClear(clearedLines: 4);
      expect(musicSpy.duckCallCount, 2);
    });

    test('combo ducks music only on streak >= 2', () async {
      await player.playCombo(comboStreak: 1);
      expect(musicSpy.duckCallCount, 0, reason: 'Combo streak 1 should not duck music');

      await player.playCombo(comboStreak: 2);
      expect(musicSpy.duckCallCount, 1);
      expect(musicSpy.lastDuckDuration, const Duration(milliseconds: 150));

      await player.playCombo(comboStreak: 5);
      expect(musicSpy.duckCallCount, 2);
    });

    test('game over ducks music for 500 ms', () async {
      await player.playGameOver();
      expect(musicSpy.duckCallCount, 1);
      expect(musicSpy.lastDuckDuration, const Duration(milliseconds: 500));
    });
  });

  group('FlameGameSfxPlayer - Part D Voice Allocation & Cutoff Prevention', () {
    late List<MethodCall> methodCalls;
    late FlameGameSfxPlayer player;

    setUp(() {
      methodCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return 1;
        },
      );

      player = FlameGameSfxPlayer(
        logger: _SilentLogger(),
      );
    });

    tearDown(() async {
      await player.dispose();
    });

    test('line_clear is not cut off after 8 short sounds', () async {
      await player.preload();

      final String clearPlayerId = player.lineClearChannel.players[0].playerId;
      final List<String> ringPlayerIds =
          player.ring.players.map((AudioPlayer p) => p.playerId).toList();

      methodCalls.clear();

      // Play long line clear sound
      await player.playLineClear(clearedLines: 1);

      // Verify line clear engaged on the dedicated player
      final bool clearStarted = methodCalls.any(
        (MethodCall c) =>
            c.arguments is Map &&
            (c.arguments as Map)['playerId'] == clearPlayerId &&
            c.method == 'setPlayerMode',
      );
      expect(clearStarted, isTrue, reason: 'Line clear must engage on dedicated voice');

      methodCalls.clear();

      // Fire 8 rapid short sounds (more than ring size 6)
      for (int i = 0; i < 8; i++) {
        await player.playPiecePlaced();
      }

      // Dedicated line_clear player must NEVER have received a stop or reuse call from ring
      final bool clearTouchedByRing = methodCalls.any(
        (MethodCall c) =>
            c.arguments is Map &&
            (c.arguments as Map)['playerId'] == clearPlayerId,
      );
      expect(
        clearTouchedByRing,
        isFalse,
        reason: 'Dedicated line_clear voice must not be touched, stolen, or stopped by short sounds in ring',
      );

      // Verify ring players did receive stop/reuse calls
      final int ringStopCalls = methodCalls.where(
        (MethodCall c) =>
            c.arguments is Map &&
            ringPlayerIds.contains((c.arguments as Map)['playerId']) &&
            c.method == 'stop',
      ).length;
      expect(ringStopCalls, greaterThanOrEqualTo(2), reason: 'Ring must recycle its own voices');
    });

    test('voice channels remain strictly bounded within platform track limits', () async {
      await player.preload();

      expect(player.ring.activePlayerCount, 6, reason: 'Ring size strictly 6');
      expect(player.lineClearChannel.activePlayerCount, 2, reason: 'Line clear dedicated voices strictly 2');
      expect(player.gameOverChannel.activePlayerCount, 1, reason: 'Game over dedicated voice strictly 1');

      final int totalTracks = player.ring.activePlayerCount +
          player.lineClearChannel.activePlayerCount +
          player.gameOverChannel.activePlayerCount;
      expect(totalTracks, 9);
      expect(totalTracks, lessThanOrEqualTo(32), reason: 'Must stay well within Android 32-track SoundPool cap');
    });

    test('combo sounds play simultaneously over active line_clear tail', () async {
      await player.preload();

      final String clearPlayerId = player.lineClearChannel.players[0].playerId;

      await player.playLineClear(clearedLines: 2);

      // Clear method calls after line clear has started
      methodCalls.clear();

      // Combo sounds play concurrently
      await player.playCombo(comboStreak: 1);
      await player.playCombo(comboStreak: 2);

      // Confirm dedicated clear voice was NOT stopped or reused by combo playback
      final bool clearStoppedByCombo = methodCalls.any(
        (MethodCall c) =>
            c.arguments is Map &&
            (c.arguments as Map)['playerId'] == clearPlayerId &&
            c.method == 'stop',
      );
      expect(clearStoppedByCombo, isFalse, reason: 'Combo plays concurrently over clear tail without stopping it');
    });

    test('dispose releases all ring and dedicated channel players cleanly', () async {
      await player.preload();

      final List<String> allPlayerIds = <String>[
        ...player.ring.players.map((AudioPlayer p) => p.playerId),
        ...player.lineClearChannel.players.map((AudioPlayer p) => p.playerId),
        ...player.gameOverChannel.players.map((AudioPlayer p) => p.playerId),
      ];
      expect(allPlayerIds.length, 9);

      methodCalls.clear();
      await player.dispose();

      // All channel lists should be empty after dispose
      expect(player.ring.activePlayerCount, 0);
      expect(player.lineClearChannel.activePlayerCount, 0);
      expect(player.gameOverChannel.activePlayerCount, 0);

      // Verify dispose called on all 9 player IDs
      final Set<dynamic> disposedIds = methodCalls
          .where((MethodCall c) => c.method == 'dispose' && c.arguments is Map)
          .map((MethodCall c) => (c.arguments as Map)['playerId'])
          .toSet();

      for (final String pid in allPlayerIds) {
        expect(disposedIds.contains(pid), isTrue, reason: 'Player $pid must be disposed');
      }
    });
  });
}
