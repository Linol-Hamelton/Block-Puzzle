import 'package:flutter_test/flutter_test.dart';
import 'package:block_puzzle_mobile/features/diagnostics/step1j_decomposition.dart';

void main() {
  group('Step1jDecomposition', () {
    tearDown(() {
      Step1jDecomposition.activeConfig.value = Step1jConfig.aBaseline;
    });

    test('defines all six configurations A through F', () {
      expect(Step1jConfig.values.length, 6);
      expect(Step1jConfig.aBaseline.code, 'A');
      expect(Step1jConfig.bNoHud.code, 'B');
      expect(Step1jConfig.cNoClip.code, 'C');
      expect(Step1jConfig.dNoPiecesPic.code, 'D');
      expect(Step1jConfig.eNoRackPic.code, 'E');
      expect(Step1jConfig.fAllRemoved.code, 'F');
    });

    test('defaults to baseline configuration', () {
      expect(
        Step1jDecomposition.activeConfig.value,
        Step1jConfig.aBaseline,
      );
    });

    test('flags are completely disabled when ENABLE_DIAGNOSTICS is false', () {
      if (!Step1jDecomposition.isDiagnosticsEnabled) {
        for (final Step1jConfig config in Step1jConfig.values) {
          Step1jDecomposition.activeConfig.value = config;
          expect(Step1jDecomposition.hideB, isFalse);
          expect(Step1jDecomposition.hideC, isFalse);
          expect(Step1jDecomposition.hideD, isFalse);
          expect(Step1jDecomposition.hideE, isFalse);
        }
      }
    });

    test('flags reflect active configuration when ENABLE_DIAGNOSTICS is true', () {
      if (Step1jDecomposition.isDiagnosticsEnabled) {
        Step1jDecomposition.activeConfig.value = Step1jConfig.aBaseline;
        expect(Step1jDecomposition.hideB, isFalse);
        expect(Step1jDecomposition.hideC, isFalse);
        expect(Step1jDecomposition.hideD, isFalse);
        expect(Step1jDecomposition.hideE, isFalse);

        Step1jDecomposition.activeConfig.value = Step1jConfig.bNoHud;
        expect(Step1jDecomposition.hideB, isTrue);
        expect(Step1jDecomposition.hideC, isFalse);
        expect(Step1jDecomposition.hideD, isFalse);
        expect(Step1jDecomposition.hideE, isFalse);

        Step1jDecomposition.activeConfig.value = Step1jConfig.cNoClip;
        expect(Step1jDecomposition.hideB, isFalse);
        expect(Step1jDecomposition.hideC, isTrue);
        expect(Step1jDecomposition.hideD, isFalse);
        expect(Step1jDecomposition.hideE, isFalse);

        Step1jDecomposition.activeConfig.value = Step1jConfig.dNoPiecesPic;
        expect(Step1jDecomposition.hideB, isFalse);
        expect(Step1jDecomposition.hideC, isFalse);
        expect(Step1jDecomposition.hideD, isTrue);
        expect(Step1jDecomposition.hideE, isFalse);

        Step1jDecomposition.activeConfig.value = Step1jConfig.eNoRackPic;
        expect(Step1jDecomposition.hideB, isFalse);
        expect(Step1jDecomposition.hideC, isFalse);
        expect(Step1jDecomposition.hideD, isFalse);
        expect(Step1jDecomposition.hideE, isTrue);

        Step1jDecomposition.activeConfig.value = Step1jConfig.fAllRemoved;
        expect(Step1jDecomposition.hideB, isTrue);
        expect(Step1jDecomposition.hideC, isTrue);
        expect(Step1jDecomposition.hideD, isTrue);
        expect(Step1jDecomposition.hideE, isTrue);
      }
    });
  });
}
