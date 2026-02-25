import '../../domain/progression/player_progress_repository.dart';
import '../../domain/progression/player_progress_state.dart';

class InMemoryPlayerProgressRepository implements PlayerProgressRepository {
  PlayerProgressState? _state;

  @override
  Future<PlayerProgressState?> load() async {
    return _state;
  }

  @override
  Future<void> save(PlayerProgressState state) async {
    _state = state;
  }
}
