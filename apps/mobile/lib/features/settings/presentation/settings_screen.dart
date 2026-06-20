import 'package:flutter/material.dart';

import '../../../core/audio/music_controller.dart';
import '../../../core/device/haptics_controller.dart';
import '../../../core/di/di_container.dart';
import '../../../domain/progression/player_progress_repository.dart';
import '../../../domain/progression/player_progress_state.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/nebula_background.dart';
import '../../game_loop/audio/game_sfx_player.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final MusicController _music;
  late final GameSfxPlayer _sfx;
  late final HapticsController _haptics;
  late final PlayerProgressRepository _progress;

  bool _musicOn = true;
  bool _soundOn = true;
  bool _hapticsOn = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _music = sl<MusicController>();
    _sfx = sl<GameSfxPlayer>();
    _haptics = sl<HapticsController>();
    _progress = sl<PlayerProgressRepository>();
    _load();
  }

  Future<void> _load() async {
    await _music.loadPreference();
    final PlayerProgressState? state = await _progress.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _musicOn = _music.isEnabled;
      _soundOn = state?.settings.soundEnabled ?? _sfx.isEnabled;
      _hapticsOn = state?.settings.hapticsEnabled ?? _haptics.isEnabled;
      _loading = false;
    });
  }

  Future<void> _setMusic(bool value) async {
    setState(() => _musicOn = value);
    await _music.setEnabled(value);
  }

  Future<void> _persistSettings(PlayerSettings Function(PlayerSettings) update) async {
    final PlayerProgressState existing =
        await _progress.load() ?? PlayerProgressState.initialForDay(DateTime.now().toUtc());
    await _progress.save(
      existing.copyWith(settings: update(existing.settings)),
    );
  }

  Future<void> _setSound(bool value) async {
    setState(() => _soundOn = value);
    _sfx.isEnabled = value;
    await _persistSettings((PlayerSettings s) => s.copyWith(soundEnabled: value));
  }

  Future<void> _setHaptics(bool value) async {
    setState(() => _hapticsOn = value);
    _haptics.isEnabled = value;
    await _persistSettings(
      (PlayerSettings s) => s.copyWith(hapticsEnabled: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFFC5F2FF),
            fontWeight: FontWeight.w500,
            fontSize: 24,
            letterSpacing: 0.3,
            shadows: <Shadow>[
              Shadow(color: Color(0x7A53D5FF), blurRadius: 16),
            ],
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: NebulaBackground()),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: <Widget>[
                          const _SectionLabel('Audio'),
                          _SettingTile(
                            icon: Icons.music_note_rounded,
                            title: 'Music',
                            subtitle: 'Background music loop',
                            value: _musicOn,
                            onChanged: _setMusic,
                          ),
                          _SettingTile(
                            icon: Icons.graphic_eq_rounded,
                            title: 'Sound effects',
                            subtitle: 'Placement, line clear, combos',
                            value: _soundOn,
                            onChanged: _setSound,
                          ),
                          const SizedBox(height: 16),
                          const _SectionLabel('Feedback'),
                          _SettingTile(
                            icon: Icons.vibration_rounded,
                            title: 'Haptics',
                            subtitle: 'Vibration on key actions',
                            value: _hapticsOn,
                            onChanged: _setHaptics,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: LuminaPalette.textSecondary,
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: LuminaPalette.panel,
        border: Border.all(color: LuminaPalette.panelBorder),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF56D4FF),
        secondary: Icon(icon, color: const Color(0xFFC5F2FF)),
        title: Text(
          title,
          style: const TextStyle(
            color: LuminaPalette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: LuminaPalette.textSecondary),
        ),
      ),
    );
  }
}
