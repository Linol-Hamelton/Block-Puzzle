import '../../../../domain/gameplay/board_state.dart';
import '../../../../domain/gameplay/line_clear_service.dart';

class ClearLinesUseCase {
  const ClearLinesUseCase({
    required this.lineClearService,
  });

  final LineClearService lineClearService;

  LineClearResult execute({
    required BoardState boardState,
  }) {
    return lineClearService.apply(boardState: boardState);
  }
}
