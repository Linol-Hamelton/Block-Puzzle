import 'package:flutter_test/flutter_test.dart';
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

void main() {
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
}
