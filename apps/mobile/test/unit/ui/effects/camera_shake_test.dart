import 'dart:ui';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/ui/effects/camera_shake_effect.dart';
import 'package:block_puzzle_mobile/ui/effects/landing_squash_component.dart';
import 'package:block_puzzle_mobile/ui/effects/vfx_director.dart';
import 'package:block_puzzle_mobile/ui/effects/vfx_events.dart';

void main() {
  group('CameraShakeEffect lifecycle and drift prevention', () {
    late Viewfinder viewfinder;

    setUp(() {
      viewfinder = Viewfinder();
      viewfinder.position = Vector2(50, 80);
    });

    test('oscillates and restores exact initial position upon completion', () {
      bool completed = false;
      final CameraShakeEffect shake = CameraShakeEffect(
        viewfinder: viewfinder,
        amplitude: 4.0,
        duration: 0.16,
        onComplete: () => completed = true,
      );

      shake.onMount();

      // Mid-shake: position should deviate from (50, 80)
      shake.update(0.04);
      expect(viewfinder.position.x, isNot(equals(50.0)));

      // Advance past duration: must restore exact (50, 80) without drift
      shake.update(0.14);
      expect(viewfinder.position.x, equals(50.0));
      expect(viewfinder.position.y, equals(80.0));
      expect(completed, isTrue);
    });

    test('restores exact initial position even on premature removal', () {
      final CameraShakeEffect shake = CameraShakeEffect(
        viewfinder: viewfinder,
        amplitude: 5.0,
        duration: 0.20,
      );

      shake.onMount();
      shake.update(0.05);
      expect(viewfinder.position.x, isNot(equals(50.0)));

      shake.onRemove();
      expect(viewfinder.position.x, equals(50.0));
      expect(viewfinder.position.y, equals(80.0));
    });
  });

  group('ZoomPunchEffect lifecycle', () {
    late Viewfinder viewfinder;

    setUp(() {
      viewfinder = Viewfinder();
      viewfinder.zoom = 1.0;
    });

    test('punches zoom and smoothly springs back to initial zoom', () {
      bool completed = false;
      final ZoomPunchEffect zoom = ZoomPunchEffect(
        viewfinder: viewfinder,
        maxZoomDelta: 0.03,
        duration: 0.25,
        onComplete: () => completed = true,
      );

      zoom.onMount();

      // Peak punch: zoom > 1.0
      zoom.update(0.05);
      expect(viewfinder.zoom, greaterThan(1.0));

      // After duration: returns to exact 1.0
      zoom.update(0.22);
      expect(viewfinder.zoom, equals(1.0));
      expect(completed, isTrue);
    });

    test('restores initial zoom on premature removal', () {
      final ZoomPunchEffect zoom = ZoomPunchEffect(
        viewfinder: viewfinder,
        maxZoomDelta: 0.03,
        duration: 0.25,
      );

      zoom.onMount();
      zoom.update(0.05);
      expect(viewfinder.zoom, greaterThan(1.0));

      zoom.onRemove();
      expect(viewfinder.zoom, equals(1.0));
    });
  });

  group('LandingSquashComponent lifecycle and rendering', () {
    test('computes bounding box and renders without throwing', () {
      final List<Rect> cells = <Rect>[
        const Rect.fromLTWH(40, 40, 36, 36),
        const Rect.fromLTWH(76, 40, 36, 36),
        const Rect.fromLTWH(40, 76, 36, 36),
      ];

      final LandingSquashComponent squash = LandingSquashComponent(
        cellRects: cells,
        color: const Color(0xFF55CEFF),
        duration: 0.20,
      );

      final PictureRecorder recorder = PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // t=0 (compressed)
      squash.render(canvas);

      // t=0.5 (rebounding)
      squash.update(0.10);
      squash.render(canvas);

      expect(squash.isFinished, isFalse);

      // t=1.0 (finished)
      squash.update(0.12);
      expect(squash.isFinished, isTrue);
    });

    test('gracefully handles empty cell list', () {
      final LandingSquashComponent squash = LandingSquashComponent(
        cellRects: <Rect>[],
        color: const Color(0xFFFFFFFF),
      );

      final PictureRecorder recorder = PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      expect(() => squash.render(canvas), returnsNormally);
    });
  });

  group('Hit-Stop freeze frame in VfxDirector', () {
    test('triggers hit-stop and freezes simulation for specified duration', () {
      final VfxDirector director = VfxDirector(
        isReducedMotion: () => false,
      );

      expect(director.isHitStopActive, isFalse);

      director.triggerHitStop(0.05);
      expect(director.isHitStopActive, isTrue);

      // Advance partial duration: still active
      director.update(0.025);
      expect(director.isHitStopActive, isTrue);

      // Advance past duration: cleared
      director.update(0.035);
      expect(director.isHitStopActive, isFalse);
    });

    test('hit-stop is suppressed when reducedMotion is true', () {
      final VfxDirector quietDirector = VfxDirector(
        isReducedMotion: () => true,
      );

      quietDirector.triggerHitStop(0.06);
      expect(quietDirector.isHitStopActive, isFalse);
    });

    test('PiecePlacedVfxEvent with cellRects spawns LandingSquashComponent', () {
      final VfxDirector director = VfxDirector(
        isReducedMotion: () => false,
      );

      director.handleEvent(
        VfxEvent.piecePlaced(
          position: Vector2(100, 100),
          cellRects: <Rect>[const Rect.fromLTWH(100, 100, 40, 40)],
          color: const Color(0xFF00FF00),
        ),
      );

      expect(director.children.whereType<LandingSquashComponent>().length, 1);
    });
  });
}
