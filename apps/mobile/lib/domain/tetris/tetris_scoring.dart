import 'dart:math' as math;

/// Spin classification at lock time (T-spins only in this baseline).
enum TSpinType { none, mini, full }

/// Tetris Guideline scoring and the level/gravity curve. Pure functions, no
/// state — the engine threads level/combo/back-to-back/spin through them.
class TetrisScoring {
  const TetrisScoring._();

  /// Score for a lock action: [rows] cleared (0..4) at [level], with an
  /// optional T-spin [spin]. A back-to-back "difficult" clear (a Tetris, or a
  /// T-spin that clears lines) is multiplied by 1.5.
  static int actionScore({
    required int rows,
    required int level,
    TSpinType spin = TSpinType.none,
    bool backToBack = false,
  }) {
    final int base;
    switch (spin) {
      case TSpinType.full:
        base = switch (rows) {
          0 => 400,
          1 => 800,
          2 => 1200,
          3 => 1600,
          _ => 1600,
        };
      case TSpinType.mini:
        base = switch (rows) {
          0 => 100,
          1 => 200,
          2 => 400,
          _ => 400,
        };
      case TSpinType.none:
        base = switch (rows) {
          1 => 100,
          2 => 300,
          3 => 500,
          4 => 800,
          _ => 0,
        };
    }
    if (base == 0) {
      return 0;
    }
    final num scaled = base * level;
    return (isDifficult(rows: rows, spin: spin) && backToBack
            ? scaled * 1.5
            : scaled)
        .round();
  }

  /// Back-compat alias for a plain line clear (no spin).
  static int lineClearScore({
    required int clearedRows,
    required int level,
    bool backToBack = false,
  }) {
    return actionScore(
      rows: clearedRows,
      level: level,
      backToBack: backToBack,
    );
  }

  /// Whether an action counts as "difficult" for back-to-back chaining: a
  /// Tetris, or any T-spin that clears at least one line.
  static bool isDifficult({required int rows, TSpinType spin = TSpinType.none}) {
    if (rows == 4) {
      return true;
    }
    return spin != TSpinType.none && rows > 0;
  }

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
