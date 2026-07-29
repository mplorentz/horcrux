import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/key_diagram.dart';
import '../widgets/row_button.dart';
import 'account_choice_screen.dart';

/// Onboarding explainer screen showing the interactive hub-and-spoke diagram.
///
/// Flow: OnboardingScreen → [Learn More] → HowItWorksScreen → [Get Started] → AccountChoiceScreen
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
  int _stewardSliderValue = 3;
  int _thresholdSliderValue = 2;

  List<KeyDiagramSteward> get _stewards {
    return List.generate(
      _stewardCount,
      (i) => KeyDiagramSteward(
        id: 'steward_$i',
        label: 'Steward ${i + 1}',
        isPlaceholder: true,
      ),
    );
  }

  void _onStewardSliderChanged(double value) {
    setState(() {
      _stewardSliderValue = value.round();
      _stewardCount = _stewardSliderValue;
      _threshold = _threshold.clamp(1, _stewardCount);
      _thresholdSliderValue = _threshold;
      _changeCounter++;
    });
  }

  void _onThresholdSliderChanged(double value) {
    setState(() {
      _thresholdSliderValue = value.round();
      _threshold = _thresholdSliderValue;
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
                              '$_stewardCount stewards, any $_threshold can recover',
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
                            child: TextButton(
                              onPressed: () {
                                // ignore: deprecated_member_use
                                launchUrl(
                                  Uri.parse('https://horcruxbackup.com/how-it-works/'),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              child: Text(
                                'Learn more on horcruxbackup.com',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: primaryText,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountChoiceScreen(),
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
        children: const [
          TextSpan(text: 'Horcrux stores your secrets in encrypted '),
          TextSpan(
            text: 'vaults',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: '. Each vault is split into multiple '),
          TextSpan(
            text: 'keys',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: ' held by trusted people called ',
          ),
          TextSpan(
            text: 'stewards',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: '. You choose how many keys to create, who holds them, and the '),
          TextSpan(
            text: 'threshold',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: ' — how many stewards must cooperate to open the vault. To recover your secrets, stewards request keys from each other. They\'ll receive a notification from Horcrux asking whether to share their key. Only when the threshold is met can the vault be opened.',
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
                value: _stewardSliderValue.toDouble(),
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
                value: _thresholdSliderValue.toDouble(),
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