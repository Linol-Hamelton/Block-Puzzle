import 'package:flutter/material.dart';

import '../../../core/di/di_container.dart';
import '../../../ui/theme/app_theme.dart';
import '../application/store_availability.dart';

/// Refuses to show the store when monetization is disabled.
///
/// Under DEC-0026 and DEC-0028 item 7, all monetization surfaces and paid
/// SKUs are hidden before Stage C. Hiding the entry button on the home screen
/// is necessary but not sufficient: any direct navigation, deep link, or
/// restored route must also be stopped from exposing store products or prices.
class StoreGate extends StatelessWidget {
  const StoreGate({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = sl.isRegistered<StoreAvailability>()
        ? sl<StoreAvailability>().isEnabled
        : false;
    if (isEnabled) {
      return child;
    }
    return const StoreUnavailableScreen();
  }
}

/// Fallback screen rendered whenever an unavailable store route is reached.
class StoreUnavailableScreen extends StatelessWidget {
  const StoreUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.storefront_outlined,
                size: 64,
                color: LuminaPalette.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Store is unavailable',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: LuminaPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Monetization is deferred until Stage C per DEC-0026 / DEC-0028. All game modes and themes in version 1.0 are 100% free.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LuminaPalette.textSecondary,
                  height: 1.4,
                ),
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
