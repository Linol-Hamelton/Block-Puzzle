/// Match-3 scoring rules. Pure and static, mirroring `TetrisScoring`.
///
/// Score for one clear step scales with the number of tiles removed, the length
/// of the longest run (4/5-in-a-row bonuses), and the cascade depth (a chain
/// reaction is worth progressively more).
class Match3Scoring {
  const Match3Scoring._();

  /// Base points awarded per cleared tile.
  static const int basePerTile = 30;

  /// Extra points for each effect gem that actually goes off.
  ///
  /// Paid per detonation rather than folded into the per-tile rate, because a
  /// chain that sets off four gems should be worth visibly more than one that
  /// clears the same number of tiles by luck. This is what makes building a
  /// bonus and spending it well the way to score, rather than tapping quickly.
  static const int specialBonus = 120;

  /// Points for one clear step.
  ///
  /// - [clearedCount]: number of tiles removed this step.
  /// - [longestRun]: length of the longest single run in this step (>= 3), or
  ///   zero for a step driven by a combo rather than a match.
  /// - [cascadeLevel]: 1 for the swap's own match, 2 for the first chain, etc.;
  ///   acts as a multiplier so deep cascades pay off.
  /// - [specialsTriggered]: how many effect gems fired in this step.
  static int clearScore({
    required int clearedCount,
    required int longestRun,
    required int cascadeLevel,
    int specialsTriggered = 0,
  }) {
    if (clearedCount <= 0) {
      return 0;
    }
    final int level = cascadeLevel < 1 ? 1 : cascadeLevel;
    final int base = clearedCount * basePerTile;
    final int specials =
        (specialsTriggered < 0 ? 0 : specialsTriggered) * specialBonus;
    return (base + _runBonus(longestRun) + specials) * level;
  }

  /// Flat bonus for big single runs (a 4-match and 5-match are special in most
  /// match-3 games even before special-tile spawns are introduced).
  static int _runBonus(int longestRun) {
    if (longestRun >= 5) {
      return 150;
    }
    if (longestRun == 4) {
      return 60;
    }
    return 0;
  }
}
