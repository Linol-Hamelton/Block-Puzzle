import 'tile.dart';

/// A rectangular Match-3 board. Each cell holds a [Tile] - a colour plus the
/// effect it carries - or `null` for a transient hole (during the clear →
/// gravity → refill window). A settled board has no nulls. Coordinates are
/// y-down, x-right, origin at the top-left (gravity pulls toward higher y).
///
/// Instances are treated as immutable: mutating operations ([swapped],
/// [withCell], [clearedAt]) return a new grid, mirroring [TetrisBoard].
///
/// Cells used to be bare [TileColor]s. They carry a [Tile] now because a board
/// with no room for an effect cannot express a bonus gem at all - the reason
/// specials were deferred when this module was first written.
class TileGrid {
  TileGrid({
    required this.width,
    required this.height,
    List<Tile?>? cells,
  }) : _cells = cells ?? List<Tile?>.filled(width * height, null) {
    assert(_cells.length == width * height, 'cells length must be width*height');
  }

  /// Convenience for tests and fixtures: builds a board of plain gems.
  factory TileGrid.ofColors({
    required int width,
    required int height,
    required List<TileColor?> colors,
  }) {
    return TileGrid(
      width: width,
      height: height,
      cells: colors
          .map((TileColor? c) => c == null ? null : Tile(c))
          .toList(growable: false),
    );
  }

  final int width;
  final int height;
  final List<Tile?> _cells;

  int _index(int x, int y) => (y * width) + x;

  bool inBounds(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  Tile? tileAt(int x, int y) => inBounds(x, y) ? _cells[_index(x, y)] : null;

  Tile? tileAtPos(GridPos p) => tileAt(p.x, p.y);

  /// The colour at a cell, ignoring any effect it carries.
  ///
  /// Matching is by colour: a line gem still matches its plain neighbours,
  /// which is what lets a player build one special out of another.
  TileColor? at(int x, int y) => tileAt(x, y)?.color;

  TileColor? atPos(GridPos p) => at(p.x, p.y);

  SpecialKind specialAt(GridPos p) =>
      tileAtPos(p)?.special ?? SpecialKind.none;

  /// True when every cell is filled (the settled, playable state).
  bool get isFull {
    for (final Tile? c in _cells) {
      if (c == null) {
        return false;
      }
    }
    return true;
  }

  /// Every filled position, top-left to bottom-right.
  Iterable<GridPos> get filledPositions sync* {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (_cells[_index(x, y)] != null) {
          yield GridPos(x, y);
        }
      }
    }
  }

  /// Returns a copy with the tiles at [a] and [b] exchanged. Out-of-bounds
  /// positions are ignored (the caller validates adjacency first).
  TileGrid swapped(GridPos a, GridPos b) {
    if (!inBounds(a.x, a.y) || !inBounds(b.x, b.y)) {
      return this;
    }
    final List<Tile?> next = List<Tile?>.of(_cells);
    final int ia = _index(a.x, a.y);
    final int ib = _index(b.x, b.y);
    final Tile? tmp = next[ia];
    next[ia] = next[ib];
    next[ib] = tmp;
    return TileGrid(width: width, height: height, cells: next);
  }

  /// Returns a copy with [tile] (or null) written at ([x],[y]).
  TileGrid withCell(int x, int y, Tile? tile) {
    if (!inBounds(x, y)) {
      return this;
    }
    final List<Tile?> next = List<Tile?>.of(_cells);
    next[_index(x, y)] = tile;
    return TileGrid(width: width, height: height, cells: next);
  }

  /// Returns a copy with the effect at [p] replaced, keeping its colour.
  TileGrid withSpecialAt(GridPos p, SpecialKind kind) {
    final Tile? existing = tileAtPos(p);
    if (existing == null) {
      return this;
    }
    return withCell(p.x, p.y, existing.withSpecial(kind));
  }

  /// Returns a copy with every position in [cells] set to null (cleared).
  TileGrid clearedAt(Iterable<GridPos> cells) {
    final List<Tile?> next = List<Tile?>.of(_cells);
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
        'cells': _cells.map((Tile? c) => c?.toJson()).toList(growable: false),
      };

  /// Reads a board back.
  ///
  /// Cells written before specials existed are bare colour names; [Tile.fromJson]
  /// accepts both forms, so an older snapshot loads as a board of plain gems
  /// rather than failing.
  factory TileGrid.fromJson(Map<String, Object?> json) {
    final int width = (json['width'] as int?) ?? 8;
    final int height = (json['height'] as int?) ?? 8;
    final List<dynamic> raw = (json['cells'] as List<dynamic>?) ?? <dynamic>[];
    final List<Tile?> cells = List<Tile?>.generate(
      width * height,
      (int i) => i < raw.length ? Tile.fromJson(raw[i]) : null,
    );
    return TileGrid(width: width, height: height, cells: cells);
  }
}
