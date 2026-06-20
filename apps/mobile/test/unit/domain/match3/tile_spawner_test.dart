import 'package:block_puzzle_mobile/domain/match3/match_detector.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_grid.dart';
import 'package:block_puzzle_mobile/domain/match3/tile_spawner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MatchDetector detector = MatchDetector();

  group('TileSpawner.fillInitial', () {
    test('produces a board with no pre-existing match', () {
      for (final int seed in <int>[1, 7, 42, 1000]) {
        final TileGrid grid = TileSpawner(seed: seed).fillInitial(8, 8);
        expect(grid.isFull, isTrue);
        expect(detector.hasMatch(grid), isFalse,
            reason: 'seed $seed produced a starting match');
      }
    });

    test('is deterministic for a given seed', () {
      final TileGrid a = TileSpawner(seed: 99).fillInitial(8, 8);
      final TileGrid b = TileSpawner(seed: 99).fillInitial(8, 8);
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          expect(a.at(x, y), b.at(x, y));
        }
      }
    });

    test('refill fills every hole', () {
      final TileSpawner spawner = TileSpawner(seed: 3);
      final TileGrid holed = spawner.fillInitial(4, 4).withCell(1, 1, null);
      expect(holed.isFull, isFalse);
      expect(spawner.refill(holed).isFull, isTrue);
    });
  });
}
