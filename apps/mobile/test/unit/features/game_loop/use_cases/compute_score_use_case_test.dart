import 'package:block_puzzle_mobile/domain/scoring/basic_score_service.dart';
import 'package:block_puzzle_mobile/domain/scoring/score_state.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/use_cases/compute_score_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComputeScoreUseCase', () {
    const ComputeScoreUseCase useCase = ComputeScoreUseCase(
      scoreService: BasicScoreService(),
    );

    test('adds score and starts combo when lines are cleared', () {
      final ScoreState result = useCase.execute(
        previous: ScoreState.initial,
        clearedLines: 1,
      );

      expect(result.totalScore, 10);
      expect(result.comboStreak, 1);
    });

    test('applies combo bonus for consecutive clears', () {
      final ScoreState first = useCase.execute(
        previous: ScoreState.initial,
        clearedLines: 1,
      );
      final ScoreState second = useCase.execute(
        previous: first,
        clearedLines: 2,
      );

      expect(second.totalScore, 35);
      expect(second.comboStreak, 2);
    });

    test('resets combo when no lines are cleared', () {
      final ScoreState withCombo = useCase.execute(
        previous: ScoreState.initial,
        clearedLines: 1,
      );
      final ScoreState result = useCase.execute(
        previous: withCombo,
        clearedLines: 0,
      );

      expect(result.totalScore, 10);
      expect(result.comboStreak, 0);
    });
  });
}
