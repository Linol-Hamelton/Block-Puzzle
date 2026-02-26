import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../data/analytics/analytics_tracker.dart';
import '../../../data/remote_config/remote_config_repository.dart';
import '../../../domain/progression/player_progress_repository.dart';
import '../../../domain/progression/player_progress_state.dart';
import '../../monetization/iap_product.dart';
import '../../monetization/iap_purchase_result.dart';
import '../../monetization/iap_store_service.dart';
import 'store_view_state.dart';

class StoreController {
  static const String _newUserSegment = 'new_user';
  static const String _engagedSegment = 'engaged_user';
  static const String _collectorSegment = 'collector';
  static const String _utilityOwnerSegment = 'utility_owner';
  static const String _defaultUtilityPassSku = 'utility_tools_pass';
  static const String _defaultBundleSku = 'premium_starter_bundle';
  static const String _defaultNeonSku = 'skin_pack_neon';
  static const String _defaultMonoSku = 'skin_pack_mono';

  StoreController({
    required this.iapStoreService,
    required this.remoteConfigRepository,
    required this.playerProgressRepository,
    required this.analyticsTracker,
    required this.logger,
  });

  final IapStoreService iapStoreService;
  final RemoteConfigRepository remoteConfigRepository;
  final PlayerProgressRepository playerProgressRepository;
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
        'user_segment': state.userSegment,
        'offer_strategy_variant': state.offerStrategyVariant,
        'is_recommended_offer': state.recommendedProductId == product.id,
        'position_index': _productPosition(product.id),
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
            'user_segment': state.userSegment,
            'offer_strategy_variant': state.offerStrategyVariant,
            'is_recommended_offer': state.recommendedProductId == product.id,
            'position_index': _productPosition(product.id),
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
      final Map<String, Object?> remoteConfig =
          await remoteConfigRepository.getCached();
      final List<IapProduct> catalog = await iapStoreService.loadCatalog();
      final Set<String> owned = await iapStoreService.loadOwnedProductIds();
      final PlayerProgressState? progressState =
          await playerProgressRepository.load();
      final _OfferTargetingDecision targeting = _buildOfferTargetingDecision(
        catalog: catalog,
        ownedProductIds: owned,
        remoteConfig: remoteConfig,
        progressState: progressState,
      );
      final List<IapProduct> orderedCatalog = _orderCatalog(
        catalog: catalog,
        ownedProductIds: owned,
        targetedProductIds: targeting.targetedProductIds,
      );
      _stateNotifier.value = state.copyWith(
        isLoading: false,
        products: orderedCatalog,
        ownedProductIds: owned,
        rolloutStrategy: iapStoreService.rolloutStrategy,
        offerStrategyVariant: targeting.offerStrategyVariant,
        userSegment: targeting.userSegment,
        targetedProductIds: targeting.targetedProductIds,
        recommendedProductId: targeting.recommendedProductId,
        resetRecommendedProduct: targeting.recommendedProductId == null,
      );

