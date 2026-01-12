import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/daily_log.dart';

enum AnalyticsPeriod { week, month, year }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final foodLogState = ref.watch(foodLogProvider);
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: () {}),
        ],
      ),
      body: _buildContent(foodLogState, user),
    );
  }

  Widget _buildContent(DailyLogState logState, user) {
    final targetCalories = user?.dailyCalorieTarget ?? 2000;

    // Convert state to list of logs
    final logs = <DailyLog>[];
    if (logState.todayLog != null) {
      logs.add(logState.todayLog!);
    }
    logs.addAll(logState.logHistory.values);

    final stats = _calculateStats(logs);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          _PeriodSelector(
            selected: _selectedPeriod,
            onChanged: (period) => setState(() => _selectedPeriod = period),
          ),
          const SizedBox(height: 24),

          // Streak card
          _StreakCard(
            currentStreak: stats['streak'] as int,
            longestStreak: stats['longestStreak'] as int,
          ),
          const SizedBox(height: 20),

          // Calorie chart
          const Text(
            'Calorie Intake',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _CalorieChart(
            logs: logs,
            period: _selectedPeriod,
            targetCalories: targetCalories.toDouble(),
          ),
          const SizedBox(height: 24),

          // Summary stats
          const Text(
            'Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Avg. Calories',
                  value: '${stats['avgCalories']}',
                  subValue: 'kcal/day',
                  color: AppColors.calories,
                  icon: Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Days Logged',
                  value: '${stats['daysLogged']}',
                  subValue: 'days',
                  color: AppColors.primary,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'On Target',
                  value: '${stats['onTargetDays']}',
                  subValue: 'days',
                  color: AppColors.success,
                  icon: Icons.gps_fixed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Total Logged',
                  value: '${stats['totalFoods']}',
                  subValue: 'food items',
                  color: AppColors.secondary,
                  icon: Icons.restaurant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Macros breakdown
          const Text(
            'Macro Average',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _MacroPieChart(
            avgProtein: (stats['avgProtein'] as num).toDouble(),
            avgCarbs: (stats['avgCarbs'] as num).toDouble(),
            avgFat: (stats['avgFat'] as num).toDouble(),
          ),
          const SizedBox(height: 24),

          // Top foods
          const Text(
            'Most Logged Foods',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _TopFoodsList(logs: logs),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStats(List<DailyLog> logs) {
    if (logs.isEmpty) {
      return {
        'avgCalories': 0,
        'daysLogged': 0,
        'onTargetDays': 0,
        'totalFoods': 0,
        'avgProtein': 0.0,
        'avgCarbs': 0.0,
        'avgFat': 0.0,
        'streak': 0,
        'longestStreak': 0,
      };
    }

    final targetCalories = 2000; // Default
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int totalFoods = 0;
    int onTargetDays = 0;

    for (final log in logs) {
      totalCalories += log.totalCalories;
      totalProtein += log.totalProtein;
      totalCarbs += log.totalCarbs;
      totalFat += log.totalFat;
      totalFoods += log.totalFoodItems;

      if ((log.totalCalories - targetCalories).abs() <= targetCalories * 0.1) {
        onTargetDays++;
      }
    }

    final daysLogged = logs.length;
    final avgCalories = daysLogged > 0
        ? (totalCalories / daysLogged).round()
        : 0;
    final avgProtein = daysLogged > 0 ? totalProtein / daysLogged : 0.0;
    final avgCarbs = daysLogged > 0 ? totalCarbs / daysLogged : 0.0;
    final avgFat = daysLogged > 0 ? totalFat / daysLogged : 0.0;

    // Calculate streak
    int currentStreak = 0;
    int longestStreak = 0;

    final sortedLogs = List<DailyLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sortedLogs.isNotEmpty) {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      for (int i = 0; i < sortedLogs.length; i++) {
        final logDate = sortedLogs[i].date;
        final expectedDate = todayOnly.subtract(Duration(days: i));

        if (logDate.year == expectedDate.year &&
            logDate.month == expectedDate.month &&
            logDate.day == expectedDate.day) {
          currentStreak++;
        } else {
          break;
        }
      }

      int tempStreak = 0;
      DateTime? prevDate;
      for (final log in sortedLogs) {
        if (prevDate == null) {
          tempStreak = 1;
        } else {
          final diff = prevDate.difference(log.date).inDays;
          if (diff == 1) {
            tempStreak++;
          } else {
            if (tempStreak > longestStreak) longestStreak = tempStreak;
            tempStreak = 1;
          }
        }
        prevDate = log.date;
      }
      if (tempStreak > longestStreak) longestStreak = tempStreak;
    }

    return {
      'avgCalories': avgCalories,
      'daysLogged': daysLogged,
      'onTargetDays': onTargetDays,
      'totalFoods': totalFoods,
      'avgProtein': avgProtein,
      'avgCarbs': avgCarbs,
      'avgFat': avgFat,
      'streak': currentStreak,
      'longestStreak': longestStreak,
    };
  }
}

class _PeriodSelector extends StatelessWidget {
  final AnalyticsPeriod selected;
  final ValueChanged<AnalyticsPeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = selected == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const _StreakCard({required this.currentStreak, required this.longestStreak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Streak',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  '$currentStreak days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Best',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '$longestStreak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieChart extends StatelessWidget {
  final List<DailyLog> logs;
  final AnalyticsPeriod period;
  final double targetCalories;

  const _CalorieChart({
    required this.logs,
    required this.period,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    final data = _prepareChartData();

    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No data for this period',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: (data.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2)
              .clamp(targetCalories + 500, double.infinity),
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.y,
                  color: entry.value.y <= targetCalories
                      ? AppColors.primary
                      : AppColors.warning,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= data.length) return const Text('');
                  return Text(
                    data[value.toInt()].label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: targetCalories,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: value == targetCalories
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.divider,
                strokeWidth: value == targetCalories ? 2 : 1,
                dashArray: value == targetCalories ? [5, 5] : null,
              );
            },
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  List<_ChartDataPoint> _prepareChartData() {
    final now = DateTime.now();
    final List<_ChartDataPoint> data = [];

    int days = switch (period) {
      AnalyticsPeriod.week => 7,
      AnalyticsPeriod.month => 30,
      AnalyticsPeriod.year => 12, // Monthly averages
    };

    if (period == AnalyticsPeriod.year) {
      // Monthly aggregation
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthLogs = logs.where(
          (log) => log.date.year == month.year && log.date.month == month.month,
        );

        final avgCalories = monthLogs.isEmpty
            ? 0.0
            : monthLogs.map((l) => l.totalCalories).reduce((a, b) => a + b) /
                  monthLogs.length;

        data.add(
          _ChartDataPoint(
            label: DateFormat('MMM').format(month),
            y: avgCalories,
          ),
        );
      }
    } else {
      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayLog = logs.firstWhere(
          (log) =>
              log.date.year == date.year &&
              log.date.month == date.month &&
              log.date.day == date.day,
          orElse: () => DailyLog.empty(date),
        );

        data.add(
          _ChartDataPoint(
            label: period == AnalyticsPeriod.week
                ? DateFormat('EEE').format(date)
                : DateFormat('d').format(date),
            y: dayLog.totalCalories,
          ),
        );
      }
    }

    return data;
  }
}

class _ChartDataPoint {
  final String label;
  final double y;

  _ChartDataPoint({required this.label, required this.y});
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroPieChart extends StatelessWidget {
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;

  const _MacroPieChart({
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
  });

  @override
  Widget build(BuildContext context) {
    final total = avgProtein + avgCarbs + avgFat;

    if (total == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No macro data available',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: avgProtein,
                    color: AppColors.protein,
                    title: '${(avgProtein / total * 100).toInt()}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: avgCarbs,
                    color: AppColors.carbs,
                    title: '${(avgCarbs / total * 100).toInt()}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: avgFat,
                    color: AppColors.fat,
                    title: '${(avgFat / total * 100).toInt()}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 50,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: AppColors.protein,
                label: 'Protein',
                value: '${avgProtein.toInt()}g',
              ),
              const SizedBox(height: 12),
              _LegendItem(
                color: AppColors.carbs,
                label: 'Carbs',
                value: '${avgCarbs.toInt()}g',
              ),
              const SizedBox(height: 12),
              _LegendItem(
                color: AppColors.fat,
                label: 'Fat',
                value: '${avgFat.toInt()}g',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopFoodsList extends StatelessWidget {
  final List<DailyLog> logs;

  const _TopFoodsList({required this.logs});

  @override
  Widget build(BuildContext context) {
    final foodCounts = <String, int>{};

    for (final log in logs) {
      for (final meal in log.meals) {
        for (final food in meal.foods) {
          foodCounts[food.name] = (foodCounts[food.name] ?? 0) + 1;
        }
      }
    }

    final sortedFoods = foodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topFoods = sortedFoods.take(5).toList();

    if (topFoods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Start logging food to see your favorites',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: topFoods.asMap().entries.map((entry) {
        final index = entry.key;
        final food = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  food.key,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${food.value}x',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
