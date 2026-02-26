import 'package:block_puzzle_mobile/core/logging/app_logger.dart';
import 'package:block_puzzle_mobile/data/analytics/analytics_tracker.dart';
import 'package:block_puzzle_mobile/data/remote_config/remote_config_repository.dart';
import 'package:block_puzzle_mobile/data/repositories/in_memory_player_progress_repository.dart';
import 'package:block_puzzle_mobile/domain/progression/player_progress_state.dart';
import 'package:block_puzzle_mobile/features/monetization/debug_iap_store_service.dart';
import 'package:block_puzzle_mobile/features/store/application/store_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreController', () {
    test('loads catalog, resolves segment and tracks targeting events',
        () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
      final StoreController controller = StoreController(
        iapStoreService: DebugIapStoreService(),
        remoteConfigRepository:
            const _InMemoryRemoteConfigRepository(<String, Object?>{}),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        analyticsTracker: analytics,
        logger: AppLogger(),
      );

      await controller.initialize();

      expect(controller.state.products, isNotEmpty);
      expect(controller.state.userSegment, 'new_user');
      expect(controller.state.recommendedProductId, isNotNull);
      expect(
        analytics.events.contains('store_open'),
        isTrue,
      );
      expect(
        analytics.events.contains('offer_targeting_exposure'),
        isTrue,
      );
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'store_open' &&
              event.params['user_segment'] == 'new_user' &&
              event.params['recommended_sku'] != null,
        ),
        isTrue,
      );
    });

    test('purchases item and tracks iap_purchase with targeting context',
        () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
      final StoreController controller = StoreController(
        iapStoreService: DebugIapStoreService(),
        remoteConfigRepository:
            const _InMemoryRemoteConfigRepository(<String, Object?>{}),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
        analyticsTracker: analytics,
        logger: AppLogger(),
      );
      await controller.initialize();

      final String recommendedSku = controller.state.recommendedProductId!;
      final product = controller.state.products.firstWhere(
        (item) => item.id == recommendedSku,
      );
      await controller.purchaseProduct(product);

      expect(controller.state.ownedProductIds.contains(product.id), isTrue);
      expect(analytics.events.contains('iap_purchase_attempt'), isTrue);
      expect(analytics.events.contains('iap_purchase'), isTrue);
      expect(
        analytics.trackedEvents.any(
          (event) =>
              event.name == 'iap_purchase' &&
              event.params['user_segment'] == controller.state.userSegment &&
              event.params['is_recommended_offer'] == true,
        ),
        isTrue,
      );
    });

    test('restores purchases and tracks iap_restore', () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
      final DebugIapStoreService service = DebugIapStoreService();
      final StoreController controller = StoreController(
        iapStoreService: service,
        remoteConfigRepository:
            const _InMemoryRemoteConfigRepository(<String, Object?>{}),
        playerProgressRepository: InMemoryPlayerProgressRepository(),
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

    test('targets utility offer for engaged segment and reorders catalog',
        () async {
      final _MemoryAnalyticsTracker analytics = _MemoryAnalyticsTracker();
      final DebugIapStoreService service = DebugIapStoreService(
        includeBundle: true,
        includeUtilityPass: true,
      );
      final InMemoryPlayerProgressRepository progressRepository =
          InMemoryPlayerProgressRepository();
      await progressRepository.save(
        PlayerProgressState.initialForDay(
          DateTime.utc(2026, 2, 25),
        ).copyWith(
          dailyMoves: 16,
          dailyScoreEarned: 620,
        ),
      );

      final StoreController controller = StoreController(
        iapStoreService: service,
        remoteConfigRepository: const _InMemoryRemoteConfigRepository(
          <String, Object?>{
            'ab.offer_strategy_variant': 'cosmetics_first_v2',
            'iap.targeting.engaged_primary_sku': 'utility_tools_pass',
          },
        ),
        playerProgressRepository: progressRepository,
        analyticsTracker: analytics,
        logger: AppLogger(),
      );

      await controller.initialize();

      expect(controller.state.userSegment, 'engaged_user');
      expect(controller.state.recommendedProductId, 'utility_tools_pass');
      expect(controller.state.products.first.id, 'utility_tools_pass');
    });
  });
}

class _MemoryAnalyticsTracker implements AnalyticsTracker {
  final List<_TrackedAnalyticsEvent> trackedEvents = <_TrackedAnalyticsEvent>[];

  List<String> get events =>
      trackedEvents.map((event) => event.name).toList(growable: false);

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    trackedEvents.add(
      _TrackedAnalyticsEvent(
        name: eventName,
        params: Map<String, Object?>.from(params),
      ),
    );
  }
}

class _TrackedAnalyticsEvent {
  const _TrackedAnalyticsEvent({
    required this.name,
    required this.params,
  });

  final String name;
  final Map<String, Object?> params;
}

class _InMemoryRemoteConfigRepository implements RemoteConfigRepository {
  const _InMemoryRemoteConfigRepository(this._config);

  final Map<String, Object?> _config;

  @override
  Future<Map<String, Object?>> fetchLatest() async {
    return getCached();
  }

  @override
  Future<Map<String, Object?>> getCached() async {
    return _config;
  }
}
