import 'shopping_item_dto.dart';

class CategoryDto {
  final String id;
  final String title;
  final String iconStr;
  final List<ShoppingItemDto> items;

  CategoryDto({
    required this.id,
    required this.title,
    required this.iconStr,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'iconStr': iconStr,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'],
      title: json['title'],
      iconStr: json['iconStr'],
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) =>
                    ShoppingItemDto.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
