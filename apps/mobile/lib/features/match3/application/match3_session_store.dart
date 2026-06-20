import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';

/// Match-3-only persistence (SharedPreferences): the best score and a resume
/// snapshot. Kept separate from Classic's `GameSessionRepository` and from
/// `TetrisSessionStore` so the three modes don't perturb each other; folds into
/// the multi-game snapshot envelope when the shared engine seam lands
/// (see docs/architecture/04_MULTI_GAME_ENGINE_PLAN.md).
class Match3SessionStore {
  Match3SessionStore({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;
  static const String _bestScoreKey = 'match3_best_score';
  static const String _snapshotKey = 'match3_active_snapshot';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _prefsInstance() async {
    final SharedPreferences? cached = _prefs;
    if (cached != null) {
      return cached;
    }
    final SharedPreferences created = await SharedPreferences.getInstance();
    _prefs = created;
    return created;
  }

  Future<int> loadBestScore() async {
    try {
      final SharedPreferences prefs = await _prefsInstance();
      return prefs.getInt(_bestScoreKey) ?? 0;
    } catch (error) {
      _logger.warn('Match3 loadBestScore failed: $error');
      return 0;
    }
  }

  Future<void> saveBestScore(int score) async {
    try {
      final SharedPreferences prefs = await _prefsInstance();
      final int current = prefs.getInt(_bestScoreKey) ?? 0;
      if (score > current) {
        await prefs.setInt(_bestScoreKey, score);
      }
    } catch (error) {
      _logger.warn('Match3 saveBestScore failed: $error');
    }
  }

  Future<Map<String, Object?>?> loadSnapshot() async {
    try {
      final SharedPreferences prefs = await _prefsInstance();
      final String? raw = prefs.getString(_snapshotKey);
      if (raw == null) {
        return null;
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return decoded.cast<String, Object?>();
    } catch (error) {
      _logger.warn('Match3 loadSnapshot failed: $error');
      return null;
    }
  }

  Future<void> saveSnapshot(Map<String, Object?> snapshot) async {
    try {
      final SharedPreferences prefs = await _prefsInstance();
      await prefs.setString(_snapshotKey, jsonEncode(snapshot));
    } catch (error) {
      _logger.warn('Match3 saveSnapshot failed: $error');
    }
  }

  Future<void> clearSnapshot() async {
    try {
      final SharedPreferences prefs = await _prefsInstance();
      await prefs.remove(_snapshotKey);
    } catch (error) {
      _logger.warn('Match3 clearSnapshot failed: $error');
    }
  }
}