      if (trackStoreOpen) {
        await analyticsTracker.track(
          'store_open',
          params: <String, Object?>{
            'items_count': orderedCatalog.length,
            'owned_count': owned.length,
            'strategy': iapStoreService.rolloutStrategy,
            'offer_strategy_variant': targeting.offerStrategyVariant,
            'user_segment': targeting.userSegment,
            'recommended_sku': targeting.recommendedProductId,
          },
        );
        await analyticsTracker.track(
          'offer_targeting_exposure',
          params: <String, Object?>{
            'segment': targeting.userSegment,
            'strategy_variant': targeting.offerStrategyVariant,
            'recommended_sku': targeting.recommendedProductId ?? 'none',
            'targeted_skus': targeting.targetedProductIds.join(','),
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

  int _productPosition(String productId) {
    final int position =
        state.products.indexWhere((IapProduct item) => item.id == productId);
    return position < 0 ? -1 : position;
  }

  _OfferTargetingDecision _buildOfferTargetingDecision({
    required List<IapProduct> catalog,
    required Set<String> ownedProductIds,
    required Map<String, Object?> remoteConfig,
    required PlayerProgressState? progressState,
  }) {
    final String segment = _resolveUserSegment(
      ownedProductIds: ownedProductIds,
      progressState: progressState,
      remoteConfig: remoteConfig,
    );
    final String offerStrategyVariant = _readStringConfig(
      remoteConfig,
      key: 'ab.offer_strategy_variant',
      fallback: '${iapStoreService.rolloutStrategy}_v1',
    );
    final List<String> basePrioritySkus = _basePrioritySkus(
      offerStrategyVariant: offerStrategyVariant,
      remoteConfig: remoteConfig,
    );
    final String? segmentPrimarySku = _segmentPrimarySku(
      segment: segment,
      offerStrategyVariant: offerStrategyVariant,
      remoteConfig: remoteConfig,
    );
    final Set<String> catalogProductIds =
        catalog.map((IapProduct product) => product.id).toSet();

    final List<String> targeted = <String>[
      if (segmentPrimarySku != null) segmentPrimarySku,
      ...basePrioritySkus,
    ]
        .where((String sku) => catalogProductIds.contains(sku))
        .toSet()
        .toList(growable: false);

    String? recommendedSku;
    for (final String sku in targeted) {
      if (!ownedProductIds.contains(sku)) {
        recommendedSku = sku;
        break;
      }
    }
    recommendedSku ??= targeted.isEmpty ? null : targeted.first;

    return _OfferTargetingDecision(
      userSegment: segment,
      offerStrategyVariant: offerStrategyVariant,
      targetedProductIds: targeted,
      recommendedProductId: recommendedSku,
    );
  }

  String _resolveUserSegment({
    required Set<String> ownedProductIds,
    required PlayerProgressState? progressState,
    required Map<String, Object?> remoteConfig,
  }) {
    final String utilityPassSku = _readStringConfig(
      remoteConfig,
      key: 'iap.rewarded_tools_unlimited_sku',
      fallback: _defaultUtilityPassSku,
    );
    if (ownedProductIds.contains(utilityPassSku)) {
      return _utilityOwnerSegment;
    }

    final int collectorOwnedThreshold = _readIntConfig(
      remoteConfig,
      key: 'iap.segment_collector_owned_threshold',
      fallback: 2,
    ).clamp(1, 10);
    if (ownedProductIds.length >= collectorOwnedThreshold) {
      return _collectorSegment;
    }

    if (progressState == null) {
      return _newUserSegment;
    }

    final int engagedStreakThreshold = _readIntConfig(
      remoteConfig,
      key: 'iap.segment_engaged_streak_threshold',
      fallback: 2,
    ).clamp(1, 30);
    final int engagedDailyMovesThreshold = _readIntConfig(
      remoteConfig,
      key: 'iap.segment_engaged_daily_moves_threshold',
      fallback: 10,
    ).clamp(1, 500);
    final int engagedDailyScoreThreshold = _readIntConfig(
      remoteConfig,
      key: 'iap.segment_engaged_daily_score_threshold',
      fallback: 400,
    ).clamp(1, 100000);

    final bool isEngaged =
        progressState.streakCurrentDays >= engagedStreakThreshold ||
            progressState.dailyMoves >= engagedDailyMovesThreshold ||
            progressState.dailyScoreEarned >= engagedDailyScoreThreshold;
    if (isEngaged) {
      return _engagedSegment;
    }

    return _newUserSegment;
  }

  List<String> _basePrioritySkus({
    required String offerStrategyVariant,
    required Map<String, Object?> remoteConfig,
  }) {
    final String utilitySku = _readStringConfig(
      remoteConfig,
      key: 'iap.rewarded_tools_unlimited_sku',
      fallback: _defaultUtilityPassSku,
    );
    final String bundleSku = _readStringConfig(
      remoteConfig,
      key: 'iap.targeting_bundle_sku',
      fallback: _defaultBundleSku,
    );
    final String cosmeticsPrimarySku = _readStringConfig(
      remoteConfig,
      key: 'iap.targeting_cosmetic_primary_sku',
      fallback: _defaultNeonSku,
    );
    final String cosmeticsSecondarySku = _readStringConfig(
      remoteConfig,
      key: 'iap.targeting_cosmetic_secondary_sku',
      fallback: _defaultMonoSku,
    );

    final String normalized = offerStrategyVariant.toLowerCase();
    if (normalized.contains('bundle')) {
      return <String>[
        bundleSku,
        utilitySku,
        cosmeticsPrimarySku,
        cosmeticsSecondarySku,
      ];
    }
    if (normalized.contains('cosmetics')) {
      return <String>[
        cosmeticsPrimarySku,
        cosmeticsSecondarySku,
        utilitySku,
        bundleSku,
      ];
    }
    if (normalized.contains('utility')) {
      return <String>[
        utilitySku,
        cosmeticsPrimarySku,
        cosmeticsSecondarySku,
        bundleSku,
      ];
    }
    return <String>[
      utilitySku,
      bundleSku,
      cosmeticsPrimarySku,
      cosmeticsSecondarySku,
    ];
  }

  String? _segmentPrimarySku({
    required String segment,
    required String offerStrategyVariant,
    required Map<String, Object?> remoteConfig,
  }) {
    final String utilitySku = _readStringConfig(
      remoteConfig,
      key: 'iap.rewarded_tools_unlimited_sku',
      fallback: _defaultUtilityPassSku,
    );
    final String bundleSku = _readStringConfig(
      remoteConfig,
      key: 'iap.targeting_bundle_sku',
      fallback: _defaultBundleSku,
    );
    final String cosmeticsPrimarySku = _readStringConfig(
      remoteConfig,
      key: 'iap.targeting_cosmetic_primary_sku',
      fallback: _defaultNeonSku,
    );
    final String cosmeticsSecondarySku = _readStringConfig(
      remoteConfig,
      key: 'iap.targeting_cosmetic_secondary_sku',
      fallback: _defaultMonoSku,
    );

    if (segment == _utilityOwnerSegment) {
      return _readStringConfig(
        remoteConfig,
        key: 'iap.targeting.utility_owner_primary_sku',
        fallback: cosmeticsSecondarySku,
      );
    }
    if (segment == _collectorSegment) {
      return _readStringConfig(
        remoteConfig,
        key: 'iap.targeting.collector_primary_sku',
        fallback: bundleSku,
      );
    }
    if (segment == _engagedSegment) {
      return _readStringConfig(
        remoteConfig,
        key: 'iap.targeting.engaged_primary_sku',
        fallback: utilitySku,
      );
    }

    final String defaultNewUserPrimary =
        offerStrategyVariant.toLowerCase().contains('bundle')
            ? bundleSku
            : cosmeticsPrimarySku;
    return _readStringConfig(
      remoteConfig,
      key: 'iap.targeting.new_user_primary_sku',
      fallback: defaultNewUserPrimary,
    );
  }

  List<IapProduct> _orderCatalog({
    required List<IapProduct> catalog,
    required Set<String> ownedProductIds,
    required List<String> targetedProductIds,
  }) {
    final Map<String, int> priorityRank = <String, int>{};
    for (int i = 0; i < targetedProductIds.length; i++) {
      priorityRank[targetedProductIds[i]] = i;
    }

    final List<IapProduct> ordered = List<IapProduct>.from(catalog);
    ordered.sort((IapProduct a, IapProduct b) {
      final bool aOwned = ownedProductIds.contains(a.id);
      final bool bOwned = ownedProductIds.contains(b.id);
      if (aOwned != bOwned) {
        return aOwned ? 1 : -1;
      }

      final int aRank = priorityRank[a.id] ?? 9999;
      final int bRank = priorityRank[b.id] ?? 9999;
      if (aRank != bRank) {
        return aRank.compareTo(bRank);
      }

      final int byPrice = a.priceValue.compareTo(b.priceValue);
      if (byPrice != 0) {
        return byPrice;
      }
      return a.id.compareTo(b.id);
    });
    return ordered;
  }

  String _readStringConfig(
    Map<String, Object?> config, {
    required String key,
    required String fallback,
  }) {
    final Object? raw = config[key];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return fallback;
  }

  int _readIntConfig(
    Map<String, Object?> config, {
    required String key,
    required int fallback,
  }) {
    final Object? raw = config[key];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw) ?? fallback;
    }
    return fallback;
  }
}

class _OfferTargetingDecision {
  const _OfferTargetingDecision({
    required this.userSegment,
    required this.offerStrategyVariant,
    required this.targetedProductIds,
    required this.recommendedProductId,
  });

  final String userSegment;
  final String offerStrategyVariant;
  final List<String> targetedProductIds;
  final String? recommendedProductId;
}
