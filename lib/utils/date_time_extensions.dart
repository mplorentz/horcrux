/// Seconds elapsed between the Unix epoch (1970-01-01T00:00:00Z) and now.
///
/// Shorthand for `DateTime.now().secondsSinceEpoch`. Common enough in Nostr
/// event construction and other Unix-timestamp contexts that it earns its
/// own top-level function.
int secondsSinceEpoch() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// Extensions on [DateTime] for common conversions.
extension DateTimeExtension on DateTime {
  /// Seconds elapsed since the Unix epoch (1970-01-01T00:00:00Z).
  ///
  /// Convenience for `millisecondsSinceEpoch ~/ 1000`, which is the form
  /// Nostr event `created_at` values and most Unix-style timestamps want.
  ///
  /// Timezone-independent: the returned integer is the same whether this
  /// [DateTime] is local or UTC, because [millisecondsSinceEpoch] is
  /// defined relative to the absolute instant in time.
  int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;
}
