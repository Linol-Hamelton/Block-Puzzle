import 'package:flutter/material.dart';

import '../../features/game_loop/application/game_loop_view_state.dart';

/// Game-over overlay card showing round summary and action buttons.
///
/// Extracted from `game_loop_screen.dart` to be a public, reusable
/// component and independently testable.
class GameOverOverlayCard extends StatelessWidget {
  const GameOverOverlayCard({
    required this.state,
    required this.onRestartPressed,
    this.onRevivePressed,
    this.onSharePressed,
    super.key,
  });

  final GameLoopViewState state;
  final VoidCallback onRestartPressed;
  final VoidCallback? onRevivePressed;
  final VoidCallback? onSharePressed;

  @override
  Widget build(BuildContext context) {
    final bool isNewBest = state.scoreState.totalScore >= state.bestScore &&
        state.scoreState.totalScore > 0;
    final ButtonStyle actionButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size(112, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
      ),
    );

    return Card(
      margin: const EdgeInsets.all(20),
      color: const Color(0xFFF0F6FF),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0x442B4E7A)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.flag_circle_outlined,
                    color: Color(0xFF1E5B82),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Round Complete',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isNewBest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF3E7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'New Best',
                        style: TextStyle(
                          color: Color(0xFF276642),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _RoundStatTile(
                      label: 'Score',
                      value: '${state.scoreState.totalScore}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoundStatTile(
                      label: 'Best',
                      value: '${state.bestScore}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoundStatTile(
                      label: 'Level',
                      value: '${state.level}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoundStatTile(
                      label: 'Moves',
                      value: '${state.movesPlayed}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Daily goals: ${state.dailyGoals.completedCount}/${state.dailyGoals.totalCount}',
                        style: const TextStyle(
                          color: Color(0xFF244A66),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      'Streak ${state.streak.currentDays}d',
                      style: const TextStyle(
                        color: Color(0xFF244A66),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  if (onSharePressed != null)
                    FilledButton.tonalIcon(
                      onPressed: onSharePressed,
                      style: actionButtonStyle,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  if (onRevivePressed != null)
                    FilledButton.tonalIcon(
                      onPressed: onRevivePressed,
                      style: actionButtonStyle,
                      icon: const Icon(Icons.favorite),
                      label: const Text('Revive'),
                    ),
                  FilledButton.icon(
                    onPressed: onRestartPressed,
                    style: actionButtonStyle,
                    icon: const Icon(Icons.replay),
                    label: const Text('Restart'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundStatTile extends StatelessWidget {
  const _RoundStatTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF3F617C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14293D),
            ),
          ),
        ],
      ),
    );
  }
}
