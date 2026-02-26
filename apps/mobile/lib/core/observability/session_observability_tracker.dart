import 'session_observability_snapshot.dart';

class SessionObservabilityTracker {
  String _sessionId = 'unknown_session';
  int _roundsStarted = 0;
  int _roundsEnded = 0;
  int _totalRoundDurationSec = 0;
  int _gameOverNoMovesCount = 0;
  int _moveAttempts = 0;
  int _moveRejectedCount = 0;
  int _runtimeErrorCount = 0;

  void startSession({
    required String sessionId,
  }) {
    _sessionId = sessionId;
    _roundsStarted = 0;
    _roundsEnded = 0;
    _totalRoundDurationSec = 0;
    _gameOverNoMovesCount = 0;
    _moveAttempts = 0;
    _moveRejectedCount = 0;
    _runtimeErrorCount = 0;
  }

  void onRoundStarted() {
    _roundsStarted += 1;
  }

  void onMoveAttempt() {
    _moveAttempts += 1;
  }

  void onMoveRejected() {
    _moveRejectedCount += 1;
  }

  void onGameEnded({
    required String reason,
    required int durationSec,
  }) {
    _roundsEnded += 1;
    if (durationSec > 0) {
      _totalRoundDurationSec += durationSec;
    }
    if (reason == 'no_valid_moves') {
      _gameOverNoMovesCount += 1;
    }
  }

  void onRuntimeError() {
    _runtimeErrorCount += 1;
  }

  SessionObservabilitySnapshot buildSnapshot({
    required int sessionDurationSec,
    required int roundsPlayed,
  }) {
    final int normalizedRoundsPlayed = _max(roundsPlayed, _roundsStarted);
    return SessionObservabilitySnapshot(
      sessionId: _sessionId,
      roundsPlayed: normalizedRoundsPlayed,
      roundsEnded: _roundsEnded,
      sessionDurationSec: _max(sessionDurationSec, 0),
      totalRoundDurationSec: _max(_totalRoundDurationSec, 0),
      gameOverNoMovesCount: _max(_gameOverNoMovesCount, 0),
      moveAttempts: _max(_moveAttempts, 0),
      moveRejectedCount: _max(_moveRejectedCount, 0),
      runtimeErrorCount: _max(_runtimeErrorCount, 0),
    );
  }

  int _max(int value, int min) {
    return value < min ? min : value;
  }
}
