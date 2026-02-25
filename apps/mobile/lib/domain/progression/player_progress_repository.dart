import 'player_progress_state.dart';

abstract interface class PlayerProgressRepository {
  Future<PlayerProgressState?> load();

  Future<void> save(PlayerProgressState state);
}
