import 'dart:math';

import 'package:block_puzzle_mobile/domain/gameplay/basic_move_validator.dart';
import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/domain/gameplay/move.dart';
import 'package:block_puzzle_mobile/domain/generator/basic_piece_generation_service.dart';
import 'package:block_puzzle_mobile/domain/generator/difficulty_profile.dart';
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
    test('always returns exactly 3 pieces', () {
      final service = BasicPieceGenerationService(random: Random(42));
      final BoardState board = BoardState.empty();

      final triplet = service.nextTriplet(
        boardState: board,
        profile: DifficultyProfile.initial,
      );

      expect(triplet.pieces.length, 3);
    });

    test('each piece has a unique id', () {
      final service = BasicPieceGenerationService(random: Random(42));
      final BoardState board = BoardState.empty();

      final triplet = service.nextTriplet(
        boardState: board,
        profile: DifficultyProfile.initial,
      );

      final ids = triplet.pieces.map((p) => p.id).toSet();
      expect(ids.length, 3, reason: 'All 3 piece IDs should be unique');
    });

    test('each piece has at least 1 cell', () {
      final service = BasicPieceGenerationService(random: Random(42));
      final BoardState board = BoardState.empty();

      for (int i = 0; i < 20; i++) {
        final triplet = service.nextTriplet(
          boardState: board,
          profile: DifficultyProfile.initial,
        );
        for (final piece in triplet.pieces) {
          expect(piece.cells, isNotEmpty,
              reason: 'Piece ${piece.id} should have at least 1 cell');
        }
      }
    });

    test('generates unique IDs across multiple calls', () {
      final service = BasicPieceGenerationService(random: Random(7));
      final BoardState board = BoardState.empty();
      final Set<String> allIds = <String>{};

      for (int i = 0; i < 10; i++) {
        final triplet = service.nextTriplet(
          boardState: board,
          profile: DifficultyProfile.initial,
        );
        for (final piece in triplet.pieces) {
          expect(allIds.contains(piece.id), isFalse,
              reason: 'Duplicate ID found: ${piece.id}');
          allIds.add(piece.id);
        }
      }
      expect(allIds.length, 30);
    });

    test('deterministic with same Random seed', () {
      final service1 = BasicPieceGenerationService(random: Random(123));
      final service2 = BasicPieceGenerationService(random: Random(123));
      final BoardState board = BoardState.empty();

      final triplet1 = service1.nextTriplet(
        boardState: board,
        profile: DifficultyProfile.initial,
      );
      final triplet2 = service2.nextTriplet(
        boardState: board,
        profile: DifficultyProfile.initial,
      );

      for (int i = 0; i < 3; i++) {
        expect(
            triplet1.pieces[i].cells.length, triplet2.pieces[i].cells.length,
            reason: 'Piece $i cell count should match with same seed');
      }
    });

    test('Fair Bag: first piece is always placeable on crowded board across 50 seeds', () {
      // Board with 63 out of 64 cells occupied; only (3, 3) is free.
      final BoardState crowdedBoard = BoardState(
        size: 8,
        occupiedCells: <BoardCell>{
          for (int y = 0; y < 8; y++)
            for (int x = 0; x < 8; x++)
              if (!(x == 3 && y == 3)) BoardCell(x: x, y: y),
        },
      );

      const BasicMoveValidator validator = BasicMoveValidator();

      for (int seed = 1; seed <= 50; seed++) {
        final BasicPieceGenerationService service = BasicPieceGenerationService(
          random: Random(seed),
          moveValidator: validator,
        );

        final triplet = service.nextTriplet(
          boardState: crowdedBoard,
          profile: DifficultyProfile.initial,
        );

        final firstPiece = triplet.pieces.first;
        // Verify first piece is mathematically placeable on crowdedBoard
        bool placeable = false;
        for (int y = 0; y < 8; y++) {
          for (int x = 0; x < 8; x++) {
            if (validator
                .validate(
                  boardState: crowdedBoard,
                  move: Move(piece: firstPiece, anchorX: x, anchorY: y),
                )
                .isValid) {
              placeable = true;
              break;
            }
          }
          if (placeable) break;
        }

        expect(placeable, isTrue,
            reason: 'Seed $seed must guarantee first piece (${firstPiece.id}) is placeable on crowded board');
      }
    });

    test('Fair Bag: empty board piece generation behavior unchanged', () {
      final serviceWithValidator = BasicPieceGenerationService(
        random: Random(42),
        moveValidator: const BasicMoveValidator(),
      );
      final serviceBaseline = BasicPieceGenerationService(
        random: Random(42),
      );

      final BoardState emptyBoard = BoardState.empty();
      final triplet1 = serviceWithValidator.nextTriplet(
        boardState: emptyBoard,
        profile: DifficultyProfile.initial,
      );
      final triplet2 = serviceBaseline.nextTriplet(
        boardState: emptyBoard,
        profile: DifficultyProfile.initial,
      );

      for (int i = 0; i < 3; i++) {
        expect(triplet1.pieces[i].cells.length, triplet2.pieces[i].cells.length);
        expect(triplet1.pieces[i].id.split('_').first,
            triplet2.pieces[i].id.split('_').first);
      }
    });

    test('Fair Bag: 100% full board triggers fallback safely and terminates', () {
      final BoardState completelyFullBoard = BoardState(
        size: 8,
        occupiedCells: <BoardCell>{
          for (int y = 0; y < 8; y++)
            for (int x = 0; x < 8; x++) BoardCell(x: x, y: y),
        },
      );

      final BasicPieceGenerationService service = BasicPieceGenerationService(
        random: Random(99),
        moveValidator: const BasicMoveValidator(),
      );

      // Must not hang, loop infinitely, or throw
      final triplet = service.nextTriplet(
        boardState: completelyFullBoard,
        profile: DifficultyProfile.initial,
      );

      expect(triplet.pieces.length, 3);
      expect(triplet.pieces.first.id, startsWith('dot_'));
    });

    test('Fair Bag: setSeed preserves exact sequence determinism', () {
      final BasicPieceGenerationService service = BasicPieceGenerationService(
        moveValidator: const BasicMoveValidator(),
      );
      final BoardState board = BoardState.empty();

      service.setSeed(2026);
      final tripletA = service.nextTriplet(boardState: board, profile: DifficultyProfile.initial);

      service.setSeed(2026);
      final tripletB = service.nextTriplet(boardState: board, profile: DifficultyProfile.initial);

      for (int i = 0; i < 3; i++) {
        expect(tripletA.pieces[i].id, tripletB.pieces[i].id);
        expect(tripletA.pieces[i].cells.length, tripletB.pieces[i].cells.length);
      }
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
