/// Match-3 scoring rules. Pure and static, mirroring `TetrisScoring`.
///
/// Score for one clear step scales with the number of tiles removed, the length
/// of the longest run (4/5-in-a-row bonuses), and the cascade depth (a chain
/// reaction is worth progressively more).
class Match3Scoring {
  const Match3Scoring._();

  /// Base points awarded per cleared tile.
  static const int basePerTile = 30;

  /// Points for one clear step.
  ///
  /// - [clearedCount]: number of tiles removed this step.
  /// - [longestRun]: length of the longest single run in this step (>= 3).
  /// - [cascadeLevel]: 1 for the swap's own match, 2 for the first chain, etc.;
  ///   acts as a multiplier so deep cascades pay off.
  static int clearScore({
    required int clearedCount,
    required int longestRun,
    required int cascadeLevel,
  }) {
    if (clearedCount <= 0) {
      return 0;
    }
    final int level = cascadeLevel < 1 ? 1 : cascadeLevel;
    final int base = clearedCount * basePerTile;
    return (base + _runBonus(longestRun)) * level;
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
