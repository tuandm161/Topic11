import 'shopping_item.dart';

enum BudgetAlertLevel { safe, warning80, danger100, critical120 }

class ShoppingCategory {
  String id;
  String title;
  String iconStr; // Dùng Emoji làm icon cho đơn giản
  List<ShoppingItem> items;

  ShoppingCategory({
    required this.id,
    required this.title,
    required this.iconStr,
    this.items = const [],
  });

  // Tính tổng số tiền ngân sách mục tiêu của hạng mục này
  double get totalTargetBudget {
    return items.fold(0.0, (sum, item) => sum + item.targetPrice);
  }

  // Tính tổng số tiền đã chi thực tế
  double get totalSpent {
    return items.fold(0.0, (sum, item) {
      if (item.isPurchased) {
        return sum + item.currentPrice;
      }
      return sum;
    });
  }

  // Còn lại bao nhiêu tiền
  double get remainingBudget => totalTargetBudget - totalSpent;

  double get budgetUsageRatio {
    if (totalTargetBudget <= 0) {
      return totalSpent > 0 ? 1 : 0;
    }
    return totalSpent / totalTargetBudget;
  }

  BudgetAlertLevel get alertLevel {
    final ratio = budgetUsageRatio;
    if (ratio >= 1.2) return BudgetAlertLevel.critical120;
    if (ratio >= 1.0) return BudgetAlertLevel.danger100;
    if (ratio >= 0.8) return BudgetAlertLevel.warning80;
    return BudgetAlertLevel.safe;
  }
}
