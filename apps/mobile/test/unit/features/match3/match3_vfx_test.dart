import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/core/device/haptics_controller.dart';
import 'package:block_puzzle_mobile/domain/match3/match3_engine.dart';
import 'package:block_puzzle_mobile/domain/match3/special_combo.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:block_puzzle_mobile/features/game_loop/audio/game_sfx_player.dart';
import 'package:block_puzzle_mobile/features/match3/application/match3_controller.dart';
import 'package:block_puzzle_mobile/features/match3/presentation/match3_game.dart';
import 'package:block_puzzle_mobile/features/match3/presentation/match3_screen.dart';
import 'package:block_puzzle_mobile/ui/effects/combo_pulse_component.dart';
import 'package:block_puzzle_mobile/features/diagnostics/step6_benchmark.dart';
import 'package:block_puzzle_mobile/ui/effects/score_pop_component.dart';
import 'package:block_puzzle_mobile/ui/effects/shockwave_ring_component.dart';
import 'package:block_puzzle_mobile/ui/effects/vfx_director.dart';
import 'package:block_puzzle_mobile/ui/effects/vfx_events.dart';

class _MockSfxPlayer implements GameSfxPlayer {
  @override
  bool isEnabled = false;

  @override
  double volume = 0;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> onAppResumed() async {}

  @override
  Future<void> playCombo({required int comboStreak}) async {}

  @override
  Future<void> playGameOver() async {}

  @override
  Future<void> playHardDrop() async {}

  @override
  Future<void> playHold() async {}

  @override
  Future<void> playInvalidMove() async {}

  @override
  Future<void> playLineClear({required int clearedLines}) async {}

  @override
  Future<void> playPiecePlaced() async {}

  @override
  Future<void> playRotate() async {}

  @override
  Future<void> preload() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Match3Controller controller;
  late Match3FlameGame game;

  setUp(() async {
    controller = Match3Controller(
      seed: 42,
      sfx: _MockSfxPlayer(),
      haptics: HapticsController()..isEnabled = false,
    );
    await controller.initialize();
    game = Match3FlameGame(controller: controller);
  });

  tearDown(() {
    controller.dispose();
  });

