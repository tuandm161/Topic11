class PriceLogDto {
  final double price;
  final String observedAt;

  const PriceLogDto({required this.price, required this.observedAt});

  Map<String, dynamic> toJson() {
    return {'price': price, 'observedAt': observedAt};
  }

  factory PriceLogDto.fromJson(Map<String, dynamic> json) {
    return PriceLogDto(
      price: (json['price'] as num?)?.toDouble() ?? 0,
      observedAt: json['observedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class ShoppingItemDto {
  final String id;
  final String name;
  final double targetPrice;
  final double currentPrice;
  final bool isPurchased;
  final String? imagePath;
  final String dateAdded;
  final String? purchasedDate;
  final List<PriceLogDto> priceHistory;

  ShoppingItemDto({
    required this.id,
    required this.name,
    required this.targetPrice,
    required this.currentPrice,
    required this.isPurchased,
    this.imagePath,
    required this.dateAdded,
    this.purchasedDate,
    this.priceHistory = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetPrice': targetPrice,
      'currentPrice': currentPrice,
      'isPurchased': isPurchased,
      'imagePath': imagePath,
      'dateAdded': dateAdded,
      'purchasedDate': purchasedDate,
      'priceHistory': priceHistory.map((log) => log.toJson()).toList(),
    };
  }

  factory ShoppingItemDto.fromJson(Map<String, dynamic> json) {
    return ShoppingItemDto(
      id: json['id'],
      name: json['name'],
      targetPrice: (json['targetPrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      isPurchased: json['isPurchased'] ?? false,
      imagePath: json['imagePath'],
      dateAdded: json['dateAdded'] ?? DateTime.now().toIso8601String(),
      purchasedDate: json['purchasedDate'],
      priceHistory:
          (json['priceHistory'] as List<dynamic>?)
              ?.map(
                (entry) => PriceLogDto.fromJson(entry as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
