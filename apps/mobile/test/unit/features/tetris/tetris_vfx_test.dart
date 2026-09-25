import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/core/device/haptics_controller.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetris_engine.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetromino.dart';
import 'package:block_puzzle_mobile/features/game_loop/audio/game_sfx_player.dart';
import 'package:block_puzzle_mobile/features/tetris/application/tetris_controller.dart';
import 'package:block_puzzle_mobile/features/tetris/presentation/tetris_game.dart';
import 'package:block_puzzle_mobile/features/tetris/presentation/tetris_screen.dart';
import 'package:block_puzzle_mobile/ui/effects/celebration_director.dart';
import 'package:block_puzzle_mobile/ui/effects/combo_pulse_component.dart';
import 'package:block_puzzle_mobile/ui/effects/landing_squash_component.dart';
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

  late TetrisController controller;
  late TetrisFlameGame game;

  setUp(() async {
    controller = TetrisController(
      seed: 42,
      sfx: _MockSfxPlayer(),
      haptics: HapticsController()..isEnabled = false,
    );
    await controller.initialize();
    game = TetrisFlameGame(controller: controller);
  });

  group('TetrisFlameGame VFX Integration', () {
    test('initializes and attaches VfxDirector as child component', () async {
      await game.onLoad();
      game.update(0);
      expect(game.vfxDirector, isNotNull);
      expect(game.children.contains(game.vfxDirector), isTrue);
      expect(game.children.whereType<VfxDirector>().length, 1);
      expect(game.vfxDirector.auraShader, isNotNull);
    });

    test('lock event dispatches piecePlaced and spawns LandingSquashComponent', () async {
      await game.onLoad();
      game.update(0);
      game.onGameResize(Vector2(300, 600));
      game.render(Canvas(PictureRecorder()));

      // Trigger hard drop so active piece locks
      controller.input(TetrisInput.hardDrop);
      game.update(0.016);

      // VfxDirector should have spawned LandingSquashComponent
      final List<LandingSquashComponent> squashes =
          game.vfxDirector.children.whereType<LandingSquashComponent>().toList();
      expect(squashes, isNotEmpty);
      expect(squashes.first.cellRects, isNotEmpty);
    });

    test('lineClear event dispatches LineClearedVfxEvent with ScorePop and Shockwave', () async {
      await game.onLoad();
      game.onGameResize(Vector2(300, 600));
      game.render(Canvas(PictureRecorder()));

      // Directly simulate visual lineClear event
      controller.onVisualEvent?.call(
        const TetrisEvent(TetrisEventType.lineClear, 4, 800),
      );
      game.update(0.016);

      // Verify shockwave ring, score pop, and combo pulse TETRIS! spawned
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
      expect(
        game.vfxDirector.isHitStopActive,
        isTrue,
      );
    });

    test('perfectClear event triggers AllClear fanfare and score pop', () async {
      await game.onLoad();
      game.onGameResize(Vector2(300, 600));
      game.render(Canvas(PictureRecorder()));

      controller.onVisualEvent?.call(
        const TetrisEvent(TetrisEventType.perfectClear, 1, 1000),
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
      expect(
        game.vfxDirector.isHitStopActive,
        isTrue,
      );
    });

    test('renders without errors across multiple frames including aura shader fallback', () async {
      await game.onLoad();
      game.onGameResize(Vector2(300, 600));
      game.vfxDirector.vfxLevel = VfxLevel.full;

      final PictureRecorder recorder = PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      for (int i = 0; i < 10; i++) {
        game.update(0.016);
        game.render(canvas);
      }
    });
  });

  group('Tetris CelebrationDirector Integration', () {
    testWidgets('displays celebration badge on game over when setting new record',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TetrisGameOverCard(
                score: 5000,
                best: 4000,
                lines: 40,
                level: 5,
                canRevive: false,
                onRevive: () {},
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

    testWidgets('shows Game Over title without badge when not a new record',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TetrisGameOverCard(
                score: 2000,
                best: 4000,
                lines: 20,
                level: 3,
                canRevive: false,
                onRevive: () {},
                onRestart: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Game Over'), findsOneWidget);
      expect(find.text('New Record!'), findsNothing);
    });
  });
}
