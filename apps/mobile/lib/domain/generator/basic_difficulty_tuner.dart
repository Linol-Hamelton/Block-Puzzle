import '../session/session_state.dart';
import 'difficulty_profile.dart';
import 'difficulty_tuner.dart';

class BasicDifficultyTuner implements DifficultyTuner {
  const BasicDifficultyTuner();

  static const String _variantBalanced = 'balanced_v1';
  static const String _variantFairnessBias = 'fairness_bias_v1';
  static const String _variantChallengeBias = 'challenge_bias_v1';

  @override
  DifficultyProfile resolve({
    required SessionState sessionState,
    required Map<String, Object?> remoteConfig,
  }) {
    final double baseHardWeight = _readDouble(
      remoteConfig['difficulty.hard_piece_weight'],
      fallback: DifficultyProfile.initial.hardPieceWeight,
    );
    final int baseMaxHard = _readInt(
      remoteConfig['difficulty.max_hard_pieces_per_triplet'],
      fallback: DifficultyProfile.initial.maxHardPiecesPerTriplet,
    );

    final double observedEarlyGameOverRate = _readDouble(
      remoteConfig['balance.observed_early_gameover_rate'],
      fallback: 0.0,
    );
    final int targetMovesPerRun = _readInt(
      remoteConfig['balance.target_moves_per_run'],
      fallback: 14,
    );
    final double observedAverageMoves = _readDouble(
      remoteConfig['balance.observed_avg_moves_per_run'],
      fallback: targetMovesPerRun.toDouble(),
    );
    final String difficultyVariant = _readString(
      remoteConfig['ab.difficulty_variant'],
      fallback: _variantBalanced,
    );

    double adjustedHardWeight = baseHardWeight;
    int adjustedMaxHard = baseMaxHard;

    final double scoreFactor = sessionState.currentScore >= 250 ? 0.05 : 0.0;
    adjustedHardWeight += scoreFactor;

    if (observedEarlyGameOverRate > 0.35) {
      adjustedHardWeight -= 0.08;
      adjustedMaxHard -= 1;
    }

    if (observedAverageMoves < (targetMovesPerRun - 2)) {
      adjustedHardWeight -= 0.05;
      adjustedMaxHard -= 1;
    } else if (observedAverageMoves > (targetMovesPerRun + 4)) {
      adjustedHardWeight += 0.05;
    }

    if (sessionState.movesPlayed >= 16) {
      adjustedHardWeight += 0.03;
    }

    if (difficultyVariant == _variantFairnessBias) {
      adjustedHardWeight -= 0.04;
      if (sessionState.movesPlayed <= 10) {
        adjustedHardWeight -= 0.02;
      }
      adjustedMaxHard -= 1;
    } else if (difficultyVariant == _variantChallengeBias) {
      adjustedHardWeight += 0.04;
      if (sessionState.currentScore >= 250 || sessionState.movesPlayed >= 12) {
        adjustedHardWeight += 0.02;
      }
      adjustedMaxHard += 1;
    }

    adjustedHardWeight = adjustedHardWeight.clamp(0.05, 0.85);
    adjustedMaxHard = adjustedMaxHard.clamp(0, 3);

    return DifficultyProfile(
      hardPieceWeight: adjustedHardWeight,
      maxHardPiecesPerTriplet: adjustedMaxHard,
    );
  }

  double _readDouble(
    Object? value, {
    required double fallback,
  }) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  int _readInt(
    Object? value, {
    required int fallback,
  }) {
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  String _readString(
    Object? value, {
    required String fallback,
  }) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }
}
