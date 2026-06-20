import 'score_state.dart';

class ScoreInput {
  const ScoreInput({
    required this.clearedLines,
    this.allClear = false,
  });

  final int clearedLines;

  /// True when this clear emptied the board (Perfect Clear / All-Clear bonus).
  final bool allClear;
}

abstract interface class ScoreService {
  ScoreState apply({
    required ScoreState previous,
    required ScoreInput input,
  });
}
