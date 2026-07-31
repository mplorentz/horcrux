import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/invitation_acceptance_screen.dart';
import '../screens/vault_list_screen.dart';
import '../services/invitation_service.dart';

/// Ends an onboarding flow by routing to [InvitationAcceptanceScreen] if a
/// staged invitation exists (picked up via deep link before the user had an
/// account or was logged in), otherwise to [VaultListScreen].
///
/// Clears the entire navigation stack so the user can't back into onboarding.
void routeToVaultListOrStagedInvitation(BuildContext context, WidgetRef ref) {
  final invitationService = ref.read(invitationServiceProvider);
  final staged = invitationService.getStagedInvitations();
  final destination = staged.isNotEmpty
      ? InvitationAcceptanceScreen(invitation: staged.first)
      : const VaultListScreen();

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => destination),
    (route) => false,
  );
}
