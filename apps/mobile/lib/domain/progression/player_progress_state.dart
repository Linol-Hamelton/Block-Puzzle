import 'dart:convert';

class PlayerProgressState {
  const PlayerProgressState({
    required this.dayKeyUtc,
    required this.streakCurrentDays,
    required this.streakBestDays,
    required this.dailyMoves,
    required this.dailyLinesCleared,
    required this.dailyScoreEarned,
    required this.bestScore,
    required this.onboardingStatus,
    required this.settings,
    required this.lastSeenUtc,
    required this.economyState,
    required this.cosmeticsState,
  });

  static const int schemaVersion = 2;

  final DateTime dayKeyUtc;
  final int streakCurrentDays;
  final int streakBestDays;
  final int dailyMoves;
  final int dailyLinesCleared;
  final int dailyScoreEarned;
  final int bestScore;
  final OnboardingStatus onboardingStatus;
  final PlayerSettings settings;
  final DateTime lastSeenUtc;
  final PlayerEconomyState economyState;
  final PlayerCosmeticsState cosmeticsState;

  int get rewardedToolsCredits => economyState.rewardedToolsCredits;

  Set<String> get ownedProductIds => economyState.ownedProductIds;

  factory PlayerProgressState.initialForDay(
    DateTime dayKeyUtc, {
    int initialRewardedToolsCredits = 0,
  }) {
    final DateTime normalizedDay = normalizeDayKeyUtc(dayKeyUtc);
    return PlayerProgressState(
      dayKeyUtc: normalizedDay,
      streakCurrentDays: 1,
      streakBestDays: 1,
      dailyMoves: 0,
      dailyLinesCleared: 0,
      dailyScoreEarned: 0,
      bestScore: 0,
      onboardingStatus: const OnboardingStatus(),
      settings: const PlayerSettings(),
      lastSeenUtc: normalizedDay,
      economyState: PlayerEconomyState(
        rewardedToolsCredits: initialRewardedToolsCredits,
        ownedProductIds: const <String>{},
      ),
      cosmeticsState: const PlayerCosmeticsState(),
    );
  }

