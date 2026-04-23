import 'package:flutter/material.dart';

import '../core/di/di_container.dart';
import '../infra/monitoring/crash_reporter.dart';
import '../ui/screens/home_screen.dart';
import '../ui/theme/app_theme.dart';
import '../ui/widgets/error_boundary.dart';

class BlockPuzzleApp extends StatelessWidget {
  const BlockPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      crashReporter: sl<CrashReporter>(),
      child: MaterialApp(
        title: 'Lumina Blocks',
        theme: AppTheme.darkTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
