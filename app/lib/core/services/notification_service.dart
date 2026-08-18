import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../database/database.dart';
import 'database_provider.dart';
import '../../../features/dict_card/dict_card_provider.dart';
import '../../../features/shell/app_shell.dart';

final _plugin = FlutterLocalNotificationsPlugin();

// Set in main.dart so notification tap can navigate via Riverpod
ProviderContainer? notificationContainer;

const _notifId     = 1;
const _channelId   = 'sinosphere_daily';
const _channelName = 'Daily Word';
const _notifHour   = 14; // 2pm local time

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _plugin.initialize(
    const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: _onTap,
  );
  await _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

void _onTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  notificationContainer?.read(activeSymbolProvider.notifier).set(payload);
  notificationContainer?.read(tabIndexProvider.notifier).set(0);
}

tz.TZDateTime _nextInstanceOf(int hour) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

Future<void> scheduleWordOfDay(ProviderContainer container) async {
  try {
    final words = await container.read(databaseProvider).collectionDao
        .getRandomPracticeWords(1);
    if (words.isEmpty) return;
    final word = words.first;
    await _plugin.cancelAll();

    const androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: 'Daily vocabulary word',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: false, presentSound: false,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      _notifId,
      '${word.simplified}  ${word.hangul ?? ''}',
      '${word.hanViet}  ·  ${word.englishDef}',
      _nextInstanceOf(_notifHour),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: word.simplified,
    );
  } catch (_) {}
}
