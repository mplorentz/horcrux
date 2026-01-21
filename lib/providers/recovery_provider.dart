import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/recovery_status.dart' as recovery_status;
import 'vault_provider.dart';
import '../services/recovery_service.dart';
import 'key_provider.dart';

/// Provider for pending recovery request notifications
/// Streams live updates of unviewed recovery requests (excluding user's own requests)
final pendingRecoveryRequestsProvider = StreamProvider<List<RecoveryRequest>>((ref) {
  final service = ref.watch(recoveryServiceProvider);
  return service.notificationStream;
});

/// Provider for recovery status of a specific vault
/// This provides information about whether recovery is available and active recovery requests
final recoveryStatusProvider = Provider.family<AsyncValue<RecoveryStatus>, String>((
  ref,
  vaultId,
) {
  // Watch the vault async value and transform it to recovery status
  final vaultAsync = ref.watch(vaultProvider(vaultId));
  final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

  return vaultAsync.when(
    data: (vault) {
      if (vault == null) {
        return const AsyncValue.data(
          RecoveryStatus(
            hasActiveRecovery: false,
            canRecover: false,
            activeRecoveryRequest: null,
            isInitiator: false,
          ),
        );
      }

      // Get active OR completed recovery requests
      // Completed requests need to be manageable so users can click "Recover Vault"
      // Sort by requestedAt descending to get the most recent request first
      RecoveryRequest? manageableRequest;
      final manageableRequests = vault.recoveryRequests
          .where(
            (r) => r.status.isActive || r.status == RecoveryRequestStatus.completed,
          )
          .toList();

      if (manageableRequests.isNotEmpty) {
        // Sort by requestedAt descending (most recent first)
        manageableRequests.sort(
          (a, b) => b.requestedAt.compareTo(a.requestedAt),
        );
        manageableRequest = manageableRequests.first;
      }

      // Check if we can recover (has sufficient shards)
      final canRecover = manageableRequest != null &&
          manageableRequest.approvedCount >= manageableRequest.threshold;

      // Check if current user is the initiator
      final currentPubkey = currentPubkeyAsync.value;
      final isInitiator = manageableRequest != null &&
          currentPubkey != null &&
          manageableRequest.initiatorPubkey == currentPubkey;

      return AsyncValue.data(
        RecoveryStatus(
          hasActiveRecovery: manageableRequest != null,
          canRecover: canRecover,
          activeRecoveryRequest: manageableRequest,
          isInitiator: isInitiator,
        ),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Data class for recovery status information
class RecoveryStatus {
  final bool hasActiveRecovery;
  final bool canRecover;
  final RecoveryRequest? activeRecoveryRequest;
  final bool isInitiator;

  const RecoveryStatus({
    required this.hasActiveRecovery,
    required this.canRecover,
    required this.activeRecoveryRequest,
    required this.isInitiator,
  });
}

/// Provider for a specific recovery request by ID
/// This watches the vault stream and extracts the recovery request, so it updates automatically
// TODO: This should probably be a StreamProvider? I don't really understand the point of
// providers that don't live update.
final recoveryRequestByIdProvider = Provider.family<AsyncValue<RecoveryRequest?>, String>((
  ref,
  recoveryRequestId,
) {
  // We need to find which vault contains this recovery request
  // Since we don't know the vault ID upfront, we get it from the service once
  // then watch that vault's stream
  return ref.watch(_recoveryRequestVaultIdProvider(recoveryRequestId)).when(
        data: (vaultId) {
          if (vaultId == null) {
            return const AsyncValue.data(null);
          }

          // Now watch the vault stream and extract the recovery request
          final vaultAsync = ref.watch(vaultProvider(vaultId));

          return vaultAsync.when(
            data: (vault) {
              if (vault == null) {
                return const AsyncValue.data(null);
              }

              // Find the recovery request in the vault
              try {
                final request = vault.recoveryRequests.firstWhere(
                  (r) => r.id == recoveryRequestId,
                );
                return AsyncValue.data(request);
              } catch (e) {
                return const AsyncValue.data(null);
              }
            },
            loading: () => const AsyncValue.loading(),
            error: (error, stack) => AsyncValue.error(error, stack),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
});

/// Helper provider to get the vault ID for a recovery request
/// This only needs to be called once since recovery requests don't move between vaults
final _recoveryRequestVaultIdProvider = FutureProvider.family<String?, String>((
  ref,
  recoveryRequestId,
) async {
  final service = ref.watch(recoveryServiceProvider);
  final request = await service.getRecoveryRequest(recoveryRequestId);
  return request?.vaultId;
});

/// Provider for recovery status by recovery request ID
/// This watches the recovery request and computes the status automatically
final recoveryStatusByIdProvider =
    Provider.family<AsyncValue<recovery_status.RecoveryStatus?>, String>((
  ref,
  recoveryRequestId,
) {
  final requestAsync = ref.watch(
    recoveryRequestByIdProvider(recoveryRequestId),
  );

  return requestAsync.when(
    data: (request) {
      if (request == null) return const AsyncValue.data(null);

      // Compute recovery status from the request
      final collectedShardIds = request.stewardResponses.values
          .where((r) => r.shardData != null)
          .map((r) => r.pubkey)
          .toList();

      final threshold = request.threshold;
      final totalStewards = request.totalStewards;
      final respondedCount = request.respondedCount;
      final approvedCount = request.approvedCount;
      final deniedCount = request.deniedCount;
      final canRecover = approvedCount >= threshold;

      return AsyncValue.data(
        recovery_status.RecoveryStatus(
          recoveryRequestId: recoveryRequestId,
          totalStewards: totalStewards,
          respondedCount: respondedCount,
          approvedCount: approvedCount,
          deniedCount: deniedCount,
          collectedShardIds: collectedShardIds,
          threshold: threshold,
          canRecover: canRecover,
          lastUpdated: DateTime.now(),
        ),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
