import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/invitation_service.dart';
import '../services/logger.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/key_diagram.dart';
import '../widgets/row_button.dart';
import 'account_choice_screen.dart';
import 'start_screen.dart';

/// Onboarding explainer screen showing the interactive hub-and-spoke diagram.
///
/// Flow: OnboardingScreen → [Learn More] → HowItWorksScreen → [Get Started] → StartScreen
/// If a staged invitation exists (cold-start), skips StartScreen and goes
/// directly to AccountChoiceScreen so the pickup hook can fire.
class HowItWorksScreen extends ConsumerStatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  ConsumerState<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends ConsumerState<HowItWorksScreen> {
  // Pre-populated: 3 stewards, threshold 2
  int _stewardCount = 3;
  int _threshold = 2;
  int _changeCounter = 0;

  @override
  void initState() {
    super.initState();
    Log.debug('[onboarding] HowItWorksScreen: initState');
  }

  List<KeyDiagramSteward> get _stewards {
    return List.generate(
      _stewardCount,
      (i) => KeyDiagramSteward(
        id: 'steward_$i',
        label: 'Steward ${i + 1}',
      ),
    );
  }

  void _onStewardSliderChanged(double value) {
    setState(() {
      _stewardCount = value.round().clamp(1, 8);
      _threshold = _threshold.clamp(1, _stewardCount);
      _changeCounter++;
    });
  }

  void _onThresholdSliderChanged(double value) {
    setState(() {
      _threshold = value.round().clamp(1, _stewardCount);
      _changeCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryText = theme.colorScheme.onSurface;

    return HorcruxScaffold(
      appBar: const HorcruxAppBar(title: 'How It Works'),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Explainer paragraph
                          _buildExplainerParagraph(context),
                          const SizedBox(height: 24),

                          // Key diagram (centered)
                          Center(child: _buildDiagram(context)),
                          const SizedBox(height: 12),

                          // Dynamic threshold text
                          Center(
                            child: Text(
                              '$_stewardCount stewards, any $_threshold can open',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: primaryText,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Slider controls
                          _buildSliderControls(context),
                          const SizedBox(height: 16),

                          // External link
                          Center(
                            child: OutlinedButton(
                              onPressed: () {
                                launchUrl(
                                  Uri.parse('https://horcruxbackup.com/how-it-works/'),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              child: const Text('Learn More'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Get Started button at bottom
            RowButton(
              onPressed: () {
                // Cold-start: if a staged invitation exists, skip StartScreen
                // and go directly to account creation so the pickup hook fires.
                final invitationService = ref.read(invitationServiceProvider);
                Log.debug(
                  '[onboarding] HowItWorksScreen: Get Started tapped, '
                  'hasStagedInvitations=${invitationService.hasStagedInvitations}',
                );
                if (invitationService.hasStagedInvitations) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountChoiceScreen(),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StartScreen(),
                  ),
                );
              },
              icon: Icons.arrow_forward,
              text: 'Get Started',
              addBottomSafeArea: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplainerParagraph(BuildContext context) {
    final theme = Theme.of(context);
    final primaryText = theme.colorScheme.onSurface;

    // We use RichText to bold the first occurrence of key terms.
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: primaryText,
          height: 1.6,
        ),
        children: [
          const TextSpan(text: 'Horcrux stores your secrets in encrypted '),
          TextSpan(
            text: 'vaults',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
          ),
          const TextSpan(text: '. Each vault can be opened by multiple '),
          TextSpan(
            text: 'keys',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
          ),
          const TextSpan(text: ' held by trusted people called '),
          TextSpan(
            text: 'stewards',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
          ),
          const TextSpan(
            text: '. You choose how many keys to create, who holds them, and the ',
          ),
          TextSpan(
            text: 'threshold',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
          ),
          const TextSpan(
            text: ' — how many keys are needed to open the vault. Horcrux guides you '
                'through the process.',
          ),
        ],
      ),
    );
  }

  Widget _buildDiagram(BuildContext context) {
    return KeyDiagram(
      stewards: _stewards,
      threshold: _threshold,
      changeCounter: _changeCounter,
      showRecoveryDemo: false,
    );
  }

  Widget _buildSliderControls(BuildContext context) {
    final theme = Theme.of(context);
    final primaryText = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stewards slider
        Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                'Stewards',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: primaryText,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _stewardCount.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                label: '$_stewardCount',
                onChanged: _onStewardSliderChanged,
              ),
            ),
            SizedBox(
              width: 24,
              child: Text(
                '$_stewardCount',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: primaryText,
                ),
              ),
            ),
          ],
        ),
        // Threshold slider
        Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                'Threshold',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: primaryText,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _threshold.toDouble(),
                min: 1,
                max: _stewardCount.toDouble(),
                divisions: _stewardCount > 1 ? _stewardCount - 1 : null,
                label: '$_threshold',
                onChanged: _onThresholdSliderChanged,
              ),
            ),
            SizedBox(
              width: 24,
              child: Text(
                '$_threshold',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: primaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
