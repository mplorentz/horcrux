import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/vault.dart';
import '../providers/recovery_provider.dart';
import '../providers/vault_provider.dart';

/// Widget displaying steward responses
class RecoveryStewardsWidget extends ConsumerWidget {
  final String recoveryRequestId;

  const RecoveryStewardsWidget({super.key, required this.recoveryRequestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(
      recoveryRequestByIdProvider(recoveryRequestId),
    );

    return requestAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
      ),
      data: (request) {
        if (request == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Recovery request not found'),
            ),
          );
        }

        // Now we have the request, get the vault
        final vaultAsync = ref.watch(vaultProvider(request.vaultId));

        return vaultAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading vault: $error'),
            ),
          ),
          data: (vault) {
            // Get all stewards for this vault
            final stewards = _extractStewards(vault, request);

            if (stewards.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No stewards configured',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...stewards.map((info) {
                      return _buildStewardItem(info);
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Extract all stewards from vault, merge with responses
  List<_StewardInfo> _extractStewards(Vault? vault, RecoveryRequest request) {
    if (vault == null) return [];

    // Get stewards with names from backupConfig if available
    if (vault.backupConfig?.stewards.isNotEmpty == true) {
      final result = <_StewardInfo>[];
      for (final kh in vault.backupConfig!.stewards) {
        final pubkey = kh.pubkey;
        if (pubkey == null) continue;
        final response = request.stewardResponses[pubkey];
        result.add(
          _StewardInfo(
            pubkey: pubkey,
            name: kh.displayName,
            contactInfo: kh.contactInfo,
            response: response,
          ),
        );
      }
      return result;
    }

    // Fallback: use stewards from shards
    final shard = vault.mostRecentShard;
    if (shard != null) {
      final stewards = <_StewardInfo>[];

      // Add owner if ownerName is present
      if (vault.ownerName != null) {
        final response = request.stewardResponses[shard.creatorPubkey];
        stewards.add(
          _StewardInfo(
            pubkey: shard.creatorPubkey,
            name: vault.ownerName,
            response: response,
          ),
        );
      } else if (shard.ownerName != null) {
        // Fallback to shard ownerName
        final response = request.stewardResponses[shard.creatorPubkey];
        stewards.add(
          _StewardInfo(
            pubkey: shard.creatorPubkey,
            name: shard.ownerName,
            response: response,
          ),
        );
      }

      // Add stewards - now a list of maps with name, pubkey, and optionally contactInfo
      if (shard.stewards != null) {
        for (final steward in shard.stewards!) {
          final stewardPubkey = steward['pubkey'];
          final stewardName = steward['name'];
          final stewardContactInfo = steward['contactInfo'];
          if (stewardPubkey == null) continue;

          final response = request.stewardResponses[stewardPubkey];
          stewards.add(
            _StewardInfo(
              pubkey: stewardPubkey,
              name: stewardName,
              contactInfo: stewardContactInfo,
              response: response,
            ),
          );
        }
      }

      return stewards;
    }

    return [];
  }

  Widget _buildStewardItem(_StewardInfo info) {
    final response = info.response;
    final status = response?.status ?? RecoveryResponseStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getResponseColor(status).withValues(alpha: 0.1),
            child: Icon(
              _getResponseIcon(status),
              color: _getResponseColor(status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name ?? '${info.pubkey.substring(0, 16)}...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (info.name != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${info.pubkey.substring(0, 16)}...',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (info.contactInfo != null && info.contactInfo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    info.contactInfo!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getResponseColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getResponseColor(status),
                        ),
                      ),
                    ),
                    if (response?.respondedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          _formatDateTime(response!.respondedAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getResponseIcon(RecoveryResponseStatus status) {
    switch (status) {
      case RecoveryResponseStatus.pending:
        return Icons.schedule;
      case RecoveryResponseStatus.approved:
        return Icons.check_circle;
      case RecoveryResponseStatus.denied:
        return Icons.cancel;
      case RecoveryResponseStatus.timeout:
        return Icons.timer_off;
      case RecoveryResponseStatus.error:
        return Icons.error;
    }
  }

  Color _getResponseColor(RecoveryResponseStatus status) {
    switch (status) {
      case RecoveryResponseStatus.pending:
        return Colors.orange;
      case RecoveryResponseStatus.approved:
        return Colors.green;
      case RecoveryResponseStatus.denied:
        return Colors.red;
      case RecoveryResponseStatus.timeout:
        return Colors.grey;
      case RecoveryResponseStatus.error:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Internal data class for steward info
class _StewardInfo {
  final String pubkey;
  final String? name;
  final String? contactInfo;
  final RecoveryResponse? response;

  _StewardInfo({
    required this.pubkey,
    this.name,
    this.contactInfo,
    this.response,
  });
}
