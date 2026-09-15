import 'tile.dart';
import 'tile_grid.dart';

/// The cells one detonation chain reached, and how it got there.
class DetonationResult {
  const DetonationResult({
    required this.cells,
    required this.triggered,
  });

  /// Every cell cleared by the chain, each appearing once.
  final Set<GridPos> cells;

  /// The specials that actually went off, in the order they fired. Useful for
  /// scoring and for staging the animation.
  final List<SpecialKind> triggered;

  bool get isEmpty => cells.isEmpty;
}

/// Works out what a set of clearing cells actually removes once the specials
/// among them go off.
///
/// This is the part the multi-game plan flagged as the top source of clone
/// bugs, and the reason is worth stating: the effects feed each other. Clearing
/// a bomb removes a line gem, whose row contains a colour bomb, whose colour
/// includes another bomb. Implemented as recursion it either loops forever or
/// clears the same cell twice and scores it twice.
///
/// So there is exactly one queue and one visited set. A cell enters the cleared
/// set once. A special fires once, when it is first reached, and is then inert
/// even if another effect sweeps over it. The chain is finite because every
/// iteration removes a position from a board of fixed size.
class SpecialResolver {
  const SpecialResolver();

  /// Expands [initial] into everything the chain clears.
  ///
  /// [colorBombTarget] is the colour a colour bomb consumes when it is set off
  /// by a match rather than by a swap. When a colour bomb is swapped onto a
  /// gem, the caller passes that gem's colour instead.
  DetonationResult resolve(
    TileGrid grid,
    Iterable<GridPos> initial, {
    TileColor? colorBombTarget,
  }) {
    final Set<GridPos> cleared = <GridPos>{};
    final List<SpecialKind> triggered = <SpecialKind>[];
    final List<GridPos> queue = <GridPos>[];

    for (final GridPos p in initial) {
      if (grid.inBounds(p.x, p.y) && cleared.add(p)) {
        queue.add(p);
      }
    }

    while (queue.isNotEmpty) {
      final GridPos position = queue.removeAt(0);
      final Tile? tile = grid.tileAtPos(position);
      if (tile == null || !tile.isSpecial) {
        continue;
      }

      triggered.add(tile.special);
      for (final GridPos affected in _affectedBy(
        grid,
        position,
        tile,
        colorBombTarget: colorBombTarget,
      )) {
        // add() returns false for a cell the chain already reached, which is
        // what keeps the work finite and stops a cell being scored twice.
        if (cleared.add(affected)) {
          queue.add(affected);
        }
      }
    }

    return DetonationResult(cells: cleared, triggered: triggered);
  }

  Iterable<GridPos> _affectedBy(
    TileGrid grid,
    GridPos origin,
    Tile tile, {
    TileColor? colorBombTarget,
  }) sync* {
    switch (tile.special) {
      case SpecialKind.none:
        return;

      case SpecialKind.lineHorizontal:
        for (int x = 0; x < grid.width; x++) {
          yield GridPos(x, origin.y);
        }

      case SpecialKind.lineVertical:
        for (int y = 0; y < grid.height; y++) {
          yield GridPos(origin.x, y);
        }

      case SpecialKind.bomb:
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final int x = origin.x + dx;
            final int y = origin.y + dy;
            if (grid.inBounds(x, y)) {
              yield GridPos(x, y);
            }
          }
        }

      case SpecialKind.colorBomb:
        // Consumes the colour it was swapped against when there is one, and
        // otherwise its own - so a colour bomb caught in a cascade still does
        // something rather than silently vanishing.
        final TileColor target = colorBombTarget ?? tile.color;
        for (final GridPos p in grid.filledPositions) {
          if (grid.atPos(p) == target) {
            yield p;
          }
        }
    }
  }
}
