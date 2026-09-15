import 'package:flutter/material.dart';

import '../../core/di/di_container.dart';
import '../../ui/theme/app_theme.dart';
import 'game_mode_availability.dart';

/// Refuses to show a game screen whose mode is switched off.
///
/// Hiding the menu button is not enough on its own: anything that pushes the
/// route directly - a deep link, a restored navigation stack, another screen -
/// would walk straight past it. DEC-0002 asks for a switch that closes the mode,
/// not one that hides a button, so the screen itself checks.
///
/// The check runs once at build time from the bootstrap config. A mode is not
/// yanked out from under a player mid-round: a round already in progress
/// finishes, and the switch takes effect the next time the screen is opened.
class ModeGate extends StatelessWidget {
  const ModeGate({
    required this.mode,
    required this.child,
    super.key,
  });

  final GameMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (sl<GameModeAvailability>().isEnabled(mode)) {
      return child;
    }
    return _ModeUnavailable(mode: mode);
  }
}

class _ModeUnavailable extends StatelessWidget {
  const _ModeUnavailable({required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unavailable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.pause_circle_outline_rounded,
                size: 56,
                color: LuminaPalette.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'This mode is temporarily unavailable.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'It has been switched off remotely while an issue is looked '
                'into. Your progress is safe.',
                textAlign: TextAlign.center,
                style: TextStyle(color: LuminaPalette.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
