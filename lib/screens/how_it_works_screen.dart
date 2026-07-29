import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _showRecoveryDemo = false;

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

  void _changeStewards(int delta) {
    setState(() {
      _stewardCount = (_stewardCount + delta).clamp(1, 8);
      _threshold = _threshold.clamp(1, _stewardCount);
      _changeCounter++;
    });
  }

  void _changeThreshold(int delta) {
    setState(() {
      _threshold = (_threshold + delta).clamp(1, _stewardCount);
      _changeCounter++;
    });
  }

  void _triggerRecoveryDemo() {
    setState(() {
      _showRecoveryDemo = true;
    });
    // Reset after animation completes (duration: threshold * 400 + 1200 ms)
    Future.delayed(Duration(milliseconds: _threshold * 400 + 1500), () {
      if (mounted) {
        setState(() {
          _showRecoveryDemo = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryText = theme.colorScheme.onSurface;
    final secondaryText = theme.colorScheme.outline;

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

                          // Stepper controls
                          _buildStepperControls(context),
                          const SizedBox(height: 16),

                          // Demo Recovery button (centered)
                          Center(
                            child: OutlinedButton(
                              onPressed: _stewardCount >= 2 && _threshold >= 1
                                  ? _triggerRecoveryDemo
                                  : null,
                              child: Text(
                                'Demo Recovery',
                                style: TextStyle(
                                  fontFamily: 'Archivo',
                                  fontSize: 14,
                                  color: primaryText,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Supporting line (centered)
                          Center(
                            child: Text(
                              'Your secrets, backed up\nto people you trust.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryText,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
        children: [
          const TextSpan(text: 'Horcrux stores your secrets in encrypted '),
          TextSpan(
            text: 'vaults',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: '. Each vault is split into multiple '),
          TextSpan(
            text: 'keys',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(
            text: ' held by trusted people called ',
          ),
          TextSpan(
            text: 'stewards',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: '. You choose how many keys to create, who holds them, and the '),
          TextSpan(
            text: 'threshold',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(
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
      showRecoveryDemo: _showRecoveryDemo,
    );
  }

  Widget _buildStepperControls(BuildContext context) {
    final theme = Theme.of(context);
    final primaryText = theme.colorScheme.onSurface;
    final secondaryText = theme.colorScheme.outline;

    return Column(
      children: [
        // Stewards row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Stewards:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryText,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _stewardCount > 1 ? () => _changeStewards(-1) : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('−', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
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
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _stewardCount < 8 ? () => _changeStewards(1) : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('+', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Threshold row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Threshold:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryText,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _threshold > 1 ? () => _changeThreshold(-1) : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('−', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
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
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _threshold < _stewardCount ? () => _changeThreshold(1) : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('+', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ],
    );
  }
}