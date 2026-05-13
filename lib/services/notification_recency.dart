import '../database/app_database.dart';

const String firstAppOpenUtcKey = 'horcrux_first_open_utc_ms';

const Duration eventRecencySlack = Duration(hours: 1);

Future<DateTime> getFirstAppOpenUtc({required AppDatabase database}) async {
  final ms = await database.appStateDao.getInt(firstAppOpenUtcKey);
  if (ms != null) {
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
  final now = DateTime.now().toUtc();
  await database.appStateDao.setInt(
    key: firstAppOpenUtcKey,
    value: now.millisecondsSinceEpoch,
  );
  return now;
}

/// Whether an event created at [eventUtc] should be treated as recent (and
/// therefore notifiable) relative to [firstOpenUtc].
///
/// Events older than `firstOpenUtc - eventRecencySlack` are relay backfill and
/// should be ignored by the notification layer; newer events are recent.
bool isEventRecent(DateTime eventUtc, DateTime firstOpenUtc) =>
    eventUtc.isAfter(firstOpenUtc.subtract(eventRecencySlack));
