import 'match_detector.dart';
import 'tile.dart';
import 'tile_grid.dart';

/// Validates a player swap: two tiles may only be exchanged if they are
/// orthogonally adjacent and the exchange creates at least one match. This is
/// the "revert on no-match" rule of classic Match-3.
class SwapValidator {
  const SwapValidator({MatchDetector detector = const MatchDetector()})
      : _detector = detector;

  final MatchDetector _detector;

  /// True if [a] and [b] are orthogonal neighbors exactly one cell apart.
  bool isAdjacent(GridPos a, GridPos b) {
    final int dx = (a.x - b.x).abs();
    final int dy = (a.y - b.y).abs();
    return (dx + dy) == 1;
  }

  /// True if exchanging [a] and [b] yields a board with at least one match.
  /// Does not require adjacency — combine with [isAdjacent] for a legal move.
  bool producesMatch(TileGrid grid, GridPos a, GridPos b) {
    if (grid.atPos(a) == null || grid.atPos(b) == null) {
      return false;
    }
    return _detector.hasMatch(grid.swapped(a, b));
  }

  /// A fully legal player move: adjacent AND creates a match.
  bool isLegalSwap(TileGrid grid, GridPos a, GridPos b) =>
      isAdjacent(a, b) && producesMatch(grid, a, b);
}
