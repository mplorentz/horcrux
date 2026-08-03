import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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
/// 1. Loads the bundled ToS + Privacy Policy text and version from local
///    assets (see [TermsOfService.loadBundled]) — no network required.
/// 2. Renders the text as Markdown (scrollable).
/// 3. Requires the user to tap "I agree to the Terms & Privacy Policy"
///    checkbox before proceeding.
/// 4. On acceptance: `POST /tos/accept` with the current version, then
///    either navigates to [nextScreen] (if provided) or pops back.
///
/// ## View-only mode ([viewOnly])
///
/// When opened from Settings > Account > Terms & Privacy, the screen shows
/// the terms without a checkbox or approve button. It auto-accepts silently
/// on load (forced accept) and pops back to the previous screen. The back
/// button is hidden -- the user cannot dismiss without accepting.
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

  /// When `true`, renders as a view-only screen with no checkbox or approve
  /// button. The terms are auto-accepted silently on load. Used from
  /// Settings > Account > Terms & Privacy.
  final bool viewOnly;

  const ConsentScreen({super.key, this.nextScreen, this.viewOnly = false});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  TermsOfService? _tos;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isAccepting = false;
  bool _agreed = false;
  bool _viewOnlyAccepted = false;
  bool _viewOnlyAutoAcceptStarted = false;

  @override
  void initState() {
    super.initState();
    _loadTermsOfService();
  }

  Future<void> _loadTermsOfService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _viewOnlyAutoAcceptStarted = false;
      _viewOnlyAccepted = false;
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
        // In view-only mode, auto-accept after loading.
        if (widget.viewOnly) {
          _autoAcceptTerms(tos);
        }
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

  /// Auto-accepts the current terms silently (view-only mode).
  Future<void> _autoAcceptTerms(TermsOfService tos) async {
    if (_viewOnlyAutoAcceptStarted) return;
    _viewOnlyAutoAcceptStarted = true;

    try {
      final api = ref.read(horcruxApiServiceProvider);
      await api.acceptTermsOfService(tos.version);
    } catch (e, st) {
      // POST /tos/accept failures are silently ignored so the user can
      // proceed offline. The acceptance will be re-attempted on next
      // launch via needsConsentAcceptance().
      Log.error('ConsentScreen: POST /tos/accept failed (silently ignored)', e, st);
    }

    if (!mounted) return;

    setState(() => _viewOnlyAccepted = true);

    // Brief delay so the user sees the "Accepted" state, then pop back.
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleAccept() async {
    if (_tos == null || _isAccepting) return;

    setState(() => _isAccepting = true);

    try {
      final api = ref.read(horcruxApiServiceProvider);
      await api.acceptTermsOfService(_tos!.version);
    } catch (e, st) {
      // POST /tos/accept failures are silently ignored so the user can
      // proceed offline. The acceptance will be re-attempted on next
      // launch via needsConsentAcceptance().
      Log.error('ConsentScreen: POST /tos/accept failed (silently ignored)', e, st);
    }

    if (!mounted) return;

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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return HorcruxScaffold(
      appBar: HorcruxAppBar(
        title: 'Consent',
        automaticallyImplyLeading: widget.viewOnly ? false : widget.nextScreen == null,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _buildBody(theme, textTheme),
            ),
            // View-only mode: show "Accepted" indicator after auto-accept.
            if (widget.viewOnly && _viewOnlyAccepted) _buildViewOnlyAccepted(theme, textTheme),
            // Onboarding mode: show checkbox + continue button.
            if (!widget.viewOnly && _tos != null && !_isAccepting) _buildFooter(theme, textTheme),
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

  Widget _buildViewOnlyAccepted(ThemeData theme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            'Terms accepted',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
