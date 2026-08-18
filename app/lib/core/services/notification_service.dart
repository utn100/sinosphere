import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
const _notifHour   = 15; // 3pm

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  // Use device's UTC offset to approximate local timezone
  final offsetSeconds = DateTime.now().timeZoneOffset.inSeconds;
  final locations = tz.timeZoneDatabase.locations;
  // Find a location matching the device's current UTC offset
  tz.Location? match;
  for (final loc in locations.values) {
    final tzNow = tz.TZDateTime.now(loc);
    if (tzNow.timeZoneOffset.inSeconds == offsetSeconds) {
      match = loc;
      break;
    }
  }
  tz.setLocalLocation(match ?? tz.UTC);

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

const _notifDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    _channelId, _channelName,
    channelDescription: 'Daily vocabulary word',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  ),
  iOS: DarwinNotificationDetails(
    presentAlert: true, presentBadge: false, presentSound: false,
  ),
);

Future<void> scheduleWordOfDay(ProviderContainer container) async {
  try {
    final words = await container.read(databaseProvider).collectionDao
        .getRandomPracticeWords(1);
    if (words.isEmpty) return;
    final word = words.first;
    await _plugin.cancelAll();

    // Fire immediately so user can verify notifications work on this install
    await _plugin.show(
      _testNotifId,
      '📖 ${word.simplified}  ${word.hangul ?? ''}',
      '${word.hanViet}  ·  ${word.englishDef}',
      _notifDetails,
      payload: word.simplified,
    );

    // Schedule daily at 3pm
    await _plugin.zonedSchedule(
      _notifId,
      '📖 ${word.simplified}  ${word.hangul ?? ''}',
      '${word.hanViet}  ·  ${word.englishDef}',
      _nextInstanceOf(_notifHour),
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
