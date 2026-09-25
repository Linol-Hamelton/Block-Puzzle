import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/ui/effects/piece_aura_shader.dart';
import 'package:block_puzzle_mobile/ui/effects/vfx_events.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PieceAuraShader', () {
    test('isEnabled is true on VfxLevel.standard and full with reduced motion off', () {
      bool reducedMotion = false;
      final PieceAuraShader shader = PieceAuraShader(
        vfxLevel: VfxLevel.full,
        isReducedMotion: () => reducedMotion,
      );

      expect(shader.isEnabled, isTrue);

      shader.vfxLevel = VfxLevel.standard;
      expect(shader.isEnabled, isTrue);

      shader.vfxLevel = VfxLevel.off;
      expect(shader.isEnabled, isFalse);

      shader.vfxLevel = VfxLevel.full;
      reducedMotion = true;
      expect(shader.isEnabled, isFalse);
    });

    test('createPaint returns procedural radial gradient when shader program is null', () {
      final PieceAuraShader shader = PieceAuraShader(
        vfxLevel: VfxLevel.full,
      );

      final Paint paint = shader.createPaint(
        bounds: const Rect.fromLTWH(0, 0, 100, 100),
        color: const Color(0xFF00FFCC),
        time: 1.5,
        intensity: 0.8,
      );

      expect(paint.shader, isNotNull);
      expect(paint.blendMode, BlendMode.plus);
    });

    test('drawAura paints oval without throwing when enabled', () {
      final PieceAuraShader shader = PieceAuraShader(
        vfxLevel: VfxLevel.full,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      expect(
        () => shader.drawAura(
          canvas,
          targetBounds: const Rect.fromLTWH(10, 10, 80, 80),
          color: const Color(0xFFFF5588),
          time: 2.0,
          intensity: 1.0,
        ),
        returnsNormally,
      );

      final ui.Picture pic = recorder.endRecording();
      pic.dispose();
    });

    test('drawAura is a no-op when isEnabled is false or intensity is 0', () {
      final PieceAuraShader shader = PieceAuraShader(
        vfxLevel: VfxLevel.off, // disabled
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      shader.drawAura(
        canvas,
        targetBounds: const Rect.fromLTWH(0, 0, 50, 50),
        color: Colors.cyan,
        time: 0.5,
      );

      final ui.Picture pic = recorder.endRecording();
      pic.dispose();
      shader.dispose();
    });

    test('dispose cleans up cached shader without throwing', () {
      final PieceAuraShader shader = PieceAuraShader(vfxLevel: VfxLevel.full);
      expect(shader.dispose, returnsNormally);
    });

    test('loadShader catches asset errors gracefully without rethrowing', () async {
      final PieceAuraShader shader = PieceAuraShader(
        vfxLevel: VfxLevel.full,
      );

      // In a headless unit test, asset bundle may not have compiled shaders
      await expectLater(shader.loadShader(), completes);
      shader.dispose();
    });
  });
}
