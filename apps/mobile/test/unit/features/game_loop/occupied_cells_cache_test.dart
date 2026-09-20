import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/features/game_loop/presentation/block_puzzle_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('rasterizeOccupiedCellsImage (DEC-0024 Review 12 item 4.1)', () {
    test('rasterizes occupied cells to ui.Image with physical pixel dimensions', () {
      final List<BoardCell> cells = <BoardCell>[
        const BoardCell(x: 0, y: 0),
        const BoardCell(x: 1, y: 1),
        const BoardCell(x: 2, y: 3),
      ];

      final ui.Image image = rasterizeOccupiedCellsImage(
        width: 360,
        height: 360,
        cellSize: 45,
        occupiedCells: cells,
        devicePixelRatio: 2.75,
        occupiedColor: const Color(0xFF55CEFF),
        visualPreset: BlockVisualPreset.crystal,
      );

      expect(image.width, equals(990)); // ceil(360 * 2.75) = 990
      expect(image.height, equals(990));
      image.dispose();
    });

    test('falls back to 1.0 when devicePixelRatio is zero or negative', () {
      final ui.Image image = rasterizeOccupiedCellsImage(
        width: 100,
        height: 100,
        cellSize: 25,
        occupiedCells: const <BoardCell>[BoardCell(x: 0, y: 0)],
        devicePixelRatio: -1.0,
        occupiedColor: const Color(0xFF55CEFF),
        visualPreset: BlockVisualPreset.soft,
      );

      expect(image.width, equals(100));
      expect(image.height, equals(100));
      image.dispose();
    });

    test('renders cleanly with empty occupied cells and optional starMap', () {
      final ui.Image image = rasterizeOccupiedCellsImage(
        width: 200,
        height: 200,
        cellSize: 25,
        occupiedCells: const <BoardCell>[],
        devicePixelRatio: 1.5,
        occupiedColor: const Color(0xFF55CEFF),
        visualPreset: BlockVisualPreset.crystal,
        starMap: const <Offset>[
          Offset(0.1, 0.2),
          Offset(0.5, 0.5),
        ],
      );

      expect(image.width, equals(300)); // ceil(200 * 1.5) = 300
      expect(image.height, equals(300));
      image.dispose();
    });

    test('drawOccupiedCellsImage paints without throwing', () {
      final ui.Image image = rasterizeOccupiedCellsImage(
        width: 100,
        height: 100,
        cellSize: 25,
        occupiedCells: const <BoardCell>[BoardCell(x: 1, y: 1)],
        devicePixelRatio: 2.0,
        occupiedColor: const Color(0xFF55CEFF),
        visualPreset: BlockVisualPreset.crystal,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      expect(
        () => drawOccupiedCellsImage(canvas, image, width: 100, height: 100),
        returnsNormally,
      );

      final ui.Picture picture = recorder.endRecording();
      picture.dispose();
      image.dispose();
    });

    test('stale image can be disposed safely before reallocating', () {
      ui.Image? cachedImage = rasterizeOccupiedCellsImage(
        width: 100,
        height: 100,
        cellSize: 25,
        occupiedCells: const <BoardCell>[BoardCell(x: 0, y: 0)],
        devicePixelRatio: 1.0,
        occupiedColor: const Color(0xFF55CEFF),
        visualPreset: BlockVisualPreset.soft,
      );

      final ui.Image stale = cachedImage;
      expect(stale.dispose, returnsNormally);

      cachedImage = rasterizeOccupiedCellsImage(
        width: 100,
        height: 100,
        cellSize: 25,
        occupiedCells: const <BoardCell>[BoardCell(x: 1, y: 1)],
        devicePixelRatio: 1.0,
        occupiedColor: const Color(0xFF55CEFF),
        visualPreset: BlockVisualPreset.crystal,
      );
      expect(cachedImage, isNotNull);
      cachedImage.dispose();
    });
  });
}
