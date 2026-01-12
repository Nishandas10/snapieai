import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/food_log_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'All';
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(foodLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Meals', child: Text('Meals')),
              const PopupMenuItem(value: 'Scans', child: Text('AI Scans')),
              const PopupMenuItem(value: 'Manual', child: Text('Manual Entry')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 4),
                  Text(_selectedFilter),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          _buildMonthSelector(),

          // History list
          Expanded(
            child: logState.logHistory.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(logState),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          GestureDetector(
            onTap: () => _showMonthPicker(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              final now = DateTime.now();
              if (_selectedMonth.isBefore(DateTime(now.year, now.month))) {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  );
                });
              }
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your food logs will appear here',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(DailyLogState logState) {
    // For demo, we'll show sample data
    final sampleDays = _generateSampleData();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sampleDays.length,
      itemBuilder: (context, index) {
        final day = sampleDays[index];
        return _buildDaySection(day);
      },
    );
  }

  List<Map<String, dynamic>> _generateSampleData() {
    return [
      {
        'date': DateTime.now(),
        'totalCalories': 1850,
        'items': [
          {
            'name': 'Oatmeal with Berries',
            'calories': 350,
            'type': 'Breakfast',
            'time': '8:30 AM',
          },
          {
            'name': 'Grilled Chicken Salad',
            'calories': 450,
            'type': 'Lunch',
            'time': '12:45 PM',
          },
          {
            'name': 'Greek Yogurt',
            'calories': 150,
            'type': 'Snack',
            'time': '3:30 PM',
          },
          {
            'name': 'Salmon with Vegetables',
            'calories': 550,
            'type': 'Dinner',
            'time': '7:00 PM',
          },
        ],
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'totalCalories': 1920,
        'items': [
          {
            'name': 'Scrambled Eggs',
            'calories': 300,
            'type': 'Breakfast',
            'time': '9:00 AM',
          },
          {
            'name': 'Turkey Sandwich',
            'calories': 500,
            'type': 'Lunch',
            'time': '1:00 PM',
          },
          {'name': 'Apple', 'calories': 95, 'type': 'Snack', 'time': '4:00 PM'},
          {
            'name': 'Pasta Primavera',
            'calories': 600,
            'type': 'Dinner',
            'time': '7:30 PM',
          },
        ],
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'totalCalories': 1750,
        'items': [
          {
            'name': 'Smoothie Bowl',
            'calories': 380,
            'type': 'Breakfast',
            'time': '8:00 AM',
          },
          {
            'name': 'Quinoa Bowl',
            'calories': 420,
            'type': 'Lunch',
            'time': '12:30 PM',
          },
          {
            'name': 'Stir Fry Tofu',
            'calories': 480,
            'type': 'Dinner',
            'time': '6:45 PM',
          },
        ],
      },
    ];
  }

  Widget _buildDaySection(Map<String, dynamic> day) {
    final date = day['date'] as DateTime;
    final items = day['items'] as List<Map<String, dynamic>>;
    final totalCalories = day['totalCalories'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$totalCalories kcal',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    _buildHistoryItem(item),
                    if (index < items.length - 1)
                      Divider(height: 1, color: AppColors.divider),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final IconData icon;
    final Color color;

    switch (item['type']) {
      case 'Breakfast':
        icon = Icons.free_breakfast;
        color = Colors.orange;
        break;
      case 'Lunch':
        icon = Icons.lunch_dining;
        color = Colors.green;
        break;
      case 'Dinner':
        icon = Icons.dinner_dining;
        color = Colors.blue;
        break;
      case 'Snack':
        icon = Icons.cookie;
        color = Colors.pink;
        break;
      default:
        icon = Icons.restaurant;
        color = AppColors.primary;
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        item['name'] as String,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${item['type']} • ${item['time']}',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        '${item['calories']} kcal',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
      onTap: () => _showItemDetails(item),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              item['name'] as String,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${item['type']} • ${item['time']}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientInfo('Calories', '${item['calories']}', 'kcal'),
                _buildNutrientInfo('Protein', '25', 'g'),
                _buildNutrientInfo('Carbs', '30', 'g'),
                _buildNutrientInfo('Fat', '12', 'g'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to today\'s log')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Log Again'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          unit,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
