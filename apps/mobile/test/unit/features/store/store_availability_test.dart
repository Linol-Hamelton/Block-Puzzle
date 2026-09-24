import 'package:block_puzzle_mobile/core/config/remote_config_reader.dart';
import 'package:block_puzzle_mobile/core/logging/app_logger.dart';
import 'package:block_puzzle_mobile/data/remote_config/in_memory_remote_config_repository.dart';
import 'package:block_puzzle_mobile/data/remote_config/remote_config_key_map.dart';
import 'package:block_puzzle_mobile/data/repositories/in_memory_player_progress_repository.dart';
import 'package:block_puzzle_mobile/features/monetization/debug_iap_store_service.dart';
import 'package:block_puzzle_mobile/features/monetization/iap_product.dart';
import 'package:block_puzzle_mobile/features/monetization/iap_purchase_result.dart';
import 'package:block_puzzle_mobile/features/monetization/local_catalog_iap_store_service.dart';
import 'package:block_puzzle_mobile/features/store/application/store_availability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StoreAvailability availabilityFrom(Map<String, Object?> config) =>
      StoreAvailability(RemoteConfigReader(config));

  group('StoreAvailability flag keys and mapping', () {
    test('flag keys match design specifications', () {
      expect(StoreAvailability.flagKey, 'iap.store_enabled');
      expect(StoreAvailability.auxiliaryFlagKey, 'feature_store_enabled');
    });

    test('RemoteConfigKeyMap translates iap.store_enabled to iap_store_enabled', () {
      final RemoteConfigKeyMap keyMap = RemoteConfigKeyMap.fromDefaults();
      expect(RemoteConfigKeyMap.toExternal('iap.store_enabled'), 'iap_store_enabled');
      expect(keyMap.toInternal('iap_store_enabled'), 'iap.store_enabled');
    });
  });

  group('StoreAvailability evaluation (DEC-0026 / DEC-0028 p.7)', () {
    test('defaults to false when remote config is empty (v1.0 default)', () {
      final StoreAvailability availability = availabilityFrom(<String, Object?>{});
      expect(availability.isEnabled, isFalse);
    });

    test('returns false when iap.store_enabled is false', () {
      final StoreAvailability availability = availabilityFrom(<String, Object?>{
        'iap.store_enabled': false,
      });
      expect(availability.isEnabled, isFalse);
    });

    test('returns false when rollout strategy is disabled or none', () {
      final StoreAvailability availability1 = availabilityFrom(<String, Object?>{
        'iap.store_enabled': true,
        'iap.rollout_strategy': 'disabled',
      });
      expect(availability1.isEnabled, isFalse);

      final StoreAvailability availability2 = availabilityFrom(<String, Object?>{
        'iap.store_enabled': true,
        'iap.rollout_strategy': 'none',
      });
      expect(availability2.isEnabled, isFalse);
    });

    test('returns true when iap.store_enabled is true (Stage C rollout)', () {
      final StoreAvailability availability = availabilityFrom(<String, Object?>{
        'iap.store_enabled': true,
      });
      expect(availability.isEnabled, isTrue);
    });

    test('accepts string representations from Firebase Remote Config', () {
      final StoreAvailability falseAvailability = availabilityFrom(<String, Object?>{
        'iap.store_enabled': 'false',
      });
      expect(falseAvailability.isEnabled, isFalse);

      final StoreAvailability trueAvailability = availabilityFrom(<String, Object?>{
        'iap.store_enabled': 'true',
      });
      expect(trueAvailability.isEnabled, isTrue);
    });

    test('supports auxiliary flag feature_store_enabled', () {
      final StoreAvailability availability = availabilityFrom(<String, Object?>{
        'feature_store_enabled': true,
      });
      expect(availability.isEnabled, isTrue);
    });
  });

  group('Catalog and purchase gating across IAP services', () {
    test('LocalCatalogIapStoreService returns empty catalog and blocks purchase when store disabled', () async {
      final InMemoryRemoteConfigRepository configRepo = InMemoryRemoteConfigRepository(
        initialConfig: <String, Object?>{
          'iap.store_enabled': false,
        },
      );
      final LocalCatalogIapStoreService service = LocalCatalogIapStoreService(
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        remoteConfigRepository: configRepo,
        logger: AppLogger(),
      );

      final List<IapProduct> catalog = await service.loadCatalog();
      expect(catalog, isEmpty);

      final IapPurchaseResult result = await service.purchase(
        product: const IapProduct(
          id: 'skin_pack_neon',
          title: 'Neon Skin Pack',
          description: '',
          priceLabel: '\$1.99',
          priceValue: 1.99,
          currencyCode: 'USD',
          type: IapProductType.nonConsumable,
        ),
      );
      expect(result.status, IapPurchaseStatus.failed);
      expect(result.errorCode, 'store_disabled');
    });

    test('LocalCatalogIapStoreService returns full catalog when store enabled (Stage C)', () async {
      final InMemoryRemoteConfigRepository configRepo = InMemoryRemoteConfigRepository(
        initialConfig: <String, Object?>{
          'iap.store_enabled': true,
        },
      );
      final LocalCatalogIapStoreService service = LocalCatalogIapStoreService(
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        remoteConfigRepository: configRepo,
        logger: AppLogger(),
      );

      final List<IapProduct> catalog = await service.loadCatalog();
      expect(catalog, isNotEmpty);
      expect(catalog.any((product) => product.id == 'skin_pack_neon'), isTrue);
      expect(catalog.any((product) => product.id == 'skin_pack_mono'), isTrue);
    });

    test('DebugIapStoreService returns empty catalog and blocks purchase when storeEnabled is false', () async {
      final DebugIapStoreService service = DebugIapStoreService(storeEnabled: false);

      final List<IapProduct> catalog = await service.loadCatalog();
      expect(catalog, isEmpty);

      final IapPurchaseResult result = await service.purchase(
        product: const IapProduct(
          id: 'skin_pack_neon',
          title: 'Neon Skin Pack',
          description: '',
          priceLabel: '\$1.99',
          priceValue: 1.99,
          currencyCode: 'USD',
          type: IapProductType.nonConsumable,
        ),
      );
      expect(result.status, IapPurchaseStatus.failed);
      expect(result.errorCode, 'store_disabled');
    });
  });
}
