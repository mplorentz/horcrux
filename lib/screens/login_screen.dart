import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import '../providers/key_provider.dart';
import '../utils/validators.dart';
import '../utils/app_initialization.dart';
import '../widgets/row_button.dart';
import '../widgets/horcrux_scaffold.dart';
import '../screens/import_success_screen.dart';

/// Screen for importing existing Nostr keys
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateKeyInput(String input) {
    if (input.trim().isEmpty) {
      return 'Please enter a key';
    }

    final trimmed = input.trim();

    if (isValidNsec(trimmed)) {
      return null; // Valid nsec
    }

    if (isValidHexPrivkey(trimmed)) {
      return null; // Valid hex
    }

    if (isValidBunkerUrl(trimmed)) {
      return 'Bunker URLs are not yet supported';
    }

    return 'Invalid key format. Enter nsec or hex private key.';
  }

  void _onInputChanged(String value) {
    setState(() {
      _errorText = _validateKeyInput(value);
    });
  }

  Future<void> _handleContinue() async {
    final input = _controller.text.trim();
    final error = _validateKeyInput(input);

    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final loginService = ref.read(loginServiceProvider);
      KeyPair? keyPair;

      // Auto-detect format and import
      if (isValidNsec(input)) {
        keyPair = await loginService.importNsecKey(input);
      } else if (isValidHexPrivkey(input)) {
        keyPair = await loginService.importHexPrivateKey(input);
      } else if (isValidBunkerUrl(input)) {
        // This should have been caught by validation, but handle it anyway
        throw UnimplementedError('Bunker URLs are not yet supported');
      } else {
        throw Exception('Invalid key format');
      }

      // Initialize services and refresh key providers
      await initializeAppAndRefreshKeys(ref);

      // Navigate to import success screen
      final privateKey = keyPair.privateKeyBech32;
      if (mounted && privateKey != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImportSuccessScreen(nsec: privateKey),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText =
              e.toString().replaceAll('Exception: ', '').replaceAll('UnimplementedError: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return HorcruxScaffold(
      appBar: AppBar(
        title: const Text('Login with Nostr Key'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Instructions
                    Text(
                      'Enter your Nostr key to import your account',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported formats: nsec, hex, or bunker URL',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    // Text field
                    TextField(
                      controller: _controller,
                      onChanged: _onInputChanged,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Enter nsec, hex private key, or bunker URL',
                        errorText: _errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                    const SizedBox(height: 8),
                    // Helper text
                    Text(
                      'Your key will be stored securely on this device',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Continue button
            RowButton(
              onPressed: _isLoading ? null : _handleContinue,
              icon: Icons.arrow_forward,
              text: _isLoading ? 'Importing...' : 'Continue',
              addBottomSafeArea: true,
            ),
          ],
        ),
      ),
    );
  }
}
