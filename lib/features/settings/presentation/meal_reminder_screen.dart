import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';

class MealReminderScreen extends ConsumerStatefulWidget {
  const MealReminderScreen({super.key});

  @override
  ConsumerState<MealReminderScreen> createState() => _MealReminderScreenState();
}

class _MealReminderScreenState extends ConsumerState<MealReminderScreen> {
  bool _remindersEnabled = false;
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _remindersEnabled = NotificationService.isMealRemindersEnabled();

    final (breakfastH, breakfastM) = NotificationService.getBreakfastTime();
    _breakfastTime = TimeOfDay(hour: breakfastH, minute: breakfastM);

    final (lunchH, lunchM) = NotificationService.getLunchTime();
    _lunchTime = TimeOfDay(hour: lunchH, minute: lunchM);

    final (dinnerH, dinnerM) = NotificationService.getDinnerTime();
    _dinnerTime = TimeOfDay(hour: dinnerH, minute: dinnerM);

    setState(() {});
  }

  Future<void> _toggleReminders(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable notifications in device settings'),
            ),
          );
        }
        return;
      }
    }

    await NotificationService.setMealRemindersEnabled(enabled);
    setState(() => _remindersEnabled = enabled);

    if (mounted && enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal reminders enabled!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _selectTime(String mealType, TimeOfDay currentTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != currentTime) {
      setState(() {
        switch (mealType) {
          case 'breakfast':
            _breakfastTime = picked;
            NotificationService.setBreakfastTime(picked.hour, picked.minute);
            break;
          case 'lunch':
            _lunchTime = picked;
            NotificationService.setLunchTime(picked.hour, picked.minute);
            break;
          case 'dinner':
            _dinnerTime = picked;
            NotificationService.setDinnerTime(picked.hour, picked.minute);
            break;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${mealType[0].toUpperCase()}${mealType.substring(1)} reminder updated!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Reminders')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Enable/Disable toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meal Reminders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Get notified when it\'s time to eat',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _remindersEnabled,
                  onChanged: _toggleReminders,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Meal times
          if (_remindersEnabled) ...[
            const Text(
              'Reminder Times',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Breakfast
            _MealTimeCard(
              emoji: '🍳',
              mealName: 'Breakfast',
              time: _formatTime(_breakfastTime),
              onTap: () => _selectTime('breakfast', _breakfastTime),
            ),
            const SizedBox(height: 12),

            // Lunch
            _MealTimeCard(
              emoji: '🥗',
              mealName: 'Lunch',
              time: _formatTime(_lunchTime),
              onTap: () => _selectTime('lunch', _lunchTime),
            ),
            const SizedBox(height: 12),

            // Dinner
            _MealTimeCard(
              emoji: '🍽️',
              mealName: 'Dinner',
              time: _formatTime(_dinnerTime),
              onTap: () => _selectTime('dinner', _dinnerTime),
            ),
            const SizedBox(height: 24),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You\'ll receive a notification at each scheduled time to remind you to log your meals.',
                      style: TextStyle(fontSize: 13, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Disabled state
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reminders are disabled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enable reminders to get notified when it\'s time for breakfast, lunch, and dinner.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
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

class _MealTimeCard extends StatelessWidget {
  final String emoji;
  final String mealName;
  final String time;
  final VoidCallback onTap;

  const _MealTimeCard({
    required this.emoji,
    required this.mealName,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap to change time',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
