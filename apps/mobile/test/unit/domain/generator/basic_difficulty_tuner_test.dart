import 'package:flutter_test/flutter_test.dart';

import 'package:block_puzzle_mobile/domain/generator/basic_difficulty_tuner.dart';
import 'package:block_puzzle_mobile/domain/generator/difficulty_profile.dart';
import 'package:block_puzzle_mobile/domain/session/session_state.dart';

void main() {
  late BasicDifficultyTuner tuner;

  setUp(() {
    tuner = const BasicDifficultyTuner();
  });

  group('BasicDifficultyTuner', () {
    test('returns initial profile with empty config and fresh session', () {
      final DifficultyProfile profile = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{},
      );

      expect(profile.hardPieceWeight,
          closeTo(DifficultyProfile.initial.hardPieceWeight, 0.01));
      expect(profile.maxHardPiecesPerTriplet,
          DifficultyProfile.initial.maxHardPiecesPerTriplet);
    });

    test('uses config overrides for base values', () {
      final DifficultyProfile profile = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{
          'difficulty.hard_piece_weight': 0.5,
          'difficulty.max_hard_pieces_per_triplet': 2,
        },
      );

      expect(profile.hardPieceWeight, closeTo(0.5, 0.01));
      expect(profile.maxHardPiecesPerTriplet, 2);
    });

    test('high score adds difficulty pressure', () {
      final DifficultyProfile lowScore = tuner.resolve(
        sessionState: const SessionState(
          roundsPlayed: 1,
          currentScore: 50,
          movesPlayed: 5,
        ),
        remoteConfig: <String, Object?>{},
      );

      final DifficultyProfile highScore = tuner.resolve(
        sessionState: const SessionState(
          roundsPlayed: 1,
          currentScore: 300,
          movesPlayed: 5,
        ),
        remoteConfig: <String, Object?>{},
      );

      expect(highScore.hardPieceWeight,
          greaterThan(lowScore.hardPieceWeight));
    });

    test('high early game-over rate reduces difficulty', () {
      final DifficultyProfile normal = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{
          'balance.observed_early_gameover_rate': 0.1,
        },
      );

      final DifficultyProfile highGameOver = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{
          'balance.observed_early_gameover_rate': 0.5,
        },
      );

      expect(highGameOver.hardPieceWeight,
          lessThan(normal.hardPieceWeight));
    });

    test('fairness_bias_v1 variant makes the game easier', () {
      final DifficultyProfile balanced = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{
          'ab.difficulty_variant': 'balanced_v1',
        },
      );

      final DifficultyProfile fairness = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{
          'ab.difficulty_variant': 'fairness_bias_v1',
        },
      );

      expect(fairness.hardPieceWeight,
          lessThan(balanced.hardPieceWeight));
    });

    test('challenge_bias_v1 variant makes the game harder', () {
      final DifficultyProfile balanced = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{
          'ab.difficulty_variant': 'balanced_v1',
        },
      );

      final DifficultyProfile challenge = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{
          'ab.difficulty_variant': 'challenge_bias_v1',
        },
      );

      expect(challenge.hardPieceWeight,
          greaterThan(balanced.hardPieceWeight));
    });

    test('hardPieceWeight is clamped to valid range', () {
      final DifficultyProfile veryEasy = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{
          'difficulty.hard_piece_weight': -1.0,
          'balance.observed_early_gameover_rate': 0.9,
          'ab.difficulty_variant': 'fairness_bias_v1',
        },
      );
      expect(veryEasy.hardPieceWeight, greaterThanOrEqualTo(0.05));

      final DifficultyProfile veryHard = tuner.resolve(
        sessionState: const SessionState(
          roundsPlayed: 1,
          currentScore: 1000,
          movesPlayed: 50,
        ),
        remoteConfig: <String, Object?>{
          'difficulty.hard_piece_weight': 2.0,
          'ab.difficulty_variant': 'challenge_bias_v1',
        },
      );
      expect(veryHard.hardPieceWeight, lessThanOrEqualTo(0.85));
    });

    test('maxHardPiecesPerTriplet is clamped to [0, 3]', () {
      final DifficultyProfile veryEasy = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{
          'difficulty.max_hard_pieces_per_triplet': 0,
          'balance.observed_early_gameover_rate': 0.9,
          'ab.difficulty_variant': 'fairness_bias_v1',
        },
      );
      expect(veryEasy.maxHardPiecesPerTriplet, greaterThanOrEqualTo(0));

      final DifficultyProfile veryHard = tuner.resolve(
        sessionState: SessionState.initial,
        remoteConfig: <String, Object?>{
          'difficulty.max_hard_pieces_per_triplet': 10,
          'ab.difficulty_variant': 'challenge_bias_v1',
        },
      );
      expect(veryHard.maxHardPiecesPerTriplet, lessThanOrEqualTo(3));
    });

    test('many moves in a session adds slight difficulty increase', () {
      final DifficultyProfile fewMoves = tuner.resolve(
        sessionState: const SessionState(
          roundsPlayed: 1,
          currentScore: 100,
          movesPlayed: 5,
        ),
        remoteConfig: <String, Object?>{},
      );

      final DifficultyProfile manyMoves = tuner.resolve(
        sessionState: const SessionState(
          roundsPlayed: 1,
          currentScore: 100,
          movesPlayed: 20,
        ),
        remoteConfig: <String, Object?>{},
      );

      expect(manyMoves.hardPieceWeight,
          greaterThan(fewMoves.hardPieceWeight));
    });
  });
}
