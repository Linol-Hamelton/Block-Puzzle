import 'special_resolver.dart';
import 'tile.dart';
import 'tile_grid.dart';

/// The combinations produced by swapping two effect gems together.
///
/// Named because the player learns them by name: discovering that two bombs
/// make something bigger than one bomb is most of the reason to build them.
enum ComboKind {
  /// Two line gems: a full row and a full column.
  cross('CROSS'),

  /// A line gem and a bomb: three rows and three columns.
  megaCross('MEGA CROSS'),

  /// Two bombs: a 5x5 crater.
  megaBomb('MEGA BOMB'),

  /// A colour bomb and a line gem: every gem of that colour becomes a line gem
  /// and they all fire.
  colorLines('COLOR LINES'),

  /// A colour bomb and a bomb: every gem of that colour becomes a bomb.
  colorBlast('COLOR BLAST'),

  /// Two colour bombs: the board.
  wipe('WIPE'),

  /// A colour bomb swapped onto an ordinary gem: every gem of that colour.
  colorPick('COLOR PICK');

  const ComboKind(this.label);

  /// Short caption for the view to flash. A game term, not a UI string, which
  /// is why it lives with the rule that produces it.
  final String label;
}

/// A combo's opening blast: the board to detonate against and where to light it.
class ComboOutcome {
  const ComboOutcome({
    required this.kind,
    required this.grid,
    required this.trigger,
    this.colorBombTarget,
  });

  final ComboKind kind;

  /// The board with the combo's implied effects written onto it.
  ///
  /// Combos do not get their own detonation code. They paint the effects they
  /// mean onto the cells that are about to be cleared and then let the ordinary
  /// chain in [SpecialResolver] run, so there is exactly one implementation of
  /// "what an effect clears" and the combos cannot drift away from it.
  final TileGrid grid;

  /// Where the chain starts.
  final List<GridPos> trigger;

  /// The colour a colour bomb in [trigger] consumes.
  final TileColor? colorBombTarget;
}

/// The swap matrix: what happens when the player puts two effect gems together.
class SpecialCombo {
  const SpecialCombo();

  /// True when this swap is a move in its own right, with no match required.
  ///
  /// Two effect gems always combine. A colour bomb also combines with an
  /// ordinary gem - that is the only way to spend one deliberately, and the
  /// genre has taught players to expect it. A line gem or a bomb swapped onto
  /// an ordinary gem is *not* a move: it still has to form a match, or the
  /// player could burn their bonus by fumbling a drag.
  bool isComboSwap(TileGrid grid, GridPos a, GridPos b) {
    final Tile? ta = grid.tileAtPos(a);
    final Tile? tb = grid.tileAtPos(b);
    if (ta == null || tb == null) {
      return false;
    }
    if (ta.isSpecial && tb.isSpecial) {
      return true;
    }
    return ta.special == SpecialKind.colorBomb ||
        tb.special == SpecialKind.colorBomb;
  }

  /// Works out the combo for a swap that has **already been applied** to
  /// [grid], or null when the pair does not combine.
  ComboOutcome? prepare(TileGrid grid, GridPos a, GridPos b) {
    final Tile? ta = grid.tileAtPos(a);
    final Tile? tb = grid.tileAtPos(b);
    if (ta == null || tb == null) {
      return null;
    }
    final SpecialKind ka = ta.special;
    final SpecialKind kb = tb.special;

    final bool colorA = ka == SpecialKind.colorBomb;
    final bool colorB = kb == SpecialKind.colorBomb;

    if (colorA && colorB) {
      return ComboOutcome(
        kind: ComboKind.wipe,
        grid: grid,
        trigger: grid.filledPositions.toList(growable: false),
      );
    }

    if (colorA || colorB) {
      final GridPos bombAt = colorA ? a : b;
      final Tile partner = colorA ? tb : ta;
      return _colorBombAgainst(grid, bombAt, partner);
    }

    if (!ka.isSpecial || !kb.isSpecial) {
      return null;
    }

    final bool bombA = ka == SpecialKind.bomb;
    final bool bombB = kb == SpecialKind.bomb;

    if (bombA && bombB) {
      // Nine overlapping 3x3 blasts cover the full 5x5, corners included,
      // without a second definition of what a bomb clears.
      final List<GridPos> seeded = _square(grid, a, 1);
      return ComboOutcome(
        kind: ComboKind.megaBomb,
        grid: _paint(grid, seeded, SpecialKind.bomb),
        trigger: seeded,
      );
    }

    if (bombA || bombB) {
      final GridPos centre = bombA ? a : b;
      return _lineAndBomb(grid, centre);
    }

    // Two line gems, whatever their orientations were: a row and a column.
    return ComboOutcome(
      kind: ComboKind.cross,
      grid: _paint(grid, <GridPos>[a], SpecialKind.lineHorizontal)
          .withSpecialAt(b, SpecialKind.lineVertical),
      trigger: <GridPos>[a, b],
    );
  }

