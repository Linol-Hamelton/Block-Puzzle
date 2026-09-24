import 'package:flutter/material.dart';

import '../../features/game_loop/presentation/game_loop_screen.dart';
import '../../core/di/di_container.dart';
import '../../features/diagnostics/diagnostics_screen.dart';
import '../../features/game_modes/game_mode_availability.dart';
import '../../features/game_modes/mode_gate.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/match3/presentation/match3_screen.dart';
import '../../features/store/application/store_availability.dart';
import '../../features/store/presentation/store_gate.dart';
import '../../features/store/presentation/store_screen.dart';
import '../../features/tetris/presentation/tetris_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DEC-0002: a mode turned off in Remote Config must not be reachable. The
    // flags were published and then read by nothing, so the switches existed
    // and did nothing; this is where they take effect.
    final GameModeAvailability modes = sl<GameModeAvailability>();
    final bool isStoreEnabled = sl.isRegistered<StoreAvailability>()
        ? sl<StoreAvailability>().isEnabled
        : false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumina Blocks'),
        actions: <Widget>[
          // Compiled in only with --dart-define=ENABLE_DIAGNOSTICS=true, so it
          // cannot reach a store build. See DiagnosticsScreen for why this is a
          // compile-time flag rather than a debug-mode check.
          if (kDiagnosticsEnabled)
            IconButton(
              tooltip: 'Diagnostics',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DiagnosticsScreen(),
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
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
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.25),
                  radius: 0.9,
                  colors: <Color>[
                    Color(0x2156D4FF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
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
                        borderRadius: BorderRadius.circular(10),
                        color: LuminaPalette.panel,
                        border: Border.all(
                          color: LuminaPalette.panelBorder,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
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

                    // The three games come first and are grouped together; the
                    // store and the daily variant sit below a divider so the
                    // primary choice - which game to play - is not competing
                    // with commerce for the same visual weight.
                    if (modes.isEnabled(GameMode.classic)) ...<Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ModeGate(
                                  mode: GameMode.classic,
                                  child: GameLoopScreen(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start Classic'),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (modes.isEnabled(GameMode.tetris)) ...<Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ModeGate(
                                  mode: GameMode.tetris,
                                  child: TetrisScreen(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.grid_view_rounded),
                          label: const Text('Play Tetris'),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (modes.isEnabled(GameMode.match3))
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E9E6B),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ModeGate(
                                  mode: GameMode.match3,
                                  child: Match3Screen(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.diamond_rounded),
                          label: const Text('Play Match 3'),
                        ),
                      ),
                    if (modes.allDisabled)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'All game modes are currently unavailable. '
                          'Please try again later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: LuminaPalette.textSecondary),
                        ),
                      ),

                    // The three games come first and are grouped together; the
                    // store and the daily variant sit below a divider so the
                    // primary choice - which game to play - is not competing
                    // with commerce for the same visual weight.
                    // DEC-0026 / DEC-0028 item 7: store entry is hidden until Stage C.
                    if (isStoreEnabled || modes.isEnabled(GameMode.classic)) ...<Widget>[
                      const SizedBox(height: 18),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: LuminaPalette.panelBorder,
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (isStoreEnabled) ...<Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const StoreGate(
                                  child: StoreScreen(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Open Premium Store'),
                        ),
                      ),
                      if (modes.isEnabled(GameMode.classic))
                        const SizedBox(height: 10),
                    ],

                    // Daily Challenge is the Classic loop with a fixed seed, so
                    // disabling Classic has to disable it too - otherwise the
                    // kill switch leaves a second door into the same code.
                    if (modes.isEnabled(GameMode.classic)) ...<Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: LuminaPalette.violet,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ModeGate(
                                  mode: GameMode.classic,
                                  child:
                                      GameLoopScreen(isDailyChallenge: true),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.star_rounded),
                          label: const Text('Daily Challenge'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}
