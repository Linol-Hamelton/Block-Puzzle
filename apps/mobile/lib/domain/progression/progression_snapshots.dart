class DailyGoalsSnapshot {
  const DailyGoalsSnapshot({
    required this.movesProgress,
    required this.movesTarget,
    required this.linesProgress,
    required this.linesTarget,
    required this.scoreProgress,
    required this.scoreTarget,
  });

  final int movesProgress;
  final int movesTarget;
  final int linesProgress;
  final int linesTarget;
  final int scoreProgress;
  final int scoreTarget;

  bool get movesCompleted => movesProgress >= movesTarget;
  bool get linesCompleted => linesProgress >= linesTarget;
  bool get scoreCompleted => scoreProgress >= scoreTarget;

  int get completedCount {
    int count = 0;
    if (movesCompleted) {
      count += 1;
    }
    if (linesCompleted) {
      count += 1;
    }
    if (scoreCompleted) {
      count += 1;
    }
    return count;
  }

  int get totalCount => 3;

  factory DailyGoalsSnapshot.initial() {
    return const DailyGoalsSnapshot(
      movesProgress: 0,
      movesTarget: 18,
      linesProgress: 0,
      linesTarget: 6,
      scoreProgress: 0,
      scoreTarget: 350,
    );
  }
}

class StreakSnapshot {
  const StreakSnapshot({
    required this.currentDays,
    required this.bestDays,
  });

  final int currentDays;
  final int bestDays;

  static const StreakSnapshot initial = StreakSnapshot(
    currentDays: 1,
    bestDays: 1,
  );
}
