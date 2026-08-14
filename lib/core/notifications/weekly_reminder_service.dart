import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:quran_offline/core/notifications/notification_navigation.dart';
import 'package:quran_offline/core/notifications/weekly_reminder_content.dart';
import 'package:quran_offline/core/reading/reading_activity_service.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the opt-in Friday weekly reading reminder.
class WeeklyReminderService {
  WeeklyReminderService._();

  static final WeeklyReminderService instance = WeeklyReminderService._();

  static const int notificationId = 9001;
  static const String androidChannelId = 'com.tursinalabs.quranoffline.weekly_reminder';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static void registerCoordinator() {
    WeeklyReminderCoordinator.rescheduleFromActivity = () async {
      if (!instance._initialized) return;
      await instance.rescheduleIfEnabled(
        enabled: instance._lastEnabled,
        hour: instance._lastHour,
        minute: instance._lastMinute,
        language: instance._lastLanguage,
      );
    };
  }

  bool _lastEnabled = false;
  int _lastHour = 15;
  int _lastMinute = 30;
  String _lastLanguage = 'en';

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('WeeklyReminderService timezone init failed: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        NotificationNavigation.dispatch(response.payload);
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      NotificationNavigation.dispatch(
        launchDetails?.notificationResponse?.payload,
      );
    }

    _initialized = true;
    registerCoordinator();
    await _rescheduleFromPrefs();
  }

  Future<void> _rescheduleFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedule = readWeeklyReminderSchedule(prefs);
      await rescheduleIfEnabled(
        enabled: schedule.enabled,
        hour: schedule.hour,
        minute: schedule.minute,
        language: schedule.language,
      );
    } catch (e) {
      debugPrint('WeeklyReminderService: reschedule from prefs failed: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final notificationsGranted = await android.requestNotificationsPermission();
      if (notificationsGranted == false) {
        return false;
      }
      return true;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final grantedIos = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    if (grantedIos != null) {
      return grantedIos;
    }

    final mac = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    final grantedMac = await mac?.requestPermissions(alert: true, badge: true, sound: true);
    return grantedMac ?? true;
  }

  Future<void> cancel() async {
    await _plugin.cancel(id: notificationId);
  }

  Future<void> rescheduleIfEnabled({
    required bool enabled,
    required int hour,
    required int minute,
    required String language,
  }) async {
    _lastEnabled = enabled;
    _lastHour = hour;
    _lastMinute = minute;
    _lastLanguage = language;

    if (!_initialized) {
      await initialize();
    }

    await cancel();
    if (!enabled) return;

    final content = buildWeeklyReminderContent(
      language: language,
    );

    final channelName = AppLocalizations.getWeeklyReminderChannelName(language);
    final androidDetails = AndroidNotificationDetails(
      androidChannelId,
      channelName,
      channelDescription: AppLocalizations.getSettingsText('weekly_reminder_subtitle', language),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final next = nextFridayAt(from: DateTime.now(), hour: hour, minute: minute);
    final scheduled = tz.TZDateTime.from(next, tz.local);

    if (kDebugMode) {
      debugPrint(
        'WeeklyReminderService: scheduling id=$notificationId '
        'at $scheduled (${tz.local.name}), recurring Friday ${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}',
      );
    }

    try {
      await _plugin.zonedSchedule(
        id: notificationId,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        title: content.title,
        body: content.body,
        payload: content.payload,
      );
    } catch (e, st) {
      debugPrint('WeeklyReminderService: zonedSchedule failed: $e\n$st');
      rethrow;
    }
  }
}
