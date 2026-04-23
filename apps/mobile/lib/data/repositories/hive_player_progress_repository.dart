import 'package:hive_flutter/hive_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/progression/player_progress_repository.dart';
import '../../domain/progression/player_progress_state.dart';

class HivePlayerProgressRepository implements PlayerProgressRepository {
  HivePlayerProgressRepository({
    required AppLogger logger,
  }) : _logger = logger;

  static const String _boxName = 'player_progress_box';
  static const String _storageKey = 'player_progress_state_v2';

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
  Future<PlayerProgressState?> load() async {
    final Box<String> box = await _getBox();
    final String? rawJson = box.get(_storageKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }

    try {
      return PlayerProgressState.fromJsonString(rawJson);
    } catch (error) {
      _logger.warn('Player progress decode failed, clearing cache: $error');
      await box.delete(_storageKey);
      return null;
    }
  }

  @override
  Future<void> save(PlayerProgressState state) async {
    final Box<String> box = await _getBox();
    await box.put(_storageKey, state.toJsonString());
  }
}
