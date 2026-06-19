import 'dart:math' as math;

/// Tetris Guideline scoring and the level/gravity curve. Pure functions, no
/// state — the engine threads level/combo/back-to-back through them.
class TetrisScoring {
  const TetrisScoring._();

  /// Base score for clearing [clearedRows] (1..4) at [level]. A back-to-back
  /// "difficult" clear (a Tetris, or later a T-spin) is multiplied by 1.5.
  static int lineClearScore({
    required int clearedRows,
    required int level,
    bool backToBack = false,
  }) {
    final int base = switch (clearedRows) {
      1 => 100,
      2 => 300,
      3 => 500,
      4 => 800,
      _ => 0,
    };
    if (base == 0) {
      return 0;
    }
    final num scaled = base * level;
    // Only a Tetris (4 lines) is "difficult" for back-to-back in this baseline
    // (T-spin recognition lands later).
    final bool difficult = clearedRows == 4;
    return (difficult && backToBack ? scaled * 1.5 : scaled).round();
  }

  /// Whether a clear counts as "difficult" for back-to-back chaining.
  static bool isDifficultClear(int clearedRows) => clearedRows == 4;

  /// Combo bonus. [combo] is the number of consecutive piece placements that
  /// cleared at least one line, counting from 0 for the first.
  static int comboScore({required int combo, required int level}) =>
      combo > 0 ? 50 * combo * level : 0;

  static int softDropScore(int cells) => cells < 0 ? 0 : cells;

  static int hardDropScore(int cells) => cells < 0 ? 0 : 2 * cells;

  /// Level derived from total cleared lines (10 lines per level), starting at 1.
  static int levelForLines(int totalLines) =>
      1 + (totalLines < 0 ? 0 : totalLines ~/ 10);

  /// Gravity: seconds a piece takes to fall one row at [level], using the
  /// Tetris Worlds curve `(0.8 - (level-1)*0.007)^(level-1)`. Clamped so very
  /// high levels stay renderable.
  static Duration gravityInterval(int level) {
    final int l = level < 1 ? 1 : level;
    final double base = 0.8 - ((l - 1) * 0.007);
    final double seconds = math.pow(base <= 0 ? 0.0001 : base, l - 1).toDouble();
    final int ms = (seconds * 1000).round();
    return Duration(milliseconds: ms.clamp(1, 1000));
  }
}
