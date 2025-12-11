import 'package:flutter/material.dart';
import '../models/vault.dart';

/// Widget for configuring recovery rules (threshold) for a recovery plan
class RecoveryRulesWidget extends StatelessWidget {
  final int threshold;
  final int stewardCount;
  final ValueChanged<int> onThresholdChanged;

  const RecoveryRulesWidget({
    super.key,
    required this.threshold,
    required this.stewardCount,
    required this.onThresholdChanged,
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
            if (stewardCount == 0)
              Text(
                'Add stewards to set up recovery',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              Text(
                'Keys Needed to Unlock: $threshold',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Slider(
                value: threshold.toDouble().clamp(
                      VaultBackupConstraints.minThreshold.toDouble(),
                      stewardCount.toDouble(),
                    ),
                min: VaultBackupConstraints.minThreshold.toDouble(),
                max: stewardCount.toDouble(),
                divisions: stewardCount - VaultBackupConstraints.minThreshold > 0
                    ? stewardCount - VaultBackupConstraints.minThreshold
                    : null,
                onChanged: (value) {
                  onThresholdChanged(value.round());
                },
              ),
              Text(
                'With your current plan $stewardCount key${stewardCount == 1 ? '' : 's'} will be generated and $threshold steward${threshold == 1 ? '' : 's'} will need to agree to unlock the vault.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
