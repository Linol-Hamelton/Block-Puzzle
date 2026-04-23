import 'package:hive_flutter/hive_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/session/game_session_repository.dart';
import '../../domain/session/game_snapshot.dart';

class HiveGameSessionRepository implements GameSessionRepository {
  HiveGameSessionRepository({
    required AppLogger logger,
  }) : _logger = logger;

  static const String _boxName = 'game_session_box';
  static const String _snapshotKey = 'active_game_snapshot';

  final AppLogger _logger;
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    final Box<String>? cached = _box;
    if (cached != null && cached.isOpen) {
      return cached;
    }
    final Box<String> opened = await Hive.openBox<String>(_boxName);
    _box = opened;
    return opened;
  }

  @override
  Future<GameSnapshot?> loadSnapshot() async {
    final Box<String> box = await _getBox();
    final String? rawJson = box.get(_snapshotKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }

    try {
      return GameSnapshot.fromJsonString(rawJson);
    } catch (error) {
      _logger.warn('Game snapshot decode failed, clearing: $error');
      await box.delete(_snapshotKey);
      return null;
    }
  }

  @override
  Future<void> saveSnapshot(GameSnapshot snapshot) async {
    final Box<String> box = await _getBox();
    await box.put(_snapshotKey, snapshot.toJsonString());
  }

  @override
  Future<void> clearSnapshot() async {
    final Box<String> box = await _getBox();
    await box.delete(_snapshotKey);
  }
}
