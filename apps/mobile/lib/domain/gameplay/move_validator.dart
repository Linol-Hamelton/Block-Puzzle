import 'board_state.dart';
import 'move.dart';
import 'validation_result.dart';

abstract interface class MoveValidator {
  ValidationResult validate({
    required BoardState boardState,
    required Move move,
  });
}
