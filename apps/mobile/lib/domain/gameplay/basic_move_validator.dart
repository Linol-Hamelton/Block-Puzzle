import 'board_state.dart';
import 'move.dart';
import 'move_validator.dart';
import 'piece.dart';
import 'validation_result.dart';

class BasicMoveValidator implements MoveValidator {
  const BasicMoveValidator();

  @override
  ValidationResult validate({
    required BoardState boardState,
    required Move move,
  }) {
    for (final PieceCellOffset offset in move.piece.cells) {
      final BoardCell target = BoardCell(
        x: move.anchorX + offset.dx,
        y: move.anchorY + offset.dy,
      );

      if (!boardState.isInBounds(target)) {
        return const ValidationResult.invalid('out_of_bounds');
      }

      if (boardState.isOccupied(target)) {
        return const ValidationResult.invalid('cell_occupied');
      }
    }

    return const ValidationResult.valid();
  }
}
