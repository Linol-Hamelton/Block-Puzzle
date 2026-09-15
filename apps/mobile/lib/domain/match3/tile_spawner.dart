import '../shared/deterministic_random.dart';
import 'tile.dart';
import 'tile_grid.dart';

/// Produces tiles for the initial board and for refilling after a cascade.
/// Seeded for deterministic boards (daily challenge / replay) and unit tests.
class TileSpawner {
  TileSpawner({int? seed, int colorCount = 6})
      : this._withSeed(seed ?? _freshSeed(), colorCount);

  TileSpawner._withSeed(int seed, int colorCount)
      : assert(colorCount >= 3 && colorCount <= TileColor.values.length,
            'colorCount must be in 3..${TileColor.values.length}'),
        _seed = seed,
        _random = DeterministicRandom(seed),
        _colors = TileColor.values.sublist(0, colorCount);

  TileSpawner._restored(int seed, int state, int colorCount)
      : _seed = seed,
        _random = DeterministicRandom.fromState(state),
        _colors = TileColor.values.sublist(0, colorCount);

  /// A seed is always recorded, even when the caller did not supply one, so a
  /// run started without one can still be resumed exactly.
  static int _freshSeed() => DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;

  final int _seed;
  final DeterministicRandom _random;
  final List<TileColor> _colors;

  int get seed => _seed;

  int get colorCount => _colors.length;

  /// Everything needed to keep producing the same tiles after a restart.
  ///
  /// Without this the snapshot carried the board but not the generator, so the
  /// same legal swap resolved into a different board before and after a resume.
  Map<String, Object?> toJson() => <String, Object?>{
        'seed': _seed,
        'state': _random.state,
        'color_count': _colors.length,
      };

  /// Rebuilds a spawner mid-sequence. Falls back to a fresh one on a missing or
  /// malformed payload, which is better than refusing to resume the run.
  static TileSpawner fromJson(Map<String, Object?>? json, {int colorCount = 6}) {
    if (json == null) {
      return TileSpawner(colorCount: colorCount);
    }
    final Object? seed = json['seed'];
    final Object? state = json['state'];
    final Object? colors = json['color_count'];
    if (seed is! int || state is! int) {
      return TileSpawner(colorCount: colorCount);
    }
    final int restoredColors =
        colors is int && colors >= 3 && colors <= TileColor.values.length
            ? colors
            : colorCount;
    return TileSpawner._restored(seed, state, restoredColors);
  }

  /// A uniformly-random color from the active palette.
  TileColor next() => _colors[_random.nextInt(_colors.length)];

  /// Builds a starting board with **no pre-existing match**: each cell avoids a
  /// color that would complete a run of three with its already-placed left or
  /// top neighbors. (Solvability — that a legal move exists — is enforced by the
  /// engine, which reshuffles if the fresh board is a dead end.)
  TileGrid fillInitial(int width, int height) {
    final List<Tile?> cells = List<Tile?>.filled(width * height, null);
    int index(int x, int y) => (y * width) + x;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Compare colours, not whole tiles: a fresh board has no specials, but
        // reading the colour keeps this correct if that ever changes.
        TileColor? colorAt(int cx, int cy) => cells[index(cx, cy)]?.color;

        final TileColor? leftMatch =
            (x >= 2 && colorAt(x - 1, y) == colorAt(x - 2, y))
                ? colorAt(x - 1, y)
                : null;
        final TileColor? upMatch =
            (y >= 2 && colorAt(x, y - 1) == colorAt(x, y - 2))
                ? colorAt(x, y - 1)
                : null;
        TileColor color = next();
        // Reroll until it doesn't extend a pair into a triple. The palette has
        // >= 3 colors, so a valid choice always exists.
        while (color == leftMatch || color == upMatch) {
          color = next();
        }
        cells[index(x, y)] = Tile(color);
      }
    }
    return TileGrid(width: width, height: height, cells: cells);
  }

  /// Fills every null cell of [grid] (the holes left after gravity) with fresh
  /// random tiles. New matches are allowed — they drive the cascade.
  TileGrid refill(TileGrid grid) {
    TileGrid result = grid;
    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        if (result.at(x, y) == null) {
          result = result.withCell(x, y, Tile(next()));
        }
      }
    }
    return result;
  }
}
