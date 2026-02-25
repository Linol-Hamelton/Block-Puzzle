import 'iap_product.dart';
import 'iap_purchase_result.dart';

abstract interface class IapStoreService {
  Future<List<IapProduct>> loadCatalog();

  Future<Set<String>> loadOwnedProductIds();

  Future<IapPurchaseResult> purchase({
    required IapProduct product,
  });

  Future<Set<String>> restorePurchases();
}
