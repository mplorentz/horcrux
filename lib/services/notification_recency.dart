import 'package:shared_preferences/shared_preferences.dart';

/// [SharedPreferences] key used to persist the first app-open UTC timestamp.
///
/// All callers that need to decide "is this Nostr event recent, or relay
/// backfill from before the user installed the app?" anchor their decision on
/// the same stored instant, keyed here.
const String firstAppOpenUtcKey = 'horcrux_first_open_utc_ms';

/// Slack added to [firstAppOpenUtcKey] when deciding whether a Nostr event is
/// recent enough to surface as an OS notification — absorbs clock skew between
/// the device and the sender.
const Duration eventRecencySlack = Duration(hours: 1);

/// Reads (and lazily initializes on first call) the first app-open timestamp
/// from [SharedPreferences].
///
/// Returns the persisted UTC instant, or writes `DateTime.now().toUtc()` to
/// disk and returns that. Callers compare incoming Nostr event times against
/// this value via [isEventRecent] to decide whether to show a notification.
Future<DateTime> getFirstAppOpenUtc() async {
  final prefs = await SharedPreferences.getInstance();
  final ms = prefs.getInt(firstAppOpenUtcKey);
  if (ms != null) {
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
  final now = DateTime.now().toUtc();
  await prefs.setInt(firstAppOpenUtcKey, now.millisecondsSinceEpoch);
  return now;
}

/// Whether an event created at [eventUtc] should be treated as recent (and
/// therefore notifiable) relative to [firstOpenUtc].
///
/// Events older than `firstOpenUtc - eventRecencySlack` are relay backfill and
/// should be ignored by the notification layer; newer events are recent.
bool isEventRecent(DateTime eventUtc, DateTime firstOpenUtc) =>
    eventUtc.isAfter(firstOpenUtc.subtract(eventRecencySlack));
