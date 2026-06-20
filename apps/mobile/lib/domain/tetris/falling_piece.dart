import 'tetromino.dart';

/// The active, falling tetromino: a [TetrominoType], a rotation index (0..3),
/// and the board-space origin of its bounding box (top-left). Immutable; all
/// mutations return a new instance.
class FallingPiece {
  const FallingPiece({
    required this.type,
    required this.rotationIndex,
    required this.originX,
    required this.originY,
  });

  final TetrominoType type;
  final int rotationIndex;
  final int originX;
  final int originY;

  /// The four occupied cells in **board coordinates** for the current state.
  List<TCell> absoluteCells() {
    final List<TCell> box = Tetromino.of(type).cellsAt(rotationIndex);
    return <TCell>[
      for (final TCell c in box) TCell(originX + c.x, originY + c.y),
    ];
  }

  FallingPiece movedBy(int dx, int dy) => FallingPiece(
        type: type,
        rotationIndex: rotationIndex,
        originX: originX + dx,
        originY: originY + dy,
      );

  FallingPiece withRotation(int newRotationIndex) => FallingPiece(
        type: type,
        rotationIndex: newRotationIndex & 3,
        originX: originX,
        originY: originY,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'type': type.name,
        'rotation': rotationIndex,
        'x': originX,
        'y': originY,
      };

  factory FallingPiece.fromJson(Map<String, Object?> json) {
    return FallingPiece(
      type: TetrominoType.values.firstWhere(
        (TetrominoType t) => t.name == json['type'],
        orElse: () => TetrominoType.t,
      ),
      rotationIndex: (json['rotation'] as int?) ?? 0,
      originX: (json['x'] as int?) ?? 0,
      originY: (json['y'] as int?) ?? 0,
    );
  }
}
