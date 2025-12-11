import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/key_provider.dart';
import 'services/logger.dart';
import 'screens/vault_list_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/app_initialization.dart';
import 'widgets/theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    // Wrap the entire app with ProviderScope to enable Riverpod
    const ProviderScope(child: HorcruxApp()),
  );
}

class HorcruxApp extends ConsumerStatefulWidget {
  const HorcruxApp({super.key});

  @override
  ConsumerState<HorcruxApp> createState() => _HorcruxAppState();
}

class _HorcruxAppState extends ConsumerState<HorcruxApp> {
  bool _isInitializing = true;
  String? _initError;
  ProviderSubscription<AsyncValue<bool>>? _loginStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupLoginStateListener();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if user has a key - if yes, initialize services
      final loginService = ref.read(loginServiceProvider);
      final existingKey = await loginService.getStoredNostrKey();

      if (existingKey != null) {
        // User is logged in - initialize services
        await initializeAppServices(ref);
      }
      // If no key exists, we'll show onboarding screen

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      Log.error('Error initializing app', e);
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'Failed to initialize: ${e.toString()}';
        });
      }
    }
  }

  void _setupLoginStateListener() {
    // This feels like a smell, I think the MaterialApp in build() should be reacting to the change
    // in isLoggedInProvider on its own but it isn't and I don't have time to fix it atm.
    _loginStateSubscription = ref.listenManual<AsyncValue<bool>>(
      isLoggedInProvider,
      (previous, next) {
        final wasLoggedIn = previous?.valueOrNull ?? false;
        final isLoggedIn = next.valueOrNull ?? wasLoggedIn;

        if (wasLoggedIn && !isLoggedIn) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (route) => false,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _loginStateSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch login state to determine which screen to show
    final isLoggedInAsync = ref.watch(isLoggedInProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Horcrux',
      theme: horcrux3Light,
      darkTheme: horcrux3Dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: _isInitializing
          ? const _InitializingScreen()
          : _initError != null
              ? _ErrorScreen(error: _initError!)
              : isLoggedInAsync.when(
                  data: (isLoggedIn) =>
                      isLoggedIn ? const VaultListScreen() : const OnboardingScreen(),
                  loading: () => const _InitializingScreen(),
                  error: (_, __) => const VaultListScreen(), // Fallback to main screen on error
                ),
    );
  }
}

// Loading screen shown during app initialization
class _InitializingScreen extends StatelessWidget {
  const _InitializingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFf47331)),
            const SizedBox(height: 24),
            Text(
              'Initializing Horcrux...',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              'Setting up secure storage',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// Error screen shown if initialization fails
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 24),
              const Text(
                'Initialization Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  exit(0);
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