  /// A colour bomb against anything that is not another colour bomb.
  ///
  /// The bomb is the only trigger. It clears every gem of the partner's colour,
  /// and because those cells now carry the partner's effect, each one fires as
  /// the chain reaches it.
  ComboOutcome _colorBombAgainst(TileGrid grid, GridPos bombAt, Tile partner) {
    final TileColor target = partner.color;
    if (!partner.isSpecial) {
      return ComboOutcome(
        kind: ComboKind.colorPick,
        grid: grid,
        trigger: <GridPos>[bombAt],
        colorBombTarget: target,
      );
    }

    final List<GridPos> sameColor = grid.filledPositions
        .where((GridPos p) => grid.atPos(p) == target)
        .toList(growable: false);

    if (partner.special == SpecialKind.bomb) {
      return ComboOutcome(
        kind: ComboKind.colorBlast,
        grid: _paint(grid, sameColor, SpecialKind.bomb),
        trigger: <GridPos>[bombAt],
        colorBombTarget: target,
      );
    }

    // Alternating orientation, chosen by parity rather than at random so the
    // same move plays out the same way on a replayed seed.
    TileGrid painted = grid;
    for (final GridPos p in sameColor) {
      painted = painted.withSpecialAt(
        p,
        (p.x + p.y).isEven
            ? SpecialKind.lineHorizontal
            : SpecialKind.lineVertical,
      );
    }
    return ComboOutcome(
      kind: ComboKind.colorLines,
      grid: painted,
      trigger: <GridPos>[bombAt],
      colorBombTarget: target,
    );
  }

  /// A line gem and a bomb: the bomb widens the line into a three-wide band in
  /// both axes. Built from line gems so the clipping rules stay in one place.
  ComboOutcome _lineAndBomb(TileGrid grid, GridPos centre) {
    final List<GridPos> rows = <GridPos>[
      for (int dy = -1; dy <= 1; dy++)
        if (grid.inBounds(centre.x, centre.y + dy))
          GridPos(centre.x, centre.y + dy),
    ];
    final List<GridPos> columns = <GridPos>[
      for (int dx = -1; dx <= 1; dx++)
        if (dx != 0 && grid.inBounds(centre.x + dx, centre.y))
          GridPos(centre.x + dx, centre.y),
    ];
    TileGrid painted = _paint(grid, rows, SpecialKind.lineHorizontal);
    painted = _paint(painted, columns, SpecialKind.lineVertical);
    return ComboOutcome(
      kind: ComboKind.megaCross,
      grid: painted,
      trigger: <GridPos>[...rows, ...columns],
    );
  }

  List<GridPos> _square(TileGrid grid, GridPos centre, int radius) => <GridPos>[
        for (int dy = -radius; dy <= radius; dy++)
          for (int dx = -radius; dx <= radius; dx++)
            if (grid.inBounds(centre.x + dx, centre.y + dy))
              GridPos(centre.x + dx, centre.y + dy),
      ];

  TileGrid _paint(TileGrid grid, Iterable<GridPos> cells, SpecialKind kind) {
    TileGrid painted = grid;
    for (final GridPos p in cells) {
      painted = painted.withSpecialAt(p, kind);
    }
    return painted;
  }
}
