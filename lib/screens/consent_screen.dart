import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/terms_of_service.dart';
import '../services/horcrux_api_service.dart';
import '../services/logger.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/consent_form_fields.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button.dart';

/// Onboarding consent screen for Terms of Service and Privacy Policy.
///
/// This is the first child of the combined onboarding consent screen (epic
/// [horcrux_app-mqh1]). It layers the analytics opt-in (qa7n) and
/// email/mailing-list fields (qiec) onto the ToS + Privacy screen.
///
/// The screen:
/// 1. Loads the bundled ToS + Privacy Policy text and version from local
///    assets (see [TermsOfService.loadBundled]) — no network required.
/// 2. Renders the analytics + email + mailing-list form fields (see
///    [ConsentFormFields]) ABOVE the legal text.
/// 3. Renders the legal text as Markdown (scrollable).
/// 4. Requires the user to tap "I agree to the Terms & Privacy Policy"
///    checkbox before proceeding.
/// 5. On acceptance: `POST /tos/accept` with the current version AND
///    `PUT /account` with the analytics/email/mailing-list preferences,
///    then either navigates to [nextScreen] (if provided) or pops back.
///
/// The ToS "I agree" checkbox gates the Continue button only. The analytics
/// and email fields are independent and are submitted with whatever the user
/// entered regardless of the checkbox.
///
/// ## Re-prompt
///
/// When the served version is greater than the last locally-accepted version,
/// this screen is shown again (triggered from app start via
/// [HorcruxApiService.needsConsentAcceptance]).
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
  TermsOfService? _tos;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isAccepting = false;
  bool _agreed = false;

  // Independent consent preferences (submit regardless of ToS checkbox).
  bool _analyticsOptIn = false;
  final TextEditingController _emailController = TextEditingController();
  bool _mailingList = false;

  /// Guards [didChangeDependencies] so the ToS load runs only once.
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      // Load here (not initState) so `DefaultAssetBundle.of(context)` is a
      // valid inherited-widget lookup.
      _loadTermsOfService();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadTermsOfService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tos = await TermsOfService.loadBundled(
        bundle: DefaultAssetBundle.of(context),
      );
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
          _errorMessage = 'Could not load Terms of Service.';
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

      // Navigate immediately — ToS acceptance is the gating consent.
      // Account preferences (analytics, email, mailing-list) are saved
      // fire-and-forget after navigation so a transient API outage never
      // blocks onboarding. Failures are caught internally and logged.
      final next = widget.nextScreen;
      if (next != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            settings: RouteSettings(name: next.runtimeType.toString()),
            builder: (_) => next,
          ),
          (route) => false,
        );
      } else {
        context.showHorcruxSnackBar(
          'Terms & Privacy accepted',
          kind: HorcruxSnackKind.success,
        );
        Navigator.of(context).pop(true);
      }

      // Fire-and-forget account preferences save (non-blocking).
      _saveAccountPreferences(api);
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

  /// Saves the analytics/email/mailing-list preferences via `PUT /account`.
  ///
  /// Failures are surfaced as a non-blocking warning but never prevent the
  /// user from proceeding (the ToS acceptance is the gating consent).
  Future<void> _saveAccountPreferences(HorcruxApiService api) async {
    final email = _emailController.text.trim();
    try {
      await api.updateAccount(
        email: email.isEmpty ? null : email,
        analyticsOptIn: _analyticsOptIn,
        mailingList: _mailingList && email.isNotEmpty,
      );
    } catch (e, st) {
      Log.error('ConsentScreen: failed to save account preferences', e, st);
      if (mounted) {
        context.showHorcruxSnackBar(
          "We couldn't save your contact preferences — you can update them "
          'later in Settings.',
          kind: HorcruxSnackKind.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return HorcruxScaffold(
      appBar: HorcruxAppBar(
        title: 'Consent',
        automaticallyImplyLeading: widget.nextScreen == null,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _buildBody(theme, textTheme),
            ),
            // Show checkbox + continue button once the terms are loaded.
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
                Icons.error_outline,
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
          // Analytics + email + mailing-list fields, rendered ABOVE the
          // legal text per the locked design.
          ConsentFormFields(
            analyticsOptIn: _analyticsOptIn,
            emailController: _emailController,
            mailingList: _mailingList,
            onAnalyticsOptInChanged: (v) => setState(() => _analyticsOptIn = v),
            onEmailChanged: (_) => setState(() {}),
            onMailingListChanged: (v) => setState(() => _mailingList = v),
          ),
          MarkdownBody(
            data: tos.text,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
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
          text: 'Continue',
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
