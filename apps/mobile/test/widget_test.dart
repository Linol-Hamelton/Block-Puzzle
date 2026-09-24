import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/app/block_puzzle_app.dart';
import 'package:block_puzzle_mobile/features/game_loop/presentation/game_loop_screen.dart';
import 'helpers/test_di.dart';

void main() {
  setUp(() async {
    await configureTestDependencies();
  });

  tearDown(() async {
    await resetTestDependencies();
  });

  group('BlockPuzzleApp End-to-End Integration Widget Tests', () {
    testWidgets('App launches and renders HomeScreen with branding and all game modes',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BlockPuzzleApp());
      await tester.pumpAndSettle();

      // Verify branding and title
      expect(find.text('Lumina Blocks'), findsNWidgets(2)); // AppBar title + Header
      expect(
        find.text(
          'Hypnotic puzzle flow with premium visual feedback and clean controls.',
        ),
        findsOneWidget,
      );

      // Verify gameplay buttons
      expect(find.text('Start Classic'), findsOneWidget);
      expect(find.text('Play Tetris'), findsOneWidget);
      expect(find.text('Play Match 3'), findsOneWidget);
      expect(find.text('Daily Challenge'), findsOneWidget);

      // Verify app bar actions
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });

    testWidgets('Navigates to Settings screen and returns to HomeScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BlockPuzzleApp());
      await tester.pumpAndSettle();

      // Open settings
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Back on HomeScreen
      expect(find.text('Start Classic'), findsOneWidget);
    });

    testWidgets('Navigates to Store screen when enabled and returns to HomeScreen',
        (WidgetTester tester) async {
      await configureTestDependencies(storeEnabled: true);

      await tester.pumpWidget(const BlockPuzzleApp());
      await tester.pumpAndSettle();

      expect(find.text('Open Premium Store'), findsOneWidget);

      // Open Store
      await tester.tap(find.text('Open Premium Store'));
      await tester.pumpAndSettle();

      expect(find.text('Store'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Back on HomeScreen
      expect(find.text('Start Classic'), findsOneWidget);
    });

    testWidgets('Store button is hidden when store is disabled per DEC-0026/0028',
        (WidgetTester tester) async {
      await configureTestDependencies(storeEnabled: false);

      await tester.pumpWidget(const BlockPuzzleApp());
      await tester.pumpAndSettle();

      expect(find.text('Open Premium Store'), findsNothing);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
    });

    testWidgets('Navigates to Tetris screen and returns to HomeScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BlockPuzzleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play Tetris'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Tetris'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Play Tetris'), findsOneWidget);
    });

    testWidgets('Navigates to Match 3 screen and returns to HomeScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BlockPuzzleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play Match 3'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Match 3'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Play Match 3'), findsOneWidget);
    });

    testWidgets('Navigates to Classic game screen and returns to HomeScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const BlockPuzzleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Classic'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(GameLoopScreen), findsOneWidget);

      Navigator.of(tester.element(find.byType(GameLoopScreen))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Start Classic'), findsOneWidget);
    });

    testWidgets('Remote config kill-switch shows unavailable message when all modes disabled',
        (WidgetTester tester) async {
      await configureTestDependencies(
        classicEnabled: false,
        tetrisEnabled: false,
        match3Enabled: false,
        storeEnabled: false,
      );

      await tester.pumpWidget(const BlockPuzzleApp());
      await tester.pumpAndSettle();

      expect(find.text('Start Classic'), findsNothing);
      expect(find.text('Play Tetris'), findsNothing);
      expect(find.text('Play Match 3'), findsNothing);
      expect(find.text('Daily Challenge'), findsNothing);

      expect(
        find.text(
          'All game modes are currently unavailable. Please try again later.',
        ),
        findsOneWidget,
      );
    });
  });
}

