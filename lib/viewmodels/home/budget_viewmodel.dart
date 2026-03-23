import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/shopping_item.dart';
import '../../data/interfaces/repositories/ibudget_repository.dart';

class BudgetViewModel extends ChangeNotifier {
  final IBudgetRepository _repository;

  List<ShoppingCategory> categories = [];
  bool isLoading = true;

  BudgetViewModel(this._repository) {
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading = true;
    notifyListeners();

    categories = await _repository.loadCategories();

    isLoading = false;
    notifyListeners();
  }

  Future<void> _saveData() async {
    await _repository.saveCategories(categories);
  }

  double get totalTargetApp =>
      categories.fold(0.0, (sum, cat) => sum + cat.totalTargetBudget);
  double get totalSpentApp =>
      categories.fold(0.0, (sum, cat) => sum + cat.totalSpent);
  double get appBudgetUsageRatio {
    if (totalTargetApp <= 0) {
      return totalSpentApp > 0 ? 1 : 0;
    }
    return totalSpentApp / totalTargetApp;
  }

  BudgetAlertLevel get appAlertLevel {
    final ratio = appBudgetUsageRatio;
    if (ratio >= 1.2) return BudgetAlertLevel.critical120;
    if (ratio >= 1.0) return BudgetAlertLevel.danger100;
    if (ratio >= 0.8) return BudgetAlertLevel.warning80;
    return BudgetAlertLevel.safe;
  }

  void addItemToCategory(ShoppingCategory category, ShoppingItem item) {
    if (item.currentPrice > 0 && item.priceHistory.isEmpty) {
      _recordPriceHistory(item, item.currentPrice);
    }
    category.items.add(item);
    _saveData();
    notifyListeners();
  }

  void insertItemToCategory(
    ShoppingCategory category,
    int index,
    ShoppingItem item,
  ) {
    final safeIndex = index.clamp(0, category.items.length);
    category.items.insert(safeIndex, item);
    _saveData();
    notifyListeners();
  }

  void updateItemState(
    ShoppingItem item,
    bool isPurchased,
    double currentPrice,
  ) {
    final previousPrice = item.currentPrice;
    item.isPurchased = isPurchased;
    item.currentPrice = currentPrice;
    item.purchasedDate = isPurchased
        ? (item.purchasedDate ?? DateTime.now())
        : null;
    if (currentPrice > 0 && previousPrice != currentPrice) {
      _recordPriceHistory(item, currentPrice);
    }
    _saveData();
    notifyListeners();
  }

  void updateExistingItem(ShoppingItem oldItem, ShoppingItem newItem) {
    final previousPrice = oldItem.currentPrice;
    oldItem.name = newItem.name;
    oldItem.targetPrice = newItem.targetPrice;
    oldItem.currentPrice = newItem.currentPrice;
    oldItem.isPurchased = newItem.isPurchased;
    oldItem.imagePath = newItem.imagePath;
    oldItem.purchasedDate = newItem.isPurchased ? newItem.purchasedDate : null;
    oldItem.priceHistory = List<PriceLog>.from(newItem.priceHistory);
    if (newItem.currentPrice > 0 && previousPrice != newItem.currentPrice) {
      _recordPriceHistory(oldItem, newItem.currentPrice);
    }
    _saveData();
    notifyListeners();
  }

  void deleteItem(ShoppingCategory category, ShoppingItem item) {
    category.items.remove(item);
    _saveData();
    notifyListeners();
  }

  void addCategory(String title, String iconStr) {
    categories.add(
      ShoppingCategory(
        id: DateTime.now().toString(),
        title: title,
        iconStr: iconStr,
        items: [],
      ),
    );
    _saveData();
    notifyListeners();
  }

  void updateCategory(
    ShoppingCategory category,
    String newTitle,
    String newIconStr,
  ) {
    category.title = newTitle;
    category.iconStr = newIconStr;
    _saveData();
    notifyListeners();
  }

  void deleteCategory(ShoppingCategory category) {
    categories.remove(category);
    _saveData();
    notifyListeners();
  }

  void _recordPriceHistory(ShoppingItem item, double newPrice) {
    if (newPrice <= 0) return;

    final now = DateTime.now();
    final logs = item.priceHistory;
    if (logs.isNotEmpty) {
      final latest = (List<PriceLog>.from(
        logs,
      )..sort((a, b) => a.observedAt.compareTo(b.observedAt))).last;
      final sameDay =
          latest.observedAt.year == now.year &&
          latest.observedAt.month == now.month &&
          latest.observedAt.day == now.day;
      if (sameDay && latest.price == newPrice) {
        return;
      }
    }

    logs.add(PriceLog(price: newPrice, observedAt: now));
  }
}
