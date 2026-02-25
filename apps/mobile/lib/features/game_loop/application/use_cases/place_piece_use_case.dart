import '../../../../domain/gameplay/board_state.dart';
import '../../../../domain/gameplay/move.dart';
import '../../../../domain/gameplay/move_validator.dart';
import '../../../../domain/gameplay/piece.dart';
import '../../../../domain/gameplay/validation_result.dart';

class PlacePieceResult {
  const PlacePieceResult._({
    required this.isSuccess,
    required this.boardState,
    this.failureReason,
    required this.placedCellCount,
  });

  final bool isSuccess;
  final BoardState boardState;
  final String? failureReason;
  final int placedCellCount;

  factory PlacePieceResult.success({
    required BoardState boardState,
    required int placedCellCount,
  }) {
    return PlacePieceResult._(
      isSuccess: true,
      boardState: boardState,
      placedCellCount: placedCellCount,
    );
  }

  factory PlacePieceResult.failure({
    required BoardState boardState,
    required String failureReason,
  }) {
    return PlacePieceResult._(
      isSuccess: false,
      boardState: boardState,
      failureReason: failureReason,
      placedCellCount: 0,
    );
  }
}

class PlacePieceUseCase {
  const PlacePieceUseCase({
    required this.moveValidator,
  });

  final MoveValidator moveValidator;

  PlacePieceResult execute({
    required BoardState boardState,
    required Move move,
  }) {
    final ValidationResult validation = moveValidator.validate(
      boardState: boardState,
      move: move,
    );

    if (!validation.isValid) {
      return PlacePieceResult.failure(
        boardState: boardState,
        failureReason: validation.reason ?? 'invalid_move',
      );
    }

    final List<BoardCell> pieceCells = move.piece.cells
        .map(
          (PieceCellOffset offset) => BoardCell(
            x: move.anchorX + offset.dx,
            y: move.anchorY + offset.dy,
          ),
        )
        .toList();

    final BoardState nextState = boardState.placeCells(pieceCells);

    return PlacePieceResult.success(
      boardState: nextState,
      placedCellCount: pieceCells.length,
    );
  }
}
