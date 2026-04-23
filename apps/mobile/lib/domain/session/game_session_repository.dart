import 'game_snapshot.dart';

abstract class GameSessionRepository {
  Future<GameSnapshot?> loadSnapshot();
  Future<void> saveSnapshot(GameSnapshot snapshot);
  Future<void> clearSnapshot();
}
