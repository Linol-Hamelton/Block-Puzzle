import 'falling_piece.dart';
import 'tetromino.dart';

/// Result of clearing full rows: the resulting board and how many rows cleared.
class LineClearOutcome {
  const LineClearOutcome(this.board, this.clearedRows);

  final TetrisBoard board;
  final int clearedRows;
}

/// A rectangular Tetris playfield. Each cell holds the [TetrominoType] of the
/// locked mino occupying it (for color), or `null` when empty. Coordinates are
/// y-down, x-right, origin at the top-left of the visible field.
///
/// Cells with `y < 0` represent the spawn buffer above the field: they never
/// collide and are dropped on lock (a piece that would lock with cells above
/// the top is a top-out, detected by the engine).
class TetrisBoard {
  TetrisBoard({
    this.width = 10,
    this.height = 20,
    List<TetrominoType?>? cells,
  }) : _cells = cells ?? List<TetrominoType?>.filled(width * height, null) {
    assert(_cells.length == width * height, 'cells length must be width*height');
  }

  final int width;
  final int height;
  final List<TetrominoType?> _cells;

  int _index(int x, int y) => (y * width) + x;

  bool isInBounds(int x, int y) =>
      x >= 0 && x < width && y >= 0 && y < height;

  TetrominoType? cellAt(int x, int y) =>
      isInBounds(x, y) ? _cells[_index(x, y)] : null;

  bool isFilled(int x, int y) => cellAt(x, y) != null;

  /// True if [piece] overlaps a wall, the floor, or a locked cell. Cells above
  /// the field (`y < 0`) are allowed.
  bool collides(FallingPiece piece) {
    for (final TCell c in piece.absoluteCells()) {
      if (c.x < 0 || c.x >= width || c.y >= height) {
        return true;
      }
      if (c.y >= 0 && _cells[_index(c.x, c.y)] != null) {
        return true;
      }
    }
    return false;
  }

  /// Locks [piece] into a new board. Cells above the top are dropped.
  TetrisBoard lock(FallingPiece piece) {
    final List<TetrominoType?> next = List<TetrominoType?>.of(_cells);
    for (final TCell c in piece.absoluteCells()) {
      if (c.y >= 0 && isInBounds(c.x, c.y)) {
        next[_index(c.x, c.y)] = piece.type;
      }
    }
    return TetrisBoard(width: width, height: height, cells: next);
  }

  bool isRowFull(int y) {
    for (int x = 0; x < width; x++) {
      if (_cells[_index(x, y)] == null) {
        return false;
      }
    }
    return true;
  }

  /// Indices of every fully-occupied row (top to bottom). Used to animate the
  /// clear before [clearFullRows] collapses the board.
  List<int> fullRows() {
    final List<int> rows = <int>[];
    for (int y = 0; y < height; y++) {
      if (isRowFull(y)) {
        rows.add(y);
      }
    }
    return rows;
  }

  /// True when no cell is occupied — for Perfect Clear (All-Clear) detection.
  bool get isEmpty {
    for (final TetrominoType? cell in _cells) {
      if (cell != null) {
        return false;
      }
    }
    return true;
  }

  /// Removes full rows and collapses everything above them downward.
  LineClearOutcome clearFullRows() {
    final List<List<TetrominoType?>> survivingRows = <List<TetrominoType?>>[];
    int cleared = 0;
    for (int y = 0; y < height; y++) {
      if (isRowFull(y)) {
        cleared += 1;
        continue;
      }
      survivingRows.add(
        _cells.sublist(_index(0, y), _index(0, y) + width),
      );
    }
    if (cleared == 0) {
      return LineClearOutcome(this, 0);
    }

    final List<TetrominoType?> next =
        List<TetrominoType?>.filled(width * height, null);
    // Surviving rows keep their relative order and settle to the bottom.
    final int offset = height - survivingRows.length;
    for (int i = 0; i < survivingRows.length; i++) {
      final List<TetrominoType?> row = survivingRows[i];
      final int destY = offset + i;
      for (int x = 0; x < width; x++) {
        next[_index(x, destY)] = row[x];
      }
    }
    return LineClearOutcome(
      TetrisBoard(width: width, height: height, cells: next),
      cleared,
    );
  }

  /// The lowest number of rows [piece] can drop before colliding (for ghost /
  /// hard-drop). Returns 0 if the piece cannot move down.
  int dropDistance(FallingPiece piece) {
    int distance = 0;
    while (!collides(piece.movedBy(0, distance + 1))) {
      distance += 1;
    }
    return distance;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'width': width,
        'height': height,
        'cells': _cells.map((TetrominoType? t) => t?.name).toList(growable: false),
      };

  factory TetrisBoard.fromJson(Map<String, Object?> json) {
    final int width = (json['width'] as int?) ?? 10;
    final int height = (json['height'] as int?) ?? 20;
    final List<dynamic> raw =
        (json['cells'] as List<dynamic>?) ?? <dynamic>[];
    final List<TetrominoType?> cells = List<TetrominoType?>.generate(
      width * height,
      (int i) {
        if (i >= raw.length) {
          return null;
        }
        final Object? name = raw[i];
        if (name is! String) {
          return null;
        }
        for (final TetrominoType t in TetrominoType.values) {
          if (t.name == name) {
            return t;
          }
        }
        return null;
      },
    );
    return TetrisBoard(width: width, height: height, cells: cells);
  }
}
