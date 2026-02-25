import 'package:block_puzzle_mobile/features/monetization/debug_iap_store_service.dart';
import 'package:block_puzzle_mobile/features/monetization/iap_purchase_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DebugIapStoreService', () {
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
