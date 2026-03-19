import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:maibumai/models/item_status.dart';
import 'package:maibumai/models/wish_item.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'wish_review_reminders';
  static const _channelName = '冷静期提醒';
  static const _channelDescription = '到达冷静期后的复看提醒';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {}

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();
    if (kIsWeb) return false;

    var granted = true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    if (androidGranted != null) {
      granted = granted && androidGranted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted != null) {
      granted = granted && iosGranted;
    }

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    final macosGranted = await macos?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (macosGranted != null) {
      granted = granted && macosGranted;
    }

    return granted;
  }

  Future<void> syncWishReminders(List<WishItem> items) async {
    await initialize();
    if (kIsWeb) return;

    final now = DateTime.now();
    final scheduledIds = <int>{};

    for (final item in items) {
      if (item.status != ItemStatus.wish || item.remindAt == null) {
        continue;
      }
      if (!item.remindAt!.isAfter(now)) {
        continue;
      }

      final notificationId = _notificationIdFor(item.id);
      scheduledIds.add(notificationId);
      await _plugin.zonedSchedule(
        id: notificationId,
        title: '心愿单到期提醒',
        body: '“${item.name}”已经到复看时间，重新确认是否还想买。',
        scheduledDate: tz.TZDateTime.from(item.remindAt!, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: item.id,
      );
    }

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (!scheduledIds.contains(request.id)) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  Future<void> cancelAllWishReminders() async {
    await initialize();
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  int _notificationIdFor(String itemId) {
    return itemId.runes.fold<int>(0, (hash, rune) {
          return ((hash * 31) + rune) & 0x7fffffff;
        }) |
        1;
  }
}
