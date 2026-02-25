class PlayerProgressState {
  const PlayerProgressState({
    required this.dayKeyUtc,
    required this.streakCurrentDays,
    required this.streakBestDays,
    required this.dailyMoves,
    required this.dailyLinesCleared,
    required this.dailyScoreEarned,
  });

  final DateTime dayKeyUtc;
  final int streakCurrentDays;
  final int streakBestDays;
  final int dailyMoves;
  final int dailyLinesCleared;
  final int dailyScoreEarned;

  factory PlayerProgressState.initialForDay(DateTime dayKeyUtc) {
    final DateTime normalizedDay = normalizeDayKeyUtc(dayKeyUtc);
    return PlayerProgressState(
      dayKeyUtc: normalizedDay,
      streakCurrentDays: 1,
      streakBestDays: 1,
      dailyMoves: 0,
      dailyLinesCleared: 0,
      dailyScoreEarned: 0,
    );
  }

  PlayerProgressState copyWith({
    DateTime? dayKeyUtc,
    int? streakCurrentDays,
    int? streakBestDays,
    int? dailyMoves,
    int? dailyLinesCleared,
    int? dailyScoreEarned,
  }) {
    return PlayerProgressState(
      dayKeyUtc: dayKeyUtc ?? this.dayKeyUtc,
      streakCurrentDays: streakCurrentDays ?? this.streakCurrentDays,
      streakBestDays: streakBestDays ?? this.streakBestDays,
      dailyMoves: dailyMoves ?? this.dailyMoves,
      dailyLinesCleared: dailyLinesCleared ?? this.dailyLinesCleared,
      dailyScoreEarned: dailyScoreEarned ?? this.dailyScoreEarned,
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
