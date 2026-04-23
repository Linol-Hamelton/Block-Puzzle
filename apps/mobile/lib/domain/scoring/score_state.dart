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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'total_score': totalScore,
      'combo_streak': comboStreak,
    };
  }

  factory ScoreState.fromJson(Map<String, Object?> json) {
    return ScoreState(
      totalScore: json['total_score'] as int? ?? 0,
      comboStreak: json['combo_streak'] as int? ?? 0,
    );
  }
}
