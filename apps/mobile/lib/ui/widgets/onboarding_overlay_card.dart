import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Onboarding tutorial tooltip card.
///
/// Displayed over the game board during the FTUE flow to guide
/// the player through welcome, clear-line, and combo-chain steps.
class OnboardingOverlayCard extends StatelessWidget {
  const OnboardingOverlayCard({
    required this.title,
    required this.description,
    required this.onDismiss,
    super.key,
  });

  final String title;
  final String description;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xEE172840),
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.tips_and_updates_outlined,
              color: LuminaPalette.amber,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFFCFE0F2),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: LuminaPalette.cyan,
                minimumSize: const Size(64, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: const Text('Hide'),
            ),
          ],
        ),
      ),
    );
  }
}
