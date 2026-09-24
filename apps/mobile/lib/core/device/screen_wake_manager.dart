import 'package:flutter/services.dart';

/// Manages keeping the device screen on during active gameplay per DEC-0028.
class ScreenWakeManager {
  static const MethodChannel _channel = MethodChannel('ru.luminablocks.game/device');

  /// Toggles whether the screen should remain awake (FLAG_KEEP_SCREEN_ON).
  static Future<void> setKeepScreenOn(bool enabled) async {
    try {
      await _channel.invokeMethod('setKeepScreenOn', <String, dynamic>{'enabled': enabled});
    } catch (_) {
      // Safe fallback when channel is not mocked or not supported in test environment.
    }
  }
}
