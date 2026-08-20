import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
/// Flip to true (and set _showNotifDiagnostics=true in settings_screen.dart) to
/// debug notification delivery from an installed release APK. See BUILD_STATUS.
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
const kNotifMinute   = 'sinosphere_notif_minute';
const kNotifOnOpen   = 'sinosphere_notif_on_open';

/// Maps deprecated IANA timezone aliases that some OEMs still report to their
/// canonical names present in the `timezone` package DB. Without this, e.g.
/// Vietnamese devices reporting "Asia/Saigon" fail getLocation() and fall back
/// to UTC — shifting every scheduled notification by the UTC offset.
String _canonicalZone(String z) {
  const aliases = {
    'Asia/Saigon':      'Asia/Ho_Chi_Minh',
    'Asia/Calcutta':    'Asia/Kolkata',
    'Asia/Rangoon':     'Asia/Yangon',
    'Asia/Katmandu':    'Asia/Kathmandu',
    'Asia/Ulan_Bator':  'Asia/Ulaanbaatar',
    'Asia/Chungking':   'Asia/Shanghai',
    'Asia/Harbin':      'Asia/Shanghai',
    'Asia/Thimbu':      'Asia/Thimphu',
    'Asia/Dacca':       'Asia/Dhaka',
    'America/Buenos_Aires': 'America/Argentina/Buenos_Aires',
    'Pacific/Ponape':   'Pacific/Pohnpei',
    'Pacific/Truk':     'Pacific/Chuuk',
  };
  return aliases[z] ?? z;
}

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  // Resolve the device's real IANA zone (e.g. "Asia/Bangkok") via a single
  // platform-channel call — NOT by iterating tz.timeZoneDatabase (that 600-entry
  // loop caused the old startup freeze). Falls back to UTC on any failure so this
  // can never hang or throw. Runs fire-and-forget after runApp, so even the
  // await here never blocks the splash.
  try {
    final raw = await FlutterTimezone.getLocalTimezone(); // String in v4.x
    // Some OEMs report deprecated IANA aliases the tz database no longer holds
    // (e.g. Vietnam devices report "Asia/Saigon" but the DB only has
    // "Asia/Ho_Chi_Minh"). Map known aliases to their canonical name; otherwise
    // getLocation() throws and we'd wrongly fall back to UTC.
    final zone = _canonicalZone(raw);
    tz.setLocalLocation(tz.getLocation(zone));
    _diag('local zone = $zone (device reported $raw)');
  } catch (e) {
    tz.setLocalLocation(tz.UTC);
    _diag('zone lookup failed ($e) — falling back to UTC');
  }

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

tz.TZDateTime _nextInstanceOf(int hour, int minute) {
  // tz.local is the device's real zone (set in initNotifications), so this is
  // plain local-time math — no manual UTC offset juggling. zonedSchedule with
  // matchDateTimeComponents.time then repeats daily at this local wall-clock
  // time, correctly following DST/travel.
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
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
    icon: 'ic_notification',
    // Full-color app icon shown as the large thumbnail on the right.
    // (The small status-bar icon must stay a monochrome silhouette.)
    largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
  ),
  iOS: DarwinNotificationDetails(
    presentAlert: true, presentBadge: false, presentSound: false,
  ),
);

/// Diagnostic: returns a human-readable snapshot of the notification setup so we
/// can see on-device (via SnackBar) what the OS actually reports. Covers the
/// three things that silently block delivery on Android: notifications disabled,
/// exact alarms not permitted, and which zone/time we're scheduling for.
Future<String> notifDiagnostics() async {
  final sb = StringBuffer();
  try {
    if (!_initialized) {
      await initNotifications();
      _initialized = true;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      final canExact = await android.canScheduleExactNotifications();
      sb.writeln('notifsEnabled=$enabled');
      sb.writeln('canScheduleExact=$canExact');
    } else {
      sb.writeln('(iOS or no Android impl)');
    }
    final prefs = await SharedPreferences.getInstance();
    final hour   = prefs.getInt(kNotifHour)   ?? 15;
    final minute = prefs.getInt(kNotifMinute) ?? 0;
    sb.writeln('zone=${tz.local.name}');
    sb.writeln('next=${_nextInstanceOf(hour, minute)}');
  } catch (e) {
    sb.writeln('ERROR: $e');
  }
  return sb.toString().trim();
}

