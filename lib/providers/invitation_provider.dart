import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invitation_link.dart';
import '../services/invitation_service.dart';
import '../services/logger.dart';

/// Provider for pending invitations by vault
///
/// Returns list of pending invitation links for a given vault.
/// Automatically refreshes when invitations change via stream.
final pendingInvitationsProvider =
    StreamProvider.family<List<InvitationLink>, String>((ref, vaultId) {
  final service = ref.watch(invitationServiceProvider);

  // Return a stream that:
  // 1. Loads initial data
  // 2. Subscribes to updates from the service stream
  return Stream.multi((controller) async {
    // First, load and emit initial invitations
    try {
      final initialInvitations = await service.getPendingInvitations(
        vaultId,
      );
      controller.add(initialInvitations);
    } catch (e) {
      Log.error('Error loading initial invitations for vault $vaultId', e);
      controller.addError(e);
    }

    // Then listen to the service stream for updates
    final subscription = service.invitationsChangedStream.listen(
      (_) async {
        try {
          final invitations = await service.getPendingInvitations(vaultId);
          controller.add(invitations);
        } catch (e) {
          Log.error('Error reloading invitations for vault $vaultId', e);
          controller.addError(e);
        }
      },
      onError: (error) {
        Log.error(
          'Error in invitationsChangedStream for vault $vaultId',
          error,
        );
        controller.addError(error);
      },
      onDone: () {
        controller.close();
      },
    );

    // Clean up when the provider is disposed
    controller.onCancel = () {
      subscription.cancel();
    };
  });
});

/// Provider for invitation lookup by code
///
/// Returns invitation link if found, null otherwise.
/// Automatically refreshes when invitation data changes via stream.
final invitationByCodeProvider = StreamProvider.family<InvitationLink?, String>(
  (ref, inviteCode) {
    final service = ref.watch(invitationServiceProvider);

    // Return a stream that:
    // 1. Loads initial data
    // 2. Subscribes to updates from the service stream
    return Stream.multi((controller) async {
      // First, load and emit initial invitation
      try {
        final initialInvitation = await service.lookupInvitationByCode(
          inviteCode,
        );
        controller.add(initialInvitation);
      } catch (e) {
        Log.error('Error loading invitation by code $inviteCode', e);
        controller.addError(e);
      }

      // Then listen to the service stream for updates
      final subscription = service.invitationsChangedStream.listen(
        (_) async {
          try {
            final invitation = await service.lookupInvitationByCode(inviteCode);
            controller.add(invitation);
          } catch (e) {
            Log.error('Error reloading invitation by code $inviteCode', e);
            controller.addError(e);
          }
        },
        onError: (error) {
          Log.error(
            'Error in invitationsChangedStream for code $inviteCode',
            error,
          );
          controller.addError(error);
        },
        onDone: () {
          controller.close();
        },
      );

      // Clean up when the provider is disposed
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  },
);
