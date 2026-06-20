/// Pure-domain Match-3 primitives. No Flutter/Flame dependencies — mirrors the
/// SDK-independent discipline of `lib/domain/gameplay` and `lib/domain/tetris`.
///
/// Geometry convention: board coordinates have **y increasing downward** (row 0
/// at the top, gravity pulls tiles toward higher y), x increasing to the right,
/// origin at the top-left — matching `TetrisBoard` and `BoardState`.
library;

/// A cell position on the Match-3 grid.
class GridPos {
  const GridPos(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is GridPos && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

/// Gem colors. The spawner uses the first `colorCount` of these, so the
/// declaration order is the difficulty order (fewer colors = easier).
///
/// Specials (line/bomb gems) are intentionally out of scope for this core: the
/// match/cascade state machine is validated on plain tiles first, since the
/// special×special detonation matrix is the classic source of match-3 clone
/// bugs (see the multi-game plan, risk #2).
enum TileColor { ruby, amber, citrine, emerald, sapphire, amethyst }

/// Resolves a persisted color name back to its enum value, or null.
TileColor? tileColorFromName(Object? name) {
  if (name is! String) {
    return null;
  }
  for (final TileColor c in TileColor.values) {
    if (c.name == name) {
      return c;
    }
  }
  return null;
}