  PlayerProgressState copyWith({
    DateTime? dayKeyUtc,
    int? streakCurrentDays,
    int? streakBestDays,
    int? dailyMoves,
    int? dailyLinesCleared,
    int? dailyScoreEarned,
    int? bestScore,
    OnboardingStatus? onboardingStatus,
    PlayerSettings? settings,
    DateTime? lastSeenUtc,
    PlayerEconomyState? economyState,
    PlayerCosmeticsState? cosmeticsState,
    int? rewardedToolsCredits,
    Set<String>? ownedProductIds,
  }) {
    final PlayerEconomyState nextEconomyState;
    if (economyState != null) {
      nextEconomyState = economyState;
    } else if (rewardedToolsCredits != null || ownedProductIds != null) {
      nextEconomyState = this.economyState.copyWith(
        rewardedToolsCredits: rewardedToolsCredits,
        ownedProductIds: ownedProductIds,
      );
    } else {
      nextEconomyState = this.economyState;
    }

    return PlayerProgressState(
      dayKeyUtc: dayKeyUtc ?? this.dayKeyUtc,
      streakCurrentDays: streakCurrentDays ?? this.streakCurrentDays,
      streakBestDays: streakBestDays ?? this.streakBestDays,
      dailyMoves: dailyMoves ?? this.dailyMoves,
      dailyLinesCleared: dailyLinesCleared ?? this.dailyLinesCleared,
      dailyScoreEarned: dailyScoreEarned ?? this.dailyScoreEarned,
      bestScore: bestScore ?? this.bestScore,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      settings: settings ?? this.settings,
      lastSeenUtc: lastSeenUtc ?? this.lastSeenUtc,
      economyState: nextEconomyState,
      cosmeticsState: cosmeticsState ?? this.cosmeticsState,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schema_version': schemaVersion,
      'day_key_utc': dayKeyUtc.toIso8601String(),
      'streak_current_days': streakCurrentDays,
      'streak_best_days': streakBestDays,
      'daily_moves': dailyMoves,
      'daily_lines_cleared': dailyLinesCleared,
      'daily_score_earned': dailyScoreEarned,
      'best_score': bestScore,
      'onboarding_status': onboardingStatus.toJson(),
      'settings': settings.toJson(),
      'last_seen_utc': lastSeenUtc.toIso8601String(),
      'economy_state': economyState.toJson(),
      'cosmetics_state': cosmeticsState.toJson(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory PlayerProgressState.fromJson(Map<String, Object?> json) {
    final int parsedSchemaVersion =
        _readInt(json['schema_version'], fallback: 1).clamp(1, schemaVersion);
    if (parsedSchemaVersion <= 1) {
      return PlayerProgressState._fromLegacyJson(json);
    }

    return PlayerProgressState(
      dayKeyUtc: normalizeDayKeyUtc(
        _readDateTime(
          json['day_key_utc'],
          fallback: DateTime.utc(1970, 1, 1),
        ),
      ),
      streakCurrentDays: _readInt(
        json['streak_current_days'],
        fallback: 1,
      ),
      streakBestDays: _readInt(
        json['streak_best_days'],
        fallback: 1,
      ),
      dailyMoves: _readInt(json['daily_moves'], fallback: 0),
      dailyLinesCleared: _readInt(json['daily_lines_cleared'], fallback: 0),
      dailyScoreEarned: _readInt(json['daily_score_earned'], fallback: 0),
      bestScore: _readInt(json['best_score'], fallback: 0),
      onboardingStatus: OnboardingStatus.fromJson(
        _readMap(json['onboarding_status']),
      ),
      settings: PlayerSettings.fromJson(
        _readMap(json['settings']),
      ),
      lastSeenUtc: _readDateTime(
        json['last_seen_utc'],
        fallback: DateTime.utc(1970, 1, 1),
      ),
      economyState: PlayerEconomyState.fromJson(
        _readMap(json['economy_state']),
      ),
      cosmeticsState: PlayerCosmeticsState.fromJson(
        _readMap(json['cosmetics_state']),
      ),
    );
  }

  factory PlayerProgressState.fromJsonString(String rawJson) {
    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('Player progress must be a JSON object.');
    }
    return PlayerProgressState.fromJson(
      decoded.cast<String, Object?>(),
    );
  }

  factory PlayerProgressState._fromLegacyJson(Map<String, Object?> json) {
    final DateTime dayKeyUtc = normalizeDayKeyUtc(
      _readDateTime(
        json['day_key_utc'],
        fallback: DateTime.utc(1970, 1, 1),
      ),
    );
    return PlayerProgressState(
      dayKeyUtc: dayKeyUtc,
      streakCurrentDays: _readInt(json['streak_current_days'], fallback: 1),
      streakBestDays: _readInt(json['streak_best_days'], fallback: 1),
      dailyMoves: _readInt(json['daily_moves'], fallback: 0),
      dailyLinesCleared: _readInt(json['daily_lines_cleared'], fallback: 0),
      dailyScoreEarned: _readInt(json['daily_score_earned'], fallback: 0),
      bestScore: _readInt(json['best_score'], fallback: 0),
      onboardingStatus: const OnboardingStatus(),
      settings: const PlayerSettings(),
      lastSeenUtc: dayKeyUtc,
      economyState: PlayerEconomyState(
        rewardedToolsCredits: _readInt(
          json['rewarded_tools_credits'],
          fallback: 0,
        ),
        ownedProductIds: const <String>{},
      ),
      cosmeticsState: const PlayerCosmeticsState(),
    );
  }

  static DateTime normalizeDayKeyUtc(DateTime utcDateTime) {
    return DateTime.utc(
      utcDateTime.year,
      utcDateTime.month,
      utcDateTime.day,
    );
  }

  static int _readInt(
    Object? rawValue, {
    required int fallback,
  }) {
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is num) {
      return rawValue.toInt();
    }
    if (rawValue is String) {
      return int.tryParse(rawValue) ?? fallback;
    }
    return fallback;
  }

  static DateTime _readDateTime(
    Object? rawValue, {
    required DateTime fallback,
  }) {
    if (rawValue is String) {
      return DateTime.tryParse(rawValue)?.toUtc() ?? fallback;
    }
    return fallback;
  }

  static Map<String, Object?> _readMap(Object? rawValue) {
    if (rawValue is Map<String, Object?>) {
      return rawValue;
    }
    if (rawValue is Map) {
      return rawValue.cast<String, Object?>();
    }
    return const <String, Object?>{};
  }
}

class OnboardingStatus {
  const OnboardingStatus({
    this.completed = false,
    this.lastStepId,
    this.lastStatus,
  });

  final bool completed;
  final String? lastStepId;
  final String? lastStatus;

