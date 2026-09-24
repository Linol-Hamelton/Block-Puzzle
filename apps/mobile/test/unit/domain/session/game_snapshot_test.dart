import 'package:block_puzzle_mobile/domain/gameplay/board_state.dart';
import 'package:block_puzzle_mobile/domain/gameplay/piece.dart';
import 'package:block_puzzle_mobile/domain/scoring/score_state.dart';
import 'package:block_puzzle_mobile/domain/session/game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameSnapshot', () {
    test('serializes and deserializes hasUsedFreeUndo correctly', () {
      final GameSnapshot snapshot = GameSnapshot(
        boardState: BoardState.empty(size: 8),
        scoreState: const ScoreState(totalScore: 120, comboStreak: 2),
        rackPieces: const <Piece>[],
        level: 2,
        movesPlayed: 5,
        gamesPlayed: 1,
        hasUsedFreeUndo: true,
      );

      final Map<String, Object?> json = snapshot.toJson();
      expect(json['has_used_free_undo'], isTrue);

      final GameSnapshot restored = GameSnapshot.fromJson(json);
      expect(restored.hasUsedFreeUndo, isTrue);
      expect(restored.scoreState.totalScore, 120);
      expect(restored.scoreState.comboStreak, 2);
    });

    test('backward compatibility: missing has_used_free_undo defaults to false', () {
      final Map<String, Object?> legacyJson = <String, Object?>{
        'board_state': BoardState.empty(size: 8).toJson(),
        'score_state': const ScoreState(totalScore: 50, comboStreak: 0).toJson(),
        'rack_pieces': <Object?>[],
        'level': 1,
        'moves_played': 2,
        'games_played': 0,
      };

      final GameSnapshot snapshot = GameSnapshot.fromJson(legacyJson);
      expect(snapshot.hasUsedFreeUndo, isFalse);
    });
  });
}
