import 'package:block_puzzle_mobile/core/logging/app_logger.dart';
import 'package:block_puzzle_mobile/data/analytics/analytics_tracker.dart';
import 'package:block_puzzle_mobile/features/monetization/debug_iap_store_service.dart';
import 'package:block_puzzle_mobile/features/store/application/store_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreController', () {
    test('loads catalog and tracks store_open on initialize', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
      final StoreController controller = StoreController(
        iapStoreService: DebugIapStoreService(),
        analyticsTracker: analytics,
        logger: AppLogger(),
      );

      await controller.initialize();

      expect(controller.state.products, isNotEmpty);
      expect(
        analytics.events.contains('store_open'),
        isTrue,
      );
    });

    test('purchases item and tracks iap_purchase', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
      final StoreController controller = StoreController(
        iapStoreService: DebugIapStoreService(),
        analyticsTracker: analytics,
        logger: AppLogger(),
      );
      await controller.initialize();

      final product = controller.state.products.first;
      await controller.purchaseProduct(product);

      expect(controller.state.ownedProductIds.contains(product.id), isTrue);
      expect(analytics.events.contains('iap_purchase_attempt'), isTrue);
      expect(analytics.events.contains('iap_purchase'), isTrue);
    });

    test('restores purchases and tracks iap_restore', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
      final DebugIapStoreService service = DebugIapStoreService();
      final StoreController controller = StoreController(
        iapStoreService: service,
        analyticsTracker: analytics,
        logger: AppLogger(),
      );
      await controller.initialize();

      final product = controller.state.products.first;
      await controller.purchaseProduct(product);
      await controller.restorePurchases();

      expect(analytics.events.contains('iap_restore'), isTrue);
      expect(controller.state.ownedProductIds.contains(product.id), isTrue);
    });
  });
}

class _MemoryAnalyticsTracker implements AnalyticsTracker {
  final List<String> events = <String>[];

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    events.add(eventName);
  }
}