  group('Match3FlameGame VFX Integration', () {
    test('initializes and attaches VfxDirector as child component', () async {
      await game.onLoad();
      game.update(0);
      expect(game.vfxDirector, isNotNull);
      expect(game.children.contains(game.vfxDirector), isTrue);
      expect(game.children.whereType<VfxDirector>().length, 1);
      expect(game.vfxDirector.auraShader, isNotNull);
    });

    test('computeFallDistances correctly calculates cascade gravity offsets', () {
      // 1. Empty burst returns empty map
      expect(
        Match3FlameGame.computeFallDistances(8, 8, const <GridPos>[]),
        isEmpty,
      );

      // 2. Clear bottom 3 cells (5, 6, 7) in column 0
      final Map<GridPos, double> dists1 = Match3FlameGame.computeFallDistances(
        8,
        8,
        const <GridPos>[GridPos(0, 5), GridPos(0, 6), GridPos(0, 7)],
      );
      // All 8 rows in col 0 should drop by 3 units
      for (int y = 0; y < 8; y++) {
        expect(dists1[GridPos(0, y)], 3.0);
      }

      // 3. Clear disjoint cells at row 2 and 5 in column 1
      final Map<GridPos, double> dists2 = Match3FlameGame.computeFallDistances(
        8,
        8,
        const <GridPos>[GridPos(1, 2), GridPos(1, 5)],
      );
      expect(dists2[const GridPos(1, 7)], isNull); // did not move
      expect(dists2[const GridPos(1, 6)], isNull); // did not move
      expect(dists2[const GridPos(1, 5)], 1.0);
      expect(dists2[const GridPos(1, 4)], 1.0);
      expect(dists2[const GridPos(1, 3)], 2.0);
      expect(dists2[const GridPos(1, 2)], 2.0);
      expect(dists2[const GridPos(1, 1)], 2.0); // newly refilled
      expect(dists2[const GridPos(1, 0)], 2.0); // newly refilled
    });

    test('real pipeline trySwap generates ScorePopComponent from engine step.gained points', () async {
      await game.onLoad();
      game.onGameResize(Vector2(400, 400));
      game.render(Canvas(PictureRecorder()));

      final (GridPos, GridPos)? hint = controller.engine.findHint();
      expect(hint, isNotNull);
      final bool ok = controller.trySwap(hint!.$1, hint.$2);
      expect(ok, isTrue);

      // Wait for Frame 1 to appear (openingHold ≈ 300ms)
      // Call game.update on each iteration to synchronize _lastScore to controller.score
      // so that ScorePopComponent MUST be populated from event.points (step.gained),
      // rather than the fallback `controller.score - _lastScore`.
      for (int i = 0; i < 40 && controller.frameBurst.isEmpty; i++) {
        game.update(0.025);
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }

      // Verify that engine generated Match3Event with points and VfxDirector spawned ScorePopComponent
      final List<ScorePopComponent> scorePops =
          game.vfxDirector.children.whereType<ScorePopComponent>().toList();
      expect(scorePops, isNotEmpty);
      expect(scorePops.first.text, equals('+${controller.engine.lastSteps.first.gained}'));
      for (int i = 0; i < 40 && controller.isBusy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });

    test('match event dispatches LineClearedVfxEvent with Shockwave and ScorePop', () async {
      await game.onLoad();
      game.onGameResize(Vector2(400, 400));
      game.render(Canvas(PictureRecorder()));

      controller.onVisualEvent?.call(
        const Match3Event(Match3EventType.match, 6, 2, 120),
      );
      game.update(0.016);

      expect(
        game.vfxDirector.children.whereType<ShockwaveRingComponent>(),
        isNotEmpty,
      );
      expect(
        game.vfxDirector.children.whereType<ScorePopComponent>(),
        isNotEmpty,
      );
      expect(
        game.vfxDirector.children.whereType<ComboPulseComponent>(),
        isNotEmpty,
      );
    });

    test('reduced motion disables shockwave ring on match event', () async {
      Step6Benchmark.reducedMotion.value = true;
      try {
        await game.onLoad();
        game.onGameResize(Vector2(400, 400));
        game.render(Canvas(PictureRecorder()));

        controller.onVisualEvent?.call(
          const Match3Event(Match3EventType.match, 6, 2, 120),
        );
        game.update(0.016);

        expect(
          game.vfxDirector.children.whereType<ShockwaveRingComponent>(),
          isEmpty,
        );
      } finally {
        Step6Benchmark.reducedMotion.value = false;
      }
    });

    test('drop progress animates fall distances and progress curve mid-fall across frames', () async {
      await game.onLoad();
      game.onGameResize(Vector2(400, 400));
      game.render(Canvas(PictureRecorder()));

      final (GridPos, GridPos)? hint = controller.engine.findHint();
      expect(hint, isNotNull);
      final bool ok = controller.trySwap(hint!.$1, hint.$2);
      expect(ok, isTrue);

      // Advance game time during openingHold to accumulate pre-drop elapsed time
      // so that missing per-serial reset would fail dropElapsed == 0.05
      for (int i = 0; i < 40 && controller.frameBurst.isEmpty; i++) {
        game.update(0.025);
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }

      // Render initial frame to trigger _dropProgress calculation
      game.render(Canvas(PictureRecorder()));
      expect(game.activeFallDistances, isNotEmpty);
      expect(game.activeFallDistances.values.any((double d) => d > 0), isTrue);

      // Mid-fall at dt = 0.05s
      game.update(0.05);
      game.render(Canvas(PictureRecorder()));

      expect(game.dropElapsed, equals(0.05));
      expect(game.dropProgressValue, greaterThan(0.0));
      expect(game.dropProgressValue, lessThan(1.0));

    });

    test('combo event dispatches ComboPulseVfxEvent, ScreenShake, and Hit-Stop', () async {
      await game.onLoad();
      game.onGameResize(Vector2(400, 400));
      game.render(Canvas(PictureRecorder()));

      controller.onVisualEvent?.call(
        const Match3Event.combined(ComboKind.megaBomb),
      );
      game.update(0.016);

      expect(
        game.vfxDirector.children.whereType<ComboPulseComponent>(),
        isNotEmpty,
      );
      expect(
        game.vfxDirector.isHitStopActive,
        isTrue,
      );
    });

    test('roundComplete event dispatches AllClearVfxEvent with fanfare shockwave', () async {
      await game.onLoad();
      game.onGameResize(Vector2(400, 400));
      game.render(Canvas(PictureRecorder()));

      controller.onVisualEvent?.call(
        const Match3Event(Match3EventType.roundComplete, 1, 5),
      );
      game.update(0.016);

      expect(
        game.vfxDirector.children.whereType<ShockwaveRingComponent>(),
        isNotEmpty,
      );
      expect(
        game.vfxDirector.children.whereType<ComboPulseComponent>(),
        isNotEmpty,
      );
    });

    test('roundComplete event with reduced motion suppresses shockwave ring', () async {
      Step6Benchmark.reducedMotion.value = true;
      try {
        await game.onLoad();
        game.onGameResize(Vector2(400, 400));
        game.render(Canvas(PictureRecorder()));

        controller.onVisualEvent?.call(
          const Match3Event(Match3EventType.roundComplete, 1, 5),
        );
        game.update(0.016);

        expect(
          game.vfxDirector.children.whereType<ShockwaveRingComponent>(),
          isEmpty,
        );
        expect(
          game.vfxDirector.children.whereType<ComboPulseComponent>(),
          isNotEmpty,
        );
      } finally {
        Step6Benchmark.reducedMotion.value = false;
      }
    });

    test('renders without errors including PieceAuraShader on special and igniting gems', () async {
      await game.onLoad();
      game.onGameResize(Vector2(400, 400));
      game.vfxDirector.vfxLevel = VfxLevel.full;

      // Restore grid with special gems to test shader aura rendering
      final Map<String, Object?> snapshot = controller.engine.toSnapshot();
      final TileGrid customGrid = controller.engine.grid
          .withSpecialAt(const GridPos(0, 0), SpecialKind.bomb)
          .withSpecialAt(const GridPos(1, 1), SpecialKind.colorBomb);
      snapshot['grid'] = customGrid.toJson();
      controller.engine.restore(snapshot);

      final PictureRecorder recorder = PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      for (int i = 0; i < 10; i++) {
        game.update(0.016);
        game.render(canvas);
      }
    });
  });

  group('Match-3 CelebrationDirector Integration', () {
    testWidgets('displays celebration badge on game over when setting new record',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Match3GameOverCard(
                score: 5500,
                best: 4000,
                moves: 24,
                rounds: 3,
                onRestart: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Record!'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('shows Out of Moves title without badge when not a new record',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Match3GameOverCard(
                score: 2000,
                best: 4000,
                moves: 18,
                rounds: 1,
                onRestart: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Out of Moves'), findsOneWidget);
      expect(find.text('New Record!'), findsNothing);
    });

    testWidgets('shows Out of Moves title without badge when score ties best score',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Match3GameOverCard(
                score: 4000,
                best: 4000,
                moves: 20,
                rounds: 2,
                onRestart: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Out of Moves'), findsOneWidget);
      expect(find.text('New Record!'), findsNothing);
    });
  });
}
