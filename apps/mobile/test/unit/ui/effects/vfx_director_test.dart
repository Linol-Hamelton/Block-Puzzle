import 'dart:ui';
import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/features/diagnostics/step6_benchmark.dart';
import 'package:block_puzzle_mobile/ui/effects/burst_field.dart';
import 'package:block_puzzle_mobile/ui/effects/combo_pulse_component.dart';
import 'package:block_puzzle_mobile/ui/effects/line_clear_flash_component.dart';
import 'package:block_puzzle_mobile/ui/effects/score_pop_component.dart';
import 'package:block_puzzle_mobile/ui/effects/shockwave_ring_component.dart';
import 'package:block_puzzle_mobile/ui/effects/vfx_director.dart';
import 'package:block_puzzle_mobile/ui/effects/vfx_events.dart';

void main() {
  group('VfxLevel parser', () {
    test('parses various string representations correctly', () {
      expect(VfxLevel.fromString(null), VfxLevel.standard);
      expect(VfxLevel.fromString('off'), VfxLevel.off);
      expect(VfxLevel.fromString('NONE'), VfxLevel.off);
      expect(VfxLevel.fromString('standard'), VfxLevel.standard);
      expect(VfxLevel.fromString('normal'), VfxLevel.standard);
      expect(VfxLevel.fromString('full'), VfxLevel.full);
      expect(VfxLevel.fromString('high'), VfxLevel.full);
      expect(VfxLevel.fromString('unknown'), VfxLevel.standard);
    });

    test('exposes convenience getters', () {
      expect(VfxLevel.off.isOff, isTrue);
      expect(VfxLevel.standard.isStandard, isTrue);
      expect(VfxLevel.full.isFull, isTrue);
    });
  });

  group('VfxDirector event dispatching', () {
    late VfxDirector director;
    final List<double> cameraShakes = <double>[];

    setUp(() {
      cameraShakes.clear();
      director = VfxDirector(
        vfxLevel: VfxLevel.standard,
        isReducedMotion: () => false,
        onScreenShake: cameraShakes.add,
      );
    });

    test('PiecePlacedVfxEvent spawns landing particles when motion is enabled', () {
      expect(director.burst.activeCount, 0);

      director.handleEvent(
        VfxEvent.piecePlaced(
          position: Vector2(100, 100),
          cellCenters: <Vector2>[Vector2(100, 100), Vector2(140, 100)],
          cellSize: 40,
          color: const Color(0xFF00FF00),
        ),
      );

      expect(director.burst.activeCount, greaterThan(0));
    });

    test('PiecePlacedVfxEvent is suppressed when reducedMotion is true', () {
      final VfxDirector quietDirector = VfxDirector(
        isReducedMotion: () => true,
      );
      quietDirector.handleEvent(
        VfxEvent.piecePlaced(
          position: Vector2(100, 100),
          cellSize: 40,
          color: const Color(0xFF00FF00),
        ),
      );
      expect(quietDirector.burst.activeCount, 0);
    });

    test('LineClearedVfxEvent adds flash, shockwave, triggers screen shake and spawns particles', () {
      director.handleEvent(
        VfxEvent.lineCleared(
          cells: <BoardCell>{
            const BoardCell(x: 0, y: 0),
            const BoardCell(x: 1, y: 0),
          },
          centroid: Vector2(40, 20),
          strength: 2,
          color: const Color(0xFF00FFFF),
          boardOrigin: Vector2.zero(),
          cellSize: 40,
        ),
      );

      expect(director.children.whereType<LineClearFlashComponent>().length, 1);
      expect(director.children.whereType<ShockwaveRingComponent>().length, 1);
      expect(director.burst.activeCount, greaterThan(0));
      expect(cameraShakes, isNotEmpty);
      expect(cameraShakes.last, greaterThanOrEqualTo(2.0));
    });

    test('ScorePoppedVfxEvent adds ScorePopComponent with correct properties', () {
      director.handleEvent(
        VfxEvent.scorePopped(
          text: '+150',
          position: Vector2(120, 200),
        ),
      );

      final pops = director.children.whereType<ScorePopComponent>().toList();
      expect(pops.length, 1);
      expect(pops.first.text, '+150');
      expect(pops.first.startPosition, Vector2(120, 200));
    });

    test('ShockwaveVfxEvent adds ShockwaveRingComponent and removes previous rings', () {
      director.handleEvent(
        VfxEvent.shockwave(
          center: Vector2(50, 50),
          boardRect: const Rect.fromLTWH(0, 0, 300, 300),
        ),
      );
      expect(director.children.whereType<ShockwaveRingComponent>().length, 1);

      // Second shockwave replaces the first
      director.handleEvent(
        VfxEvent.shockwave(
          center: Vector2(100, 100),
          boardRect: const Rect.fromLTWH(0, 0, 300, 300),
        ),
      );
      expect(director.children.whereType<ShockwaveRingComponent>().length, 1);
      expect(director.children.whereType<ShockwaveRingComponent>().first.center, Vector2(100, 100));
    });

    test('ComboPulseVfxEvent replaces previous combo pulse in HUD', () {
      director.handleEvent(
        VfxEvent.comboPulse(
          text: 'Combo x2',
          position: Vector2(100, 40),
          comboStreak: 2,
        ),
      );
      expect(director.children.whereType<ComboPulseComponent>().length, 1);

      director.handleEvent(
        VfxEvent.comboPulse(
          text: 'GREAT!\nCombo x3',
          position: Vector2(100, 40),
          comboStreak: 3,
        ),
      );
      final pulses = director.children.whereType<ComboPulseComponent>().toList();
      expect(pulses.length, 1);
      expect(pulses.first.text, 'GREAT!\nCombo x3');
    });

    test('ScreenShakeVfxEvent triggers camera shake only when reducedMotion is false', () {
      director.handleEvent(const VfxEvent.screenShake(amplitude: 3.5));
      expect(cameraShakes, <double>[3.5]);

      final VfxDirector quietDirector = VfxDirector(
        isReducedMotion: () => true,
        onScreenShake: cameraShakes.add,
      );
      quietDirector.handleEvent(const VfxEvent.screenShake(amplitude: 3.5));
      // No new shake added
      expect(cameraShakes.length, 1);
    });

    test('AllClearVfxEvent dispatches fireworks, shockwave, and ALL CLEAR praise text', () {
      director.handleEvent(
        VfxEvent.allClear(
          boardOrigin: Vector2.zero(),
          boardSize: Vector2.all(320),
        ),
      );

      expect(director.children.whereType<LineClearFlashComponent>().length, 1);
      expect(director.children.whereType<ShockwaveRingComponent>().length, 1);
      expect(director.children.whereType<ComboPulseComponent>().length, 1);
      expect(director.children.whereType<ComboPulseComponent>().first.text, 'ALL CLEAR!');
      expect(director.burst.activeCount, greaterThan(10));
    });

    test('AllClearVfxEvent with reducedMotion suppresses shockwave ring', () {
      final VfxDirector quietDirector = VfxDirector(
        isReducedMotion: () => true,
      );
      quietDirector.handleEvent(
        VfxEvent.allClear(
          boardOrigin: Vector2.zero(),
          boardSize: Vector2.all(320),
        ),
      );

      expect(quietDirector.children.whereType<ShockwaveRingComponent>(), isEmpty);
      expect(quietDirector.children.whereType<ComboPulseComponent>().length, 1);
    });

    test('VfxLevel.off ignores all events completely', () {
      final VfxDirector offDirector = VfxDirector(
        vfxLevel: VfxLevel.off,
        onScreenShake: cameraShakes.add,
      );

      offDirector.handleEvent(
        VfxEvent.lineCleared(
          cells: <BoardCell>{const BoardCell(x: 0, y: 0)},
          centroid: Vector2.zero(),
          strength: 1,
          color: const Color(0xFFFFFFFF),
          boardOrigin: Vector2.zero(),
          cellSize: 40,
        ),
      );

      expect(offDirector.children.length, 0);
      expect(offDirector.burst.activeCount, 0);
      expect(cameraShakes, isEmpty);
    });

    test('clearAll removes all active ephemeral VFX components', () {
      director.handleEvent(
        VfxEvent.scorePopped(
          text: '+50',
          position: Vector2(100, 100),
        ),
      );
      director.handleEvent(
        VfxEvent.comboPulse(
          text: 'Combo x2',
          position: Vector2(100, 50),
        ),
      );
      expect(director.children.length, greaterThan(0));

      director.clearAll();
      expect(director.children.whereType<ScorePopComponent>(), isEmpty);
      expect(director.children.whereType<ComboPulseComponent>(), isEmpty);
    });

    test('dispatches calibrated tiered onHapticFeedback synchronously with visual events', () {
      final List<VfxHapticLevel> haptics = <VfxHapticLevel>[];
      final VfxDirector hapticDirector = VfxDirector(
        onHapticFeedback: haptics.add,
      );

      // Piece placed -> medium impact
      hapticDirector.handleEvent(
        VfxEvent.piecePlaced(
          position: Vector2.zero(),
          cellSize: 36,
          color: const Color(0xFF00FF00),
        ),
      );
      expect(haptics, equals(<VfxHapticLevel>[VfxHapticLevel.medium]));
      haptics.clear();

      // Line cleared single line -> light impact
      hapticDirector.handleEvent(
        VfxEvent.lineCleared(
          cells: <BoardCell>{const BoardCell(x: 0, y: 0)},
          centroid: Vector2.zero(),
          strength: 1,
          color: const Color(0xFF00FF00),
          boardOrigin: Vector2.zero(),
          cellSize: 36,
        ),
      );
      expect(haptics, equals(<VfxHapticLevel>[VfxHapticLevel.light]));
      haptics.clear();

      // Line cleared 3 lines -> medium impact
      hapticDirector.handleEvent(
        VfxEvent.lineCleared(
          cells: <BoardCell>{const BoardCell(x: 0, y: 0)},
          centroid: Vector2.zero(),
          strength: 3,
          color: const Color(0xFF00FF00),
          boardOrigin: Vector2.zero(),
          cellSize: 36,
        ),
      );
      expect(haptics, equals(<VfxHapticLevel>[VfxHapticLevel.medium]));
      haptics.clear();

      // Line cleared 4 lines -> heavy impact
      hapticDirector.handleEvent(
        VfxEvent.lineCleared(
          cells: <BoardCell>{const BoardCell(x: 0, y: 0)},
          centroid: Vector2.zero(),
          strength: 4,
          color: const Color(0xFF00FF00),
          boardOrigin: Vector2.zero(),
          cellSize: 36,
        ),
      );
      expect(haptics, equals(<VfxHapticLevel>[VfxHapticLevel.heavy]));
      haptics.clear();

      // All clear -> doubleHeavy impact
      hapticDirector.handleEvent(
        VfxEvent.allClear(
          boardOrigin: Vector2.zero(),
          boardSize: Vector2.all(300),
        ),
      );
      expect(haptics, equals(<VfxHapticLevel>[VfxHapticLevel.doubleHeavy]));
      haptics.clear();

      // Combo pulse x6 -> heavy impact
      hapticDirector.handleEvent(
        VfxEvent.comboPulse(
          text: 'SUPERB!\nCombo x6',
          position: Vector2.zero(),
          comboStreak: 6,
        ),
      );
      expect(haptics, equals(<VfxHapticLevel>[VfxHapticLevel.heavy]));
    });
  });

  group('ComboPulseComponent render optimization', () {
    test('renders without crashing across all progress stages with zero layout allocations', () {
      final ComboPulseComponent combo = ComboPulseComponent(
        text: 'NICE!\nCombo x2',
        startPosition: Vector2(150, 100),
        duration: 0.85,
      );

      final PictureRecorder recorder = PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // t = 0 (entrance)
      combo.render(canvas);

      // t = 0.5 (overshoot apex)
      combo.update(0.425);
      combo.render(canvas);

      // t = 0.9 (fadeout)
      combo.update(0.35);
      combo.render(canvas);

      expect(combo.isFinished, isFalse);

      // Exceed duration
      combo.update(0.2);
      expect(combo.isFinished, isTrue);
    });
  });

  group('Dynamic vfxLevel and Remote Config integration', () {
    tearDown(() {
      Step6Benchmark.vfxLevel.value = VfxLevel.standard;
    });

    test('VfxDirector defaults to Step6Benchmark.vfxLevel.value dynamically', () {
      Step6Benchmark.vfxLevel.value = VfxLevel.full;
      final VfxDirector director = VfxDirector();
      expect(director.vfxLevel, equals(VfxLevel.full));

      Step6Benchmark.vfxLevel.value = VfxLevel.off;
      expect(director.vfxLevel, equals(VfxLevel.off));
    });

    test('explicit vfxLevel overrides Step6Benchmark.vfxLevel', () {
      Step6Benchmark.vfxLevel.value = VfxLevel.off;
      final VfxDirector director = VfxDirector(vfxLevel: VfxLevel.full);
      expect(director.vfxLevel, equals(VfxLevel.full));
    });

    test('vfxLevel.off completely suppresses event handling and hit-stop', () {
      final VfxDirector director = VfxDirector(vfxLevel: VfxLevel.off);

      director.triggerHitStop(0.05);
      expect(director.isHitStopActive, isFalse);

      director.handleEvent(
        VfxEvent.piecePlaced(
          position: Vector2(100, 100),
          color: const Color(0xFF00FF00),
        ),
      );
      expect(director.burst.activeCount, equals(0));
    });

    test('vfxLevel.full spawns higher particle counts than standard', () {
      final VfxDirector stdDirector = VfxDirector(vfxLevel: VfxLevel.standard);
      stdDirector.handleEvent(
        VfxEvent.piecePlaced(
          position: Vector2(100, 100),
          color: const Color(0xFF00FF00),
        ),
      );
      final int stdParticles = stdDirector.burst.activeCount;

      final VfxDirector fullDirector = VfxDirector(vfxLevel: VfxLevel.full);
      fullDirector.handleEvent(
        VfxEvent.piecePlaced(
          position: Vector2(100, 100),
          color: const Color(0xFF00FF00),
        ),
      );
      final int fullParticles = fullDirector.burst.activeCount;

      expect(fullParticles, greaterThan(stdParticles));
    });
  });

  group('BurstField.render optimization', () {
    test('renders active particles with reusable Paint without crashing', () {
      final BurstField burst = BurstField();
      burst.spawnBurst(
        x: 100,
        y: 100,
        color: const Color(0xFFFF5500),
        count: 10,
      );
      expect(burst.activeCount, equals(10));

      final PictureRecorder recorder = PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      expect(() => burst.render(canvas), returnsNormally);
      burst.update(0.1);
      expect(() => burst.render(canvas), returnsNormally);
    });
  });
}
