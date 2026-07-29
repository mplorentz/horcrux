import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button.dart';
import '../widgets/horcrux_scaffold.dart';
import 'how_it_works_screen.dart';

/// Onboarding screen shown when user is not logged in
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HorcruxScaffold(
      body: SafeArea(
        bottom: false, // Exclude bottom safe area, let RowButton handle it
        child: Column(
          children: [
            const SizedBox(height: 64),
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
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icon/app_icon.png',
                                  height: 160,
                                  width: 160,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Horcrux',
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                        fontSize: 90,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 64),
                          // Body text explaining Horcrux - left aligned
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Text(
                                  'Horcrux is a tool for backing up sensitive data like digital wills, passwords, and cryptographic keys. Rather than backing the data up to the cloud, Horcrux sends the sensitive data in pieces to your friends and family\'s devices. Recovery is accomplished by getting consent from these friends and family to reassemble your data.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                          // Bottom spacer
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Learn More button at bottom
            RowButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HowItWorksScreen(),
                  ),
                );
              },
              icon: Icons.arrow_forward,
              text: 'Learn More',
              addBottomSafeArea: true,
            ),
          ],
        ),
      ),
    );
  }
}
