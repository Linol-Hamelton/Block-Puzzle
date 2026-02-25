import 'package:block_puzzle_mobile/features/monetization/debug_iap_store_service.dart';
import 'package:block_puzzle_mobile/features/monetization/iap_purchase_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DebugIapStoreService', () {
    test('uses cosmetics-first rollout by default', () async {
      final DebugIapStoreService service = DebugIapStoreService();

      final catalog = await service.loadCatalog();

      expect(service.rolloutStrategy, 'cosmetics_first');
      expect(
        catalog.where((product) => product.id == 'premium_starter_bundle'),
        isEmpty,
      );
    });

    test('includes starter bundle only when explicitly enabled', () async {
      final DebugIapStoreService service = DebugIapStoreService(
        includeBundle: true,
      );

      final catalog = await service.loadCatalog();

      expect(service.rolloutStrategy, 'cosmetics_bundle');
      expect(
        catalog.where((product) => product.id == 'premium_starter_bundle'),
        isNotEmpty,
      );
    });

    test('returns non-empty catalog', () async {
      final DebugIapStoreService service = DebugIapStoreService();

      final catalog = await service.loadCatalog();

      expect(catalog, isNotEmpty);
      expect(catalog.first.id, isNotEmpty);
      expect(catalog.first.priceValue, greaterThan(0));
    });

    test('marks product as owned after successful purchase', () async {
      final DebugIapStoreService service = DebugIapStoreService();
      final catalog = await service.loadCatalog();

      final result = await service.purchase(product: catalog.first);
      final owned = await service.loadOwnedProductIds();

      expect(result.status, IapPurchaseStatus.success);
      expect(owned.contains(catalog.first.id), isTrue);
    });

    test('returns cancelled when purchasing already owned product', () async {
      final DebugIapStoreService service = DebugIapStoreService();
      final catalog = await service.loadCatalog();
      final product = catalog.first;

      await service.purchase(product: product);
      final secondAttempt = await service.purchase(product: product);

      expect(secondAttempt.status, IapPurchaseStatus.cancelled);
    });
  });
}
