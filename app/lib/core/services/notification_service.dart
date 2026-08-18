import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

Future<void> initNotifications() async {
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

    // Show a daily repeating notification at approximately 9am
    // Note: periodicallyShow fires every 24h from first call.
    // On first launch we show immediately if after 9am, or we could just show it.
    await _plugin.periodicallyShow(
      _notifId,
      '${word.simplified}  ${word.hangul != null ? word.hangul! : ''}',
      '${word.hanViet}  ·  ${word.englishDef}',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: word.simplified,
    );
  } catch (_) {}
}
