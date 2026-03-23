import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../domain/entities/category.dart';
import '../domain/entities/shopping_item.dart';
import 'add_item_screen.dart';
import 'di.dart';

class CategoryItemsScreen extends StatefulWidget {
  final ShoppingCategory category;

  const CategoryItemsScreen({super.key, required this.category});

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  final budgetVM = DI.budgetViewModel;
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _searchController = TextEditingController();

  _ItemFilter _selectedFilter = _ItemFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    budgetVM.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    budgetVM.removeListener(_onViewModelChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filterItems(widget.category.items);
    final purchasedCount = widget.category.items
        .where((item) => item.isPurchased)
        .length;
    final totalBudget = widget.category.totalTargetBudget;
    final totalSpent = widget.category.totalSpent;
    final usageRatio = widget.category.budgetUsageRatio;
    final progress = usageRatio.clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.iconStr} ${widget.category.title}'),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: _buildCategorySummary(
                purchasedCount: purchasedCount,
                totalCount: widget.category.items.length,
                totalBudget: totalBudget,
                totalSpent: totalSpent,
                progress: progress,
                usageRatio: usageRatio,
                alertLevel: widget.category.alertLevel,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Tìm món cần mua...',
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ItemFilter.values.map((filter) {
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: _selectedFilter == filter,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = filter);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          if (filteredItems.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyItemsView(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _StaggeredReveal(
                    key: ValueKey('cat-item-${item.id}'),
                    index: index,
                    child: Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB3261E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) {
                        HapticFeedback.heavyImpact();
                        final originalIndex = widget.category.items.indexOf(
                          item,
                        );
                        budgetVM.deleteItem(widget.category, item);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã xóa: ${item.name}'),
                            action: SnackBarAction(
                              label: 'Hoàn tác',
                              onPressed: () {
                                budgetVM.insertItemToCategory(
                                  widget.category,
                                  originalIndex,
                                  item,
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: _buildItemCard(item),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewItem,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Thêm món'),
      ),
    );
  }

  Widget _buildCategorySummary({
    required int purchasedCount,
    required int totalCount,
    required double totalBudget,
    required double totalSpent,
    required double progress,
    required double usageRatio,
    required BudgetAlertLevel alertLevel,
  }) {
    final alert = _categoryAlertVisual(alertLevel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEEDC), Color(0xFFFFE0C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFE8C69F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến độ hạng mục',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: const Color(0xFF4A261F)),
          ),
          const SizedBox(height: 8),
          Text(
            '$purchasedCount/$totalCount món đã mua',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF65443F),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: alert.backgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(alert.icon, size: 15, color: alert.color),
                const SizedBox(width: 5),
                Text(
                  alert.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: alert.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              valueColor: AlwaysStoppedAnimation(alert.color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mục tiêu ${_currencyFormat.format(totalBudget)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF634640),
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
          const SizedBox(height: 6),
          Text(
            'Đã dùng ${(usageRatio * 100).clamp(0, 999).toStringAsFixed(0)}%',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF665551)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ShoppingItem item) {
    final target = item.targetPrice;
    final current = item.currentPrice;
    final hasCurrent = current > 0;
    final isDealGood = hasCurrent && current <= target;
    final isWarning = hasCurrent && current > target;
    final trend = _trendVisualFor(item.priceTrend);
    final lowestObserved = item.lowestObservedPrice;

    final badgeBg = switch (item.dealLevel) {
      DealLevel.good => const Color(0xFFE8F5E9),
      DealLevel.warning => const Color(0xFFFCEBEB),
      DealLevel.unknown => const Color(0xFFF4F4F4),
    };

    final badgeTextColor = switch (item.dealLevel) {
      DealLevel.good => const Color(0xFF1B5E20),
      DealLevel.warning => const Color(0xFFB3261E),
      DealLevel.unknown => const Color(0xFF595959),
    };

    final badgeText = switch (item.dealLevel) {
      DealLevel.good =>
        'Deal tốt ${_currencyFormat.format(item.dealDelta.abs())}',
      DealLevel.warning =>
        'Vượt mục tiêu ${_currencyFormat.format(item.dealDelta)}',
      DealLevel.unknown => 'Chưa có giá deal',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _editItem(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: item.isPurchased,
                onChanged: (value) async {
                  if (value == true) {
                    HapticFeedback.lightImpact();
                    await _editItem(item);
                  } else {
                    HapticFeedback.selectionClick();
                    budgetVM.updateItemState(item, false, item.currentPrice);
                  }
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  decoration: item.isPurchased
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                        ),
                        if (!item.isPurchased && item.currentPrice > 0)
                          IconButton(
                            tooltip: 'Mua ngay',
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              budgetVM.updateItemState(
                                item,
                                true,
                                item.currentPrice,
                              );
                            },
                            icon: const Icon(Icons.task_alt_rounded),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mục tiêu: ${_currencyFormat.format(target)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF65524E),
                      ),
                    ),
                    Text(
                      hasCurrent
                          ? 'Giá hiện tại: ${_currencyFormat.format(current)}'
                          : 'Giá hiện tại: chưa nhập',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isWarning
                            ? const Color(0xFFB3261E)
                            : (isDealGood
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFF65524E)),
                        fontWeight: hasCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (item.priceHistory.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: trend.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: trend.color.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(trend.icon, size: 17, color: trend.color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Lịch sử giá ${item.priceHistory.length} mốc'
                                '${lowestObserved == null ? '' : ' · thấp nhất ${_currencyFormat.format(lowestObserved)}'}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF5F4E4A),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _showPriceHistorySheet(item);
                              },
                              child: Text(
                                trend.label,
                                style: TextStyle(
                                  color: trend.color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (item.isPurchased && item.purchasedDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ngày mua: ${_dateFormat.format(item.purchasedDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6A5A55),
                        ),
                      ),
                    ],
                    if (item.imagePath != null &&
                        item.imagePath!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 110,
                          height: 78,
                          child: _buildImagePreview(item.imagePath!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imagePath) {
    if (kIsWeb) {
      return Image.network(imagePath, fit: BoxFit.cover);
    }
    return Image.file(File(imagePath), fit: BoxFit.cover);
  }

  _TrendVisual _trendVisualFor(PriceTrend trend) {
    switch (trend) {
      case PriceTrend.down:
        return const _TrendVisual(
          label: 'Đang giảm',
          icon: Icons.trending_down_rounded,
          color: Color(0xFF1B7A43),
        );
      case PriceTrend.flat:
        return const _TrendVisual(
          label: 'Đi ngang',
          icon: Icons.trending_flat_rounded,
          color: Color(0xFF9A6A10),
        );
      case PriceTrend.up:
        return const _TrendVisual(
          label: 'Đang tăng',
          icon: Icons.trending_up_rounded,
          color: Color(0xFFB3261E),
        );
      case PriceTrend.unknown:
        return const _TrendVisual(
          label: 'Mới ghi nhận',
          icon: Icons.timeline_rounded,
          color: Color(0xFF5F6368),
        );
    }
  }

  _CategoryAlertVisual _categoryAlertVisual(BudgetAlertLevel level) {
    switch (level) {
      case BudgetAlertLevel.safe:
        return const _CategoryAlertVisual(
          label: 'Đang ổn',
          icon: Icons.check_circle_outline_rounded,
          color: Color(0xFF2D7D4C),
          backgroundColor: Color(0xFFE9F7EF),
        );
      case BudgetAlertLevel.warning80:
        return const _CategoryAlertVisual(
          label: 'Mốc 80%',
          icon: Icons.priority_high_rounded,
          color: Color(0xFFB87400),
          backgroundColor: Color(0xFFFFF1DD),
        );
      case BudgetAlertLevel.danger100:
        return const _CategoryAlertVisual(
          label: 'Mốc 100%',
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFB3261E),
          backgroundColor: Color(0xFFFCEBEB),
        );
      case BudgetAlertLevel.critical120:
        return const _CategoryAlertVisual(
          label: 'Mốc 120%',
          icon: Icons.error_outline_rounded,
          color: Color(0xFF7E1A12),
          backgroundColor: Color(0xFFF8E3E2),
        );
    }
  }

  Future<void> _showPriceHistorySheet(ShoppingItem item) async {
    final sortedLogs = List<PriceLog>.from(item.priceHistory)
      ..sort((a, b) => a.observedAt.compareTo(b.observedAt));
    if (sortedLogs.isEmpty) return;

    final latest = sortedLogs.last.price;
    final lowest = sortedLogs
        .map((log) => log.price)
        .reduce((a, b) => a < b ? a : b);
    final trend = _trendVisualFor(item.priceTrend);
    final detailDateFormat = DateFormat('dd/MM/yyyy HH:mm');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3E221D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _historyMetaChip(
                          icon: trend.icon,
                          text: trend.label,
                          color: trend.color,
                          bgColor: trend.color.withValues(alpha: 0.1),
                        ),
                        _historyMetaChip(
                          icon: Icons.sell_outlined,
                          text: 'Mới nhất ${_currencyFormat.format(latest)}',
                          color: const Color(0xFF5A3A33),
                          bgColor: const Color(0xFFF7EEE4),
                        ),
                        _historyMetaChip(
                          icon: Icons.savings_outlined,
                          text: 'Thấp nhất ${_currencyFormat.format(lowest)}',
                          color: const Color(0xFF1B7A43),
                          bgColor: const Color(0xFFEAF7EF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    _buildPriceHistoryChart(sortedLogs),
                    const SizedBox(height: 12),
                    Text(
                      'Các lần ghi nhận giá',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF452721),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sortedLogs.reversed.map((log) {
                      final diff = log.price - item.targetPrice;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          title: Text(
                            _currencyFormat.format(log.price),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: diff > 0
                                      ? const Color(0xFFB3261E)
                                      : const Color(0xFF1B7A43),
                                ),
                          ),
                          subtitle: Text(
                            detailDateFormat.format(log.observedAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF6C5A56)),
                          ),
                          trailing: Text(
                            diff > 0
                                ? '+${_currencyFormat.format(diff)}'
                                : '-${_currencyFormat.format(diff.abs())}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: diff > 0
                                      ? const Color(0xFFB3261E)
                                      : const Color(0xFF1B7A43),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _historyMetaChip({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHistoryChart(List<PriceLog> sortedLogs) {
    if (sortedLogs.length == 1) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Hiện có 1 mốc giá: ${_currencyFormat.format(sortedLogs.first.price)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5E4D49),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final prices = sortedLogs.map((log) => log.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final yRange = (maxPrice - minPrice).abs();
    final yPadding = yRange <= 1
        ? (maxPrice <= 0 ? 1000 : maxPrice * 0.1)
        : yRange * 0.25;
    final minY = (minPrice - yPadding).clamp(0, double.infinity).toDouble();
    final maxY = maxPrice + yPadding;
    final dayFormat = DateFormat('dd/MM');

    final spots = List<FlSpot>.generate(
      sortedLogs.length,
      (index) => FlSpot(index.toDouble(), sortedLogs[index].price),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (sortedLogs.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yRange <= 1 ? (maxY / 4) : yRange / 3,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: const Color(0xFFE7DDD3), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFFC62828),
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFC62828).withValues(alpha: 0.28),
                        const Color(0xFFC62828).withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 56,
                    interval: yRange <= 1 ? (maxY / 4) : yRange / 3,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _shortMoney(value),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF786762),
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= sortedLogs.length) {
                        return const SizedBox.shrink();
                      }
                      final show =
                          index == 0 ||
                          index == sortedLogs.length - 1 ||
                          (sortedLogs.length > 4 &&
                              index == sortedLogs.length ~/ 2);
                      if (!show) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          dayFormat.format(sortedLogs[index].observedAt),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFF7A6762),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _shortMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  List<ShoppingItem> _filterItems(List<ShoppingItem> items) {
    return items.where((item) {
      final queryMatched =
          _query.isEmpty || item.name.toLowerCase().contains(_query);
      if (!queryMatched) return false;

      switch (_selectedFilter) {
        case _ItemFilter.all:
          return true;
        case _ItemFilter.needBuy:
          return !item.isPurchased;
        case _ItemFilter.purchased:
          return item.isPurchased;
        case _ItemFilter.goodDeal:
          return item.currentPrice > 0 && item.currentPrice <= item.targetPrice;
      }
    }).toList();
  }

  Future<void> _addNewItem() async {
    HapticFeedback.lightImpact();
    final newItem = await Navigator.push<ShoppingItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(categoryName: widget.category.title),
      ),
    );
    if (newItem != null) {
      HapticFeedback.selectionClick();
      budgetVM.addItemToCategory(widget.category, newItem);
    }
  }

  Future<void> _editItem(ShoppingItem item) async {
    HapticFeedback.selectionClick();
    final updatedItem = await Navigator.push<ShoppingItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          categoryName: widget.category.title,
          existingItem: item,
        ),
      ),
    );
    if (updatedItem != null) {
      HapticFeedback.selectionClick();
      budgetVM.updateExistingItem(item, updatedItem);
    }
  }
}

enum _ItemFilter {
  all('Tất cả'),
  needBuy('Cần mua'),
  purchased('Đã mua'),
  goodDeal('Deal tốt');

  final String label;
  const _ItemFilter(this.label);
}

class _TrendVisual {
  final String label;
  final IconData icon;
  final Color color;

  const _TrendVisual({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _CategoryAlertVisual {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _CategoryAlertVisual({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
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
    final delayMs = (widget.index * 38).clamp(0, 220);
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0.02, 0.04),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 230),
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _EmptyItemsView extends StatelessWidget {
  const _EmptyItemsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 58,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có món phù hợp bộ lọc',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3D231F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thử đổi bộ lọc hoặc thêm món mới để tiếp tục.',
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
