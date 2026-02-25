import '../session/session_state.dart';
import 'difficulty_profile.dart';

abstract interface class DifficultyTuner {
  DifficultyProfile resolve({
    required SessionState sessionState,
    required Map<String, Object?> remoteConfig,
  });
}
