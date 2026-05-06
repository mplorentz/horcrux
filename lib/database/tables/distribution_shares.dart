import 'package:drift/drift.dart';

import 'distributions.dart';
import 'stewards.dart';

/// Per-(distribution × steward) tracking row. **No `share_payload` column** —
/// the owner never durably retains share material destined for other
/// stewards. The `giftWrapEventId` is captured at gift-wrap construction
/// time (it is not later-reproducible because the NIP-59 wrap is signed by
/// an ephemeral key with randomized `created_at` jitter).
///
/// The `steward_id` FK is RESTRICTed: distribution_shares retain a pointer
/// to the historical steward row, which is why steward rows are never
/// deleted directly — only soft-retired via `leftAt`.
@DataClassName('DistributionShareRow')
class DistributionShares extends Table {
  TextColumn get id => text()();
  TextColumn get distributionId => text().references(
        Distributions,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get stewardId => text().references(
        Stewards,
        #id,
        onDelete: KeyAction.restrict,
      )();
  TextColumn get giftWrapEventId => text()();
  IntColumn get sentAt => integer().nullable()();
  IntColumn get acknowledgedAt => integer().nullable()();
  TextColumn get acknowledgmentEventId => text().nullable()();

  /// Distribution version the steward ack'd; lets us detect stale acks.
  IntColumn get acknowledgmentDistributionVersion => integer().nullable()();

  /// Wire `created_at` of the ack event — kept for audit only, never used
  /// for "freshness" decisions (see "Time, monotonicity, clock skew").
  IntColumn get acknowledgmentCreatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
