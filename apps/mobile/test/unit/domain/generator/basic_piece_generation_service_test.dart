import 'dart:math';

import 'package:block_puzzle_mobile/domain/generator/basic_piece_generation_service.dart';
import 'package:block_puzzle_mobile/domain/generator/difficulty_profile.dart';
import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BasicPieceGenerationService', () {
    test('limits hard pieces on high board fill', () {
      final BasicPieceGenerationService service = BasicPieceGenerationService(
        random: _DeterministicRandom(),
      );
      final BoardState highFillBoard = BoardState(
        size: 8,
        occupiedCells: <BoardCell>{
          for (int y = 0; y < 8; y++)
            for (int x = 0; x < 6; x++) BoardCell(x: x, y: y),
        },
      );

      final triplet = service.nextTriplet(
        boardState: highFillBoard,
        profile: const DifficultyProfile(
          hardPieceWeight: 0.8,
          maxHardPiecesPerTriplet: 3,
        ),
      );

      final int hardCount = triplet.pieces
          .where((piece) =>
              piece.id.startsWith('line4_') || piece.id.startsWith('line5_'))
          .length;

      expect(hardCount, lessThanOrEqualTo(1));
    });

    test('keeps hard pieces available on low board fill', () {
      final BasicPieceGenerationService service = BasicPieceGenerationService(
        random: _DeterministicRandom(),
      );
      final BoardState lowFillBoard = BoardState.empty(size: 8);

      final triplet = service.nextTriplet(
        boardState: lowFillBoard,
        profile: const DifficultyProfile(
          hardPieceWeight: 0.8,
          maxHardPiecesPerTriplet: 3,
        ),
      );

      final int hardCount = triplet.pieces
          .where((piece) =>
              piece.id.startsWith('line4_') || piece.id.startsWith('line5_'))
          .length;

      expect(hardCount, greaterThanOrEqualTo(2));
    });
  });
}

class _DeterministicRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0.0;

  @override
  int nextInt(int max) => 0;
}
