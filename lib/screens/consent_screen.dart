import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/terms_of_service.dart';
import '../services/horcrux_api_service.dart';
import '../services/logger.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button.dart';

/// Onboarding consent screen for Terms of Service and Privacy Policy.
///
/// This is the first child of the combined onboarding consent screen (epic
/// [horcrux_app-mqh1]). Future beads will layer analytics opt-in (qa7n) and
/// email/mailing-list fields (qiec) onto this screen.
///
/// The screen:
/// 1. Fetches the current ToS text + version from `GET /tos` on the
///    operator-run horcrux-api.
/// 2. Renders the text (scrollable).
/// 3. Requires the user to tap "I agree to the Terms & Privacy Policy"
///    checkbox before proceeding.
/// 4. On acceptance: `POST /tos/accept` with the current version, then
///    either navigates to [nextScreen] (if provided) or pops back.
///
/// ## Re-prompt
///
/// When the served version is greater than the last locally-accepted version,
/// this screen is shown again (triggered from app start via
/// [HorcruxApiService.needsConsentAcceptance]).
///
/// ## Settings entry
///
/// Accessible from Settings → Account → Terms & Privacy for viewing or
/// re-accepting updated terms.
class ConsentScreen extends ConsumerStatefulWidget {
  /// Optional screen to navigate to after the user accepts the terms.
  ///
  /// When `null`, the screen pops itself after acceptance (used for
  /// re-prompt from Settings or app-start). When provided, the navigation
  /// stack is cleared and replaced with [nextScreen] (via
  /// `pushAndRemoveUntil`).
  final Widget? nextScreen;

  const ConsentScreen({super.key, this.nextScreen});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  /// The fetched ToS data, or null if still loading / errored.
  TermsOfService? _tos;

  /// Non-null when loading or an error occurred.
  String? _errorMessage;
  bool _isLoading = true;
  bool _isAccepting = false;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _loadTermsOfService();
  }

  Future<void> _loadTermsOfService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(horcruxApiServiceProvider);
      final tos = await api.fetchTermsOfService();
      if (mounted) {
        setState(() {
          _tos = tos;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      Log.error('ConsentScreen: failed to load ToS', e, st);
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load Terms of Service. '
              'Please check your internet connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAccept() async {
    if (_tos == null || _isAccepting) return;

    setState(() => _isAccepting = true);

    try {
      final api = ref.read(horcruxApiServiceProvider);
      await api.acceptTermsOfService(_tos!.version);

      if (!mounted) return;

      // Navigate onward or pop back.
      final next = widget.nextScreen;
      if (next != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => next),
          (route) => false,
        );
      } else {
        context.showHorcruxSnackBar(
          'Terms & Privacy accepted',
          kind: HorcruxSnackKind.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      Log.error('ConsentScreen: failed to accept ToS', e, st);
      if (mounted) {
        context.showHorcruxSnackBar(
          'Failed to accept Terms of Service: $e',
          kind: HorcruxSnackKind.error,
        );
        setState(() => _isAccepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return HorcruxScaffold(
      appBar: HorcruxAppBar(
        title: _isAccepting ? 'Accepting...' : 'Terms & Privacy',
        automaticallyImplyLeading: widget.nextScreen == null,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _buildBody(theme, textTheme),
            ),
            // Agree checkbox + Continue button
            if (_tos != null && !_isAccepting) _buildFooter(theme, textTheme),
            if (_isAccepting) _buildAcceptingIndicator(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, TextTheme textTheme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Terms of Service...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadTermsOfService,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final tos = _tos!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Terms of Service & Privacy Policy',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Version ${tos.version}',
              style: textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tos.text,
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Checkbox
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  activeColor: theme.colorScheme.onSurface,
                  checkColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agreed = !_agreed),
                  child: Text(
                    'I agree to the Terms of Service & Privacy Policy',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Continue button
        RowButton(
          onPressed: _agreed ? _handleAccept : null,
          icon: Icons.check,
          text: 'Agree & Continue',
          addBottomSafeArea: true,
        ),
      ],
    );
  }

  Widget _buildAcceptingIndicator(ThemeData theme) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Recording acceptance...'),
        ],
      ),
    );
  }
}