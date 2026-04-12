import '../../core/logging/app_logger.dart';
import '../../data/remote_config/remote_config_repository.dart';
import '../../domain/progression/player_progress_repository.dart';
import '../../domain/progression/player_progress_state.dart';
import 'iap_product.dart';
import 'iap_purchase_result.dart';
import 'iap_store_service.dart';

class LocalCatalogIapStoreService implements IapStoreService {
  LocalCatalogIapStoreService({
    required PlayerProgressRepository playerProgressRepository,
    required RemoteConfigRepository remoteConfigRepository,
    required AppLogger logger,
    this.allowLocalPurchases = true,
  })  : _playerProgressRepository = playerProgressRepository,
        _remoteConfigRepository = remoteConfigRepository,
        _logger = logger;

  final PlayerProgressRepository _playerProgressRepository;
  final RemoteConfigRepository _remoteConfigRepository;
  final AppLogger _logger;
  final bool allowLocalPurchases;

  String _rolloutStrategy = 'cosmetics_first';

  static const List<IapProduct> _cosmeticsCatalog = <IapProduct>[
    IapProduct(
      id: 'skin_pack_neon',
      title: 'Neon Skin Pack',
      description: 'Vibrant board and block colors for high-energy sessions.',
      priceLabel: '\$1.99',
      priceValue: 1.99,
      currencyCode: 'USD',
      type: IapProductType.nonConsumable,
      badge: 'Popular',
    ),
    IapProduct(
      id: 'skin_pack_mono',
      title: 'Mono Elegance',
      description: 'Minimal high-contrast theme tuned for long focus play.',
      priceLabel: '\$2.99',
      priceValue: 2.99,
      currencyCode: 'USD',
      type: IapProductType.nonConsumable,
    ),
  ];

  static const IapProduct _bundle = IapProduct(
    id: 'premium_starter_bundle',
    title: 'Starter Bundle',
    description: 'Premium visual pack + exclusive profile badge.',
    priceLabel: '\$4.99',
    priceValue: 4.99,
    currencyCode: 'USD',
    type: IapProductType.nonConsumable,
    badge: 'Best Value',
  );

  static const IapProduct _utilityPass = IapProduct(
    id: 'utility_tools_pass',
    title: 'Utility Tools Pass',
    description: 'Unlimited hint and undo access with ad-free progression.',
    priceLabel: '\$3.99',
    priceValue: 3.99,
    currencyCode: 'USD',
    type: IapProductType.nonConsumable,
    badge: 'Utility',
  );

  @override
  String get rolloutStrategy => _rolloutStrategy;

  @override
  Future<List<IapProduct>> loadCatalog() async {
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

    final List<IapProduct> catalog = <IapProduct>[
      ..._cosmeticsCatalog,
    ];
    if (includeBundle) {
      catalog.add(_bundle);
    }
    if (includeUtilityPass) {
      catalog.add(_utilityPass);
    }
    return catalog;
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
    if (!allowLocalPurchases) {
      _logger.warn('Local purchase disabled for ${product.id}');
      return IapPurchaseResult.failed(
        errorCode: 'billing_unavailable',
        message: 'billing_unavailable',
      );
    }

    final PlayerProgressState progress = await _loadOrCreateProgress();
    if (progress.ownedProductIds.contains(product.id)) {
      return IapPurchaseResult.cancelled('already_owned');
    }

    final Set<String> nextOwnedIds = <String>{
      ...progress.ownedProductIds,
      product.id,
    };
    final PlayerProgressState updated = progress.copyWith(
      ownedProductIds: nextOwnedIds,
    );
    await _playerProgressRepository.save(updated);
    return IapPurchaseResult.success();
  }

  @override
  Future<Set<String>> restorePurchases() async {
    return loadOwnedProductIds();
  }

  Future<PlayerProgressState> _loadOrCreateProgress() async {
    final PlayerProgressState? existing = await _playerProgressRepository.load();
    if (existing != null) {
      return existing;
    }
    return PlayerProgressState.initialForDay(DateTime.now().toUtc());
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