/// Diagnostic: fire a notification immediately (proves the channel + delivery
/// work, independent of scheduling/Doze).
Future<void> sendTestNotificationNow() async {
  if (!_initialized) {
    await initNotifications();
    _initialized = true;
  }
  final granted = await requestNotificationPermission();
  _diag('sendTestNow: permission=$granted');
  await _plugin.show(_testNotifId, 'Test notification 🔔',
      'If you see this, delivery works.', _notifDetails, payload: 'zh|test');
  _diag('sendTestNow: show() returned');
}

/// Diagnostic: schedule a one-off notification ~1 minute out using the exact
/// alarm path (proves scheduled delivery works without waiting until tomorrow).
Future<void> scheduleTestInOneMinute() async {
  if (!_initialized) {
    await initNotifications();
    _initialized = true;
  }
  await requestNotificationPermission();
  final android = _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  final canExact = await android?.canScheduleExactNotifications();
  _diag('scheduleTest: canScheduleExact=$canExact');
  final when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
  try {
    await _plugin.zonedSchedule(
      _testNotifId, 'Scheduled test ⏰',
      'Fired at ${when.hour}:${when.minute.toString().padLeft(2, '0')} — exact alarm works.',
      when, _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'zh|test',
    );
    _diag('scheduleTest: scheduled for $when');
  } catch (e) {
    _diag('scheduleTest ERROR: $e');
  }
}

Future<void> scheduleWordOfDay(ProviderContainer container, {bool showNow = true}) async {
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

    // Exact-alarm gate: on Android 12+ USE_EXACT_ALARM may not be honored and
    // the OS silently downgrades/refuses the exact alarm — the #1 cause of a
    // scheduled notification never firing. Check, and if not granted, send the
    // user to the system "Alarms & reminders" page to grant it.
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final canExact = await androidImpl.canScheduleExactNotifications();
      _diag('canScheduleExact=$canExact');
      if (canExact == false) {
        _diag('requesting exact-alarm permission…');
        await androidImpl.requestExactAlarmsPermission();
      }
    }

    final prefs   = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kNotifEnabled) ?? true;
    final hour    = prefs.getInt(kNotifHour)     ?? 15;
    final minute  = prefs.getInt(kNotifMinute)   ?? 0;
    final onOpen  = prefs.getBool(kNotifOnOpen)  ?? true;
    // Follow the app's current language mode (persisted in SharedPreferences,
    // since this may run before any provider is available).
    final isKorean = prefs.getString('sinosphere_lang_mode') == 'korean';
    print('[NOTIF] enabled=$enabled hour=$hour minute=$minute onOpen=$onOpen korean=$isKorean');

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

    // Immediate notification on app open (if enabled). Suppressed when
    // rescheduling from Settings (showNow=false) so toggling a switch or
    // changing the time doesn't spam a notification each time.
    if (onOpen && showNow) {
      _diag('calling show()');
      await _plugin.show(_testNotifId, title, body, _notifDetails,
          payload: payload);
      _diag('show() done');
    }

    // Daily scheduled notification
    _diag('calling zonedSchedule() at ${_nextInstanceOf(hour, minute)}');
    await _plugin.zonedSchedule(
      _notifId, title, body,
      _nextInstanceOf(hour, minute),
      _notifDetails,
      // Exact alarm — fires precisely at the chosen hour even in Doze.
      // Backed by USE_EXACT_ALARM in the manifest (granted at install).
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
