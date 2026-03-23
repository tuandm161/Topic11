import '../../../domain/entities/category.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../dtos/category_dto.dart';
import '../../dtos/shopping_item_dto.dart';

class BudgetMapper {
  static ShoppingItem toEntity(ShoppingItemDto dto) {
    return ShoppingItem(
      id: dto.id,
      name: dto.name,
      targetPrice: dto.targetPrice,
      currentPrice: dto.currentPrice,
      isPurchased: dto.isPurchased,
      imagePath: dto.imagePath,
      date: DateTime.tryParse(dto.dateAdded) ?? DateTime.now(),
      purchasedDate: DateTime.tryParse(dto.purchasedDate ?? ''),
      priceHistory: dto.priceHistory
          .map(
            (log) => PriceLog(
              price: log.price,
              observedAt: DateTime.tryParse(log.observedAt) ?? DateTime.now(),
            ),
          )
          .toList(),
    );
  }

  static ShoppingItemDto toDto(ShoppingItem entity) {
    return ShoppingItemDto(
      id: entity.id,
      name: entity.name,
      targetPrice: entity.targetPrice,
      currentPrice: entity.currentPrice,
      isPurchased: entity.isPurchased,
      imagePath: entity.imagePath,
      dateAdded: entity.dateAdded.toIso8601String(),
      purchasedDate: entity.purchasedDate?.toIso8601String(),
      priceHistory: entity.priceHistory
          .map(
            (log) => PriceLogDto(
              price: log.price,
              observedAt: log.observedAt.toIso8601String(),
            ),
          )
          .toList(),
    );
  }

  static ShoppingCategory categoryToEntity(CategoryDto dto) {
    return ShoppingCategory(
      id: dto.id,
      title: dto.title,
      iconStr: dto.iconStr,
      items: dto.items.map((item) => toEntity(item)).toList(),
    );
  }

  static CategoryDto categoryToDto(ShoppingCategory entity) {
    return CategoryDto(
      id: entity.id,
      title: entity.title,
      iconStr: entity.iconStr,
      items: entity.items.map((item) => toDto(item)).toList(),
    );
  }
}
