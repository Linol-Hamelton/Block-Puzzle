import '../../monetization/iap_product.dart';

class StoreViewState {
  const StoreViewState({
    required this.isLoading,
    required this.isPurchasing,
    required this.products,
    required this.ownedProductIds,
    required this.rolloutStrategy,
    this.message,
  });

  final bool isLoading;
  final bool isPurchasing;
  final List<IapProduct> products;
  final Set<String> ownedProductIds;
  final String rolloutStrategy;
  final String? message;

  factory StoreViewState.initial() {
    return const StoreViewState(
      isLoading: true,
      isPurchasing: false,
      products: <IapProduct>[],
      ownedProductIds: <String>{},
      rolloutStrategy: 'cosmetics_first',
      message: null,
    );
  }

  StoreViewState copyWith({
    bool? isLoading,
    bool? isPurchasing,
    List<IapProduct>? products,
    Set<String>? ownedProductIds,
    String? rolloutStrategy,
    String? message,
    bool resetMessage = false,
  }) {
    return StoreViewState(
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      products: products ?? this.products,
      ownedProductIds: ownedProductIds ?? this.ownedProductIds,
      rolloutStrategy: rolloutStrategy ?? this.rolloutStrategy,
      message: resetMessage ? null : (message ?? this.message),
    );
  }
}
