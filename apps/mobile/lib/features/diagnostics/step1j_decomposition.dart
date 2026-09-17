import 'package:flutter/foundation.dart';

import 'diagnostics_screen.dart';

/// Configurations for DEC-0024 Step 1j: decomposing Classic frame cost by subtraction.
enum Step1jConfig {
  aBaseline('A: Baseline (Full Classic)', 'A'),
  bNoHud('B: No HUD / AppBar / Combo', 'B'),
  cNoClip('C: No ClipRRect / DecoratedBox', 'C'),
  dNoPiecesPic('D: No Starfield / Pieces Picture', 'D'),
  eNoRackPic('E: No Rack Pieces Picture', 'E'),
  fAllRemoved('F: All B+C+D+E Removed', 'F');

  const Step1jConfig(this.label, this.code);
  final String label;
  final String code;
}

/// Diagnostic controls for decomposing the Classic frame during Step 1j.
///
/// Dead-code eliminated in store/release builds without `--dart-define=ENABLE_DIAGNOSTICS=true`.
abstract final class Step1jDecomposition {
  static final ValueNotifier<Step1jConfig> activeConfig =
      ValueNotifier<Step1jConfig>(Step1jConfig.aBaseline);

  static bool get isDiagnosticsEnabled => kDiagnosticsEnabled;

  /// B: HUD panel, AppBar, and combo overlay.
  static bool get hideB =>
      kDiagnosticsEnabled &&
      (activeConfig.value == Step1jConfig.bNoHud ||
          activeConfig.value == Step1jConfig.fAllRemoved);

  /// C: ClipRRect and DecoratedBox around GameWidget.
  static bool get hideC =>
      kDiagnosticsEnabled &&
      (activeConfig.value == Step1jConfig.cNoClip ||
          activeConfig.value == Step1jConfig.fAllRemoved);

  /// D: Starfield and occupied cells Picture in Classic.
  static bool get hideD =>
      kDiagnosticsEnabled &&
      (activeConfig.value == Step1jConfig.dNoPiecesPic ||
          activeConfig.value == Step1jConfig.fAllRemoved);

  /// E: Rack pieces Picture in RackPieceComponent.
  static bool get hideE =>
      kDiagnosticsEnabled &&
      (activeConfig.value == Step1jConfig.eNoRackPic ||
          activeConfig.value == Step1jConfig.fAllRemoved);
}
