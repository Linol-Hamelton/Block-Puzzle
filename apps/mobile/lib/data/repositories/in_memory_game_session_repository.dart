import '../../domain/session/game_session_repository.dart';
import '../../domain/session/game_snapshot.dart';

class InMemoryGameSessionRepository implements GameSessionRepository {
  GameSnapshot? _snapshot;

  @override
  Future<GameSnapshot?> loadSnapshot() async {
    return _snapshot;
  }

  @override
  Future<void> saveSnapshot(GameSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<void> clearSnapshot() async {
    _snapshot = null;
  }
}
