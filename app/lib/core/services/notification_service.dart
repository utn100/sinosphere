import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../database/database.dart';
import 'database_provider.dart';
import '../../../features/dict_card/dict_card_provider.dart';
import '../../../features/shell/app_shell.dart';

final _plugin = FlutterLocalNotificationsPlugin();

ProviderContainer? notificationContainer;

const _notifId     = 1;
const _testNotifId = 2;
const _channelId   = 'sinosphere_daily';
const _channelName = 'Daily Word';

// SharedPreferences keys
const kNotifEnabled  = 'sinosphere_notif_enabled';
const kNotifHour     = 'sinosphere_notif_hour';
const kNotifOnOpen   = 'sinosphere_notif_on_open';

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.UTC); // device handles local time for scheduled notifications

  const android = AndroidInitializationSettings('@drawable/ic_notification');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _plugin.initialize(
    const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: _onTap,
    onDidReceiveBackgroundNotificationResponse: _onTapBackground,
  );
  // Note: Android 13+ permission is requested automatically on first show()
  // Do NOT await requestNotificationsPermission() here — it blocks the UI
}

@pragma('vm:entry-point')
void _onTapBackground(NotificationResponse r) => _handlePayload(r.payload);
void _onTap(NotificationResponse r)           => _handlePayload(r.payload);

void _handlePayload(String? payload) {
  if (payload == null || payload.isEmpty) return;
  final c = notificationContainer;
  if (c == null) return;
  if (payload.length == 1) {
    c.read(activeSymbolProvider.notifier).set(payload);
  } else {
    c.read(pendingCompoundProvider.notifier).set(payload);
  }
  c.read(tabIndexProvider.notifier).set(0);
}

tz.TZDateTime _nextInstanceOf(int hour) {
  final now    = DateTime.now();
  final offset = now.timeZoneOffset;
  final utcNow = tz.TZDateTime.now(tz.UTC);
  var scheduled = tz.TZDateTime(tz.UTC,
      utcNow.year, utcNow.month, utcNow.day, hour).subtract(offset);
  if (scheduled.isBefore(utcNow)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

const _notifDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    _channelId, _channelName,
    channelDescription: 'Daily vocabulary word',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: 'ic_notification',
  ),
  iOS: DarwinNotificationDetails(
    presentAlert: true, presentBadge: false, presentSound: false,
  ),
);

Future<void> scheduleWordOfDay(ProviderContainer container) async {
  try {
    // Request permission here (non-blocking, activity is already active)
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final prefs   = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kNotifEnabled) ?? true;
    final hour    = prefs.getInt(kNotifHour)     ?? 15;
    final onOpen  = prefs.getBool(kNotifOnOpen)  ?? true;

    if (!enabled) {
      await _plugin.cancelAll();
      return;
    }

    final words = await container.read(databaseProvider).collectionDao
        .getRandomPracticeWords(1);
    if (words.isEmpty) return;
    final word  = words.first;
    await _plugin.cancelAll();

    final title = word.simplified.length == 1
        ? '${word.simplified}  ${word.hanViet}'
        : '${word.simplified}  ${word.hangul ?? ''}';
    final body = word.englishDef;

    // Immediate notification on app open (if enabled)
    if (onOpen) {
      await _plugin.show(_testNotifId, title, body, _notifDetails,
          payload: word.simplified);
    }

    // Daily scheduled notification
    await _plugin.zonedSchedule(
      _notifId, title, body,
      _nextInstanceOf(hour),
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: word.simplified,
    );
  } catch (e) {
    print('Notification error: $e');
  }
}
