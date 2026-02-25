import '../gameplay/board_state.dart';
import 'difficulty_profile.dart';
import 'piece_triplet.dart';

abstract interface class PieceGenerationService {
  PieceTriplet nextTriplet({
    required BoardState boardState,
    required DifficultyProfile profile,
  });
}
