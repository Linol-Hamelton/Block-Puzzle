import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/domain/scoring/basic_score_service.dart';
import 'package:block_puzzle_mobile/domain/scoring/score_service.dart';
import 'package:block_puzzle_mobile/domain/scoring/score_state.dart';

void main() {
  late BasicScoreService service;

  setUp(() {
    service = const BasicScoreService();
  });

  group('BasicScoreService', () {
    test('initial state has zero score and zero combo', () {
      expect(ScoreState.initial.totalScore, 0);
      expect(ScoreState.initial.comboStreak, 0);
    });

    test('no lines cleared gives zero score delta and resets combo', () {
      final ScoreState result = service.apply(
        previous: const ScoreState(totalScore: 100, comboStreak: 3),
        input: const ScoreInput(clearedLines: 0),
      );

      expect(result.totalScore, 100);
      expect(result.comboStreak, 0);
    });

    test('clearing 1 line from initial state gives 10 points and combo 1', () {
      final ScoreState result = service.apply(
        previous: ScoreState.initial,
        input: const ScoreInput(clearedLines: 1),
      );

      // lineScore = 1 * 10 = 10, comboBonus = (1-1)*5 = 0
      expect(result.totalScore, 10);
      expect(result.comboStreak, 1);
    });

    test('clearing 2 lines gives 20 points plus combo bonus', () {
      final ScoreState result = service.apply(
        previous: ScoreState.initial,
        input: const ScoreInput(clearedLines: 2),
      );

      // lineScore = 2 * 10 = 20, comboBonus = (1-1)*5 = 0
      expect(result.totalScore, 20);
      expect(result.comboStreak, 1);
    });

    test('consecutive clears build combo with increasing bonus', () {
      ScoreState state = ScoreState.initial;

      // Move 1: 1 line → combo 1, score = 10 + 0 = 10
      state = service.apply(
        previous: state,
        input: const ScoreInput(clearedLines: 1),
      );
      expect(state.totalScore, 10);
      expect(state.comboStreak, 1);

      // Move 2: 1 line → combo 2, score = 10 + (10 + 5) = 25
      state = service.apply(
        previous: state,
        input: const ScoreInput(clearedLines: 1),
      );
      expect(state.totalScore, 25);
      expect(state.comboStreak, 2);

      // Move 3: 1 line → combo 3, score = 25 + (10 + 10) = 45
      state = service.apply(
        previous: state,
        input: const ScoreInput(clearedLines: 1),
      );
      expect(state.totalScore, 45);
      expect(state.comboStreak, 3);
    });

    test('combo resets on zero cleared lines', () {
      ScoreState state = ScoreState.initial;

      state = service.apply(
        previous: state,
        input: const ScoreInput(clearedLines: 1),
      );
      expect(state.comboStreak, 1);

      state = service.apply(
        previous: state,
        input: const ScoreInput(clearedLines: 0),
      );
      expect(state.comboStreak, 0);
      expect(state.totalScore, 10); // No new points

      // Next clear starts combo from 1 again
      state = service.apply(
        previous: state,
        input: const ScoreInput(clearedLines: 1),
      );
      expect(state.comboStreak, 1);
      expect(state.totalScore, 20); // 10 + 0 bonus
    });

    test('large line clears produce proportional score', () {
      final ScoreState result = service.apply(
        previous: ScoreState.initial,
        input: const ScoreInput(clearedLines: 4),
      );

      // lineScore = 4 * 10 = 40, comboBonus = 0
      expect(result.totalScore, 40);
      expect(result.comboStreak, 1);
    });

    test('combo bonus accumulation example from docs', () {
      ScoreState state = ScoreState.initial;

      // Simulate a 5-combo streak with 1 line each
      for (int i = 0; i < 5; i++) {
        state = service.apply(
          previous: state,
          input: const ScoreInput(clearedLines: 1),
        );
      }

      // Total: 10+0, 10+5, 10+10, 10+15, 10+20 = 10+15+20+25+30 = 100
      expect(state.totalScore, 100);
      expect(state.comboStreak, 5);
    });
  });
}
