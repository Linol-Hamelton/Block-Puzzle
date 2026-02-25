enum IapProductType {
  consumable,
  nonConsumable,
  subscription,
}

class IapProduct {
  const IapProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.priceValue,
    required this.currencyCode,
    required this.type,
    this.badge,
  });

  final String id;
  final String title;
  final String description;
  final String priceLabel;
  final double priceValue;
  final String currencyCode;
  final IapProductType type;
  final String? badge;
}
