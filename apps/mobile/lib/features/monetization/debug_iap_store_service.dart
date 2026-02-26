import 'dart:async';

import 'iap_product.dart';
import 'iap_purchase_result.dart';
import 'iap_store_service.dart';

class DebugIapStoreService implements IapStoreService {
  DebugIapStoreService({
    this.includeBundle = false,
    this.includeUtilityPass = true,
  });

  final bool includeBundle;
  final bool includeUtilityPass;
  final Set<String> _ownedProductIds = <String>{};

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
    description: 'Unlimited hint and undo access (ad-free strategy).',
    priceLabel: '\$3.99',
    priceValue: 3.99,
    currencyCode: 'USD',
    type: IapProductType.nonConsumable,
    badge: 'Utility',
  );

  @override
  String get rolloutStrategy =>
      includeBundle ? 'cosmetics_bundle' : 'cosmetics_first';

  List<IapProduct> get _catalog {
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
  Future<List<IapProduct>> loadCatalog() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _catalog;
  }

  @override
  Future<Set<String>> loadOwnedProductIds() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return Set<String>.from(_ownedProductIds);
  }

  @override
  Future<IapPurchaseResult> purchase({
    required IapProduct product,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (_ownedProductIds.contains(product.id)) {
      return IapPurchaseResult.cancelled('already_owned');
    }
    _ownedProductIds.add(product.id);
    return IapPurchaseResult.success();
  }

  @override
  Future<Set<String>> restorePurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    return Set<String>.from(_ownedProductIds);
  }
}
