import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/notification_service.dart';

class MealRemindersOnboardingScreen extends ConsumerStatefulWidget {
  const MealRemindersOnboardingScreen({super.key});

  @override
  ConsumerState<MealRemindersOnboardingScreen> createState() =>
      _MealRemindersOnboardingScreenState();
}

class _MealRemindersOnboardingScreenState
    extends ConsumerState<MealRemindersOnboardingScreen> {
  bool _isRequestingPermission = false;
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadExistingSettings();
  }

  void _loadExistingSettings() {
    // Load any existing settings
    final (breakfastH, breakfastM) = NotificationService.getBreakfastTime();
    _breakfastTime = TimeOfDay(hour: breakfastH, minute: breakfastM);

    final (lunchH, lunchM) = NotificationService.getLunchTime();
    _lunchTime = TimeOfDay(hour: lunchH, minute: lunchM);

    final (dinnerH, dinnerM) = NotificationService.getDinnerTime();
    _dinnerTime = TimeOfDay(hour: dinnerH, minute: dinnerM);

    setState(() {});
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
            break;
          case 'lunch':
            _lunchTime = picked;
            break;
          case 'dinner':
            _dinnerTime = picked;
            break;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _continue() async {
    setState(() => _isRequestingPermission = true);

    // Request notification permissions
    final granted = await NotificationService.requestPermissions();

    if (!granted && mounted) {
      // Show dialog explaining why notifications are important
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Notifications?'),
          content: const Text(
            'Meal reminders help you stay on track with your nutrition goals. '
            'Without notifications, you won\'t receive reminders to log your meals.\n\n'
            'You can enable them later in Settings.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    // Save meal times regardless of permission status
    await NotificationService.setBreakfastTime(
      _breakfastTime.hour,
      _breakfastTime.minute,
    );
    await NotificationService.setLunchTime(_lunchTime.hour, _lunchTime.minute);
    await NotificationService.setDinnerTime(
      _dinnerTime.hour,
      _dinnerTime.minute,
    );

    // Enable reminders
    await NotificationService.setMealRemindersEnabled(true);

    // Mark setup as complete
    await NotificationService.setRemindersSetupComplete(true);

    // Schedule notifications if permission was granted
    if (granted) {
      await NotificationService.rescheduleAllNotifications();
    }

    setState(() => _isRequestingPermission = false);

    if (mounted) {
      context.go(AppRoutes.planGeneration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dietaryPreferences),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Never miss a meal! 🔔',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set up reminders to log your meals and stay on track with your goals.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Meal times header
              const Text(
                'Set Your Meal Times',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  children: [
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can change these times later in Settings',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Enable Reminders & Continue',
                onPressed: _isRequestingPermission ? null : _continue,
                isLoading: _isRequestingPermission,
              ),
            ],
          ),
        ),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
