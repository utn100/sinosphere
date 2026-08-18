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
const _notifHour   = 15; // 3pm local

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  // Use UTC as local — zonedSchedule with matchDateTimeComponents.time
  // fires at the correct local time because the OS handles DST/offsets
  tz.setLocalLocation(tz.UTC);

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
  await _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

@pragma('vm:entry-point')
void _onTapBackground(NotificationResponse response) => _handlePayload(response.payload);

void _onTap(NotificationResponse response) => _handlePayload(response.payload);

void _handlePayload(String? payload) {
  if (payload == null || payload.isEmpty) return;
  final container = notificationContainer;
  if (container == null) return;
  // Multi-char = compound word → open as bottom sheet via pendingCompoundProvider
  // Single char = character → open in dict card directly
  if (payload.length == 1) {
    container.read(activeSymbolProvider.notifier).set(payload);
  } else {
    container.read(pendingCompoundProvider.notifier).set(payload);
  }
  container.read(tabIndexProvider.notifier).set(0);
}

tz.TZDateTime _nextInstanceOf(int hour) {
  // Schedule in device local time — offset from UTC
  final now = DateTime.now();
  final offset = now.timeZoneOffset;
  final nowUtc = tz.TZDateTime.now(tz.UTC);
  // Target time in local terms, expressed as UTC offset
  var scheduled = tz.TZDateTime(tz.UTC,
      nowUtc.year, nowUtc.month, nowUtc.day,
      hour, 0, 0)
      .subtract(offset);
  if (scheduled.isBefore(nowUtc)) {
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

Future<void> initAndSchedule(ProviderContainer container) async {
  try {
    await initNotifications();
    await scheduleWordOfDay(container);
  } catch (e) {
    print('Notification init error: $e');
  }
}

Future<void> scheduleWordOfDay(ProviderContainer container) async {
  try {
    final words = await container.read(databaseProvider).collectionDao
        .getRandomPracticeWords(1);
    if (words.isEmpty) return;
    final word = words.first;
    await _plugin.cancelAll();

    final title = word.simplified.length == 1
        ? '${word.simplified}  ${word.hanViet}'
        : '${word.simplified}  ${word.hangul ?? ''}';
    final body = word.englishDef;

    // Immediate notification for testing
    await _plugin.show(_testNotifId, title, body, _notifDetails,
        payload: word.simplified);

    // Daily scheduled
    await _plugin.zonedSchedule(
      _notifId, title, body,
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
