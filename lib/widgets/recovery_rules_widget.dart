import 'package:flutter/material.dart';

import '../models/vault.dart';
import 'push_privacy_learn_more_text.dart';

/// Widget for configuring recovery rules (threshold) and per-vault push
/// alerts for a recovery plan
class RecoveryRulesWidget extends StatelessWidget {
  final int threshold;
  final int stewardCount;
  final ValueChanged<int> onThresholdChanged;
  final bool alertStewardsWithPush;
  final ValueChanged<bool> onAlertStewardsWithPushChanged;

  const RecoveryRulesWidget({
    super.key,
    required this.threshold,
    required this.stewardCount,
    required this.onThresholdChanged,
    required this.alertStewardsWithPush,
    required this.onAlertStewardsWithPushChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recovery Rules',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Configure the number of keys needed to unlock the vault. Each steward receives one key to the vault. The number of keys needed to unlock may be less than the total number of stewards for redundancy.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (stewardCount == 0) ...[
              Text(
                'You must add stewards before adjusting the recovery threshold.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              _buildPushStewardsRow(context),
            ] else ...[
              Text(
                'Keys Needed to Unlock: $threshold',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              // The screen normalizes _threshold on every steward mutation, so
              // the value passed here is already in [minThresholdForDisplay(n), n].
              // Using it directly (rather than clamping) surfaces any drift as a
              // visible slider/text mismatch instead of a silent inconsistency.
              Slider(
                value: threshold.toDouble(),
                min: VaultBackupConstraints.minThresholdForDisplay(stewardCount).toDouble(),
                max: stewardCount.toDouble(),
                divisions:
                    stewardCount - VaultBackupConstraints.minThresholdForDisplay(stewardCount) > 0
                        ? stewardCount - VaultBackupConstraints.minThresholdForDisplay(stewardCount)
                        : null,
                onChanged: (value) {
                  onThresholdChanged(value.round());
                },
              ),
              Text(
                'With your current plan $stewardCount key${stewardCount == 1 ? '' : 's'} will be generated and $threshold steward${threshold == 1 ? '' : 's'} will need to agree to unlock the vault.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              _buildPushStewardsRow(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPushStewardsRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enable push notifications',
                style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              const PushPrivacyLearnMoreText(),
            ],
          ),
        ),
        Switch(
          key: const ValueKey('alert_stewards_push_switch'),
          value: alertStewardsWithPush,
          onChanged: onAlertStewardsWithPushChanged,
        ),
      ],
    );
  }
}
