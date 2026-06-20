import 'package:block_puzzle_mobile/domain/match3/match_detector.dart';
import 'package:block_puzzle_mobile/domain/match3/tile.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:flutter_test/flutter_test.dart';

const TileColor r = TileColor.ruby;
const TileColor m = TileColor.amber;
const TileColor c = TileColor.citrine;
const TileColor e = TileColor.emerald;

/// Builds a grid from rows listed top (y=0) to bottom.
TileGrid g(List<List<TileColor>> rows) {
  final int h = rows.length;
  final int w = rows.first.length;
  return TileGrid(
    width: w,
    height: h,
    cells: <TileColor?>[for (final List<TileColor> row in rows) ...row],
  );
}

void main() {
  const MatchDetector detector = MatchDetector();

  group('MatchDetector', () {
    test('detects a horizontal run of three', () {
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, r, r, m],
      ]);
      final List<TileMatch> matches = detector.findMatches(grid);
      expect(matches, hasLength(1));
      expect(matches.single.horizontal, isTrue);
      expect(matches.single.length, 3);
      expect(matches.single.color, r);
      expect(detector.hasMatch(grid), isTrue);
    });

    test('detects a vertical run of three', () {
      final TileGrid grid =
          TileGrid(width: 1, height: 3, cells: <TileColor?>[r, r, r]);
      final List<TileMatch> matches = detector.findMatches(grid);
      expect(matches, hasLength(1));
      expect(matches.single.horizontal, isFalse);
      expect(matches.single.length, 3);
    });

    test('a checkerboard has no matches', () {
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, m, r],
        <TileColor>[m, r, m],
        <TileColor>[r, m, r],
      ]);
      expect(detector.findMatches(grid), isEmpty);
      expect(detector.hasMatch(grid), isFalse);
    });

    test('an L-shape reports two runs and a 5-cell union', () {
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, m, c],
        <TileColor>[r, m, c],
        <TileColor>[r, r, r],
      ]);
      expect(detector.findMatches(grid), hasLength(2));
      expect(detector.matchedCells(grid), hasLength(5));
    });

    test('a run of four is a single length-4 match', () {
      final TileGrid grid = g(<List<TileColor>>[
        <TileColor>[r, r, r, r],
      ]);
      final List<TileMatch> matches = detector.findMatches(grid);
      expect(matches, hasLength(1));
      expect(matches.single.length, 4);
    });
  });
}
