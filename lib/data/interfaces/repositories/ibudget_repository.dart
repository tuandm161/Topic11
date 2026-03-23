import '../../../domain/entities/category.dart';

abstract class IBudgetRepository {
  Future<List<ShoppingCategory>> loadCategories();
  Future<void> saveCategories(List<ShoppingCategory> categories);
}
