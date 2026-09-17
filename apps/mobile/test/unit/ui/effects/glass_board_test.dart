import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_puzzle_mobile/ui/effects/glass_board.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('rasterizeBoardWell (DEC-0024 Step 1i)', () {
    test('rasterizes well to ui.Image with physical pixel dimensions', () {
      final ui.Image image = rasterizeBoardWell(
        width: 360,
        height: 360,
        cell: 45,
        cols: 8,
        rows: 8,
        devicePixelRatio: 2.75,
      );

      expect(image.width, equals(990)); // 360 * 2.75 = 990
      expect(image.height, equals(990));
      image.dispose();
    });

    test('falls back to 1.0 when devicePixelRatio is zero or negative', () {
      final ui.Image image = rasterizeBoardWell(
        width: 100,
        height: 100,
        cell: 25,
        cols: 4,
        rows: 4,
        devicePixelRatio: -0.5,
      );

      expect(image.width, equals(100));
      expect(image.height, equals(100));
      image.dispose();
    });

    test('drawBoardWellImage paints without throwing', () {
      final ui.Image image = rasterizeBoardWell(
        width: 100,
        height: 100,
        cell: 25,
        cols: 4,
        rows: 4,
        devicePixelRatio: 2.0,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      expect(
        () => drawBoardWellImage(canvas, image, width: 100, height: 100),
        returnsNormally,
      );

      final ui.Picture picture = recorder.endRecording();
      picture.dispose();
      image.dispose();
    });
  });
}
