import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:block_puzzle_mobile/core/audio/music_controller.dart';
import 'package:block_puzzle_mobile/core/audio/music_playlist_manager.dart';
import 'package:block_puzzle_mobile/core/logging/app_logger.dart';

class _SilentLogger implements AppLogger {
  @override
  void info(String message) {}
  @override
  void warn(String message) {}
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}

/// In-memory fake AudioPlayer that avoids native platform calls during tests
/// while verifying player state and volume transitions.
class FakeAudioPlayer extends AudioPlayer {
  FakeAudioPlayer({super.playerId});

  final StreamController<void> completeController =
      StreamController<void>.broadcast();
  final StreamController<PlayerState> stateController =
      StreamController<PlayerState>.broadcast();

  double currentVolume = 1.0;
  ReleaseMode? configuredReleaseMode;
  AudioContext? configuredAudioContext;
  Source? currentSource;
  bool isPlayerPlaying = false;
  bool isPlayerPaused = false;
  bool isPlayerStopped = true;
  bool isPlayerDisposed = false;
  int playCallCount = 0;
  PlayerState _fakeState = PlayerState.stopped;

  @override
  PlayerState get state => _fakeState;

  @override
  Stream<PlayerState> get onPlayerStateChanged => stateController.stream;

  @override
  Stream<void> get onPlayerComplete => completeController.stream;

