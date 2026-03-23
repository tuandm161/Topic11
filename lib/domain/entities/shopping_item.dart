enum DealLevel { unknown, good, warning }

enum PriceTrend { unknown, down, flat, up }

class PriceLog {
  final double price;
  final DateTime observedAt;

  const PriceLog({required this.price, required this.observedAt});
}

class ShoppingItem {
  String id;
  String name;
  double targetPrice;
  double currentPrice;
  bool isPurchased;
  String? imagePath; // Đường dẫn ảnh hóa đơn/sản phẩm (tuỳ chọn)
  DateTime dateAdded;
  DateTime? purchasedDate;
  List<PriceLog> priceHistory;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.targetPrice,
    this.currentPrice = 0.0,
    this.isPurchased = false,
    this.imagePath,
    DateTime? date,
    this.purchasedDate,
    List<PriceLog>? priceHistory,
  }) : dateAdded = date ?? DateTime.now(),
       priceHistory = priceHistory ?? [];

  // Kiểm tra xem có đang bị "hớ" giá không (Vượt ngân sách dự kiến)
  bool get isOverBudget => currentPrice > targetPrice;

  double get dealDelta => currentPrice - targetPrice;

  DealLevel get dealLevel {
    if (currentPrice <= 0) return DealLevel.unknown;
    return currentPrice <= targetPrice ? DealLevel.good : DealLevel.warning;
  }

  double? get latestObservedPrice {
    if (priceHistory.isEmpty) return null;
    final sorted = List<PriceLog>.from(priceHistory)
      ..sort((a, b) => a.observedAt.compareTo(b.observedAt));
    return sorted.last.price;
  }

  double? get lowestObservedPrice {
    if (priceHistory.isEmpty) return null;
    return priceHistory.map((log) => log.price).reduce((a, b) => a < b ? a : b);
  }

  PriceTrend get priceTrend {
    if (priceHistory.length < 2) return PriceTrend.unknown;

    final sorted = List<PriceLog>.from(priceHistory)
      ..sort((a, b) => a.observedAt.compareTo(b.observedAt));
    final previous = sorted[sorted.length - 2].price;
    final latest = sorted.last.price;

    if (latest > previous) return PriceTrend.up;
    if (latest < previous) return PriceTrend.down;
    return PriceTrend.flat;
  }
}
