import 'package:block_puzzle_mobile/domain/generator/basic_difficulty_tuner.dart';
import 'package:block_puzzle_mobile/domain/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BasicDifficultyTuner', () {
    const BasicDifficultyTuner tuner = BasicDifficultyTuner();

    test('reduces difficulty when early game over rate is high', () {
      final profile = tuner.resolve(
        sessionState: const SessionState(
          roundsPlayed: 10,
          currentScore: 120,
          movesPlayed: 6,
        ),
        remoteConfig: <String, Object?>{
          'difficulty.hard_piece_weight': 0.30,
          'difficulty.max_hard_pieces_per_triplet': 2,
          'balance.target_moves_per_run': 14,
          'balance.observed_avg_moves_per_run': 8.5,
          'balance.observed_early_gameover_rate': 0.46,
        },
      );

      expect(profile.hardPieceWeight, lessThan(0.30));
      expect(profile.maxHardPiecesPerTriplet, lessThan(2));
    });

    test('increases difficulty slightly for long and successful sessions', () {
      final profile = tuner.resolve(
        sessionState: const SessionState(
          roundsPlayed: 22,
          currentScore: 410,
          movesPlayed: 19,
        ),
        remoteConfig: <String, Object?>{
          'difficulty.hard_piece_weight': 0.22,
          'difficulty.max_hard_pieces_per_triplet': 1,
          'balance.target_moves_per_run': 14,
          'balance.observed_avg_moves_per_run': 20.0,
          'balance.observed_early_gameover_rate': 0.12,
        },
      );

      expect(profile.hardPieceWeight, greaterThan(0.22));
      expect(profile.maxHardPiecesPerTriplet, equals(1));
    });
  });
}
