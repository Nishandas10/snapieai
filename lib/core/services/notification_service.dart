import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import 'storage_service.dart';

/// Service for handling local notifications
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // Storage keys for meal reminder times
  static const String _mealRemindersEnabledKey = 'meal_reminders_enabled';
  static const String _breakfastTimeKey = 'breakfast_reminder_time';
  static const String _lunchTimeKey = 'lunch_reminder_time';
  static const String _dinnerTimeKey = 'dinner_reminder_time';

  // Notification IDs
  static const int _breakfastNotificationId = 1001;
  static const int _lunchNotificationId = 1002;
  static const int _dinnerNotificationId = 1003;

  /// Initialize notification service
  static Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Get the device's local timezone using flutter_timezone
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      // Extract just the timezone ID from the TimezoneInfo string
      // Format is: "TimezoneInfo(Asia/Calcutta, (locale: en_IN, name: India Standard Time))"
      String timezoneName = timezoneInfo.toString();

      // Extract timezone between "TimezoneInfo(" and the first comma
      final match = RegExp(r'TimezoneInfo\(([^,]+)').firstMatch(timezoneName);
      if (match != null) {
        timezoneName = match.group(1)!.trim();
      }

      // Handle common timezone name variations
      if (timezoneName == 'Asia/Calcutta') {
        timezoneName = 'Asia/Kolkata'; // Calcutta is an old name for Kolkata
      }

      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
      debugPrint('Timezone set to: $timezoneName');
    } catch (e) {
      debugPrint('Error setting timezone: $e, using UTC');
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;

    // Reschedule notifications on app start
    await _rescheduleNotifications();
  }

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final iOS = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Check if meal reminders are enabled
  static bool isMealRemindersEnabled() {
    return StorageService.getBool(_mealRemindersEnabledKey) ?? false;
  }

  /// Set meal reminders enabled status
  static Future<void> setMealRemindersEnabled(bool enabled) async {
    await StorageService.setBool(_mealRemindersEnabledKey, enabled);

    if (enabled) {
      await _rescheduleNotifications();
    } else {
      await cancelAllMealReminders();
    }
  }

  /// Get breakfast reminder time (hour, minute)
  static (int, int) getBreakfastTime() {
    final timeStr = StorageService.getString(_breakfastTimeKey);
    if (timeStr != null) {
      final parts = timeStr.split(':');
      return (int.parse(parts[0]), int.parse(parts[1]));
    }
    return (8, 0); // Default 8:00 AM
  }

  /// Get lunch reminder time (hour, minute)
  static (int, int) getLunchTime() {
    final timeStr = StorageService.getString(_lunchTimeKey);
    if (timeStr != null) {
      final parts = timeStr.split(':');
      return (int.parse(parts[0]), int.parse(parts[1]));
    }
    return (12, 30); // Default 12:30 PM
  }

  /// Get dinner reminder time (hour, minute)
  static (int, int) getDinnerTime() {
    final timeStr = StorageService.getString(_dinnerTimeKey);
    if (timeStr != null) {
      final parts = timeStr.split(':');
      return (int.parse(parts[0]), int.parse(parts[1]));
    }
    return (19, 0); // Default 7:00 PM
  }

  /// Set breakfast reminder time
  static Future<void> setBreakfastTime(int hour, int minute) async {
    await StorageService.setString(_breakfastTimeKey, '$hour:$minute');
    if (isMealRemindersEnabled()) {
      await _scheduleBreakfastReminder(hour, minute);
    }
  }

  /// Set lunch reminder time
  static Future<void> setLunchTime(int hour, int minute) async {
    await StorageService.setString(_lunchTimeKey, '$hour:$minute');
    if (isMealRemindersEnabled()) {
      await _scheduleLunchReminder(hour, minute);
    }
  }

  /// Set dinner reminder time
  static Future<void> setDinnerTime(int hour, int minute) async {
    await StorageService.setString(_dinnerTimeKey, '$hour:$minute');
    if (isMealRemindersEnabled()) {
      await _scheduleDinnerReminder(hour, minute);
    }
  }

  /// Schedule all meal reminders
  static Future<void> _rescheduleNotifications() async {
    if (!isMealRemindersEnabled()) return;

    final (breakfastHour, breakfastMinute) = getBreakfastTime();
    final (lunchHour, lunchMinute) = getLunchTime();
    final (dinnerHour, dinnerMinute) = getDinnerTime();

    await _scheduleBreakfastReminder(breakfastHour, breakfastMinute);
    await _scheduleLunchReminder(lunchHour, lunchMinute);
    await _scheduleDinnerReminder(dinnerHour, dinnerMinute);
  }

  /// Schedule breakfast reminder
  static Future<void> _scheduleBreakfastReminder(int hour, int minute) async {
    await _scheduleDailyNotification(
      id: _breakfastNotificationId,
      hour: hour,
      minute: minute,
      title: '🍳 Breakfast Time!',
      body:
          'Good morning! Time to log your breakfast and start your day right.',
      payload: 'breakfast',
    );
  }

  /// Schedule lunch reminder
  static Future<void> _scheduleLunchReminder(int hour, int minute) async {
    await _scheduleDailyNotification(
      id: _lunchNotificationId,
      hour: hour,
      minute: minute,
      title: '🥗 Lunch Time!',
      body: 'Don\'t forget to log your lunch to stay on track with your goals.',
      payload: 'lunch',
    );
  }

  /// Schedule dinner reminder
  static Future<void> _scheduleDinnerReminder(int hour, int minute) async {
    await _scheduleDailyNotification(
      id: _dinnerNotificationId,
      hour: hour,
      minute: minute,
      title: '🍽️ Dinner Time!',
      body: 'Time for dinner! Remember to log your meal before ending the day.',
      payload: 'dinner',
    );
  }

  /// Schedule a daily notification at a specific time
  static Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    await _notifications.cancel(id);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'meal_reminders',
      'Meal Reminders',
      channelDescription: 'Reminders to log your meals',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('Scheduled $payload reminder at $hour:$minute');
  }

  /// Cancel all meal reminders
  static Future<void> cancelAllMealReminders() async {
    await _notifications.cancel(_breakfastNotificationId);
    await _notifications.cancel(_lunchNotificationId);
    await _notifications.cancel(_dinnerNotificationId);
    debugPrint('Cancelled all meal reminders');
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
