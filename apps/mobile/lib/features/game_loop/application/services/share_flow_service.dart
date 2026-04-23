import '../../../data/analytics/analytics_tracker.dart';
import '../game_loop_view_state.dart';

/// Handles share-score text generation and analytics tracking.
///
/// Extracted from [GameLoopController] to isolate social sharing
/// logic from core gameplay orchestration.
class ShareFlowService {
  static const String _defaultShareHashtag = '#BlockPuzzle';

  ShareFlowService({
    required this.analyticsTracker,
    required this.hashtag,
  });

  final AnalyticsTracker analyticsTracker;
  final String hashtag;

  /// Build the user-facing share text for game-over screen.
  String buildShareText(GameLoopViewState state) {
    final int score = state.scoreState.totalScore;
    final int best = state.bestScore;
    final int level = state.level;
    final int moves = state.movesPlayed;
    final int goalsCompleted = state.dailyGoals.completedCount;
    final int goalsTotal = state.dailyGoals.totalCount;

    return 'I scored $score in Lumina Blocks! '
        'Best: $best, Level: $level, Moves: $moves, '
        'Daily goals: $goalsCompleted/$goalsTotal. '
        'Can you beat it? $hashtag';
  }

  Future<void> trackShareTapped({
    required String channel,
    required int roundId,
    required GameLoopViewState state,
    required String uxVariant,
    required String difficultyVariant,
  }) async {
    await analyticsTracker.track(
      'share_score_tapped',
      params: <String, Object?>{
        'round_id': roundId,
        'channel': channel,
        'score_total': state.scoreState.totalScore,
        'best_score': state.bestScore,
        'level': state.level,
        'moves_played': state.movesPlayed,
        'daily_goals_completed': state.dailyGoals.completedCount,
        'daily_goals_total': state.dailyGoals.totalCount,
        'ux_variant': uxVariant,
        'difficulty_variant': difficultyVariant,
      },
    );
  }

  Future<void> trackShareResult({
    required String channel,
    required bool success,
    required int roundId,
    required GameLoopViewState state,
    required String uxVariant,
    required String difficultyVariant,
    String? failureReason,
  }) async {
    await analyticsTracker.track(
      'share_score_result',
      params: <String, Object?>{
        'round_id': roundId,
        'channel': channel,
        'success': success,
        if (failureReason != null) 'failure_reason': failureReason,
        'score_total': state.scoreState.totalScore,
        'best_score': state.bestScore,
        'level': state.level,
        'moves_played': state.movesPlayed,
        'daily_goals_completed': state.dailyGoals.completedCount,
        'daily_goals_total': state.dailyGoals.totalCount,
        'ux_variant': uxVariant,
        'difficulty_variant': difficultyVariant,
      },
    );
  }

  /// Normalize a raw hashtag value from config.
  static String normalizeHashtag(String rawValue) {
    final String trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return _defaultShareHashtag;
    }
    if (trimmed.startsWith('#')) {
      return trimmed;
    }
    return '#$trimmed';
  }
}
