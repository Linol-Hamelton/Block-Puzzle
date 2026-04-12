import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/progression/player_progress_repository.dart';
import '../../domain/progression/player_progress_state.dart';

class SharedPreferencesPlayerProgressRepository
    implements PlayerProgressRepository {
  SharedPreferencesPlayerProgressRepository({
    required AppLogger logger,
  }) : _logger = logger;

  static const String _storageKey = 'player_progress_state_v2';

  final AppLogger _logger;

  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    final SharedPreferences? cached = _preferences;
    if (cached != null) {
      return cached;
    }
    final SharedPreferences created = await SharedPreferences.getInstance();
    _preferences = created;
    return created;
  }

  @override
  Future<PlayerProgressState?> load() async {
    final SharedPreferences preferences = await _prefs();
    final String? rawJson = preferences.getString(_storageKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }

    try {
      return PlayerProgressState.fromJsonString(rawJson);
    } catch (error) {
      _logger.warn('Player progress decode failed, clearing cache: $error');
      await preferences.remove(_storageKey);
      return null;
    }
  }

  @override
  Future<void> save(PlayerProgressState state) async {
    final SharedPreferences preferences = await _prefs();
    await preferences.setString(_storageKey, state.toJsonString());
  }
}
