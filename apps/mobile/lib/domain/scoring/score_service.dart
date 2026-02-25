import 'score_state.dart';

class ScoreInput {
  const ScoreInput({
    required this.clearedLines,
  });

  final int clearedLines;
}

abstract interface class ScoreService {
  ScoreState apply({
    required ScoreState previous,
    required ScoreInput input,
  });
}
