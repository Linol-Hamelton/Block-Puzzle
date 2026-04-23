import 'dart:async';

import '../../../../core/config/remote_config_reader.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../data/analytics/analytics_tracker.dart';
import '../../../../domain/progression/player_progress_repository.dart';
import '../../../../domain/progression/player_progress_state.dart';
import '../../../../domain/progression/progression_snapshots.dart';

/// Manages daily progression: day rollover, streak tracking, daily
/// goals, and rewarded tool credit grants.
///
/// Extracted from [GameLoopController] to keep progression logic
/// isolated and independently testable.
class ProgressionSyncService {
  ProgressionSyncService({
    required this.playerProgressRepository,
    required this.analyticsTracker,
    required this.logger,
    DateTime Function()? nowUtcProvider,
  }) : _nowUtc = nowUtcProvider ?? (() => DateTime.now().toUtc());

  final PlayerProgressRepository playerProgressRepository;
  final AnalyticsTracker analyticsTracker;
  final AppLogger logger;
  final DateTime Function() _nowUtc;

  PlayerProgressState _state = PlayerProgressState.initialForDay(
    DateTime.utc(1970, 1, 1),
  );

  // Config-driven targets resolved during configure().
  int _dailyGoalMovesTarget = 18;
  int _dailyGoalLinesTarget = 6;
  int _dailyGoalScoreTarget = 350;
  int _dailyGoalRewardCredits = 1;
  bool _streakEnabled = true;

  /// Current progression state.
  PlayerProgressState get state => _state;

  /// Configure targets from remote config. Call once after config fetch.
  void configure(RemoteConfigReader config) {
    _streakEnabled = config.readBool(
      'progression.streak_enabled',
      fallback: true,
    );
    _dailyGoalMovesTarget = config.readInt(
      'progression.daily_goal_moves_target',
      fallback: 18,
    ).clamp(1, 500);
    _dailyGoalLinesTarget = config.readInt(
      'progression.daily_goal_lines_target',
      fallback: 6,
    ).clamp(1, 100);
    _dailyGoalScoreTarget = config.readInt(
      'progression.daily_goal_score_target',
      fallback: 350,
    ).clamp(20, 50000);
    _dailyGoalRewardCredits = config.readInt(
      'progression.daily_goal_reward_credits',
      fallback: 1,
    ).clamp(0, 50);
  }

  /// Load persisted progress and perform day rollover if needed.
  Future<void> loadAndSync({
    required int initialRewardedToolsCredits,
  }) async {
    final DateTime todayUtc =
        PlayerProgressState.normalizeDayKeyUtc(_nowUtc());
    _state = await playerProgressRepository.load() ??
        PlayerProgressState.initialForDay(
          todayUtc,
          initialRewardedToolsCredits: initialRewardedToolsCredits,
        );

    if (!_streakEnabled) {
      _state = _state.copyWith(
        streakCurrentDays: 0,
        streakBestDays: 0,
      );
    }

    _state = _state.copyWith(lastSeenUtc: _nowUtc());
    await syncForCurrentDay();
    await playerProgressRepository.save(_state);
  }

  /// Day-change detection and streak management.
  Future<void> syncForCurrentDay() async {
    final DateTime todayUtc =
        PlayerProgressState.normalizeDayKeyUtc(_nowUtc());
    if (_state.dayKeyUtc == todayUtc) {
      return;
    }

    final int dayDelta = todayUtc.difference(_state.dayKeyUtc).inDays;
    int nextStreakCurrent = _state.streakCurrentDays;
    int nextStreakBest = _state.streakBestDays;
    String streakReason = 'same_day';

    if (_streakEnabled) {
      if (dayDelta == 1) {
        nextStreakCurrent =
            (_state.streakCurrentDays + 1).clamp(1, 10000);
        streakReason = 'continued';
      } else {
        nextStreakCurrent = 1;
        streakReason = 'reset_gap';
      }
      if (nextStreakCurrent > nextStreakBest) {
        nextStreakBest = nextStreakCurrent;
      }
    } else {
      nextStreakCurrent = 0;
      nextStreakBest = 0;
      streakReason = 'disabled';
    }

    _state = _state.copyWith(
      dayKeyUtc: todayUtc,
      streakCurrentDays: nextStreakCurrent,
      streakBestDays: nextStreakBest,
      dailyMoves: 0,
      dailyLinesCleared: 0,
      dailyScoreEarned: 0,
      lastSeenUtc: _nowUtc(),
    );
    await playerProgressRepository.save(_state);
    await _trackStreakUpdated(reason: streakReason);
  }

