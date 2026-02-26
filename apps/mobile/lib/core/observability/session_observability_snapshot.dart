class SessionObservabilitySnapshot {
  const SessionObservabilitySnapshot({
    required this.sessionId,
    required this.roundsPlayed,
    required this.roundsEnded,
    required this.sessionDurationSec,
    required this.totalRoundDurationSec,
    required this.gameOverNoMovesCount,
    required this.moveAttempts,
    required this.moveRejectedCount,
    required this.runtimeErrorCount,
  });

  final String sessionId;
  final int roundsPlayed;
  final int roundsEnded;
  final int sessionDurationSec;
  final int totalRoundDurationSec;
  final int gameOverNoMovesCount;
  final int moveAttempts;
  final int moveRejectedCount;
  final int runtimeErrorCount;

  double get earlyGameOverRate {
    if (roundsEnded <= 0) {
      return 0.0;
    }
    return gameOverNoMovesCount / roundsEnded;
  }

  double get moveRejectedRate {
    if (moveAttempts <= 0) {
      return 0.0;
    }
    return moveRejectedCount / moveAttempts;
  }

  double get avgRoundDurationSec {
    if (roundsEnded <= 0) {
      return 0.0;
    }
    return totalRoundDurationSec / roundsEnded;
  }

  Map<String, Object?> toAnalyticsPayload({
    required int alertCount,
  }) {
    return <String, Object?>{
      'session_id': sessionId,
      'rounds_played': roundsPlayed,
      'rounds_ended': roundsEnded,
      'session_duration_sec': sessionDurationSec,
      'move_attempts': moveAttempts,
      'move_rejected_count': moveRejectedCount,
      'move_rejected_rate': _round(moveRejectedRate),
      'no_valid_moves_game_over_count': gameOverNoMovesCount,
      'early_gameover_rate': _round(earlyGameOverRate),
      'avg_round_duration_sec': _round(avgRoundDurationSec),
      'runtime_error_count': runtimeErrorCount,
      'alert_count': alertCount,
    };
  }

  double _round(double value) {
    return (value * 10000).round() / 10000;
  }
}
