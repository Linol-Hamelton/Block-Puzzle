import 'package:flutter/material.dart';

import '../ui/screens/home_screen.dart';
import '../ui/theme/app_theme.dart';

class BlockPuzzleApp extends StatelessWidget {
  const BlockPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumina Blocks',
      theme: AppTheme.lightTheme(),
      home: const HomeScreen(),
    );
  }
}
