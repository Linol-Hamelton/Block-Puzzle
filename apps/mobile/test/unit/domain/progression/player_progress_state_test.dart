import 'package:block_puzzle_mobile/domain/progression/player_progress_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerProgressState Cloud Serialization & Rules Contract', () {
    test('toJson roundtrip preserves all fields', () {
      final PlayerProgressState original = PlayerProgressState.initialForDay(
        DateTime.utc(2026, 9, 16),
      ).copyWith(
        bestScore: 8520,
        streakCurrentDays: 5,
        streakBestDays: 12,
        dailyScoreEarned: 1500,
        dailyLinesCleared: 24,
        dailyMoves: 45,
        economyState: const PlayerEconomyState(
          rewardedToolsCredits: 3,
          ownedProductIds: <String>{'skin_pack_neon', 'premium_starter_bundle'},
        ),
        cosmeticsState: const PlayerCosmeticsState(
          selectedSkinId: 'skin_pack_neon',
          unlockedSkinIds: <String>{'skin_pack_neon', 'skin_pack_mono'},
        ),
      );

      final Map<String, Object?> json = original.toJson();
      final PlayerProgressState restored = PlayerProgressState.fromJson(json);

      expect(restored.bestScore, 8520);
      expect(restored.streakCurrentDays, 5);
      expect(restored.streakBestDays, 12);
      expect(restored.dailyScoreEarned, 1500);
      expect(restored.dailyLinesCleared, 24);
      expect(restored.dailyMoves, 45);
      expect(restored.economyState.rewardedToolsCredits, 3);
      expect(
        restored.economyState.ownedProductIds,
        containsAll(<String>['skin_pack_neon', 'premium_starter_bundle']),
      );
      expect(restored.cosmeticsState.selectedSkinId, 'skin_pack_neon');
      expect(
        restored.cosmeticsState.unlockedSkinIds,
        containsAll(<String>['skin_pack_neon', 'skin_pack_mono']),
      );
    });

    test('toCloudJson strips owned products and unlocked skins per DEC-0003 & DEC-0008', () {
      final PlayerProgressState localState = PlayerProgressState.initialForDay(
        DateTime.utc(2026, 9, 16),
      ).copyWith(
        bestScore: 9999,
        economyState: const PlayerEconomyState(
          rewardedToolsCredits: 5,
          ownedProductIds: <String>{'skin_pack_neon', 'premium_starter_bundle'},
        ),
        cosmeticsState: const PlayerCosmeticsState(
          selectedSkinId: 'skin_pack_neon',
          unlockedSkinIds: <String>{'skin_pack_neon'},
        ),
      );

      final Map<String, Object?> cloudJson = localState.toCloudJson();

      final Map<String, Object?> economy =
          cloudJson['economy_state']! as Map<String, Object?>;
      final Map<String, Object?> cosmetics =
          cloudJson['cosmetics_state']! as Map<String, Object?>;

      expect(
        economy['owned_product_ids'],
        isEmpty,
        reason: 'Rules reject client writes containing owned_product_ids',
      );
      expect(
        cosmetics['unlocked_skin_ids'],
        isEmpty,
        reason: 'Rules reject client writes containing unlocked_skin_ids',
      );
      expect(cloudJson['best_score'], 9999);
      expect(economy['rewarded_tools_credits'], 5);
      expect(cosmetics['selected_skin_id'], 'skin_pack_neon');
    });

    test('withEntitlementsFrom restores local entitlements onto cloud-fetched state', () {
      final PlayerProgressState localState = PlayerProgressState.initialForDay(
        DateTime.utc(2026, 9, 15),
      ).copyWith(
        bestScore: 1000,
        economyState: const PlayerEconomyState(
          rewardedToolsCredits: 2,
          ownedProductIds: <String>{'skin_pack_neon'},
        ),
        cosmeticsState: const PlayerCosmeticsState(
          selectedSkinId: 'skin_pack_neon',
          unlockedSkinIds: <String>{'skin_pack_neon'},
        ),
      );

      // Cloud state has higher score, but empty entitlements (as returned from cloud)
      final PlayerProgressState cloudState = PlayerProgressState.initialForDay(
        DateTime.utc(2026, 9, 16),
      ).copyWith(
        bestScore: 5000,
        economyState: const PlayerEconomyState(
          rewardedToolsCredits: 4,
          ownedProductIds: <String>{},
        ),
        cosmeticsState: const PlayerCosmeticsState(
          selectedSkinId: 'skin_pack_neon',
          unlockedSkinIds: <String>{},
        ),
      );

      final PlayerProgressState merged = cloudState.withEntitlementsFrom(localState);

      expect(merged.bestScore, 5000);
      expect(merged.economyState.rewardedToolsCredits, 4);
      expect(merged.economyState.ownedProductIds, contains('skin_pack_neon'));
      expect(merged.cosmeticsState.unlockedSkinIds, contains('skin_pack_neon'));
    });

    test('PlayerSettings serialization roundtrip and backward compatibility migration', () {
      // 1. Backward compatibility: old JSON without music_volume, sound_volume, reduced_motion
      final Map<String, Object?> legacyJson = <String, Object?>{
        'sound_enabled': true,
        'haptics_enabled': false,
        'selected_blocks_preset': 'soft',
      };
      final PlayerSettings migrated = PlayerSettings.fromJson(legacyJson);
      expect(migrated.soundEnabled, isTrue);
      expect(migrated.hapticsEnabled, isFalse);
      expect(migrated.selectedBlocksPreset, 'soft');
      expect(migrated.musicVolume, 0.50);
      expect(migrated.soundVolume, 1.0);
      expect(migrated.reducedMotion, isFalse);
      expect(migrated.selectedTheme, 'pastel');

      // 2. Roundtrip with new fields
      const PlayerSettings custom = PlayerSettings(
        soundEnabled: false,
        hapticsEnabled: true,
        selectedBlocksPreset: 'soft',
        selectedTheme: 'neon',
        musicVolume: 0.35,
        soundVolume: 0.80,
        reducedMotion: true,
      );
      final Map<String, Object?> json = custom.toJson();
      final PlayerSettings restored = PlayerSettings.fromJson(json);
      expect(restored.soundEnabled, isFalse);
      expect(restored.hapticsEnabled, isTrue);
      expect(restored.selectedTheme, 'neon');
      expect(restored.musicVolume, closeTo(0.35, 1e-4));
      expect(restored.soundVolume, closeTo(0.80, 1e-4));
      expect(restored.reducedMotion, isTrue);
    });
  });
}
