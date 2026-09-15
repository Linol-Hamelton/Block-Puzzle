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
enum TileColor { ruby, amber, citrine, emerald, sapphire, amethyst }

/// What a tile does when it is cleared.
///
/// The multi-game plan named this the top clone-bug risk, because the effects
/// chain: clearing a bomb can clear a line gem, which clears a colour bomb, and
/// a careless implementation either loops forever or double-counts the same
/// cell. Every effect here is resolved through one queue in [SpecialResolver]
/// with a visited set, so a cell is cleared once and scored once no matter how
/// many effects reach it.
enum SpecialKind {
  /// An ordinary gem.
  none,

  /// Clears its whole row. Spawned by a horizontal run of exactly four.
  lineHorizontal,

  /// Clears its whole column. Spawned by a vertical run of exactly four.
  lineVertical,

  /// Clears the 3x3 block around itself. Spawned where a horizontal and a
  /// vertical run cross - the T and L shapes.
  bomb,

  /// Clears every tile sharing its colour. Spawned by a run of five or more.
  colorBomb;

  bool get isSpecial => this != SpecialKind.none;
}

/// One cell: a colour plus whatever effect it carries.
class Tile {
  const Tile(this.color, [this.special = SpecialKind.none]);

  final TileColor color;
  final SpecialKind special;

  bool get isSpecial => special.isSpecial;

  Tile withSpecial(SpecialKind kind) => Tile(color, kind);

  Tile get plain => Tile(color);

  @override
  bool operator ==(Object other) =>
      other is Tile && other.color == color && other.special == special;

  @override
  int get hashCode => Object.hash(color, special);

  @override
  String toString() =>
      special == SpecialKind.none ? color.name : '${color.name}:${special.name}';

  Map<String, Object?> toJson() => <String, Object?>{
        'c': color.name,
        if (special != SpecialKind.none) 's': special.name,
      };

  /// Reads a tile from persisted JSON.
  ///
  /// Also accepts a bare colour name, which is what version 1 snapshots and
  /// boards stored before specials existed. Such a tile loads as plain rather
  /// than failing the whole restore.
  static Tile? fromJson(Object? json) {
    if (json is String) {
      final TileColor? color = tileColorFromName(json);
      return color == null ? null : Tile(color);
    }
    if (json is Map) {
      final TileColor? color = tileColorFromName(json['c']);
      if (color == null) {
        return null;
      }
      return Tile(color, _specialFromName(json['s']));
    }
    return null;
  }

  static SpecialKind _specialFromName(Object? name) {
    if (name is! String) {
      return SpecialKind.none;
    }
    for (final SpecialKind kind in SpecialKind.values) {
      if (kind.name == name) {
        return kind;
      }
    }
    return SpecialKind.none;
  }
}

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
