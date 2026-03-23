import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../domain/entities/category.dart';
import 'add_category_screen.dart';
import 'category_items_screen.dart';
import 'chart_screen.dart';
import 'di.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final budgetVM = DI.budgetViewModel;
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  _CategoryFilter _selectedFilter = _CategoryFilter.all;
  bool _showIntro = false;

  @override
  void initState() {
    super.initState();
    budgetVM.addListener(_onViewModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showIntro = true);
    });
  }

  @override
  void dispose() {
    budgetVM.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _filterCategories(budgetVM.categories);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Săn Sale Tết'),
        actions: [
          IconButton(
            tooltip: 'Báo cáo',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              _openChartScreen();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: budgetVM.isLoading
            ? const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                key: const ValueKey('content'),
                onRefresh: () async => setState(() {}),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                        offset: _showIntro
                            ? Offset.zero
                            : const Offset(0, 0.05),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 360),
                          opacity: _showIntro ? 1 : 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: _buildHeroSummaryCard(),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _buildFilterSection(),
                      ),
                    ),
                    if (filteredCategories.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyCategoriesView(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                        sliver: SliverList.builder(
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];
                            return _StaggeredReveal(
                              key: ValueKey('home-cat-${category.id}'),
                              index: index,
                              child: _buildCategoryCard(
                                category: category,
                                index: index,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCategory,
        icon: const Icon(Icons.add),
        label: const Text('Thêm hạng mục'),
      ),
    );
  }

  Widget _buildHeroSummaryCard() {
    final totalBudget = budgetVM.totalTargetApp;
    final totalSpent = budgetVM.totalSpentApp;
    final remaining = totalBudget - totalSpent;
    final appRatio = budgetVM.appBudgetUsageRatio;
    final progress = appRatio.clamp(0.0, 1.0);
    final appAlert = _alertVisualFor(
      budgetVM.appAlertLevel,
      ratio: budgetVM.appBudgetUsageRatio,
    );
    final purchasedItems = budgetVM.categories.fold<int>(
      0,
      (sum, category) =>
          sum + category.items.where((item) => item.isPurchased).length,
    );
    final allItems = budgetVM.categories.fold<int>(
      0,
      (sum, category) => sum + category.items.length,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE9D2), Color(0xFFFFD9B7), Color(0xFFF8C799)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFE8B689)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F9C5B2F),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -12,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng ngân sách mùa Tết',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4D221C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currencyFormat.format(totalBudget),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF311512),
                ),
              ),
              const SizedBox(height: 14),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.65),
                      valueColor: AlwaysStoppedAnimation(appAlert.color),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: appAlert.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: appAlert.color.withValues(alpha: 0.32),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(appAlert.icon, size: 19, color: appAlert.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appAlert.headline,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: appAlert.color,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appAlert.hint,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: appAlert.color.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      icon: Icons.payments_outlined,
                      label: 'Đã chi',
                      value: _currencyFormat.format(totalSpent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statTile(
                      icon: remaining < 0
                          ? Icons.warning_amber_rounded
                          : Icons.savings_outlined,
                      label: 'Còn lại',
                      value: _currencyFormat.format(remaining),
                      valueColor: remaining < 0
                          ? const Color(0xFFAF1F16)
                          : const Color(0xFF1B7A43),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: Color(0xFF5A302B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Đã hoàn thành $purchasedItems/$allItems món',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5A302B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5D342D)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F4F49),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? const Color(0xFF3F2824),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hạng mục mua sắm',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 21,
                color: const Color(0xFF4B2621),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _openChartScreen,
              icon: const Icon(Icons.stacked_bar_chart_rounded),
              label: const Text('Xem báo cáo'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _CategoryFilter.values.map((filter) {
            final selected = _selectedFilter == filter;
            return ChoiceChip(
              label: Text(filter.label),
              selected: selected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = filter);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required ShoppingCategory category,
    required int index,
  }) {
    final totalBudget = category.totalTargetBudget;
    final totalSpent = category.totalSpent;
    final remaining = totalBudget - totalSpent;
    final progress = category.budgetUsageRatio.clamp(0.0, 1.0);
    final alert = _alertVisualFor(
      category.alertLevel,
      ratio: category.budgetUsageRatio,
    );
    final purchasedCount = category.items
        .where((item) => item.isPurchased)
        .length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 230),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: 12, top: index == 0 ? 2 : 0),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            HapticFeedback.selectionClick();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryItemsScreen(category: category),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFF4E8),
                        border: Border.all(color: const Color(0xFFEAD5BF)),
                      ),
                      child: Text(
                        category.iconStr,
                        style: const TextStyle(fontSize: 21),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: const Color(0xFF41211D)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$purchasedCount/${category.items.length} món đã mua',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF6A524D),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _statusChip(
                      icon: alert.icon,
                      label: alert.chipLabel,
                      color: alert.color,
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Tùy chọn',
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result =
                              await Navigator.push<Map<String, dynamic>>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddCategoryScreen(
                                    existingCategory: category,
                                  ),
                                ),
                              );
                          if (result != null) {
                            HapticFeedback.lightImpact();
                            budgetVM.updateCategory(
                              category,
                              result['title'],
                              result['iconStr'],
                            );
                          }
                          return;
                        }
                        if (!mounted) return;
                        HapticFeedback.mediumImpact();
                        _showDeleteConfirmation(category);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Sửa hạng mục'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Xóa hạng mục'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mục tiêu: ${_currencyFormat.format(totalBudget)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF684E48),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _currencyFormat.format(totalSpent),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: alert.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF4ECE2),
                        valueColor: AlwaysStoppedAnimation(alert.color),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    remaining >= 0
                        ? category.alertLevel == BudgetAlertLevel.safe
                              ? 'Còn dư ${_currencyFormat.format(remaining)}'
                              : 'Đã dùng ${_ratioLabel(category.budgetUsageRatio)} ngân sách · Còn dư ${_currencyFormat.format(remaining)}'
                        : 'Quá ${_currencyFormat.format(remaining.abs())} so với kế hoạch',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          remaining >= 0 &&
                              category.alertLevel == BudgetAlertLevel.safe
                          ? const Color(0xFF2E7D32)
                          : alert.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _AlertVisual _alertVisualFor(
    BudgetAlertLevel level, {
    required double ratio,
  }) {
    switch (level) {
      case BudgetAlertLevel.safe:
        return _AlertVisual(
          color: const Color(0xFF2D7D4C),
          backgroundColor: const Color(0xFFE9F7EF),
          icon: Icons.check_circle_outline_rounded,
          chipLabel: 'Đang ổn',
          headline: 'Ngân sách đang ổn định',
          hint: 'Đã dùng ${_ratioLabel(ratio)} ngân sách.',
        );
      case BudgetAlertLevel.warning80:
        return _AlertVisual(
          color: const Color(0xFFB87400),
          backgroundColor: const Color(0xFFFFF1DD),
          icon: Icons.priority_high_rounded,
          chipLabel: 'Sắp chạm trần',
          headline: 'Ngân sách đã qua mốc 80%',
          hint: 'Đã dùng ${_ratioLabel(ratio)}. Nên ưu tiên deal tốt.',
        );
      case BudgetAlertLevel.danger100:
        return _AlertVisual(
          color: const Color(0xFFB3261E),
          backgroundColor: const Color(0xFFFCEBEB),
          icon: Icons.warning_amber_rounded,
          chipLabel: 'Chạm ngân sách',
          headline: 'Đã chạm mốc 100%',
          hint: 'Đã dùng ${_ratioLabel(ratio)}. Cần siết chi tiêu ngay.',
        );
      case BudgetAlertLevel.critical120:
        return _AlertVisual(
          color: const Color(0xFF7E1A12),
          backgroundColor: const Color(0xFFF8E3E2),
          icon: Icons.error_outline_rounded,
          chipLabel: 'Vượt nghiêm trọng',
          headline: 'Đã vượt trên mốc 120%',
          hint: 'Đã dùng ${_ratioLabel(ratio)}. Nên giảm bớt món ưu tiên thấp.',
        );
    }
  }

  String _ratioLabel(double ratio) {
    if (ratio.isNaN || ratio.isInfinite || ratio <= 0) return '0%';
    return '${(ratio * 100).clamp(0, 999).toStringAsFixed(0)}%';
  }

  List<ShoppingCategory> _filterCategories(List<ShoppingCategory> categories) {
    return categories.where((category) {
      switch (_selectedFilter) {
        case _CategoryFilter.all:
          return true;
        case _CategoryFilter.safe:
          return category.alertLevel == BudgetAlertLevel.safe ||
              category.alertLevel == BudgetAlertLevel.warning80;
        case _CategoryFilter.over:
          return category.alertLevel == BudgetAlertLevel.danger100 ||
              category.alertLevel == BudgetAlertLevel.critical120;
        case _CategoryFilter.empty:
          return category.items.isEmpty;
      }
    }).toList();
  }

  Future<void> _openAddCategory() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
    );
    if (result != null) {
      HapticFeedback.lightImpact();
      budgetVM.addCategory(result['title'], result['iconStr']);
    }
  }

  void _openChartScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChartScreen(categories: budgetVM.categories),
      ),
    );
  }

  void _showDeleteConfirmation(ShoppingCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hạng mục'),
        content: Text('Xóa "${category.title}" và toàn bộ món trong mục này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              budgetVM.deleteCategory(category);
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

enum _CategoryFilter {
  all('Tất cả'),
  safe('Trong ngân sách'),
  over('Vượt ngân sách'),
  empty('Chưa có món');

  final String label;
  const _CategoryFilter(this.label);
}

class _AlertVisual {
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final String chipLabel;
  final String headline;
  final String hint;

  const _AlertVisual({
    required this.color,
    required this.backgroundColor,
    required this.icon,
    required this.chipLabel,
    required this.headline,
    required this.hint,
  });
}

class _StaggeredReveal extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredReveal({super.key, required this.index, required this.child});

  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delayMs = (widget.index * 45).clamp(0, 240);
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.04),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _EmptyCategoriesView extends StatelessWidget {
  const _EmptyCategoriesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 58,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa có hạng mục phù hợp',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3C2521),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thêm hạng mục mới hoặc đổi bộ lọc để tiếp tục.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5B57)),
            ),
          ],
        ),
      ),
    );
  }
}