  /// Apply progression after a move: increment daily counters and best score.
  Future<void> applyAfterMove({
    required int clearedLines,
    required int scoreDelta,
    required int bestScore,
  }) async {
    _state = _state.copyWith(
      dailyMoves: _state.dailyMoves + 1,
      dailyLinesCleared: _state.dailyLinesCleared + clearedLines,
      dailyScoreEarned: _state.dailyScoreEarned + scoreDelta,
      bestScore: bestScore > _state.bestScore ? bestScore : _state.bestScore,
      lastSeenUtc: _nowUtc(),
    );
    await playerProgressRepository.save(_state);
  }

  /// Build snapshot of current daily goals.
  DailyGoalsSnapshot buildDailyGoalsSnapshot() {
    return DailyGoalsSnapshot(
      movesProgress: _state.dailyMoves,
      movesTarget: _dailyGoalMovesTarget,
      linesProgress: _state.dailyLinesCleared,
      linesTarget: _dailyGoalLinesTarget,
      scoreProgress: _state.dailyScoreEarned,
      scoreTarget: _dailyGoalScoreTarget,
    );
  }

  /// Build snapshot of current streak.
  StreakSnapshot buildStreakSnapshot() {
    return StreakSnapshot(
      currentDays: _streakEnabled ? _state.streakCurrentDays : 0,
      bestDays: _streakEnabled ? _state.streakBestDays : 0,
    );
  }

  /// Track newly completed goals and grant rewarded tool credits.
  Future<void> trackNewGoalCompletions({
    required DailyGoalsSnapshot before,
    required DailyGoalsSnapshot after,
  }) async {
    int newlyCompletedGoals = 0;
    if (!before.movesCompleted && after.movesCompleted) {
      newlyCompletedGoals += 1;
      await _trackDailyGoalProgress(
        goalId: 'daily_moves',
        progress: after.movesProgress,
        target: after.movesTarget,
        completedGoals: after.completedCount,
      );
    }
    if (!before.linesCompleted && after.linesCompleted) {
      newlyCompletedGoals += 1;
      await _trackDailyGoalProgress(
        goalId: 'daily_lines_cleared',
        progress: after.linesProgress,
        target: after.linesTarget,
        completedGoals: after.completedCount,
      );
    }
    if (!before.scoreCompleted && after.scoreCompleted) {
      newlyCompletedGoals += 1;
      await _trackDailyGoalProgress(
        goalId: 'daily_score',
        progress: after.scoreProgress,
        target: after.scoreTarget,
        completedGoals: after.completedCount,
      );
    }

    if (newlyCompletedGoals <= 0 || _dailyGoalRewardCredits <= 0) {
      return;
    }

    final int creditsEarned = newlyCompletedGoals * _dailyGoalRewardCredits;
    _state = _state.copyWith(
      rewardedToolsCredits: _state.rewardedToolsCredits + creditsEarned,
      lastSeenUtc: _nowUtc(),
    );
    await playerProgressRepository.save(_state);

    unawaited(
      analyticsTracker.track(
        'rewarded_tools_credits_earned',
        params: <String, Object?>{
          'source': 'daily_goals',
          'goals_completed_now': newlyCompletedGoals,
          'credits_earned': creditsEarned,
          'credits_balance': _state.rewardedToolsCredits,
        },
      ),
    );
  }

  /// Consume rewarded tool credits. Returns cost source label.
  Future<String> consumeCredits({
    required int cost,
    required bool hasUnlimitedAccess,
  }) async {
    if (hasUnlimitedAccess) {
      return 'iap_unlimited';
    }

    final int nextCredits =
        (_state.rewardedToolsCredits - cost).clamp(0, 100000);
    _state = _state.copyWith(
      rewardedToolsCredits: nextCredits,
      lastSeenUtc: _nowUtc(),
    );
    await playerProgressRepository.save(_state);
    return 'earned_credits';
  }

  /// Update the internal state (used when state is externally modified).
  void updateState(PlayerProgressState newState) {
    _state = newState;
  }

  /// Update owned IAP products and save to persistence.
  Future<void> updateOwnedIapProducts(Set<String> nextOwnedProductIds) async {
    _state = _state.copyWith(
      ownedProductIds: nextOwnedProductIds,
      lastSeenUtc: _nowUtc(),
    );
    await playerProgressRepository.save(_state);
  }


  // ── Private analytics helpers ──────────────────────────────────

  Future<void> _trackStreakUpdated({required String reason}) async {
    await analyticsTracker.track(
      'streak_updated',
      params: <String, Object?>{
        'current_streak': _state.streakCurrentDays,
        'best_streak': _state.streakBestDays,
        'reason': reason,
      },
    );
  }

  Future<void> _trackDailyGoalProgress({
    required String goalId,
    required int progress,
    required int target,
    required int completedGoals,
  }) async {
    await analyticsTracker.track(
      'daily_goal_progress',
      params: <String, Object?>{
        'goal_id': goalId,
        'progress': progress,
        'target': target,
        'is_completed': progress >= target,
        'completed_goals': completedGoals,
        'total_goals': 3,
      },
    );
  }
}
