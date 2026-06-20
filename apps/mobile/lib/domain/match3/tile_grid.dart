import 'tile.dart';

/// A rectangular Match-3 board. Each cell holds the [TileColor] of its gem, or
/// `null` for a transient hole (during the clear → gravity → refill window).
/// A settled board has no nulls. Coordinates are y-down, x-right, origin at the
/// top-left (gravity pulls toward higher y).
///
/// Instances are treated as immutable: mutating operations ([swapped],
/// [withCell], [clearedAt]) return a new grid, mirroring [TetrisBoard].
class TileGrid {
  TileGrid({
    required this.width,
    required this.height,
    List<TileColor?>? cells,
  }) : _cells = cells ?? List<TileColor?>.filled(width * height, null) {
    assert(_cells.length == width * height, 'cells length must be width*height');
  }

  final int width;
  final int height;
  final List<TileColor?> _cells;

  int _index(int x, int y) => (y * width) + x;

  bool inBounds(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  TileColor? at(int x, int y) => inBounds(x, y) ? _cells[_index(x, y)] : null;

  TileColor? atPos(GridPos p) => at(p.x, p.y);

  /// True when every cell is filled (the settled, playable state).
  bool get isFull {
    for (final TileColor? c in _cells) {
      if (c == null) {
        return false;
      }
    }
    return true;
  }

  /// Returns a copy with the tiles at [a] and [b] exchanged. Out-of-bounds
  /// positions are ignored (the caller validates adjacency first).
  TileGrid swapped(GridPos a, GridPos b) {
    if (!inBounds(a.x, a.y) || !inBounds(b.x, b.y)) {
      return this;
    }
    final List<TileColor?> next = List<TileColor?>.of(_cells);
    final int ia = _index(a.x, a.y);
    final int ib = _index(b.x, b.y);
    final TileColor? tmp = next[ia];
    next[ia] = next[ib];
    next[ib] = tmp;
    return TileGrid(width: width, height: height, cells: next);
  }

  /// Returns a copy with [color] (or null) written at ([x],[y]).
  TileGrid withCell(int x, int y, TileColor? color) {
    if (!inBounds(x, y)) {
      return this;
    }
    final List<TileColor?> next = List<TileColor?>.of(_cells);
    next[_index(x, y)] = color;
    return TileGrid(width: width, height: height, cells: next);
  }

  /// Returns a copy with every position in [cells] set to null (cleared).
  TileGrid clearedAt(Iterable<GridPos> cells) {
    final List<TileColor?> next = List<TileColor?>.of(_cells);
    for (final GridPos p in cells) {
      if (inBounds(p.x, p.y)) {
        next[_index(p.x, p.y)] = null;
      }
    }
    return TileGrid(width: width, height: height, cells: next);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'width': width,
        'height': height,
        'cells':
            _cells.map((TileColor? c) => c?.name).toList(growable: false),
      };

  factory TileGrid.fromJson(Map<String, Object?> json) {
    final int width = (json['width'] as int?) ?? 8;
    final int height = (json['height'] as int?) ?? 8;
    final List<dynamic> raw = (json['cells'] as List<dynamic>?) ?? <dynamic>[];
    final List<TileColor?> cells = List<TileColor?>.generate(
      width * height,
      (int i) => i < raw.length ? tileColorFromName(raw[i]) : null,
    );
    return TileGrid(width: width, height: height, cells: cells);
  }
}
