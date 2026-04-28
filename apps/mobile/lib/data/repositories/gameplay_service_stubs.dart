import '../../domain/generator/difficulty_profile.dart';
import '../../domain/generator/difficulty_tuner.dart';
import '../../domain/generator/piece_generation_service.dart';
import '../../domain/generator/piece_triplet.dart';
import '../../domain/gameplay/board_state.dart';
import '../../domain/gameplay/piece.dart';
import '../../domain/session/session_state.dart';

class StubPieceGenerationService implements PieceGenerationService {
  @override
  void setSeed(int? seed) {}

  @override
  PieceTriplet nextTriplet({
    required BoardState boardState,
    required DifficultyProfile profile,
  }) {
    return PieceTriplet(
      pieces: <Piece>[
        const Piece(
            id: 'stub_1',
            cells: <PieceCellOffset>[PieceCellOffset(dx: 0, dy: 0)]),
        const Piece(
            id: 'stub_2',
            cells: <PieceCellOffset>[PieceCellOffset(dx: 0, dy: 0)]),
        const Piece(
            id: 'stub_3',
            cells: <PieceCellOffset>[PieceCellOffset(dx: 0, dy: 0)]),
      ],
    );
  }
}

class StubDifficultyTuner implements DifficultyTuner {
  @override
  DifficultyProfile resolve({
    required SessionState sessionState,
    required Map<String, Object?> remoteConfig,
  }) {
    return DifficultyProfile.initial;
  }
}
