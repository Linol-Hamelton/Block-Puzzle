import '../session/session_state.dart';
import 'difficulty_profile.dart';
import 'difficulty_tuner.dart';

class BasicDifficultyTuner implements DifficultyTuner {
  const BasicDifficultyTuner();

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
}
