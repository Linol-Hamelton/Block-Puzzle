import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/audio/music_controller.dart';
import '../../../core/device/haptics_controller.dart';
import '../../../core/di/di_container.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../../domain/progression/player_progress_repository.dart';
import '../../../domain/progression/player_progress_state.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/nebula_background.dart';
import '../../diagnostics/step6_benchmark.dart';
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
  double _musicVolume = 0.50;
  double _soundVolume = 1.0;
  bool _reducedMotion = false;
  String _selectedTheme = 'pastel';
  bool _loading = true;

  Timer? _musicDebounceTimer;
  Timer? _soundDebounceTimer;

  @override
  void initState() {
    super.initState();
    _music = sl<MusicController>();
    _sfx = sl<GameSfxPlayer>();
    _haptics = sl<HapticsController>();
    _progress = sl<PlayerProgressRepository>();
    _load();
  }

  @override
  void dispose() {
    _musicDebounceTimer?.cancel();
    _soundDebounceTimer?.cancel();
    super.dispose();
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
      _musicVolume = state?.settings.musicVolume ?? _music.baseVolume;
      _soundVolume = state?.settings.soundVolume ?? _sfx.volume;
      _reducedMotion = state?.settings.reducedMotion ?? Step6Benchmark.reducedMotion.value;
      _selectedTheme = state?.settings.selectedTheme ?? 'pastel';
      _loading = false;
    });
  }

  Future<void> _setSelectedTheme(String value) async {
    setState(() => _selectedTheme = value);
    await _persistSettings((PlayerSettings s) => s.copyWith(selectedTheme: value));
  }

  Future<void> _persistSettings(PlayerSettings Function(PlayerSettings) update) async {
    final PlayerProgressState existing =
        await _progress.load() ?? PlayerProgressState.initialForDay(DateTime.now().toUtc());
    await _progress.save(
      existing.copyWith(settings: update(existing.settings)),
    );
  }

  Future<void> _setMusic(bool value) async {
    setState(() => _musicOn = value);
    await _music.setEnabled(value);
  }

  void _onMusicVolumeChanged(double value) {
    setState(() => _musicVolume = value);
    _music.setBaseVolume(value);
    _musicDebounceTimer?.cancel();
    _musicDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      unawaited(_persistSettings((PlayerSettings s) => s.copyWith(musicVolume: value)));
    });
  }

  Future<void> _setSound(bool value) async {
    setState(() => _soundOn = value);
    _sfx.isEnabled = value;
    await _persistSettings((PlayerSettings s) => s.copyWith(soundEnabled: value));
  }

  void _onSoundVolumeChanged(double value) {
    setState(() => _soundVolume = value);
    _sfx.volume = value;
    _soundDebounceTimer?.cancel();
    _soundDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      unawaited(_persistSettings((PlayerSettings s) => s.copyWith(soundVolume: value)));
    });
  }

  Future<void> _setHaptics(bool value) async {
    setState(() => _hapticsOn = value);
    _haptics.isEnabled = value;
    await _persistSettings(
      (PlayerSettings s) => s.copyWith(hapticsEnabled: value),
    );
  }

  Future<void> _setReducedMotion(bool value) async {
    setState(() => _reducedMotion = value);
    Step6Benchmark.reducedMotion.value = value;
    await _persistSettings((PlayerSettings s) => s.copyWith(reducedMotion: value));
    if (sl.isRegistered<AnalyticsTracker>()) {
      unawaited(sl<AnalyticsTracker>().track('reduced_motion_toggled', params: <String, Object?>{
        'enabled': value,
      }));
    }
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
                          if (_musicOn)
                            _SliderSettingTile(
                              icon: Icons.volume_down_rounded,
                              title: 'Music volume',
                              value: _musicVolume,
                              onChanged: _onMusicVolumeChanged,
                            ),
                          _SettingTile(
                            icon: Icons.graphic_eq_rounded,
                            title: 'Sound effects',
                            subtitle: 'Placement, line clear, combos',
                            value: _soundOn,
                            onChanged: _setSound,
                          ),
                          if (_soundOn)
                            _SliderSettingTile(
                              icon: Icons.volume_up_rounded,
                              title: 'SFX volume',
                              value: _soundVolume,
                              onChanged: _onSoundVolumeChanged,
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
                          _SettingTile(
                            icon: Icons.motion_photos_off_rounded,
                            title: 'Reduced motion',
                            subtitle: 'Reduce screen shakes and bright flashes',
                            value: _reducedMotion,
                            onChanged: _setReducedMotion,
                          ),
                          const SizedBox(height: 16),
                          const _SectionLabel('Theme (Free)'),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: SegmentedButton<String>(
                              segments: const <ButtonSegment<String>>[
                                ButtonSegment<String>(
                                  value: 'pastel',
                                  label: Text('Pastel'),
                                  icon: Icon(Icons.palette_outlined),
                                ),
                                ButtonSegment<String>(
                                  value: 'neon',
                                  label: Text('Neon'),
                                  icon: Icon(Icons.flash_on_outlined),
                                ),
                                ButtonSegment<String>(
                                  value: 'mono',
                                  label: Text('Mono'),
                                  icon: Icon(Icons.contrast_outlined),
                                ),
                              ],
                              selected: <String>{_selectedTheme},
                              onSelectionChanged: (Set<String> newSelection) {
                                _setSelectedTheme(newSelection.first);
                              },
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
      child: Material(
        color: Colors.transparent,
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
      ),
    );
  }
}

class _SliderSettingTile extends StatelessWidget {
  const _SliderSettingTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: LuminaPalette.panel,
        border: Border.all(color: LuminaPalette.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: const Color(0xFFC5F2FF)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: LuminaPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  color: LuminaPalette.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF56D4FF),
              inactiveTrackColor: const Color(0x3356D4FF),
              thumbColor: const Color(0xFF56D4FF),
              overlayColor: const Color(0x2956D4FF),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
