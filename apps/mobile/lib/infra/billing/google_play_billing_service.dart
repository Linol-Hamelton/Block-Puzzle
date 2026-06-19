import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/logging/app_logger.dart';
import '../../data/remote_config/remote_config_repository.dart';
import '../../domain/progression/player_progress_repository.dart';
import '../../domain/progression/player_progress_state.dart';
import '../../features/monetization/iap_product.dart';
import '../../features/monetization/iap_purchase_result.dart';
import '../../features/monetization/iap_store_service.dart';
import 'purchase_receipt_validator.dart';

/// Production [IapStoreService] backed by Google Play Billing (via the
/// `in_app_purchase` plugin, Billing Library v7) with **server-side receipt
/// validation**: a purchase is only granted after [PurchaseReceiptValidator]
/// confirms it, and the granted entitlement is acknowledged
/// (`completePurchase`) and cached locally in [PlayerProgressState].
///
/// The plugin delivers purchase outcomes asynchronously on
/// [InAppPurchase.purchaseStream]; this service bridges that to the
/// `Future<IapPurchaseResult> purchase(...)` contract with a per-product
/// completer. See `docs/adr/003-billing-receipt-validation.md`.
class GooglePlayBillingService implements IapStoreService {
  GooglePlayBillingService({
    required PlayerProgressRepository playerProgressRepository,
    required RemoteConfigRepository remoteConfigRepository,
    required PurchaseReceiptValidator receiptValidator,
    required AppLogger logger,
    InAppPurchase? inAppPurchase,
    Duration purchaseTimeout = const Duration(minutes: 3),
    Duration restoreWindow = const Duration(seconds: 2),
  })  : _playerProgressRepository = playerProgressRepository,
        _remoteConfigRepository = remoteConfigRepository,
        _receiptValidator = receiptValidator,
        _logger = logger,
        _iap = inAppPurchase ?? InAppPurchase.instance,
        _purchaseTimeout = purchaseTimeout,
        _restoreWindow = restoreWindow;

  final PlayerProgressRepository _playerProgressRepository;
  final RemoteConfigRepository _remoteConfigRepository;
  final PurchaseReceiptValidator _receiptValidator;
  final AppLogger _logger;
  final InAppPurchase _iap;
  final Duration _purchaseTimeout;
  final Duration _restoreWindow;

  Future<void>? _initFuture;
  bool _available = false;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, Completer<IapPurchaseResult>> _pendingPurchases =
      <String, Completer<IapPurchaseResult>>{};

  String _rolloutStrategy = 'cosmetics_first';

  static const List<_CatalogEntry> _catalog = <_CatalogEntry>[
    _CatalogEntry(
      id: 'skin_pack_neon',
      title: 'Neon Skin Pack',
      description: 'Vibrant board and block colors for high-energy sessions.',
      priceLabel: '\$1.99',
      priceValue: 1.99,
      type: IapProductType.nonConsumable,
      badge: 'Popular',
      gate: _CatalogGate.always,
    ),
    _CatalogEntry(
      id: 'skin_pack_mono',
      title: 'Mono Elegance',
      description: 'Minimal high-contrast theme tuned for long focus play.',
      priceLabel: '\$2.99',
      priceValue: 2.99,
      type: IapProductType.nonConsumable,
      gate: _CatalogGate.always,
    ),
    _CatalogEntry(
      id: 'premium_starter_bundle',
      title: 'Starter Bundle',
      description: 'Premium visual pack + exclusive profile badge.',
      priceLabel: '\$4.99',
      priceValue: 4.99,
      type: IapProductType.nonConsumable,
      badge: 'Best Value',
      gate: _CatalogGate.bundle,
    ),
    _CatalogEntry(
      id: 'utility_tools_pass',
      title: 'Utility Tools Pass',
      description: 'Unlimited hint and undo access with ad-free progression.',
      priceLabel: '\$3.99',
      priceValue: 3.99,
      type: IapProductType.nonConsumable,
      badge: 'Utility',
      gate: _CatalogGate.utility,
    ),
  ];

  @override
  String get rolloutStrategy => _rolloutStrategy;

