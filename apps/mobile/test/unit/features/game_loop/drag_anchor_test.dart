import 'package:block_puzzle_mobile/features/game_loop/presentation/block_puzzle_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RackPieceComponent Drag Anchor (DEC-0024 point 5)', () {
    test('horizontalCenterOffset centers touch point horizontally for 1-cell piece', () {
      const double pieceWidth = 24.0; // 1 cell
      const double expectedCenter = 12.0;

      // Touching left edge (local X = 0)
      final double offsetLeft = RackPieceComponent.horizontalCenterOffset(
        localTouchX: 0.0,
        pieceWidth: pieceWidth,
      );
      expect(offsetLeft, -12.0);
      // Simulating piece at pos.x = 100:
      const double initialPosX = 100.0;
      const double touchWorldX = initialPosX + 0.0; // 100.0
      final double newPosX = initialPosX + offsetLeft; // 88.0
      expect(touchWorldX - newPosX, expectedCenter);

      // Touching center (local X = 12)
      final double offsetCenter = RackPieceComponent.horizontalCenterOffset(
        localTouchX: 12.0,
        pieceWidth: pieceWidth,
      );
      expect(offsetCenter, 0.0);

      // Touching right edge (local X = 24)
      final double offsetRight = RackPieceComponent.horizontalCenterOffset(
        localTouchX: 24.0,
        pieceWidth: pieceWidth,
      );
      expect(offsetRight, 12.0);
      const double touchWorldRight = initialPosX + 24.0; // 124.0
      final double newPosRight = initialPosX + offsetRight; // 112.0
      expect(touchWorldRight - newPosRight, expectedCenter);
    });

    test('horizontalCenterOffset centers touch point horizontally for 3-cell piece', () {
      const double pieceWidth = 72.0; // 3 cells * 24px
      const double expectedCenter = 36.0;

      // Touching at local X = 10
      final double offset1 = RackPieceComponent.horizontalCenterOffset(
        localTouchX: 10.0,
        pieceWidth: pieceWidth,
      );
      expect(offset1, 10.0 - expectedCenter); // -26.0

      const double initialPosX = 200.0;
      const double touchWorld1 = initialPosX + 10.0; // 210.0
      final double newPos1 = initialPosX + offset1; // 174.0
      expect(touchWorld1 - newPos1, expectedCenter);

      // Touching at local X = 60
      final double offset2 = RackPieceComponent.horizontalCenterOffset(
        localTouchX: 60.0,
        pieceWidth: pieceWidth,
      );
      expect(offset2, 60.0 - expectedCenter); // 24.0

      const double touchWorld2 = initialPosX + 60.0; // 260.0
      final double newPos2 = initialPosX + offset2; // 224.0
      expect(touchWorld2 - newPos2, expectedCenter);
    });

    test('touchDragLiftPixels constant is preserved at 50.0 pixels per DEC-0024 point 5', () {
      // DEC-0024 point 5 explicitly requires _touchDragLiftPixels = 50 to remain untouched
      // because horizontal centering is what aligns the grip, while the vertical lift
      // keeps the piece visible above the thumb.
      expect(BlockPuzzleGame.touchDragLiftPixels, 50.0);
    });
  });
}
