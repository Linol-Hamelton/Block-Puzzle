import 'package:flutter/material.dart';

import '../../features/game_loop/presentation/game_loop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Block Puzzle')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const GameLoopScreen(),
              ),
            );
          },
          child: const Text('Start Classic'),
        ),
      ),
    );
  }
}
