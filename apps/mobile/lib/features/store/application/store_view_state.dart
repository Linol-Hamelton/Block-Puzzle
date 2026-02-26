import '../../monetization/iap_product.dart';

class StoreViewState {
  const StoreViewState({
    required this.isLoading,
    required this.isPurchasing,
    required this.products,
    required this.ownedProductIds,
    required this.rolloutStrategy,
    required this.offerStrategyVariant,
    required this.userSegment,
    required this.targetedProductIds,
    this.message,
    this.recommendedProductId,
  });

  final bool isLoading;
  final bool isPurchasing;
  final List<IapProduct> products;
  final Set<String> ownedProductIds;
  final String rolloutStrategy;
  final String offerStrategyVariant;
  final String userSegment;
  final List<String> targetedProductIds;
  final String? message;
  final String? recommendedProductId;

  factory StoreViewState.initial() {
    return const StoreViewState(
      isLoading: true,
      isPurchasing: false,
      products: <IapProduct>[],
      ownedProductIds: <String>{},
      rolloutStrategy: 'cosmetics_first',
      offerStrategyVariant: 'cosmetics_first_v1',
      userSegment: 'new_user',
      targetedProductIds: <String>[],
      message: null,
      recommendedProductId: null,
    );
  }

  StoreViewState copyWith({
    bool? isLoading,
    bool? isPurchasing,
    List<IapProduct>? products,
    Set<String>? ownedProductIds,
    String? rolloutStrategy,
    String? offerStrategyVariant,
    String? userSegment,
    List<String>? targetedProductIds,
    String? message,
    String? recommendedProductId,
    bool resetMessage = false,
    bool resetRecommendedProduct = false,
  }) {
    return StoreViewState(
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      products: products ?? this.products,
      ownedProductIds: ownedProductIds ?? this.ownedProductIds,
      rolloutStrategy: rolloutStrategy ?? this.rolloutStrategy,
      offerStrategyVariant: offerStrategyVariant ?? this.offerStrategyVariant,
      userSegment: userSegment ?? this.userSegment,
      targetedProductIds: targetedProductIds ?? this.targetedProductIds,
      message: resetMessage ? null : (message ?? this.message),
      recommendedProductId: resetRecommendedProduct
          ? null
          : (recommendedProductId ?? this.recommendedProductId),
    );
  }
}