  @override
  Future<List<IapProduct>> loadCatalog() async {
    await _ensureInitialized();

    final Map<String, Object?> remoteConfig =
        await _remoteConfigRepository.getCached();
    final bool includeBundle = _readBool(
      remoteConfig['iap.bundle_enabled'],
      fallback: false,
    );
    final bool includeUtilityPass = _readBool(
      remoteConfig['iap.rewarded_tools_unlimited_enabled'],
      fallback: true,
    );
    _rolloutStrategy = _readString(
      remoteConfig['iap.rollout_strategy'],
      fallback: includeBundle ? 'cosmetics_bundle' : 'cosmetics_first',
    );

    final List<_CatalogEntry> enabled = _catalog
        .where(
          (_CatalogEntry e) =>
              e.gate == _CatalogGate.always ||
              (e.gate == _CatalogGate.bundle && includeBundle) ||
              (e.gate == _CatalogGate.utility && includeUtilityPass),
        )
        .toList(growable: false);

    if (!_available) {
      _logger.warn('Billing unavailable — serving fallback catalog metadata.');
      return enabled.map((_CatalogEntry e) => e.toFallbackProduct()).toList();
    }

    final Set<String> ids = enabled.map((_CatalogEntry e) => e.id).toSet();
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(ids);
    if (response.error != null) {
      _logger.warn(
        'queryProductDetails error: ${response.error!.code} '
        '${response.error!.message} — falling back to metadata.',
      );
      return enabled.map((_CatalogEntry e) => e.toFallbackProduct()).toList();
    }
    if (response.notFoundIDs.isNotEmpty) {
      _logger.warn(
        'Store did not return products: ${response.notFoundIDs.join(', ')}',
      );
    }

    final Map<String, ProductDetails> byId = <String, ProductDetails>{
      for (final ProductDetails p in response.productDetails) p.id: p,
    };
    return enabled.map((_CatalogEntry e) {
      final ProductDetails? details = byId[e.id];
      return details == null
          ? e.toFallbackProduct()
          : e.toStoreProduct(details);
    }).toList(growable: false);
  }

  @override
  Future<Set<String>> loadOwnedProductIds() async {
    final PlayerProgressState? progress = await _playerProgressRepository.load();
    return progress?.ownedProductIds ?? <String>{};
  }

  @override
  Future<IapPurchaseResult> purchase({
    required IapProduct product,
  }) async {
    await _ensureInitialized();
    if (!_available) {
      return IapPurchaseResult.failed(
        errorCode: 'billing_unavailable',
        message: 'Google Play Billing is not available on this device.',
      );
    }

    final Set<String> owned = await loadOwnedProductIds();
    if (owned.contains(product.id)) {
      return IapPurchaseResult.cancelled('already_owned');
    }
    if (_pendingPurchases.containsKey(product.id)) {
      return IapPurchaseResult.failed(
        errorCode: 'purchase_in_progress',
        message: 'A purchase for ${product.id} is already in progress.',
      );
    }

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(<String>{product.id});
    if (response.error != null || response.productDetails.isEmpty) {
      return IapPurchaseResult.failed(
        errorCode: 'product_unavailable',
        message: response.error?.message ??
            'Product ${product.id} is not available in the store.',
      );
    }

    final Completer<IapPurchaseResult> completer =
        Completer<IapPurchaseResult>();
    _pendingPurchases[product.id] = completer;

    final PurchaseParam param = PurchaseParam(
      productDetails: response.productDetails.first,
    );
    final bool started;
    try {
      started = await _iap.buyNonConsumable(purchaseParam: param);
    } catch (error) {
      _pendingPurchases.remove(product.id);
      return IapPurchaseResult.failed(
        errorCode: 'purchase_request_failed',
        message: '$error',
      );
    }
    if (!started) {
      _pendingPurchases.remove(product.id);
      return IapPurchaseResult.failed(
        errorCode: 'purchase_request_failed',
        message: 'buyNonConsumable returned false for ${product.id}.',
      );
    }

    return completer.future.timeout(
      _purchaseTimeout,
      onTimeout: () {
        _pendingPurchases.remove(product.id);
        return IapPurchaseResult.failed(
          errorCode: 'purchase_timeout',
          message: 'No terminal purchase update for ${product.id}.',
        );
      },
    );
  }

  @override
  Future<Set<String>> restorePurchases() async {
    await _ensureInitialized();
    if (!_available) {
      return loadOwnedProductIds();
    }
    await _iap.restorePurchases();
    // Restored items arrive on the purchase stream and are validated +
    // persisted by [_handlePurchase]. Allow a short window for delivery.
    await Future<void>.delayed(_restoreWindow);
    return loadOwnedProductIds();
  }

