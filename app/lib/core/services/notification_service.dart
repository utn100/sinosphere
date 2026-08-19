import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'database_provider.dart';
import '../../../features/dict_card/dict_card_provider.dart';
import '../../../features/shell/app_shell.dart';
import '../../app.dart' show rootScaffoldMessengerKey;

final _plugin = FlutterLocalNotificationsPlugin();
bool _initialized = false;

/// When true, notification progress/errors are surfaced on-screen via SnackBar.
/// print() is stripped from Flutter release builds, so this is the only way to
/// diagnose release-only notification failures on a device without adb.
bool notifDebugToUi = false;

void _diag(String msg) {
  print('[NOTIF] $msg'); // stripped in release, kept for debug/logcat
  if (!notifDebugToUi) return;
  final messenger = rootScaffoldMessengerKey.currentState;
  messenger?.showSnackBar(SnackBar(
    content: Text('[NOTIF] $msg'),
    duration: const Duration(seconds: 4),
  ));
}

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

/// Requests the Android 13+ POST_NOTIFICATIONS runtime permission.
/// Isolated in its own guard so it always runs regardless of what happens
/// in the scheduling logic — this is what shows the system dialog on first
/// install. Returns whatever the platform reports (null on iOS / pre-33).
Future<bool?> requestNotificationPermission() async {
  try {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      print('[NOTIF] no Android impl resolved');
      return null;
    }
    final granted = await android.requestNotificationsPermission();
    _diag('permission granted=$granted');
    return granted;
  } catch (e, st) {
    _diag('requestPermission ERROR: $e');
    print('[NOTIF] requestNotificationPermission ERROR: $e\n$st');
    return null;
  }
}

void _handlePayload(String? payload) {
  if (payload == null || payload.isEmpty) return;
  final c = notificationContainer;
  if (c == null) return;
  // Payload is a structured 'kind|value' string (see scheduleWordOfDay). Hand it
  // to the Dict screen, which has DB + BuildContext to resolve it and align the
  // language mode. Legacy plain-string payloads fall through here too and are
  // treated as a ZH lookup by dict_card_screen's parser.
  c.read(pendingNotifWordProvider.notifier).set(payload);
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
    // Full-color app icon shown as the large thumbnail on the right.
    // (The small status-bar icon must stay a monochrome silhouette.)
    largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
  ),
  iOS: DarwinNotificationDetails(
    presentAlert: true, presentBadge: false, presentSound: false,
  ),
);

Future<void> scheduleWordOfDay(ProviderContainer container) async {
  try {
    _diag('start, _initialized=$_initialized');
    if (!_initialized) {
      await initNotifications();
      _initialized = true;
      _diag('initNotifications done');
    }
    // Request permission FIRST, in its own guarded block, so a failure anywhere
    // in the scheduling logic below can never prevent the dialog from appearing.
    // (In release/R8 builds a swallowed exception later was hiding this call.)
    await requestNotificationPermission();

    final prefs   = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kNotifEnabled) ?? true;
    final hour    = prefs.getInt(kNotifHour)     ?? 15;
    final onOpen  = prefs.getBool(kNotifOnOpen)  ?? true;
    // Follow the app's current language mode (persisted in SharedPreferences,
    // since this may run before any provider is available).
    final isKorean = prefs.getString('sinosphere_lang_mode') == 'korean';
    print('[NOTIF] enabled=$enabled hour=$hour onOpen=$onOpen korean=$isKorean');

    if (!enabled) {
      await _plugin.cancelAll();
      return;
    }

    final dao = container.read(databaseProvider).collectionDao;
    final words = isKorean
        ? await dao.getRandomKrNotifWord()
        : await dao.getRandomPracticeWords(1);
    print('[NOTIF] words=${words.length}');
    if (words.isEmpty) return;
    final word  = words.first;
    print('[NOTIF] word=${word.simplified}');
    await _plugin.cancelAll();

    // Rotating encouraging tagline, chosen by day-of-year so it stays stable
    // within a day but changes over time (no Math.random in this codebase path).
    const taglines = [
      'Word of the day 📚',
      "Today's word ✨",
      'Time to learn! 🌱',
      'Your daily word is here 🔤',
      'Keep your streak going 🔥',
    ];
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year)).inDays;
    final tagline = taglines[dayOfYear % taglines.length];

    // Tagline only in the title so it never gets truncated. Body layout:
    //   ZH mode: <word> <pinyin> · <english def>
    //   KR mode: <hangul word> · <english def>   (no reading)
    final title = tagline;
    final String body;
    if (isKorean) {
      body = '${word.simplified} · ${word.englishDef}';
    } else {
      final pinyin = word.pinyin;
      body = pinyin.isNotEmpty
          ? '${word.simplified} $pinyin · ${word.englishDef}'
          : '${word.simplified} · ${word.englishDef}';
    }

    // Structured tap payload so the Dict screen can align language mode and
    // look the word up unambiguously (see _handlePayload + dict_card_screen):
    //   ZH        -> 'zh|<simplified>'
    //   KR native -> 'krn|<id>'   (lookup in korean_words)
    //   KR sino   -> 'krs|<id>'   (lookup in compound_words)
    final String payload;
    if (!isKorean) {
      payload = 'zh|${word.simplified}';
    } else if (word.originType == 'native_korean') {
      payload = 'krn|${word.id}';
    } else {
      payload = 'krs|${word.id}';
    }

    // Immediate notification on app open (if enabled)
    if (onOpen) {
      _diag('calling show()');
      await _plugin.show(_testNotifId, title, body, _notifDetails,
          payload: payload);
      _diag('show() done');
    }

    // Daily scheduled notification
    _diag('calling zonedSchedule() at ${_nextInstanceOf(hour)}');
    await _plugin.zonedSchedule(
      _notifId, title, body,
      _nextInstanceOf(hour),
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
    _diag('scheduled OK');
  } catch (e, st) {
    _diag('ERROR: $e');
    print('[NOTIF] ERROR: $e\n$st');
  }
}
