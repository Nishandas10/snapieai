import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';

class ProgressDetailScreen extends ConsumerStatefulWidget {
  final String metricType;

  const ProgressDetailScreen({super.key, required this.metricType});

  @override
  ConsumerState<ProgressDetailScreen> createState() =>
      _ProgressDetailScreenState();
}

class _ProgressDetailScreenState extends ConsumerState<ProgressDetailScreen> {
  String _selectedPeriod = 'Week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Week', child: Text('Week')),
              const PopupMenuItem(value: 'Month', child: Text('Month')),
              const PopupMenuItem(value: '3 Months', child: Text('3 Months')),
              const PopupMenuItem(value: 'Year', child: Text('Year')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            _buildSummaryCard(),
            const SizedBox(height: 24),

            // Chart
            Text(
              'Progress Over Time',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 24),

            // Statistics
            Text(
              'Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatistics(),
            const SizedBox(height: 24),

            // History
            Text(
              'History',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildHistory(),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.metricType) {
      case 'weight':
        return 'Weight Progress';
      case 'calories':
        return 'Calorie Intake';
      case 'protein':
        return 'Protein Intake';
      case 'water':
        return 'Water Intake';
      default:
        return 'Progress';
    }
  }

  String _getUnit() {
    switch (widget.metricType) {
      case 'weight':
        return 'kg';
      case 'calories':
        return 'kcal';
      case 'protein':
        return 'g';
      case 'water':
        return 'ml';
      default:
        return '';
    }
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Current',
                  _getCurrentValue(),
                  _getUnit(),
                  AppColors.primary,
                ),
                Container(height: 50, width: 1, color: AppColors.divider),
                _buildSummaryItem(
                  'Target',
                  _getTargetValue(),
                  _getUnit(),
                  AppColors.success,
                ),
                Container(height: 50, width: 1, color: AppColors.divider),
                _buildSummaryItem(
                  'Change',
                  _getChangeValue(),
                  _getUnit(),
                  _getChangeColor(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  String _getCurrentValue() {
    switch (widget.metricType) {
      case 'weight':
        return '72.5';
      case 'calories':
        return '1850';
      case 'protein':
        return '120';
      case 'water':
        return '2100';
      default:
        return '0';
    }
  }

  String _getTargetValue() {
    switch (widget.metricType) {
      case 'weight':
        return '70.0';
      case 'calories':
        return '2000';
      case 'protein':
        return '150';
      case 'water':
        return '2500';
      default:
        return '0';
    }
  }

  String _getChangeValue() {
    switch (widget.metricType) {
      case 'weight':
        return '-2.5';
      case 'calories':
        return '+150';
      case 'protein':
        return '+30';
      case 'water':
        return '+400';
      default:
        return '0';
    }
  }

  Color _getChangeColor() {
    switch (widget.metricType) {
      case 'weight':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: AppColors.divider, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  const days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  if (value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        days[value.toInt()],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: _getChartMinY(),
          maxY: _getChartMaxY(),
          lineBarsData: [
            LineChartBarData(
              spots: _getChartData(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartData() {
    switch (widget.metricType) {
      case 'weight':
        return const [
          FlSpot(0, 75),
          FlSpot(1, 74.5),
          FlSpot(2, 74),
          FlSpot(3, 73.5),
          FlSpot(4, 73),
          FlSpot(5, 72.8),
          FlSpot(6, 72.5),
        ];
      case 'calories':
        return const [
          FlSpot(0, 1800),
          FlSpot(1, 1950),
          FlSpot(2, 1750),
          FlSpot(3, 2000),
          FlSpot(4, 1850),
          FlSpot(5, 1900),
          FlSpot(6, 1850),
        ];
      case 'protein':
        return const [
          FlSpot(0, 100),
          FlSpot(1, 110),
          FlSpot(2, 95),
          FlSpot(3, 120),
          FlSpot(4, 115),
          FlSpot(5, 125),
          FlSpot(6, 120),
        ];
      case 'water':
        return const [
          FlSpot(0, 1800),
          FlSpot(1, 2000),
          FlSpot(2, 1500),
          FlSpot(3, 2200),
          FlSpot(4, 2100),
          FlSpot(5, 2300),
          FlSpot(6, 2100),
        ];
      default:
        return const [];
    }
  }

  double _getChartMinY() {
    switch (widget.metricType) {
      case 'weight':
        return 70;
      case 'calories':
        return 1500;
      case 'protein':
        return 80;
      case 'water':
        return 1000;
      default:
        return 0;
    }
  }

  double _getChartMaxY() {
    switch (widget.metricType) {
      case 'weight':
        return 80;
      case 'calories':
        return 2200;
      case 'protein':
        return 150;
      case 'water':
        return 2500;
      default:
        return 100;
    }
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Average', _getAverageValue(), _getUnit()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Highest', _getHighestValue(), _getUnit()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Lowest', _getLowestValue(), _getUnit()),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            unit,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _getAverageValue() {
    switch (widget.metricType) {
      case 'weight':
        return '73.6';
      case 'calories':
        return '1871';
      case 'protein':
        return '112';
      case 'water':
        return '2000';
      default:
        return '0';
    }
  }

  String _getHighestValue() {
    switch (widget.metricType) {
      case 'weight':
        return '75.0';
      case 'calories':
        return '2000';
      case 'protein':
        return '125';
      case 'water':
        return '2300';
      default:
        return '0';
    }
  }

  String _getLowestValue() {
    switch (widget.metricType) {
      case 'weight':
        return '72.5';
      case 'calories':
        return '1750';
      case 'protein':
        return '95';
      case 'water':
        return '1500';
      default:
        return '0';
    }
  }

  Widget _buildHistory() {
    final historyItems = _getHistoryItems();

    return Column(
      children: historyItems.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getIcon(), color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['date']!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      item['time']!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${item['value']} ${_getUnit()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getIcon() {
    switch (widget.metricType) {
      case 'weight':
        return Icons.monitor_weight_outlined;
      case 'calories':
        return Icons.local_fire_department_outlined;
      case 'protein':
        return Icons.egg_outlined;
      case 'water':
        return Icons.water_drop_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }

  List<Map<String, String>> _getHistoryItems() {
    // Sample data - in real app, this would come from a provider
    switch (widget.metricType) {
      case 'weight':
        return [
          {'date': 'Today', 'time': '8:30 AM', 'value': '72.5'},
          {'date': 'Yesterday', 'time': '8:15 AM', 'value': '72.8'},
          {'date': 'Dec 18', 'time': '8:45 AM', 'value': '73.0'},
          {'date': 'Dec 17', 'time': '8:30 AM', 'value': '73.5'},
          {'date': 'Dec 16', 'time': '8:20 AM', 'value': '74.0'},
        ];
      default:
        return [
          {'date': 'Today', 'time': 'Total', 'value': _getCurrentValue()},
          {'date': 'Yesterday', 'time': 'Total', 'value': _getAverageValue()},
          {'date': 'Dec 18', 'time': 'Total', 'value': _getHighestValue()},
          {'date': 'Dec 17', 'time': 'Total', 'value': _getLowestValue()},
        ];
    }
  }
}
