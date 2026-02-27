import 'package:flutter/foundation.dart';

class AppLogger {
  void info(String message) {
    if (kDebugMode || kProfileMode) {
      debugPrint('[INFO] $message');
    }
  }

  void warn(String message) {
    if (!kReleaseMode) {
      debugPrint('[WARN] $message');
    }
  }

  void error(String message) {
    debugPrint('[ERROR] $message');
  }
}
