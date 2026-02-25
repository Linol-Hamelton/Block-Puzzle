import 'score_service.dart';
import 'score_state.dart';

class BasicScoreService implements ScoreService {
  const BasicScoreService();

  @override
  ScoreState apply({
    required ScoreState previous,
    required ScoreInput input,
  }) {
    if (input.clearedLines <= 0) {
      return ScoreState(
        totalScore: previous.totalScore,
        comboStreak: 0,
      );
    }

    final int nextComboStreak = previous.comboStreak + 1;
    final int lineScore = input.clearedLines * 10;
    final int comboBonus = (nextComboStreak - 1) * 5;

    return ScoreState(
      totalScore: previous.totalScore + lineScore + comboBonus,
      comboStreak: nextComboStreak,
    );
  }
}
