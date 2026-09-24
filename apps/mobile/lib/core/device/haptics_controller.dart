import 'package:flutter/services.dart';

class HapticsController {
  bool isEnabled = true;

  Future<void> vibrate() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  Future<void> lightImpact() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> mediumImpact() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> heavyImpact() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<void> doubleHeavyImpact({
    Duration gap = const Duration(milliseconds: 80),
  }) async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(gap);
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<void> selectionClick() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
