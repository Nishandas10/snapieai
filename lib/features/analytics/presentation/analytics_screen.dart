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
  List<DailyLog> _historicalLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case AnalyticsPeriod.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case AnalyticsPeriod.month:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case AnalyticsPeriod.year:
        startDate = now.subtract(const Duration(days: 365));
        break;
    }

    try {
      final logs = await ref
          .read(foodLogProvider.notifier)
          .getLogsForDateRange(startDate, now);
      if (mounted) {
        setState(() {
          _historicalLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onPeriodChanged(AnalyticsPeriod period) {
    setState(() => _selectedPeriod = period);
    _loadHistoricalData();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(user),
    );
  }

  Widget _buildContent(user) {
    final targetCalories = user?.dailyCalorieTarget ?? 2000;

    final stats = _calculateStats(_historicalLogs);

    // Check if user has a weight goal (lose_fat or gain_muscle)
    final hasWeightGoal =
        user?.goal == 'lose_fat' || user?.goal == 'gain_muscle';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal Progress Section (only for lose_fat/gain_muscle goals)
          if (hasWeightGoal) ...[
            _WeightGoalProgressCard(
              currentWeight: user?.weightKg,
              targetWeight: user?.targetWeightKg,
              startingWeight: user?.startingWeightKg,
              weeklyGoal: user?.weeklyWeightGoalKg,
              goal: user?.goal ?? 'lose_fat',
              onEditCurrentWeight: () => _showEditWeightDialog(context, true),
              onEditTargetWeight: () => _showEditWeightDialog(context, false),
            ),
            const SizedBox(height: 24),
          ],

          // Period selector
          _PeriodSelector(
            selected: _selectedPeriod,
            onChanged: _onPeriodChanged,
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
            logs: _historicalLogs,
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

          // BMI Card (visible to all users)
          _BmiCard(bmi: user?.bmi, bmiCategory: user?.bmiCategory ?? 'Unknown'),
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
          _TopFoodsList(logs: _historicalLogs),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditWeightDialog(BuildContext context, bool isCurrentWeight) {
    final user = ref.read(userProfileProvider);
    final initialValue = isCurrentWeight
        ? (user?.weightKg ?? 70.0)
        : (user?.targetWeightKg ?? 65.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditWeightBottomSheet(
        title: isCurrentWeight
            ? 'Update Current Weight'
            : 'Update Target Weight',
        initialValue: initialValue,
        onSave: (newWeight, isKg) async {
          // Convert to kg if user entered lbs
          final weightInKg = isKg ? newWeight : newWeight * 0.453592;

          if (isCurrentWeight) {
            // If startingWeightKg is not set, set it to current weight before updating
            // This ensures we have a baseline for progress tracking
            if (user?.startingWeightKg == null) {
              await ref
                  .read(userProfileProvider.notifier)
                  .updateProfile(
                    weightKg: weightInKg,
                    startingWeightKg: user?.weightKg ?? weightInKg,
                  );
            } else {
              await ref
                  .read(userProfileProvider.notifier)
                  .updateProfile(weightKg: weightInKg);
            }
          } else {
            // When setting target weight, if no starting weight, use current weight
            if (user?.startingWeightKg == null && user?.weightKg != null) {
              await ref
                  .read(userProfileProvider.notifier)
                  .updateProfile(
                    targetWeightKg: weightInKg,
                    startingWeightKg: user!.weightKg,
                  );
            } else {
              await ref
                  .read(userProfileProvider.notifier)
                  .updateProfile(targetWeightKg: weightInKg);
            }
          }
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
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

/// Weight Goal Progress Card - Shows current weight, target weight, and progress
class _WeightGoalProgressCard extends StatefulWidget {
  final double? currentWeight;
  final double? targetWeight;
  final double? startingWeight;
  final double? weeklyGoal;
  final String goal;
  final VoidCallback onEditCurrentWeight;
  final VoidCallback onEditTargetWeight;

  const _WeightGoalProgressCard({
    required this.currentWeight,
    required this.targetWeight,
    this.startingWeight,
    required this.weeklyGoal,
    required this.goal,
    required this.onEditCurrentWeight,
    required this.onEditTargetWeight,
  });

  @override
  State<_WeightGoalProgressCard> createState() =>
      _WeightGoalProgressCardState();
}

class _WeightGoalProgressCardState extends State<_WeightGoalProgressCard> {
  bool _isKg = true; // true = kg, false = lbs

  double _toDisplayUnit(double kg) => _isKg ? kg : kg * 2.20462;
  String get _unit => _isKg ? 'kg' : 'lbs';

  @override
  Widget build(BuildContext context) {
    final current = widget.currentWeight ?? 70.0;
    final target = widget.targetWeight ?? 65.0;
    final starting =
        widget.startingWeight ?? current; // Use current as starting if not set
    final isLosing = widget.goal == 'lose_fat';

    // Calculate progress properly
    double progress = 0.0;
    final totalDistance = (starting - target).abs();

    if (totalDistance > 0) {
      if (isLosing) {
        // For weight loss: progress = how much weight lost / total to lose
        final weightLost = starting - current;
        progress = (weightLost / totalDistance).clamp(0.0, 1.0);
      } else {
        // For muscle gain: progress = how much weight gained / total to gain
        final weightGained = current - starting;
        progress = (weightGained / totalDistance).clamp(0.0, 1.0);
      }
    } else {
      progress = 1.0; // Already at target
    }

    final weightDiff = isLosing ? (current - target) : (target - current);
    final displayDiff = _toDisplayUnit(weightDiff);
    final progressText = weightDiff > 0
        ? '${displayDiff.toStringAsFixed(1)} $_unit to go'
        : 'Goal reached! 🎉';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isLosing ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4),
            isLosing ? const Color(0xFFFF8E8E) : const Color(0xFF7BE0D8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                (isLosing ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4))
                    .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with unit toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLosing ? Icons.trending_down : Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isLosing ? 'Weight Loss Goal' : 'Muscle Gain Goal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Unit toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isKg = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isKg ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'kg',
                          style: TextStyle(
                            color: _isKg
                                ? (isLosing
                                      ? const Color(0xFFFF6B6B)
                                      : const Color(0xFF4ECDC4))
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isKg = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: !_isKg ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'lbs',
                          style: TextStyle(
                            color: !_isKg
                                ? (isLosing
                                      ? const Color(0xFFFF6B6B)
                                      : const Color(0xFF4ECDC4))
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weight display row
          Row(
            children: [
              // Current Weight
              Expanded(
                child: _WeightDisplay(
                  label: 'Current',
                  weight: _toDisplayUnit(current),
                  unit: _unit,
                  onEdit: widget.onEditCurrentWeight,
                ),
              ),

              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progressText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Target Weight
              Expanded(
                child: _WeightDisplay(
                  label: 'Target',
                  weight: _toDisplayUnit(target),
                  unit: _unit,
                  onEdit: widget.onEditTargetWeight,
                  isTarget: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  // Background
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Progress
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Weekly goal info
          if (widget.weeklyGoal != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_toDisplayUnit(widget.weeklyGoal!).toStringAsFixed(1)} $_unit/week',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeightDisplay extends StatelessWidget {
  final String label;
  final double weight;
  final String unit;
  final VoidCallback onEdit;
  final bool isTarget;

  const _WeightDisplay({
    required this.label,
    required this.weight,
    required this.unit,
    required this.onEdit,
    this.isTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isTarget ? 0.25 : 0.15),
          borderRadius: BorderRadius.circular(16),
          border: isTarget
              ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2)
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 12,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  weight.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for editing weight
class _EditWeightBottomSheet extends StatefulWidget {
  final String title;
  final double initialValue; // Always in kg
  final Function(double, bool) onSave; // (value, isKg)

  const _EditWeightBottomSheet({
    required this.title,
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_EditWeightBottomSheet> createState() => _EditWeightBottomSheetState();
}

class _EditWeightBottomSheetState extends State<_EditWeightBottomSheet> {
  late double _weightKg;
  bool _isKg = true;

  double get _displayWeight => _isKg ? _weightKg : _weightKg * 2.20462;
  String get _unit => _isKg ? 'kg' : 'lbs';
  double get _minWeight => _isKg ? 30.0 : 66.0; // 30kg ≈ 66lbs
  double get _maxWeight => _isKg ? 200.0 : 440.0; // 200kg ≈ 440lbs

  @override
  void initState() {
    super.initState();
    _weightKg = widget.initialValue;
  }

  void _onSliderChanged(double value) {
    setState(() {
      // Convert to kg for internal storage
      _weightKg = _isKg ? value : value * 0.453592;
    });
  }

  void _toggleUnit(bool isKg) {
    setState(() {
      _isKg = isKg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title and unit toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Unit toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _toggleUnit(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isKg
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'kg',
                              style: TextStyle(
                                color: _isKg
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleUnit(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: !_isKg
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'lbs',
                              style: TextStyle(
                                color: !_isKg
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weight display
              Center(
                child: Text(
                  '${_displayWeight.toStringAsFixed(1)} $_unit',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.1),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                  ),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _displayWeight.clamp(_minWeight, _maxWeight),
                  min: _minWeight,
                  max: _maxWeight,
                  divisions: _isKg ? 1700 : 3740, // 0.1 increments
                  onChanged: _onSliderChanged,
                ),
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_minWeight.toInt()} $_unit',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${_maxWeight.toInt()} $_unit',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      widget.onSave(_weightKg, true), // Always save in kg
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BMI Card widget - displays user's current BMI with visual indicator
class _BmiCard extends StatelessWidget {
  final double? bmi;
  final String bmiCategory;

  const _BmiCard({required this.bmi, required this.bmiCategory});

  Color get _bmiColor {
    if (bmi == null) return AppColors.textSecondary;
    if (bmi! < 18.5) return Colors.blue;
    if (bmi! < 25) return AppColors.success;
    if (bmi! < 30) return AppColors.warning;
    return AppColors.error;
  }

  String get _bmiAdvice {
    if (bmi == null) return 'Add your height and weight to see your BMI';
    if (bmi! < 18.5) return 'Consider gaining some weight for better health';
    if (bmi! < 25) return 'Great job! You\'re in a healthy range';
    if (bmi! < 30) return 'Consider making lifestyle changes';
    return 'Consult a healthcare provider for guidance';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bmiColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_weight_outlined,
                  color: _bmiColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Body Mass Index',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // BMI Value and Category
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bmi?.toStringAsFixed(1) ?? '--',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _bmiColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _bmiColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bmiCategory,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _bmiColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // BMI Scale
          _BmiScale(bmi: bmi),
          const SizedBox(height: 16),

          // Advice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _bmiAdvice,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
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

/// BMI Scale visual indicator
class _BmiScale extends StatelessWidget {
  final double? bmi;

  const _BmiScale({required this.bmi});

  @override
  Widget build(BuildContext context) {
    // BMI ranges: <18.5 (underweight), 18.5-25 (normal), 25-30 (overweight), >30 (obese)
    final colors = [
      Colors.blue,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];

    // Calculate indicator position (0.0 to 1.0)
    double indicatorPosition = 0.5;
    if (bmi != null) {
      // Scale: 15 to 40 BMI range
      indicatorPosition = ((bmi! - 15) / 25).clamp(0.0, 1.0);
    }

    return Column(
      children: [
        // Scale bar
        Stack(
          children: [
            // Background gradient
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(colors: colors),
              ),
            ),
            // Position indicator
            if (bmi != null)
              Positioned(
                left:
                    indicatorPosition *
                        (MediaQuery.of(context).size.width - 80) -
                    6,
                top: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textPrimary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '15',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            Text(
              '18.5',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            Text(
              '25',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            Text(
              '30',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            Text(
              '40',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
