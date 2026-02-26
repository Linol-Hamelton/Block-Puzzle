class PlayerProgressState {
  const PlayerProgressState({
    required this.dayKeyUtc,
    required this.streakCurrentDays,
    required this.streakBestDays,
    required this.dailyMoves,
    required this.dailyLinesCleared,
    required this.dailyScoreEarned,
    required this.rewardedToolsCredits,
  });

  final DateTime dayKeyUtc;
  final int streakCurrentDays;
  final int streakBestDays;
  final int dailyMoves;
  final int dailyLinesCleared;
  final int dailyScoreEarned;
  final int rewardedToolsCredits;

  factory PlayerProgressState.initialForDay(
    DateTime dayKeyUtc, {
    int initialRewardedToolsCredits = 0,
  }) {
    final DateTime normalizedDay = normalizeDayKeyUtc(dayKeyUtc);
    return PlayerProgressState(
      dayKeyUtc: normalizedDay,
      streakCurrentDays: 1,
      streakBestDays: 1,
      dailyMoves: 0,
      dailyLinesCleared: 0,
      dailyScoreEarned: 0,
      rewardedToolsCredits: initialRewardedToolsCredits,
    );
  }

  PlayerProgressState copyWith({
    DateTime? dayKeyUtc,
    int? streakCurrentDays,
    int? streakBestDays,
    int? dailyMoves,
    int? dailyLinesCleared,
    int? dailyScoreEarned,
    int? rewardedToolsCredits,
  }) {
    return PlayerProgressState(
      dayKeyUtc: dayKeyUtc ?? this.dayKeyUtc,
      streakCurrentDays: streakCurrentDays ?? this.streakCurrentDays,
      streakBestDays: streakBestDays ?? this.streakBestDays,
      dailyMoves: dailyMoves ?? this.dailyMoves,
      dailyLinesCleared: dailyLinesCleared ?? this.dailyLinesCleared,
      dailyScoreEarned: dailyScoreEarned ?? this.dailyScoreEarned,
      rewardedToolsCredits: rewardedToolsCredits ?? this.rewardedToolsCredits,
    );
  }

  static DateTime normalizeDayKeyUtc(DateTime utcDateTime) {
    return DateTime.utc(
      utcDateTime.year,
      utcDateTime.month,
      utcDateTime.day,
    );
  }
}
