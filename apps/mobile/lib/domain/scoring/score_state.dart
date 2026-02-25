class ScoreState {
  const ScoreState({
    required this.totalScore,
    required this.comboStreak,
  });

  final int totalScore;
  final int comboStreak;

  static const ScoreState initial = ScoreState(
    totalScore: 0,
    comboStreak: 0,
  );
}
