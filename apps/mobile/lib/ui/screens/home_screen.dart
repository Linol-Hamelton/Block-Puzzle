import 'package:flutter/material.dart';

import '../../features/game_loop/presentation/game_loop_screen.dart';
import '../../features/store/presentation/store_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Block Puzzle')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFF7FCFF),
              Color(0xFFE5F0F8),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.grid_4x4_rounded,
                    size: 66,
                    color: Color(0xFF0A4D68),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Block Puzzle',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF13263A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hypnotic gameplay, premium visual progression, ad-free experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4B6171),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const GameLoopScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Classic'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const StoreScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Open Premium Store'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
