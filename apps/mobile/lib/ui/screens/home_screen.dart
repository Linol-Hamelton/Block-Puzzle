import 'package:flutter/material.dart';

import '../../features/game_loop/presentation/game_loop_screen.dart';
import '../../features/store/presentation/store_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lumina Blocks')),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFF0A1222),
                    Color(0xFF101E35),
                    Color(0xFF142845),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.25),
                  radius: 0.9,
                  colors: <Color>[
                    LuminaPalette.cyan.withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: LuminaPalette.panel,
                        border: Border.all(
                          color: LuminaPalette.panelBorder,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/branding/lumina_icon.png',
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lumina Blocks',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: LuminaPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hypnotic puzzle flow with premium visual feedback and clean controls.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LuminaPalette.textSecondary,
                        height: 1.35,
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
        ],
      ),
    );
  }
}
