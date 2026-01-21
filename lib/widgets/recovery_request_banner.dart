import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../providers/recovery_provider.dart';
import '../services/recovery_service.dart';
import '../services/logger.dart';
import '../screens/recovery_request_detail_screen.dart';
import 'recovery_request_list_modal.dart';

/// Banner for recovery request notifications
/// Displays below AppBar with high contrast styling
/// Automatically shows/hides based on pending recovery requests
class RecoveryRequestBanner extends ConsumerWidget {
  const RecoveryRequestBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequestsAsync = ref.watch(pendingRecoveryRequestsProvider);

    return pendingRequestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        final requestCount = requests.length;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        // Use onSurface color for background (light in dark mode, dark in light mode)
        // This creates high contrast regardless of theme
        final backgroundColor = colorScheme.onSurface;
        final textColor = colorScheme.surface;

        return InkWell(
          onTap: () => _handleTap(context, ref, requests),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon in square container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications,
                    size: 20,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 12),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$requestCount recovery request${requestCount == 1 ? '' : 's'} pending',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to respond',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron icon
                Icon(
                  Icons.chevron_right,
                  color: textColor.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        Log.error('Error loading recovery requests', error);
        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    List<RecoveryRequest> requests,
  ) async {
    if (requests.isEmpty) return;

    if (requests.length == 1) {
      // Single request: navigate directly to detail screen
      final request = requests.first;
      try {
        await ref.read(recoveryServiceProvider).markNotificationAsViewed(request.id);

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecoveryRequestDetailScreen(recoveryRequest: request),
            ),
          );
        }
      } catch (e) {
        Log.error('Error viewing notification', e);
      }
    } else {
      // Multiple requests: show modal list
      RecoveryRequestListModal.show(context, requests);
    }
  }
}
