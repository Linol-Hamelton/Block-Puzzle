/// Round progression for a Match-3 run.
///
/// A run is one continuous board rather than a sequence of separate levels.
/// Score accumulates, crossing a round's threshold completes that round and
/// pays out extra moves, and the run ends when the move budget is spent.
///
/// The shape of the numbers is the whole design: each round costs more than the
/// last ([targetGrowth]) while the payout stays flat ([movesPerRound]), so a run
/// always ends. The player is trading moves for score the entire time, and how
/// far they get is a measure of how efficiently they spent them.
class Match3Progression {
  const Match3Progression({
    this.movesPerRound = 6,
    this.baseTarget = 1200,
    this.targetGrowth = 400,
  })  : assert(movesPerRound >= 0, 'a round cannot take moves away'),
        assert(baseTarget > 0, 'round one must be reachable'),
        assert(targetGrowth >= 0, 'rounds must not get cheaper');

  /// Moves a run opens with, before any round pays out.
  ///
  /// A constant and not a field: the opening budget is the engine's
  /// [Match3Engine.moveLimit], and stating it in two places is how the two
  /// drift apart.
  static const int defaultStartingMoves = 20;

  /// Moves granted for completing one round.
  final int movesPerRound;

  /// Score that completes round one.
  final int baseTarget;

  /// How much more each round costs than the one before it.
  final int targetGrowth;

  /// Total score that completes [round] (1-based).
  ///
  /// Targets are cumulative against the run's total score, not per-round
  /// subtotals, because the HUD shows one score and a threshold the player can
  /// compare it against directly.
  ///
  /// The closed form of `base, base + growth, base + 2*growth, ...` summed over
  /// the first n rounds. Integer arithmetic throughout: a target that drifted
  /// with floating point would make a replayed run diverge from the original.
  int targetForRound(int round) {
    final int n = round < 1 ? 1 : round;
    return (n * baseTarget) + (targetGrowth * n * (n - 1) ~/ 2);
  }

  /// Score at which [round] began - the previous round's target, or zero.
  int floorForRound(int round) =>
      round <= 1 ? 0 : targetForRound(round - 1);

  /// The round a run of [score] points is playing, for a snapshot written
  /// before rounds existed. Bounded so a corrupt score cannot spin here.
  int roundForScore(int score) {
    int round = 1;
    while (round < 4096 && score >= targetForRound(round)) {
      round += 1;
    }
    return round;
  }

  /// How far into the current round [score] is, in 0..1.
  double progressInRound(int score, int round) {
    final int floor = floorForRound(round);
    final int span = targetForRound(round) - floor;
    if (span <= 0) {
      return 1;
    }
    return ((score - floor) / span).clamp(0, 1).toDouble();
  }
}
