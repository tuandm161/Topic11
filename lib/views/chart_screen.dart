import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/entities/category.dart';

class ChartScreen extends StatelessWidget {
  final List<ShoppingCategory> categories;

  const ChartScreen({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final dayFormat = DateFormat('dd/MM');

    final totalSpent = categories.fold<double>(
      0,
      (sum, category) => sum + category.totalSpent,
    );
    final totalBudget = categories.fold<double>(
      0,
      (sum, category) => sum + category.totalTargetBudget,
    );

    final categorySlices = _buildCategorySlices();
    final dailyEntries = _buildDailySpendingData();

    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo chi tiêu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildOverviewCard(
            context: context,
            totalSpent: totalSpent,
            totalBudget: totalBudget,
            currencyFormat: currencyFormat,
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Phân bổ chi tiêu theo hạng mục'),
          const SizedBox(height: 8),
          _buildCategoryPieCard(
            context: context,
            slices: categorySlices,
            totalSpent: totalSpent,
            currencyFormat: currencyFormat,
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Xu hướng chi tiêu theo ngày'),
          const SizedBox(height: 8),
          _buildDailyTrendCard(
            context: context,
            entries: dailyEntries,
            dayFormat: dayFormat,
            currencyFormat: currencyFormat,
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Tóm tắt nhanh'),
          const SizedBox(height: 8),
          ...categories.map(
            (category) => _buildCategorySummaryRow(
              context: context,
              category: category,
              currencyFormat: currencyFormat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required BuildContext context,
    required double totalSpent,
    required double totalBudget,
    required NumberFormat currencyFormat,
  }) {
    final ratioRaw = totalBudget <= 0
        ? (totalSpent > 0 ? 1.0 : 0.0)
        : (totalSpent / totalBudget);
    final ratio = ratioRaw.clamp(0.0, 1.0);
    final remaining = totalBudget - totalSpent;
    final alert = _alertVisualFor(_alertLevelForRatio(ratioRaw));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE7CD), Color(0xFFFFD9B7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFE9BC92)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan ngân sách Tết',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4C2620),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${currencyFormat.format(totalSpent)} / ${currencyFormat.format(totalBudget)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF311814),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.68),
              valueColor: AlwaysStoppedAnimation(alert.color),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: alert.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: alert.color.withValues(alpha: 0.34)),
            ),
            child: Row(
              children: [
                Icon(alert.icon, size: 18, color: alert.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${alert.label}: đã dùng ${_ratioLabel(ratioRaw)} ngân sách',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: alert.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Còn lại: ${currencyFormat.format(remaining)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: remaining < 0
                  ? const Color(0xFFB3261E)
                  : const Color(0xFF2E7D32),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _thresholdChip(context, ratioRaw, 0.8, '80%'),
              _thresholdChip(context, ratioRaw, 1.0, '100%'),
              _thresholdChip(context, ratioRaw, 1.2, '120%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieCard({
    required BuildContext context,
    required List<_CategorySlice> slices,
    required double totalSpent,
    required NumberFormat currencyFormat,
  }) {
    if (slices.isEmpty || totalSpent <= 0) {
      return _emptyCard(
        context: context,
        message: 'Chưa có dữ liệu chi tiêu để vẽ phân bổ hạng mục.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          children: [
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 44,
                  pieTouchData: PieTouchData(enabled: true),
                  sections: slices.map((slice) {
                    final percent = (slice.amount / totalSpent) * 100;
                    return PieChartSectionData(
                      value: slice.amount,
                      color: slice.color,
                      radius: 66,
                      title: '${percent.toStringAsFixed(0)}%',
                      titleStyle: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...slices.take(5).map((slice) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: slice.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slice.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      currencyFormat.format(slice.amount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5B4A45),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTrendCard({
    required BuildContext context,
    required List<_DailySpendingEntry> entries,
    required DateFormat dayFormat,
    required NumberFormat currencyFormat,
  }) {
    if (entries.isEmpty) {
      return _emptyCard(
        context: context,
        message: 'Chưa có dữ liệu mua hàng theo ngày.',
      );
    }

    final spots = <FlSpot>[];
    double maxValue = 0;

    for (var i = 0; i < entries.length; i++) {
      final amount = entries[i].amount;
      spots.add(FlSpot(i.toDouble(), amount));
      if (amount > maxValue) {
        maxValue = amount;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (entries.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxValue <= 0 ? 10 : maxValue * 1.25,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: maxValue <= 0 ? 10 : maxValue / 4,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: const Color(0xFFEADFD4), strokeWidth: 1),
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
                            const Color(0xFFC62828).withValues(alpha: 0.02),
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
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: entries.length > 7 ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dayFormat.format(entries[index].date),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: const Color(0xFF6A5A55),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        interval: maxValue <= 0 ? 10 : maxValue / 4,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _shortMoney(value),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF7A6762),
                                  fontWeight: FontWeight.w700,
                                ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ngày gần nhất: ${dayFormat.format(entries.last.date)} - ${currencyFormat.format(entries.last.amount)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64534F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySummaryRow({
    required BuildContext context,
    required ShoppingCategory category,
    required NumberFormat currencyFormat,
  }) {
    final spent = category.totalSpent;
    final budget = category.totalTargetBudget;
    final ratio = category.budgetUsageRatio.clamp(0.0, 1.0);
    final alert = _alertVisualFor(category.alertLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Text(category.iconStr, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: alert.backgroundColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(alert.icon, size: 13, color: alert.color),
                      const SizedBox(width: 4),
                      Text(
                        alert.shortLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: alert.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${currencyFormat.format(spent)} / ${currencyFormat.format(budget)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: alert.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: const Color(0xFFF4ECE2),
                valueColor: AlwaysStoppedAnimation(alert.color),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Đã dùng ${_ratioLabel(category.budgetUsageRatio)} ngân sách',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6A5853),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: const Color(0xFF4E2C26),
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _emptyCard({required BuildContext context, required String message}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6D5B57),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<_CategorySlice> _buildCategorySlices() {
    final colors = <Color>[
      const Color(0xFFC62828),
      const Color(0xFFF39C12),
      const Color(0xFF2E7D32),
      const Color(0xFF5D4037),
      const Color(0xFF1565C0),
      const Color(0xFFD84315),
      const Color(0xFF00838F),
    ];

    final spentCategories =
        categories.where((category) => category.totalSpent > 0).toList()
          ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    return spentCategories.asMap().entries.map((entry) {
      return _CategorySlice(
        title: entry.value.title,
        amount: entry.value.totalSpent,
        color: colors[entry.key % colors.length],
      );
    }).toList();
  }

  List<_DailySpendingEntry> _buildDailySpendingData() {
    final totalsByDay = <DateTime, double>{};

    for (final category in categories) {
      for (final item in category.items) {
        if (!item.isPurchased || item.currentPrice <= 0) continue;
        final sourceDate = item.purchasedDate ?? item.dateAdded;
        final key = DateTime(sourceDate.year, sourceDate.month, sourceDate.day);
        totalsByDay[key] = (totalsByDay[key] ?? 0) + item.currentPrice;
      }
    }

    final result =
        totalsByDay.entries
            .map(
              (entry) =>
                  _DailySpendingEntry(date: entry.key, amount: entry.value),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return result;
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

  _AlertVisual _alertVisualFor(BudgetAlertLevel level) {
    switch (level) {
      case BudgetAlertLevel.safe:
        return const _AlertVisual(
          color: Color(0xFF2D7D4C),
          backgroundColor: Color(0xFFE9F7EF),
          icon: Icons.check_circle_outline_rounded,
          label: 'Ngân sách ổn',
          shortLabel: 'Ổn',
        );
      case BudgetAlertLevel.warning80:
        return const _AlertVisual(
          color: Color(0xFFB87400),
          backgroundColor: Color(0xFFFFF1DD),
          icon: Icons.priority_high_rounded,
          label: 'Mốc 80%',
          shortLabel: '80%+',
        );
      case BudgetAlertLevel.danger100:
        return const _AlertVisual(
          color: Color(0xFFB3261E),
          backgroundColor: Color(0xFFFCEBEB),
          icon: Icons.warning_amber_rounded,
          label: 'Mốc 100%',
          shortLabel: '100%+',
        );
      case BudgetAlertLevel.critical120:
        return const _AlertVisual(
          color: Color(0xFF7E1A12),
          backgroundColor: Color(0xFFF8E3E2),
          icon: Icons.error_outline_rounded,
          label: 'Mốc 120%',
          shortLabel: '120%+',
        );
    }
  }

  BudgetAlertLevel _alertLevelForRatio(double ratio) {
    if (ratio >= 1.2) return BudgetAlertLevel.critical120;
    if (ratio >= 1.0) return BudgetAlertLevel.danger100;
    if (ratio >= 0.8) return BudgetAlertLevel.warning80;
    return BudgetAlertLevel.safe;
  }

  String _ratioLabel(double ratio) {
    if (ratio.isNaN || ratio.isInfinite || ratio <= 0) return '0%';
    return '${(ratio * 100).clamp(0, 999).toStringAsFixed(0)}%';
  }

  Widget _thresholdChip(
    BuildContext context,
    double ratio,
    double threshold,
    String label,
  ) {
    final isReached = ratio >= threshold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isReached
            ? const Color(0xFFB3261E).withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isReached
              ? const Color(0xFFB3261E).withValues(alpha: 0.45)
              : const Color(0xFFD8C3B0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReached ? Icons.flag_rounded : Icons.outlined_flag_rounded,
            size: 14,
            color: isReached
                ? const Color(0xFFB3261E)
                : const Color(0xFF6A5752),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isReached
                  ? const Color(0xFFB3261E)
                  : const Color(0xFF6A5752),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySlice {
  final String title;
  final double amount;
  final Color color;

  const _CategorySlice({
    required this.title,
    required this.amount,
    required this.color,
  });
}

class _DailySpendingEntry {
  final DateTime date;
  final double amount;

  const _DailySpendingEntry({required this.date, required this.amount});
}

class _AlertVisual {
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final String label;
  final String shortLabel;

  const _AlertVisual({
    required this.color,
    required this.backgroundColor,
    required this.icon,
    required this.label,
    required this.shortLabel,
  });
}