  OnboardingStatus copyWith({
    bool? completed,
    String? lastStepId,
    String? lastStatus,
    bool resetLastStepId = false,
    bool resetLastStatus = false,
  }) {
    return OnboardingStatus(
      completed: completed ?? this.completed,
      lastStepId: resetLastStepId ? null : (lastStepId ?? this.lastStepId),
      lastStatus: resetLastStatus ? null : (lastStatus ?? this.lastStatus),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'completed': completed,
      'last_step_id': lastStepId,
      'last_status': lastStatus,
    };
  }

  factory OnboardingStatus.fromJson(Map<String, Object?> json) {
    return OnboardingStatus(
      completed: json['completed'] == true,
      lastStepId: json['last_step_id'] as String?,
      lastStatus: json['last_status'] as String?,
    );
  }
}

class PlayerSettings {
  const PlayerSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.selectedBlocksPreset = 'soft',
  });

  final bool soundEnabled;
  final bool hapticsEnabled;
  final String selectedBlocksPreset;

  PlayerSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    String? selectedBlocksPreset,
  }) {
    return PlayerSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      selectedBlocksPreset: selectedBlocksPreset ?? this.selectedBlocksPreset,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sound_enabled': soundEnabled,
      'haptics_enabled': hapticsEnabled,
      'selected_blocks_preset': selectedBlocksPreset,
    };
  }

  factory PlayerSettings.fromJson(Map<String, Object?> json) {
    return PlayerSettings(
      soundEnabled: json['sound_enabled'] != false,
      hapticsEnabled: json['haptics_enabled'] != false,
      selectedBlocksPreset:
          (json['selected_blocks_preset'] as String?)?.trim().isNotEmpty ==
                  true
              ? (json['selected_blocks_preset'] as String).trim()
              : 'soft',
    );
  }
}

class PlayerEconomyState {
  const PlayerEconomyState({
    required this.rewardedToolsCredits,
    required this.ownedProductIds,
  });

  final int rewardedToolsCredits;
  final Set<String> ownedProductIds;

  PlayerEconomyState copyWith({
    int? rewardedToolsCredits,
    Set<String>? ownedProductIds,
  }) {
    return PlayerEconomyState(
      rewardedToolsCredits:
          rewardedToolsCredits ?? this.rewardedToolsCredits,
      ownedProductIds: ownedProductIds ?? this.ownedProductIds,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'rewarded_tools_credits': rewardedToolsCredits,
      'owned_product_ids': ownedProductIds.toList(growable: false),
    };
  }

  factory PlayerEconomyState.fromJson(Map<String, Object?> json) {
    final Object? rawOwnedIds = json['owned_product_ids'];
    final Set<String> ownedIds;
    if (rawOwnedIds is List) {
      ownedIds = rawOwnedIds
          .whereType<String>()
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toSet();
    } else {
      ownedIds = <String>{};
    }

    return PlayerEconomyState(
      rewardedToolsCredits: PlayerProgressState._readInt(
        json['rewarded_tools_credits'],
        fallback: 0,
      ),
      ownedProductIds: ownedIds,
    );
  }
}

class PlayerCosmeticsState {
  const PlayerCosmeticsState({
    this.selectedSkinId,
    this.unlockedSkinIds = const <String>{},
  });

  final String? selectedSkinId;
  final Set<String> unlockedSkinIds;

  PlayerCosmeticsState copyWith({
    String? selectedSkinId,
    Set<String>? unlockedSkinIds,
    bool resetSelectedSkinId = false,
  }) {
    return PlayerCosmeticsState(
      selectedSkinId:
          resetSelectedSkinId ? null : (selectedSkinId ?? this.selectedSkinId),
      unlockedSkinIds: unlockedSkinIds ?? this.unlockedSkinIds,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'selected_skin_id': selectedSkinId,
      'unlocked_skin_ids': unlockedSkinIds.toList(growable: false),
    };
  }

  factory PlayerCosmeticsState.fromJson(Map<String, Object?> json) {
    final Object? rawUnlockedIds = json['unlocked_skin_ids'];
    final Set<String> unlockedIds;
    if (rawUnlockedIds is List) {
      unlockedIds = rawUnlockedIds
          .whereType<String>()
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toSet();
    } else {
      unlockedIds = <String>{};
    }

    return PlayerCosmeticsState(
      selectedSkinId: json['selected_skin_id'] as String?,
      unlockedSkinIds: unlockedIds,
    );
  }
}
