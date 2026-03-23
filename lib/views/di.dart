import '../viewmodels/home/budget_viewmodel.dart';
import '../data/implementations/repositories/local_budget_repository.dart';

class DI {
  // Simple static instance matching the user's required DI view
  static final BudgetViewModel budgetViewModel = BudgetViewModel(
    LocalBudgetRepository(),
  );
}
