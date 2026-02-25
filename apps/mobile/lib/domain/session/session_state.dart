class SessionState {
  const SessionState({
    required this.roundsPlayed,
    required this.currentScore,
    required this.movesPlayed,
  });

  final int roundsPlayed;
  final int currentScore;
  final int movesPlayed;

  static const SessionState initial = SessionState(
    roundsPlayed: 0,
    currentScore: 0,
    movesPlayed: 0,
  );
}
