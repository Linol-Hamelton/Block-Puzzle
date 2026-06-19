/// Pure-domain Tetris piece model. No Flutter/Flame dependencies — mirrors the
/// SDK-independent discipline of `lib/domain/gameplay`.
///
/// Geometry convention: board coordinates have **y increasing downward** (row 0
/// at the top), matching `BoardState`. Each tetromino's four rotation states are
/// expressed as cells inside a local bounding box (3×3 for J/L/S/T/Z, 4×4 for I,
/// 2×2 for O). A piece on the board has an origin (the box's top-left in board
/// coordinates); a cell's board position is `origin + boxCell`.
///
/// Rotation indices follow the Tetris Guideline: 0 = spawn, 1 = R (one step
/// clockwise), 2 = 180°, 3 = L (one step counter-clockwise).
library;

/// A cell offset inside a tetromino's bounding box.
class TCell {
  const TCell(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is TCell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

enum TetrominoType { i, j, l, o, s, t, z }

/// Static tetromino data: the four rotation states and the bounding-box size.
class Tetromino {
  const Tetromino({
    required this.type,
    required this.boxSize,
    required this.states,
  });

  final TetrominoType type;

  /// Side length of the (square) bounding box the [states] are expressed in.
  final int boxSize;

  /// `states[rotationIndex]` → the four filled cells for that rotation.
  final List<List<TCell>> states;

  List<TCell> cellsAt(int rotationIndex) => states[rotationIndex & 3];

  static Tetromino of(TetrominoType type) => _all[type]!;

  static const List<TetrominoType> spawnOrder = <TetrominoType>[
    TetrominoType.i,
    TetrominoType.j,
    TetrominoType.l,
    TetrominoType.o,
    TetrominoType.s,
    TetrominoType.t,
    TetrominoType.z,
  ];

  static const Map<TetrominoType, Tetromino> _all =
      <TetrominoType, Tetromino>{
    // I — 4×4 box.
    TetrominoType.i: Tetromino(
      type: TetrominoType.i,
      boxSize: 4,
      states: <List<TCell>>[
        <TCell>[TCell(0, 1), TCell(1, 1), TCell(2, 1), TCell(3, 1)],
        <TCell>[TCell(2, 0), TCell(2, 1), TCell(2, 2), TCell(2, 3)],
        <TCell>[TCell(0, 2), TCell(1, 2), TCell(2, 2), TCell(3, 2)],
        <TCell>[TCell(1, 0), TCell(1, 1), TCell(1, 2), TCell(1, 3)],
      ],
    ),
    // O — 2×2 box, identical across rotations (no wall kicks).
    TetrominoType.o: Tetromino(
      type: TetrominoType.o,
      boxSize: 2,
      states: <List<TCell>>[
        <TCell>[TCell(0, 0), TCell(1, 0), TCell(0, 1), TCell(1, 1)],
        <TCell>[TCell(0, 0), TCell(1, 0), TCell(0, 1), TCell(1, 1)],
        <TCell>[TCell(0, 0), TCell(1, 0), TCell(0, 1), TCell(1, 1)],
        <TCell>[TCell(0, 0), TCell(1, 0), TCell(0, 1), TCell(1, 1)],
      ],
    ),
    // T — 3×3 box.
    TetrominoType.t: Tetromino(
      type: TetrominoType.t,
      boxSize: 3,
      states: <List<TCell>>[
        <TCell>[TCell(1, 0), TCell(0, 1), TCell(1, 1), TCell(2, 1)],
        <TCell>[TCell(1, 0), TCell(1, 1), TCell(2, 1), TCell(1, 2)],
        <TCell>[TCell(0, 1), TCell(1, 1), TCell(2, 1), TCell(1, 2)],
        <TCell>[TCell(1, 0), TCell(0, 1), TCell(1, 1), TCell(1, 2)],
      ],
    ),
    // J — 3×3 box.
    TetrominoType.j: Tetromino(
      type: TetrominoType.j,
      boxSize: 3,
      states: <List<TCell>>[
        <TCell>[TCell(0, 0), TCell(0, 1), TCell(1, 1), TCell(2, 1)],
        <TCell>[TCell(1, 0), TCell(2, 0), TCell(1, 1), TCell(1, 2)],
        <TCell>[TCell(0, 1), TCell(1, 1), TCell(2, 1), TCell(2, 2)],
        <TCell>[TCell(1, 0), TCell(1, 1), TCell(0, 2), TCell(1, 2)],
      ],
    ),
    // L — 3×3 box.
    TetrominoType.l: Tetromino(
      type: TetrominoType.l,
      boxSize: 3,
      states: <List<TCell>>[
        <TCell>[TCell(2, 0), TCell(0, 1), TCell(1, 1), TCell(2, 1)],
        <TCell>[TCell(1, 0), TCell(1, 1), TCell(1, 2), TCell(2, 2)],
        <TCell>[TCell(0, 1), TCell(1, 1), TCell(2, 1), TCell(0, 2)],
        <TCell>[TCell(0, 0), TCell(1, 0), TCell(1, 1), TCell(1, 2)],
      ],
    ),
    // S — 3×3 box.
    TetrominoType.s: Tetromino(
      type: TetrominoType.s,
      boxSize: 3,
      states: <List<TCell>>[
        <TCell>[TCell(1, 0), TCell(2, 0), TCell(0, 1), TCell(1, 1)],
        <TCell>[TCell(1, 0), TCell(1, 1), TCell(2, 1), TCell(2, 2)],
        <TCell>[TCell(1, 1), TCell(2, 1), TCell(0, 2), TCell(1, 2)],
        <TCell>[TCell(0, 0), TCell(0, 1), TCell(1, 1), TCell(1, 2)],
      ],
    ),
    // Z — 3×3 box.
    TetrominoType.z: Tetromino(
      type: TetrominoType.z,
      boxSize: 3,
      states: <List<TCell>>[
        <TCell>[TCell(0, 0), TCell(1, 0), TCell(1, 1), TCell(2, 1)],
        <TCell>[TCell(2, 0), TCell(1, 1), TCell(2, 1), TCell(1, 2)],
        <TCell>[TCell(0, 1), TCell(1, 1), TCell(1, 2), TCell(2, 2)],
        <TCell>[TCell(1, 0), TCell(0, 1), TCell(1, 1), TCell(0, 2)],
      ],
    ),
  };
}
