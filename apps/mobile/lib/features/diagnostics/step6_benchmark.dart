import 'package:flutter/foundation.dart';

import '../../../domain/gameplay/board_state.dart';
import 'diagnostics_screen.dart';

enum Step6BenchmarkScenario {
  singleClear,
  tripleClear,
}

/// Diagnostic harness for DEC-0024/DEC-0028 Step 6+: Shockwave ring, particles,
/// floating score popups, triple line clear, and reduced motion benchmarking.
///
/// Dead-code eliminated in release builds without `--dart-define=ENABLE_DIAGNOSTICS=true`.
abstract final class Step6Benchmark {
  static final ValueNotifier<bool> benchActive = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> effectsEnabled = ValueNotifier<bool>(false);
  static final ValueNotifier<Step6BenchmarkScenario> scenario =
      ValueNotifier<Step6BenchmarkScenario>(Step6BenchmarkScenario.singleClear);
  static final ValueNotifier<bool> reducedMotion = ValueNotifier<bool>(false);

  static bool get isDiagnosticsEnabled => kDiagnosticsEnabled;

  /// Standard half-filled board configuration (26 occupied cells) for reproducible benchmarking.
  static final Set<BoardCell> halfBoard26Cells = Set<BoardCell>.unmodifiable(<BoardCell>{
    const BoardCell(x: 0, y: 0),
    const BoardCell(x: 1, y: 0),
    const BoardCell(x: 0, y: 1),
    const BoardCell(x: 1, y: 1),
    const BoardCell(x: 2, y: 1),
    const BoardCell(x: 3, y: 2),
    const BoardCell(x: 4, y: 2),
    const BoardCell(x: 5, y: 2),
    const BoardCell(x: 0, y: 3),
    const BoardCell(x: 1, y: 3),
    const BoardCell(x: 6, y: 3),
    const BoardCell(x: 7, y: 3),
    const BoardCell(x: 4, y: 4),
    const BoardCell(x: 5, y: 4),
    const BoardCell(x: 6, y: 4),
    const BoardCell(x: 1, y: 5),
    const BoardCell(x: 2, y: 5),
    const BoardCell(x: 3, y: 5),
    const BoardCell(x: 0, y: 6),
    const BoardCell(x: 5, y: 6),
    const BoardCell(x: 6, y: 6),
    const BoardCell(x: 7, y: 6),
    const BoardCell(x: 2, y: 7),
    const BoardCell(x: 3, y: 7),
    const BoardCell(x: 4, y: 7),
    const BoardCell(x: 7, y: 7),
  });

  /// 8 distinct board coordinates for 8 concurrent clear events during benchmarking.
  static const List<BoardCell> benchCentroids = <BoardCell>[
    BoardCell(x: 1, y: 1),
    BoardCell(x: 5, y: 1),
    BoardCell(x: 3, y: 3),
    BoardCell(x: 1, y: 5),
    BoardCell(x: 5, y: 5),
    BoardCell(x: 3, y: 1),
    BoardCell(x: 1, y: 3),
    BoardCell(x: 5, y: 3),
  ];

  /// Standard triple-clear configuration (24 occupied cells across rows 1, 3, 5).
  static final Set<BoardCell> tripleClear24Cells = Set<BoardCell>.unmodifiable(<BoardCell>{
    for (final int y in const <int>[1, 3, 5])
      for (int x = 0; x < 8; x++)
        BoardCell(x: x, y: y),
  });
}
