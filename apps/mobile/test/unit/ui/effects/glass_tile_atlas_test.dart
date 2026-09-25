import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/tetris/tetromino.dart';
import 'package:block_puzzle_mobile/ui/effects/glass_tile_atlas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlassTileAtlas', () {
    test('bakeTetris produces valid atlas with 7 tetromino minos', () {
      final GlassTileAtlas<TetrominoType> atlas = GlassTileAtlas.bakeTetris(
        cell: 30,
        devicePixelRatio: 2.0,
      );

      expect(atlas.unit, 30);
      expect(atlas.devicePixelRatio, 2.0);
      expect(atlas.image.width, 30 * 2 * 7); // 420 physical px
      expect(atlas.image.height, 30 * 2);    // 60 physical px

      for (final TetrominoType type in TetrominoType.values) {
        final Rect? src = atlas.sourceRectFor(type);
        expect(src, isNotNull);
        expect(src!.width, 60);
        expect(src.height, 60);
      }

      atlas.dispose();
    });

    test('bakeMatch3 produces valid atlas with 6 gem shapes', () {
      final GlassTileAtlas<TileColor> atlas = GlassTileAtlas.bakeMatch3(
        cell: 40,
        devicePixelRatio: 1.5,
      );

      expect(atlas.unit, 40);
      expect(atlas.devicePixelRatio, 1.5);
      expect(atlas.image.width, 40 * 1.5 * 6); // 360 physical px
      expect(atlas.image.height, 40 * 1.5);    // 60 physical px

      for (final TileColor color in TileColor.values) {
        final Rect? src = atlas.sourceRectFor(color);
        expect(src, isNotNull);
        expect(src!.width, 60);
        expect(src.height, 60);
      }

      atlas.dispose();
    });

    test('isValidFor detects cell and ratio mismatches', () {
      final GlassTileAtlas<TetrominoType> atlas = GlassTileAtlas.bakeTetris(
        cell: 32,
        devicePixelRatio: 2.5,
      );

      expect(atlas.isValidFor(unit: 32, devicePixelRatio: 2.5), isTrue);
      expect(atlas.isValidFor(unit: 36, devicePixelRatio: 2.5), isFalse);
      expect(atlas.isValidFor(unit: 32, devicePixelRatio: 3.0), isFalse);

      atlas.dispose();
    });

    test('drawTile blits without throwing', () {
      final GlassTileAtlas<TetrominoType> atlas = GlassTileAtlas.bakeTetris(
        cell: 20,
        devicePixelRatio: 1.0,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      expect(
        () => atlas.drawTile(
          canvas,
          key: TetrominoType.t,
          dstCellRect: const Rect.fromLTWH(10, 10, 20, 20),
        ),
        returnsNormally,
      );

      final ui.Picture pic = recorder.endRecording();
      pic.dispose();
      atlas.dispose();
    });

    test('drawBatch renders multiple tiles via drawRawAtlas without throwing', () {
      final GlassTileAtlas<TileColor> atlas = GlassTileAtlas.bakeMatch3(
        cell: 25,
        devicePixelRatio: 2.0,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      expect(
        () => atlas.drawBatch(
          canvas,
          keys: <TileColor>[TileColor.ruby, TileColor.citrine, TileColor.amethyst],
          positions: <Offset>[
            const Offset(0, 0),
            const Offset(25, 0),
            const Offset(50, 0),
          ],
        ),
        returnsNormally,
      );

      final ui.Picture pic = recorder.endRecording();
      pic.dispose();
      atlas.dispose();
    });

    test('drawBatch with empty input returns normally', () {
      final GlassTileAtlas<TetrominoType> atlas = GlassTileAtlas.bakeTetris(
        cell: 20,
        devicePixelRatio: 1.0,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      expect(
        () => atlas.drawBatch(
          canvas,
          keys: const <TetrominoType>[],
          positions: const <Offset>[],
        ),
        returnsNormally,
      );

      final ui.Picture pic = recorder.endRecording();
      pic.dispose();
      atlas.dispose();
    });
  });
}
