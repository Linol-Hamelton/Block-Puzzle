import '../../../../domain/scoring/score_service.dart';
import '../../../../domain/scoring/score_state.dart';

class ComputeScoreUseCase {
  const ComputeScoreUseCase({
    required this.scoreService,
  });

  final ScoreService scoreService;

  ScoreState execute({
    required ScoreState previous,
    required int clearedLines,
  }) {
    return scoreService.apply(
      previous: previous,
      input: ScoreInput(clearedLines: clearedLines),
    );
  }
}
