import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../monetization/iap_product.dart';
import '../../monetization/iap_purchase_result.dart';
import '../../monetization/iap_store_service.dart';
import 'store_view_state.dart';

class StoreController {
  StoreController({
    required this.iapStoreService,
    required this.analyticsTracker,
    required this.logger,
  });

  final IapStoreService iapStoreService;
  final AnalyticsTracker analyticsTracker;
  final AppLogger logger;

  final ValueNotifier<StoreViewState> _stateNotifier =
      ValueNotifier<StoreViewState>(StoreViewState.initial());

  bool _initialized = false;

  ValueListenable<StoreViewState> get stateListenable => _stateNotifier;
  StoreViewState get state => _stateNotifier.value;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await _reloadCatalog(trackStoreOpen: true);
  }

  Future<void> refresh() async {
    await _reloadCatalog(trackStoreOpen: false);
  }

  Future<void> purchaseProduct(IapProduct product) async {
    if (state.isPurchasing) {
      return;
    }
    if (state.ownedProductIds.contains(product.id)) {
      _stateNotifier.value = state.copyWith(
        message: '"${product.title}" уже куплен',
      );
      return;
    }

    _stateNotifier.value = state.copyWith(
      isPurchasing: true,
      resetMessage: true,
    );

    await analyticsTracker.track(
      'iap_purchase_attempt',
      params: <String, Object?>{
        'sku': product.id,
        'price': product.priceValue,
        'currency': product.currencyCode,
      },
    );

    try {
      final IapPurchaseResult result = await iapStoreService.purchase(
        product: product,
      );

      if (result.isSuccess) {
        final Set<String> owned = await iapStoreService.loadOwnedProductIds();
        _stateNotifier.value = state.copyWith(
          isPurchasing: false,
          ownedProductIds: owned,
          message: 'Покупка "${product.title}" успешно завершена',
        );

        await analyticsTracker.track(
          'iap_purchase',
          params: <String, Object?>{
            'sku': product.id,
            'price': product.priceValue,
            'currency': product.currencyCode,
            'country': 'unknown',
          },
        );
      } else {
        final String reason = result.message ??
            (result.status == IapPurchaseStatus.cancelled
                ? 'cancelled'
                : 'failed');
        _stateNotifier.value = state.copyWith(
          isPurchasing: false,
          message: 'Покупка отменена: $reason',
        );
      }
    } catch (error, stackTrace) {
      logger.error('Store purchase failed: $error');
      logger.error('$stackTrace');
      _stateNotifier.value = state.copyWith(
        isPurchasing: false,
        message: 'Ошибка покупки: $error',
      );
    }
  }

  Future<void> restorePurchases() async {
    if (state.isPurchasing) {
      return;
    }
    _stateNotifier.value = state.copyWith(
      isPurchasing: true,
      resetMessage: true,
    );

    try {
      final Set<String> owned = await iapStoreService.restorePurchases();
      _stateNotifier.value = state.copyWith(
        isPurchasing: false,
        ownedProductIds: owned,
        message: 'Восстановлено покупок: ${owned.length}',
      );

      await analyticsTracker.track(
        'iap_restore',
        params: <String, Object?>{
          'restored_count': owned.length,
        },
      );
    } catch (error) {
      logger.error('Restore purchases failed: $error');
      _stateNotifier.value = state.copyWith(
        isPurchasing: false,
        message: 'Ошибка восстановления: $error',
      );
    }
  }

  Future<void> _reloadCatalog({
    required bool trackStoreOpen,
  }) async {
    _stateNotifier.value = state.copyWith(
      isLoading: true,
      resetMessage: true,
    );

    try {
      final List<IapProduct> catalog = await iapStoreService.loadCatalog();
      final Set<String> owned = await iapStoreService.loadOwnedProductIds();
      _stateNotifier.value = state.copyWith(
        isLoading: false,
        products: catalog,
        ownedProductIds: owned,
      );

      if (trackStoreOpen) {
        await analyticsTracker.track(
          'store_open',
          params: <String, Object?>{
            'items_count': catalog.length,
            'owned_count': owned.length,
          },
        );
      }
    } catch (error) {
      logger.error('Store catalog load failed: $error');
      _stateNotifier.value = state.copyWith(
        isLoading: false,
        message: 'Не удалось загрузить магазин',
      );
    }
  }

  void dispose() {
    _stateNotifier.dispose();
  }
}