  void emitPlayerState(PlayerState newState) {
    _fakeState = newState;
    stateController.add(newState);
  }

  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume;
  }

  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {
    configuredReleaseMode = mode;
  }

  @override
  Future<void> setAudioContext(AudioContext context) async {
    configuredAudioContext = context;
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    currentSource = source;
    if (volume != null) {
      currentVolume = volume;
    }
    isPlayerPlaying = true;
    isPlayerPaused = false;
    isPlayerStopped = false;
    _fakeState = PlayerState.playing;
    playCallCount++;
  }

  @override
  Future<void> pause() async {
    isPlayerPlaying = false;
    isPlayerPaused = true;
    _fakeState = PlayerState.paused;
  }

  @override
  Future<void> resume() async {
    isPlayerPlaying = true;
    isPlayerPaused = false;
    _fakeState = PlayerState.playing;
    playCallCount++;
  }

  @override
  Future<void> stop() async {
    isPlayerPlaying = false;
    isPlayerPaused = false;
    isPlayerStopped = true;
    _fakeState = PlayerState.stopped;
  }

  @override
  Future<void> dispose() async {
    isPlayerDisposed = true;
    isPlayerPlaying = false;
    _fakeState = PlayerState.disposed;
    await completeController.close();
    await stateController.close();
  }

  void completeTrack() {
    completeController.add(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
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
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('MusicPlaylistManager - Mathematical Invariants & AudioContext', () {
    test('equal-power curve maintains gainA^2 + gainB^2 == 1.0 and -3 dB midpoint', () {
      // Test at 101 sample points between 0.0 and 1.0
      for (int i = 0; i <= 100; i++) {
        final double t = i / 100.0;
        final ({double gainA, double gainB}) gains =
            MusicPlaylistManager.computeEqualPowerGains(t);

        final double powerSum = (gains.gainA * gains.gainA) + (gains.gainB * gains.gainB);
        expect(
          (powerSum - 1.0).abs(),
          lessThan(1e-6),
          reason: 'Equal-power invariant failed at t=$t: powerSum=$powerSum',
        );
      }

      // Midpoint t = 0.5 must be approx sqrt(2)/2 = 0.7071 (-3.01 dB)
      final ({double gainA, double gainB}) mid =
          MusicPlaylistManager.computeEqualPowerGains(0.5);
      final double expectedMid = math.sqrt(2.0) / 2.0;
      expect((mid.gainA - expectedMid).abs(), lessThan(1e-4));
      expect((mid.gainB - expectedMid).abs(), lessThan(1e-4));

      final double midDb = 20 * math.log(mid.gainA) / math.ln10;
      expect((midDb - (-3.0103)).abs(), lessThan(0.01));

      // Duck factor -3 dB check
      final double duckDb =
          20 * math.log(MusicPlaylistManager.kDuckFactorMinus3dB) / math.ln10;
      expect((duckDb - (-3.0)).abs(), lessThan(0.001));
    });

    test('initialize configures explicit AudioContext with AndroidAudioFocus.gainTransientMayDuck', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager manager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playerA: playerA,
        playerB: playerB,
        playlist: const <String>['track1.m4a', 'track2.m4a'],
      );

      await manager.initialize();

      expect(playerA.configuredAudioContext, isNotNull);
      expect(playerB.configuredAudioContext, isNotNull);
      expect(
        playerA.configuredAudioContext!.android.audioFocus,
        equals(AndroidAudioFocus.gainTransientMayDuck),
      );
      expect(
        playerA.configuredAudioContext!.android.contentType,
        equals(AndroidContentType.music),
      );
      expect(
        playerA.configuredAudioContext!.android.usageType,
        equals(AndroidUsageType.media),
      );
      expect(
        playerA.configuredAudioContext!.iOS.category,
        equals(AVAudioSessionCategory.playback),
      );

      expect(playerA.configuredReleaseMode, equals(ReleaseMode.stop));
      expect(playerB.configuredReleaseMode, equals(ReleaseMode.stop));

      await manager.dispose();
    });
  });

  group('MusicPlaylistManager - DEC-0024 Criteria Cases', () {
    test('case 1: ducking in the middle of a crossfade does not break the final volume level', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager manager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playerA: playerA,
        playerB: playerB,
        playlist: const <String>['track0.m4a', 'track1.m4a'],
        baseVolume: 0.32,
        crossfadeDuration: const Duration(milliseconds: 240),
      );

      await manager.initialize();
      await manager.play();

      expect(playerA.currentVolume, closeTo(0.32, 1e-4));

      // Initiate crossfade to track 1
      unawaited(manager.crossfadeTo(1));
      expect(manager.isCrossfading, isTrue);

      // Advance halfway through crossfade
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(manager.isCrossfading, isTrue);

      // Trigger ducking for 80 ms in the middle of crossfade
      manager.duck(duration: const Duration(milliseconds: 80));
      expect(manager.duckMultiplier, closeTo(MusicPlaylistManager.kDuckFactorMinus1_5dB, 1e-4));

      // Check that during ducking, volume is attenuated on both players
      expect(playerA.currentVolume, lessThan(0.32));
      expect(playerB.currentVolume, lessThan(0.32));

      // Wait for duck timer (80 ms), recovery ramp (250 ms) and crossfade to fully complete
      await Future<void>.delayed(const Duration(milliseconds: 360));

      // After crossfade completes and duck finishes, final volume of incoming player
      // (which is now activePlayer, playerB) MUST be restored exactly to baseVolume (0.32)
      expect(manager.isCrossfading, isFalse);
      expect(manager.duckMultiplier, equals(1.0));
      expect(manager.activePlayer, equals(playerB));
      expect(playerB.currentVolume, closeTo(0.32, 1e-4));

      await manager.dispose();
    });

    test('case 2: play() during active crossfade cancels previous timer and does not leak players', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager manager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playerA: playerA,
        playerB: playerB,
        playlist: const <String>['track0.m4a', 'track1.m4a', 'track2.m4a'],
        baseVolume: 0.32,
        crossfadeDuration: const Duration(milliseconds: 500),
      );

      await manager.initialize();
      await manager.play(trackIndex: 0);

      // Start crossfade to track 1
      unawaited(manager.crossfadeTo(1));
      expect(manager.isCrossfading, isTrue);

      // Mid-crossfade, invoke play(trackIndex: 2)
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await manager.play(trackIndex: 2);

      // Crossfade must be cancelled
      expect(manager.isCrossfading, isFalse);
      expect(manager.currentTrackIndex, equals(2));
      expect(manager.isPlaying, isTrue);

      // Standby player must be stopped
      expect(manager.standbyPlayer, equals(playerB));
      expect(playerB.isPlayerStopped, isTrue);

      // Active player must be playing track 2 at full base volume
      expect(playerA.currentVolume, closeTo(0.32, 1e-4));

      // Wait past original crossfade duration to ensure no trailing timer fires
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(manager.currentTrackIndex, equals(2));
      expect(manager.isCrossfading, isFalse);

      await manager.dispose();
    });

    test('case 3: dispose() frees both players and cancels all timers and subscriptions', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager manager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playerA: playerA,
        playerB: playerB,
        playlist: const <String>['track0.m4a', 'track1.m4a'],
        crossfadeDuration: const Duration(milliseconds: 500),
      );

      await manager.initialize();
      await manager.play();
      unawaited(manager.crossfadeTo(1));
      manager.duck();

      await manager.dispose();

      expect(manager.isDisposed, isTrue);
      expect(playerA.isPlayerDisposed, isTrue);
      expect(playerB.isPlayerDisposed, isTrue);

      // Subsequent operations do not throw and remain safe no-ops
      await manager.play();
      manager.duck();
      await manager.pause();
      await manager.resume();
      await manager.stop();
    });

    test('case 4: playlist progression advances cyclically without skips', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager manager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playerA: playerA,
        playerB: playerB,
        playlist: const <String>['track0.m4a', 'track1.m4a', 'track2.m4a'],
        crossfadeDuration: const Duration(milliseconds: 60),
      );

      await manager.initialize();
      await manager.play(trackIndex: 0);
      expect(manager.currentTrackIndex, equals(0));

      // Simulate track 0 completion on playerA
      playerA.completeTrack();

      // Allow crossfade to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(manager.currentTrackIndex, equals(1));
      expect(manager.activePlayer, equals(playerB));

      // Simulate track 1 completion on playerB
      playerB.completeTrack();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(manager.currentTrackIndex, equals(2));
      expect(manager.activePlayer, equals(playerA));

      // Simulate track 2 completion -> cycles back to 0 without skipping
      playerA.completeTrack();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(manager.currentTrackIndex, equals(0));
      expect(manager.activePlayer, equals(playerB));

      await manager.dispose();
    });

    test('case 5: play() when already playing current track does not restart playback', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager manager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playerA: playerA,
        playerB: playerB,
        playlist: const <String>['track0.m4a'],
      );

      await manager.initialize();
      await manager.play();

      expect(playerA.playCallCount, equals(1));

      // Second play() call simulating screen navigation
      await manager.play();
      expect(playerA.playCallCount, equals(1),
          reason: 'play() must not re-trigger player when already playing');

      await manager.dispose();
    });
  });

  group('MusicController - App Scope & Lifecycle', () {
    test('MusicController persists preference and respects toggle', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager playlistManager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playerA: playerA,
        playerB: playerB,
        playlist: const <String>['track0.m4a'],
      );
      final MusicController controller = MusicController(
        logger: _SilentLogger(),
        playlistManager: playlistManager,
      );

      await controller.initialize();
      expect(controller.isPlaying, isTrue);

      // Disable music
      await controller.setEnabled(false);
      expect(controller.isEnabled, isFalse);
      expect(controller.isPlaying, isFalse);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('music_enabled'), isFalse);

      // Enable music again
      await controller.setEnabled(true);
      expect(controller.isEnabled, isTrue);
      expect(controller.isPlaying, isTrue);
      expect(prefs.getBool('music_enabled'), isTrue);

      await controller.dispose();
    });

    test('MusicController pauses on app background and resumes on foreground', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager playlistManager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playerA: playerA,
        playerB: playerB,
        playlist: const <String>['track0.m4a'],
      );
      final MusicController controller = MusicController(
        logger: _SilentLogger(),
        playlistManager: playlistManager,
      );

      await controller.initialize();
      expect(controller.isPlaying, isTrue);

      // App transitions to paused (background / phone call)
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(controller.isPaused, isTrue);

      // App transitions back to resumed
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.isPaused, isFalse);
      expect(controller.isPlaying, isTrue);

      await controller.dispose();
    });
  });

  group('MusicPlaylistManager - F2 AudioFocus External Pause Recovery', () {
    test('recovers from external pause event (AudioFocus loss) via state synchronization', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager manager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playlist: const <String>['track1.m4a', 'track2.m4a'],
        playerA: playerA,
        playerB: playerB,
      );

      await manager.initialize();
      await manager.play();

      expect(manager.isPlaying, isTrue);
      expect(manager.isPaused, isFalse);
      expect(playerA.playCallCount, 1);

      // External pause emitted on active player (e.g. permanent audio focus loss)
      playerA.emitPlayerState(PlayerState.paused);
      await Future<void>.delayed(Duration.zero);

      // Dart state reflects reality
      expect(manager.isPaused, isTrue);
      expect(manager.isPlaying, isTrue);

      // Calling play() must not be a no-op; it resumes playback
      await manager.play();

      expect(manager.isPaused, isFalse);
      expect(manager.isPlaying, isTrue);
      expect(playerA.isPlayerPlaying, isTrue);
      expect(playerA.playCallCount, 2);

      await manager.dispose();
    });

    test('recovers from external resume event and direct resume call', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager manager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playlist: const <String>['track1.m4a'],
        playerA: playerA,
        playerB: playerB,
      );

      await manager.initialize();
      await manager.play();

      playerA.emitPlayerState(PlayerState.paused);
      await Future<void>.delayed(Duration.zero);
      expect(manager.isPaused, isTrue);

      // External resume event
      playerA.emitPlayerState(PlayerState.playing);
      await Future<void>.delayed(Duration.zero);
      expect(manager.isPaused, isFalse);

      await manager.dispose();
    });

    test('play() detects underlying paused player state and resumes', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager manager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playlist: const <String>['track1.m4a'],
        playerA: playerA,
        playerB: playerB,
      );

      await manager.initialize();
      await manager.play();
      expect(playerA.playCallCount, 1);

      // Simulate native silent pause where player.state changed without stream event
      await playerA.pause();
      expect(playerA.state, PlayerState.paused);

      // Calling play() must detect underlying paused state and resume
      await manager.play();
      expect(manager.isPaused, isFalse);
      expect(playerA.playCallCount, 2);

      await manager.dispose();
    });

    test('DEC-0028: duck floor >= 0.70 across 4 rapid events at 50 ms intervals with coalescing', () async {
      final FakeAudioPlayer playerA = FakeAudioPlayer();
      final FakeAudioPlayer playerB = FakeAudioPlayer();
      final MusicPlaylistManager manager = MusicPlaylistManager(
        logger: _SilentLogger(),
        playlist: const <String>['track1.m4a'],
        playerA: playerA,
        playerB: playerB,
        baseVolume: 0.50,
      );

      await manager.initialize();
      await manager.play();
      expect(playerA.currentVolume, closeTo(0.50, 1e-4));

      // Trigger 4 rapid duck calls at 50 ms intervals
      for (int i = 0; i < 4; i++) {
        manager.duck();
        expect(manager.duckMultiplier, greaterThanOrEqualTo(0.70));
        expect(playerA.currentVolume, greaterThanOrEqualTo(0.50 * 0.70 - 1e-4));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      // Multiplier must remain bounded at or above 0.70 throughout
      expect(manager.duckMultiplier, greaterThanOrEqualTo(0.70));

      // After coalescing, duck duration, and 250 ms recovery ramp, volume must restore to base
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(manager.duckMultiplier, equals(1.0));
      expect(playerA.currentVolume, closeTo(0.50, 1e-4));

      await manager.dispose();
    });
  });
}
