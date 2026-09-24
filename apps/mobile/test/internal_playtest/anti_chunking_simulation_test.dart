import 'dart:math';

import 'package:block_puzzle_mobile/domain/gameplay/basic_move_validator.dart';
import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/domain/gameplay/move.dart';
import 'package:block_puzzle_mobile/domain/gameplay/piece.dart';
import 'package:block_puzzle_mobile/domain/generator/basic_piece_generation_service.dart';
import 'package:block_puzzle_mobile/domain/generator/difficulty_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Anti-chunking simulation (5,000 deals)', () {
    bool canPlaceAnyPiece(BoardState board, List<Piece> pieces) {
      const BasicMoveValidator validator = BasicMoveValidator();
      for (final Piece piece in pieces) {
        for (int y = 0; y < board.size; y++) {
          for (int x = 0; x < board.size; x++) {
            if (validator
                .validate(
                  boardState: board,
                  move: Move(piece: piece, anchorX: x, anchorY: y),
                )
                .isValid) {
              return true;
            }
          }
        }
      }
      return false;
    }

    bool isHeavyPiece(Piece p) {
      return p.id.startsWith('square3_') ||
          p.id.startsWith('line5_') ||
          p.id.startsWith('vline5_');
    }

    test('5,000 deals with board fill > 50%: max 1 heavy piece and 0 instant deadlocks', () {
      final Random rng = Random(12345);
      final BasicPieceGenerationService service = BasicPieceGenerationService(
        random: rng,
      );

      const DifficultyProfile profile = DifficultyProfile(
        hardPieceWeight: 0.8,
        maxHardPiecesPerTriplet: 3,
      );

      int instantDeadlocks = 0;
      int dealsAbove50Count = 0;
      int dealsWithMoreThan1Heavy = 0;

      const int totalDeals = 5000;

      for (int i = 0; i < totalDeals; i++) {
        // Generate random board fill between 51% and 78% (above 50%)
        final int targetOccupied = 33 + rng.nextInt(17); // 33 to 49 out of 64 cells (51% - 76%)
        final Set<BoardCell> cells = <BoardCell>{};

        // Guarantee at least a 2x2 or 3x1 empty pocket so the board is not pre-deadlocked
        final Set<int> protectedIndices = <int>{0, 1, 8, 9}; // top-left 2x2 kept empty

        while (cells.length < targetOccupied) {
          final int idx = rng.nextInt(64);
          if (!protectedIndices.contains(idx)) {
            cells.add(BoardCell(x: idx % 8, y: idx ~/ 8));
          }
        }

        final BoardState board = BoardState(size: 8, occupiedCells: cells);
        final double fillRatio = board.occupiedCells.length / 64.0;
        expect(fillRatio, greaterThan(0.50));
        dealsAbove50Count++;

        final triplet = service.nextTriplet(
          boardState: board,
          profile: profile,
        );

        final int heavyCount = triplet.pieces.where(isHeavyPiece).length;
        if (heavyCount > 1) {
          dealsWithMoreThan1Heavy++;
        }

        final bool hasMove = canPlaceAnyPiece(board, triplet.pieces);
        if (!hasMove) {
          instantDeadlocks++;
        }
      }

      expect(dealsAbove50Count, totalDeals);
      expect(dealsWithMoreThan1Heavy, 0,
          reason: 'Anti-chunking must guarantee max 1 heavy piece at fill > 50%');
      expect(instantDeadlocks, 0,
          reason: 'Fair Bag guarantee must prevent instant deadlocks on deal');
    });
  });
}
