import 'package:flutter_test/flutter_test.dart';
import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/features/diagnostics/step6_benchmark.dart';

void main() {
  group('Step6Benchmark', () {
    tearDown(() {
      Step6Benchmark.benchActive.value = false;
      Step6Benchmark.effectsEnabled.value = false;
      Step6Benchmark.scenario.value = Step6BenchmarkScenario.singleClear;
      Step6Benchmark.reducedMotion.value = false;
    });

    test('defaults to inactive with effects disabled, singleClear and full motion', () {
      expect(Step6Benchmark.benchActive.value, isFalse);
      expect(Step6Benchmark.effectsEnabled.value, isFalse);
      expect(Step6Benchmark.scenario.value, Step6BenchmarkScenario.singleClear);
      expect(Step6Benchmark.reducedMotion.value, isFalse);
    });

    test('halfBoard26Cells contains exactly 26 valid cells with no completed lines', () {
      final Set<BoardCell> cells = Step6Benchmark.halfBoard26Cells;
      expect(cells.length, 26);

      final List<int> rowCounts = List<int>.filled(8, 0);
      final List<int> colCounts = List<int>.filled(8, 0);

      for (final BoardCell cell in cells) {
        expect(cell.x, greaterThanOrEqualTo(0));
        expect(cell.x, lessThan(8));
        expect(cell.y, greaterThanOrEqualTo(0));
        expect(cell.y, lessThan(8));

        rowCounts[cell.y]++;
        colCounts[cell.x]++;
      }

      // Ensure no rows or columns are fully occupied (which would trigger unwanted line clears)
      for (int r = 0; r < 8; r++) {
        expect(rowCounts[r], lessThan(8));
      }
      for (int c = 0; c < 8; c++) {
        expect(colCounts[c], lessThan(8));
      }
    });

    test('tripleClear24Cells contains exactly 24 cells across 3 full rows (1, 3, 5)', () {
      final Set<BoardCell> cells = Step6Benchmark.tripleClear24Cells;
      expect(cells.length, 24);

      final List<int> rowCounts = List<int>.filled(8, 0);
      for (final BoardCell cell in cells) {
        expect(cell.x, greaterThanOrEqualTo(0));
        expect(cell.x, lessThan(8));
        expect(<int>[1, 3, 5], contains(cell.y));
        rowCounts[cell.y]++;
      }

      expect(rowCounts[1], 8);
      expect(rowCounts[3], 8);
      expect(rowCounts[5], 8);
    });

    test('benchCentroids has exactly 8 items within 8x8 bounds', () {
      const int expectedCount = 8;
      const List<BoardCell> centroids = Step6Benchmark.benchCentroids;
      expect(centroids.length, expectedCount);
      final Set<String> unique = centroids.map((BoardCell c) => '${c.x},${c.y}').toSet();
      expect(unique.length, expectedCount);

      for (final BoardCell c in centroids) {
        expect(c.x, greaterThanOrEqualTo(0));
        expect(c.x, lessThan(8));
        expect(c.y, greaterThanOrEqualTo(0));
        expect(c.y, lessThan(8));
      }
    });

    test('ValueNotifiers update state correctly', () {
      Step6Benchmark.benchActive.value = true;
      expect(Step6Benchmark.benchActive.value, isTrue);

      Step6Benchmark.effectsEnabled.value = true;
      expect(Step6Benchmark.effectsEnabled.value, isTrue);

      Step6Benchmark.scenario.value = Step6BenchmarkScenario.tripleClear;
      expect(Step6Benchmark.scenario.value, Step6BenchmarkScenario.tripleClear);

      Step6Benchmark.reducedMotion.value = true;
      expect(Step6Benchmark.reducedMotion.value, isTrue);
    });
  });
}
