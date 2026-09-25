import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/domain/scoring/score_state.dart';
import 'package:block_puzzle_mobile/features/game_loop/application/game_loop_view_state.dart';
import 'package:block_puzzle_mobile/ui/effects/celebration_director.dart';
import 'package:block_puzzle_mobile/ui/widgets/game_over_overlay_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CelebrationType enum', () {
    test('contains expected celebratory milestones', () {
      expect(CelebrationType.values, contains(CelebrationType.dailyChallengeVictory));
      expect(CelebrationType.values, contains(CelebrationType.newRecord));
      expect(CelebrationType.values, contains(CelebrationType.allClear));
    });
  });

  group('ProceduralCelebrationProvider', () {
    test('properties reflect procedural baseline', () {
      final ProceduralCelebrationProvider provider = ProceduralCelebrationProvider();
      expect(provider.name, equals('procedural'));
      expect(provider.isReady, isTrue);
    });

    test('playSoundOrHaptic triggers without throwing', () {
      final ProceduralCelebrationProvider provider = ProceduralCelebrationProvider();
      expect(() => provider.playSoundOrHaptic(CelebrationType.newRecord), returnsNormally);
      expect(() => provider.playSoundOrHaptic(CelebrationType.dailyChallengeVictory), returnsNormally);
      expect(() => provider.playSoundOrHaptic(CelebrationType.allClear), returnsNormally);
    });

    testWidgets('builds and renders newRecord trophy badge with animation', (WidgetTester tester) async {
      bool completed = false;
      final ProceduralCelebrationProvider provider = ProceduralCelebrationProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return provider.buildCelebrationWidget(
                  context: context,
                  type: CelebrationType.newRecord,
                  score: 1250,
                  onComplete: () => completed = true,
                );
              },
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('New Record Celebration Trophy'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets('builds and renders dailyChallengeVictory medal with animation', (WidgetTester tester) async {
      final ProceduralCelebrationProvider provider = ProceduralCelebrationProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return provider.buildCelebrationWidget(
                  context: context,
                  type: CelebrationType.dailyChallengeVictory,
                  stars: 3,
                );
              },
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Daily Challenge Victory Medal'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('builds and renders allClear diamond star with animation', (WidgetTester tester) async {
      final ProceduralCelebrationProvider provider = ProceduralCelebrationProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return provider.buildCelebrationWidget(
                  context: context,
                  type: CelebrationType.allClear,
                );
              },
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('All Clear Celebration Diamond'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('respects Reduced Motion and completes immediately', (WidgetTester tester) async {
      bool completed = false;
      final ProceduralCelebrationProvider provider = ProceduralCelebrationProvider(
        isReducedMotion: () => true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return provider.buildCelebrationWidget(
                  context: context,
                  type: CelebrationType.newRecord,
                  onComplete: () => completed = true,
                );
              },
            ),
          ),
        ),
      );

      expect(completed, isTrue);
      expect(find.bySemanticsLabel('New Record Celebration Trophy'), findsOneWidget);
    });
  });

  group('RiveCelebrationAdapter', () {
    test('computes state machine inputs adhering to contract', () {
      final RiveCelebrationAdapter adapter = RiveCelebrationAdapter();
      expect(adapter.name, equals('rive_adapter'));
      expect(adapter.isReady, isTrue);

      final Map<String, Object?> inputs = adapter.computeStateMachineInputs(
        type: CelebrationType.dailyChallengeVictory,
        score: 850,
        stars: 3,
        reducedMotion: false,
      );

      expect(inputs[RiveCelebrationAdapter.inputIsWin], isTrue);
      expect(inputs[RiveCelebrationAdapter.inputScore], equals(850.0));
      expect(inputs[RiveCelebrationAdapter.inputStars], equals(3.0));
      expect(inputs[RiveCelebrationAdapter.inputTriggerCelebration], isTrue);
      expect(inputs[RiveCelebrationAdapter.inputReducedMotion], isFalse);
      expect(adapter.lastAppliedInputs, equals(inputs));
    });

    testWidgets('buildCelebrationWidget records inputs and delegates to fallback', (WidgetTester tester) async {
      final RiveCelebrationAdapter adapter = RiveCelebrationAdapter();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return adapter.buildCelebrationWidget(
                  context: context,
                  type: CelebrationType.newRecord,
                  score: 999,
                );
              },
            ),
          ),
        ),
      );

      expect(adapter.lastAppliedInputs[RiveCelebrationAdapter.inputScore], equals(999.0));
      expect(find.bySemanticsLabel('New Record Celebration Trophy'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    test('playSoundOrHaptic executes through adapter', () {
      final RiveCelebrationAdapter adapter = RiveCelebrationAdapter();
      expect(() => adapter.playSoundOrHaptic(CelebrationType.allClear), returnsNormally);
    });
  });

  group('CelebrationDirector', () {
    test('allows swapping active celebration provider', () {
      final CelebrationDirector director = CelebrationDirector();
      expect(director.activeProvider, isA<ProceduralCelebrationProvider>());

      final RiveCelebrationAdapter adapter = RiveCelebrationAdapter();
      director.activeProvider = adapter;
      expect(director.activeProvider, equals(adapter));

      expect(() => director.celebrate(CelebrationType.newRecord), returnsNormally);
    });

    testWidgets('buildBadge creates celebration widget via activeProvider', (WidgetTester tester) async {
      final CelebrationDirector director = CelebrationDirector();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return director.buildBadge(
                  context: context,
                  type: CelebrationType.allClear,
                  size: 100.0,
                );
              },
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('All Clear Celebration Diamond'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('GameOverOverlayCard Celebration Integration', () {
    Widget buildSubject(GameLoopViewState state, {CelebrationProvider? celebrationProvider}) {
      return MaterialApp(
        home: Scaffold(
          body: GameOverOverlayCard(
            state: state,
            onRestartPressed: () {},
            celebrationProvider: celebrationProvider,
          ),
        ),
      );
    }

    testWidgets('renders celebratory New Record trophy when isNewBest is true', (WidgetTester tester) async {
      final GameLoopViewState recordState = GameLoopViewState.initial().copyWith(
        scoreState: const ScoreState(totalScore: 750, comboStreak: 2),
        bestScore: 750,
        sessionStartBestScore: 500,
        isDailyChallenge: false,
      );

      await tester.pumpWidget(buildSubject(recordState));
      expect(
        find.byWidgetPredicate((Widget w) => w is Semantics && w.properties.label == 'New Record Celebration Trophy'),
        findsOneWidget,
      );
      expect(find.text('New Best'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('renders celebratory Daily Challenge medal when isDailyChallenge is true', (WidgetTester tester) async {
      final GameLoopViewState dailyState = GameLoopViewState.initial().copyWith(
        scoreState: const ScoreState(totalScore: 400, comboStreak: 1),
        bestScore: 500,
        sessionStartBestScore: 500,
        isDailyChallenge: true,
      );

      await tester.pumpWidget(buildSubject(dailyState));
      expect(
        find.byWidgetPredicate((Widget w) => w is Semantics && w.properties.label == 'Daily Challenge Victory Medal'),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('does not render celebration badge on regular non-record game over', (WidgetTester tester) async {
      final GameLoopViewState regularState = GameLoopViewState.initial().copyWith(
        scoreState: const ScoreState(totalScore: 300, comboStreak: 1),
        bestScore: 500,
        sessionStartBestScore: 500,
        isDailyChallenge: false,
      );

      await tester.pumpWidget(buildSubject(regularState));
      expect(
        find.byWidgetPredicate((Widget w) => w is Semantics && w.properties.label == 'New Record Celebration Trophy'),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate((Widget w) => w is Semantics && w.properties.label == 'Daily Challenge Victory Medal'),
        findsNothing,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('respects custom injected celebration provider in GameOverOverlayCard', (WidgetTester tester) async {
      final RiveCelebrationAdapter customAdapter = RiveCelebrationAdapter();
      final GameLoopViewState recordState = GameLoopViewState.initial().copyWith(
        scoreState: const ScoreState(totalScore: 1100, comboStreak: 3),
        bestScore: 1100,
        sessionStartBestScore: 800,
      );

      await tester.pumpWidget(buildSubject(recordState, celebrationProvider: customAdapter));
      expect(customAdapter.lastAppliedInputs[RiveCelebrationAdapter.inputScore], equals(1100.0));
      expect(
        find.byWidgetPredicate((Widget w) => w is Semantics && w.properties.label == 'New Record Celebration Trophy'),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });
  });
}
