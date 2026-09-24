import 'package:block_puzzle_mobile/domain/scoring/score_state.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/game_loop_view_state.dart';
import 'package:block_puzzle_mobile/ui/widgets/game_over_overlay_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameOverOverlayCard', () {
    Widget buildSubject(GameLoopViewState state) {
      return MaterialApp(
        home: Scaffold(
          body: GameOverOverlayCard(
            state: state,
            onRestartPressed: () {},
          ),
        ),
      );
    }

    testWidgets('renders 2x2 stats grid: Score, Best, Lines Cleared, Max Combo',
        (WidgetTester tester) async {
      final GameLoopViewState state = GameLoopViewState.initial().copyWith(
        scoreState: const ScoreState(totalScore: 450, comboStreak: 3),
        bestScore: 1000,
        linesCleared: 12,
        maxCombo: 5,
      );

      await tester.pumpWidget(buildSubject(state));

      expect(find.text('Score'), findsOneWidget);
      expect(find.text('450'), findsOneWidget);
      expect(find.text('Best'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('Lines Cleared'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Max Combo'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders honest New Best badge only when score > sessionStartBestScore and sessionStartBestScore > 0',
        (WidgetTester tester) async {
      // First game ever: sessionStartBestScore is 0
      final GameLoopViewState firstGameState = GameLoopViewState.initial().copyWith(
        scoreState: const ScoreState(totalScore: 150, comboStreak: 1),
        bestScore: 150,
        sessionStartBestScore: 0,
      );

      await tester.pumpWidget(buildSubject(firstGameState));
      expect(find.text('New Best'), findsNothing);

      // Subsequent game beating previous record
      final GameLoopViewState recordState = GameLoopViewState.initial().copyWith(
        scoreState: const ScoreState(totalScore: 600, comboStreak: 2),
        bestScore: 600,
        sessionStartBestScore: 500,
      );

      await tester.pumpWidget(buildSubject(recordState));
      expect(find.text('New Best'), findsOneWidget);
    });

    testWidgets('renders To Record badge when score is within 5% of record',
        (WidgetTester tester) async {
      // Record is 1000, score is 960 (within 5% since 960 >= 950) -> toRecord = 40
      final GameLoopViewState nearState = GameLoopViewState.initial().copyWith(
        scoreState: const ScoreState(totalScore: 960, comboStreak: 2),
        bestScore: 1000,
        sessionStartBestScore: 1000,
      );

      await tester.pumpWidget(buildSubject(nearState));
      expect(find.text('To Record: 40'), findsOneWidget);
      expect(find.text('New Best'), findsNothing);
    });

    testWidgets('renders FTUE contextual tip on first game over',
        (WidgetTester tester) async {
      final GameLoopViewState firstOverState = GameLoopViewState.initial().copyWith(
        isFirstGameOver: true,
      );

      await tester.pumpWidget(buildSubject(firstOverState));
      expect(
        find.text('Tip: Keep the 3x3 center clear to place large blocks easily!'),
        findsOneWidget,
      );

      final GameLoopViewState regularState = GameLoopViewState.initial().copyWith(
        isFirstGameOver: false,
      );

      await tester.pumpWidget(buildSubject(regularState));
      expect(
        find.text('Tip: Keep the 3x3 center clear to place large blocks easily!'),
        findsNothing,
      );
    });
  });
}