  /// Cancels the purchase-stream subscription. Call when the service is torn
  /// down; as a lazy singleton it normally lives for the whole app session.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _ensureInitialized() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      _available = await _iap.isAvailable();
    } catch (error) {
      _available = false;
      _logger.warn('InAppPurchase.isAvailable threw: $error');
    }
    if (!_available) {
      return;
    }
    _subscription = _iap.purchaseStream.listen(
      _onPurchasesUpdated,
      onError: (Object error) => _logger.warn('purchaseStream error: $error'),
    );
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        return;
      case PurchaseStatus.canceled:
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        _resolve(purchase.productID, IapPurchaseResult.cancelled('canceled'));
        return;
      case PurchaseStatus.error:
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        _resolve(
          purchase.productID,
          IapPurchaseResult.failed(
            errorCode: purchase.error?.code ?? 'purchase_error',
            message: purchase.error?.message,
          ),
        );
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _handleVerifiedFlow(purchase);
        return;
    }
  }

  Future<void> _handleVerifiedFlow(PurchaseDetails purchase) async {
    final String source =
        purchase.status == PurchaseStatus.restored ? 'restore' : 'purchase';
    final ReceiptValidationResult validation = await _receiptValidator.validate(
      productId: purchase.productID,
      purchaseToken: purchase.verificationData.serverVerificationData,
      source: source,
    );

    if (!validation.isValid) {
      // Do NOT acknowledge an unverified purchase: leaving it un-completed lets
      // Play re-deliver it for another validation attempt instead of granting
      // (or refunding) a potentially fraudulent token.
      _logger.warn(
        'Receipt rejected for ${purchase.productID} '
        '[${validation.errorCode}] ($source).',
      );
      _resolve(
        purchase.productID,
        IapPurchaseResult.failed(
          errorCode: validation.errorCode ?? 'receipt_invalid',
          message: validation.message,
        ),
      );
      return;
    }

    await _grantEntitlements(<String>{
      purchase.productID,
      ...validation.entitlements,
    });
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
    _resolve(purchase.productID, IapPurchaseResult.success());
  }

  Future<void> _grantEntitlements(Set<String> productIds) async {
    final PlayerProgressState existing =
        await _playerProgressRepository.load() ??
            PlayerProgressState.initialForDay(DateTime.now().toUtc());
    final Set<String> nextOwned = <String>{
      ...existing.ownedProductIds,
      ...productIds,
    };
    if (nextOwned.length == existing.ownedProductIds.length) {
      return;
    }
    await _playerProgressRepository.save(
      existing.copyWith(ownedProductIds: nextOwned),
    );
  }

  void _resolve(String productId, IapPurchaseResult result) {
    final Completer<IapPurchaseResult>? completer =
        _pendingPurchases.remove(productId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  bool _readBool(
    Object? rawValue, {
    required bool fallback,
  }) {
    if (rawValue is bool) {
      return rawValue;
    }
    if (rawValue is num) {
      return rawValue > 0;
    }
    if (rawValue is String) {
      final String normalized = rawValue.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return fallback;
  }

  String _readString(
    Object? rawValue, {
    required String fallback,
  }) {
    if (rawValue is String && rawValue.trim().isNotEmpty) {
      return rawValue.trim();
    }
    return fallback;
  }
}

enum _CatalogGate { always, bundle, utility }

class _CatalogEntry {
  const _CatalogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.priceValue,
    required this.type,
    required this.gate,
    this.badge,
  });

  final String id;
  final String title;
  final String description;
  final String priceLabel;
  final double priceValue;
  final IapProductType type;
  final _CatalogGate gate;
  final String? badge;

  /// Catalog entry rendered from local metadata (store unavailable / SKU not
  /// configured yet). Prices are placeholders until the store responds.
  IapProduct toFallbackProduct() {
    return IapProduct(
      id: id,
      title: title,
      description: description,
      priceLabel: priceLabel,
      priceValue: priceValue,
      currencyCode: 'USD',
      type: type,
      badge: badge,
    );
  }

  /// Catalog entry enriched with live, localized store pricing.
  IapProduct toStoreProduct(ProductDetails details) {
    return IapProduct(
      id: id,
      title: details.title.isEmpty ? title : details.title,
      description: details.description.isEmpty ? description : details.description,
      priceLabel: details.price,
      priceValue: details.rawPrice,
      currencyCode: details.currencyCode,
      type: type,
      badge: badge,
    );
  }
}
