import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/inventory_item.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int daysBefore = 3;
  static const int reminderHour = 9;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'expiry_reminders',
      'Expiry reminders',
      channelDescription: 'Alerts when pantry items are about to expire',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Stable positive int id from the item's String id.
  int _notifId(String itemId) => itemId.hashCode & 0x7FFFFFFF;

  // Returns true if this item was already alerted today, otherwise records it.
  Future<bool> _alreadyAlertedToday(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final key = 'expiry_alert_$itemId';
    if (prefs.getString(key) == today) return true;
    await prefs.setString(key, today);
    return false;
  }

  Future<void> scheduleExpiryReminder({
  required String itemId,
  required String itemName,
  required DateTime expiryDate,
}) async {
  final id = _notifId(itemId);
  await _plugin.cancel(id: id);

  final now = tz.TZDateTime.now(tz.local);
  final today = tz.TZDateTime(tz.local, now.year, now.month, now.day);
  final expiryDay = tz.TZDateTime(
      tz.local, expiryDate.year, expiryDate.month, expiryDate.day);
  final remindAt = expiryDay
      .subtract(const Duration(days: daysBefore))
      .add(const Duration(hours: reminderHour));

  // Whole days from today to expiry (negative means already expired).
  final daysLeft = (expiryDay.difference(today).inHours / 24).round();

  if (remindAt.isAfter(now)) {
    // Not in the window yet: schedule for 9:00 AM, 3 days before expiry.
    await _plugin.zonedSchedule(
      id: id,
      title: 'Expiring soon',
      body: '$itemName expires in $daysBefore days.',
      scheduledDate: remindAt,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return;
  }

  // Already inside the window, or already expired: alert now, once per day.
  if (await _alreadyAlertedToday(itemId)) return;

  String title;
  String body;
  if (daysLeft < 0) {
    final ago = -daysLeft;
    title = 'Item expired';
    body = '$itemName expired $ago day${ago == 1 ? '' : 's'} ago.';
  } else if (daysLeft == 0) {
    title = 'Expiring today';
    body = '$itemName expires today.';
  } else {
    title = 'Expiring soon';
    body = '$itemName expires in $daysLeft day${daysLeft == 1 ? '' : 's'}.';
  }

  await _plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: _details,
  );
}
  Future<void> cancelReminder(String itemId) =>
      _plugin.cancel(id: _notifId(itemId));

  // Called when items are loaded, so reminders survive reinstalls and edits.
  Future<void> rescheduleAll(List<InventoryItem> items) async {
    for (final item in items) {
      try {
        await scheduleExpiryReminder(
          itemId: item.itemId,
          itemName: item.itemName,
          expiryDate: item.expiryDate,
        );
      } catch (_) {}
    }
  }
}