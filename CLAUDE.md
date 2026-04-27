# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Horcrux is a Flutter app for backup and recovery of sensitive data using Shamir's Secret Sharing. Instead of cloud backups, data is distributed in encrypted shards to friends and family via the Nostr protocol. Recovery requires consent from multiple stewards to reassemble the data.

**Key Technologies:**

- Flutter 3.35.0 with Dart SDK ^3.5.3
- Nostr protocol via `ndk` package for decentralized communication
- Riverpod for state management and dependency injection
- Shamir's Secret Sharing via `ntcdcrypto` package
- Flutter Secure Storage for key management

## Coding Principles

The most expensive part of coding is having humans read and reason about code. Optimize for this by writing clear, simple, consise code. We want to handle all edge cases but avoid over-engineering, premature optimization, and defensive programming. Try to keep the length of files between 100 and 300 lines and keep the number of components down when possible. It's ok to repeat small amounts code once or twice if it avoids creating more components or complexity, but beyond that refactor into a shared component.

Delivering a clear, consistent developer experience when writing code is largely defined by the names and idioms that appear in APIs. Inclue all words needed to avoid ambiguity for a person reading the code. Omit needless words. Name variables parameters, and associated types according to their roles rather than their type constraints. Compensate for weak type information to clarify a parameter's role. Prefer method and function names that make use sites form grammatical English phrases. Begin names of factory methods with “make”, e.g. x.makeIterator().

Use imperative verbs for functions with side effects (i.e. `processNewData()`) and nouns for pure functions (i.e. `newDataFromJSON()`). Always use named parameters when the language supports it and always document functions with a short summary of their implementation and any unexpected behavior.

Name Mutating/nonmutating method pairs consistently (i.e. `x.sort()` vs. `x.sorted()`). A mutating method will often have a nonmutating variant with similar semantics, but that returns a new value rather than updating an instance in-place. Uses of Boolean methods and properties should read as assertions about the receiver when the use is nonmutating, e.g. x.isEmpty, line1.intersects(line2).

Protocols that describe what something is should read as nouns (e.g. Collection).

Protocols that describe a capability should be named using the suffixes able, ible, or ing (e.g. Equatable, ProgressReporting).

The names of other types, properties, variables, and constants should read as nouns.

Avoid obscure terms if a more common word conveys meaning just as well. Don’t say “epidermis” if “skin” will serve your purpose. Terms of art are an essential communication tool, but should only be used to capture crucial meaning that would otherwise be lost.

Avoid abbreviations. Abbreviations, especially non-standard ones, are effectively terms-of-art, because understanding depends on correctly translating them into their non-abbreviated forms. The intended meaning for any abbreviation you use should be easily found by a web search.

Embrace precedent. Don’t optimize terms for the total beginner at the expense of conformance to existing culture.

## Common Development Commands

**Note:** This project uses `fvm` (Flutter Version Manager). All flutter commands must be prefixed with `fvm`.

### Running the App

```bash
# Run on default device
fvm flutter run

# Run on specific device
fvm flutter run -d chrome  # Web
fvm flutter run -d macos   # macOS
fvm flutter run -d ios     # iOS simulator

# Run with specific flavor
fvm flutter run --debug
fvm flutter run --release
```

### Testing

```bash
# Run all unit tests (excluding golden tests)
fvm flutter test --exclude-tags=golden

# Run golden screenshot tests
fvm flutter test --tags=golden

# Run tests in a specific file
fvm flutter test test/services/backup_service_test.dart

# Update golden test images (must be run on macOS)
fvm flutter test test/screens --update-goldens

# Run with coverage
fvm flutter test --coverage
```

### Code Quality

```bash
# Format code
fvm dart format .

# Check formatting without modifying files
fvm dart format --set-exit-if-changed .

# Run static analysis
fvm flutter analyze

# Get dependencies
fvm flutter pub get

# Clean build artifacts
fvm flutter clean
```

### Building

```bash
# Build for web (HTML renderer for testing)
fvm flutter build web --web-renderer html

# Build for macOS
fvm flutter build macos

# Build for iOS
fvm flutter build ios
```

### Web Testing with Playwright

```bash
# Build and serve web app for testing (see .vscode/tasks.json)
fvm flutter build web --web-renderer html
cd build/web
python3 -m http.server 8084
```

## Architecture

### State Management: Riverpod Pattern

All state management uses Riverpod with a strict service-based architecture:

**Services** contain business logic and are always instance classes with dependency injection:

```dart
final myServiceProvider = Provider<MyService>((ref) {
  return MyService(
    ref.read(repositoryProvider),
    ref.read(otherServiceProvider),
  );
});

class MyService {
  final MyRepository _repository;
  MyService(this._repository);

  Future<Result> doBusinessLogic() async { ... }
}
```

**Repositories** are only created when data access is complex (caching, streams, multiple queries, 100+ lines). See `.cursorrules` for detailed guidance. Simple CRUD operations stay in services directly.

**Providers** expose data to UI components using various types:

- `Provider<T>` - For services and singletons
- `FutureProvider<T>` - For async data loading
- `StreamProvider<T>` - For reactive streams
- `StreamProvider.family<T, Param>` - For parameterized streams

### Core Services

**LoginService** (`lib/services/login_service.dart`): Manages Nostr key pairs via Flutter Secure Storage. Keys are generated on first launch or during onboarding.

**NdkService** (`lib/services/ndk_service.dart`): Core Nostr protocol integration. Manages NDK connections, subscriptions, and gift-wrapped event handling. Provides streams for recovery requests and responses.

**VaultRepository** (`lib/providers/vault_provider.dart`): Repository pattern for vault CRUD. Manages in-memory cache and SharedPreferences persistence. Emits streams for reactive UI updates.

**BackupService** (`lib/services/backup_service.dart`): Orchestrates the backup process: secret sharing, encryption, and distribution to stewards via Nostr.

**RecoveryService** (`lib/services/recovery_service.dart`): Handles recovery workflow: sending requests to stewards, collecting shard responses, and reassembling secrets.

**InvitationService** (`lib/services/invitation_service.dart`): Manages invitation links and acceptance flow for adding stewards to vaults.

**RelayScanService** (`lib/services/relay_scan_service.dart`): Background service that continuously scans Nostr relays for incoming events (gift-wrapped messages, shard confirmations, recovery responses).

### App Initialization Flow

1. `main.dart` wraps app in `ProviderScope` for Riverpod
2. `_initializeApp()` checks for existing Nostr key via `LoginService`
3. If key exists, calls `initializeAppServices()` to start:
   - Deep link handling (`DeepLinkService`)
   - Relay scanning (`RelayScanService`)
4. If no key, shows `OnboardingScreen` to generate one
5. After onboarding, invalidates key providers to trigger app rebuild

### Nostr Protocol Integration

**Event Types** (defined in `lib/models/nostr_kinds.dart`):

- Gift-wrapped events (NIP-44) for encrypted peer-to-peer messaging
- Custom kinds for shard distribution, confirmations, and recovery

**Key Format Conventions:**

- **Internal**: Hex format (64 chars, no prefix) for storage, processing, API payloads
- **Display**: Bech32 format (`npub1...`, `nsec1...`) for UI, user input, logs

**Event Payloads**: Always use snake_case (not camelCase) in raw Nostr event JSON. NDK automatically converts to camelCase when processing.

**Expiration**: All published events include NIP-40 expiration tags (7 days). Auto-added by `publishEncryptedEvent` functions.

### UI Architecture

**Theme System**: Uses `horcrux3` theme (`lib/widgets/theme.dart`) with muted, professional palette.

**CRITICAL DESIGN RULE**: Orange (#DC714E) appears ONLY on `RowButton` components (primary actions at bottom of screen). All other UI uses Navy-Ink or Umber.

**Key Widgets:**

- `RowButton` - Single primary action (orange, full-width, bottom)
- `RowButtonStack` - Multiple actions with gradient (orange at bottom)
- `VaultCard` - List item for vaults
- `KeyHolderList` - Display stewards with status

**Always reference `DESIGN_GUIDE.md` before making UI changes.** It contains the complete color palette, typography system, and component patterns.

### Data Models

**Vault** (`lib/models/vault.dart`): Core data model. Contains encrypted content, metadata, shards, recovery requests, and backup config. Has `VaultState` enum (recovery/owned/keyHolder/awaitingKey) based on current user's relationship.

**ShardData**: Represents a single shard of the secret. Includes shard index, encrypted data, and steward pubkey.

**BackupConfig**: Shamir parameters (threshold, totalKeys) and steward list with statuses.

**RecoveryRequest**: Tracks active recovery attempts with request ID, status, and collected shards.

**KeyHolder**: Represents a person holding a shard, with status tracking (pending/confirmed/failed).

### Breaking Circular Dependencies

When services depend on each other, add explicit types to providers:

```dart
final Provider<ServiceA> serviceAProvider = Provider<ServiceA>((ref) {
  final ServiceB serviceB = ref.read(serviceBProvider);
  return ServiceA(serviceB);
});

final Provider<ServiceB> serviceBProvider = Provider<ServiceB>((ref) {
  final ServiceA serviceA = ref.read(serviceAProvider);
  return ServiceB(serviceA);
});
```

## Testing Guidelines

### Golden Tests

- Screenshot tests use `golden_toolkit` package
- **MUST be run on macOS** for consistent rendering (CI enforces this)
- Test config in `test/flutter_test_config.dart` loads bundled fonts
- Update goldens: `flutter test test/screens --update-goldens`
- Golden files stored in `test/screens/goldens/`

### Unit Tests

- Mock dependencies using `mockito` package
- Run mocks generator: `flutter pub run build_runner build`
- Test files mirror lib structure: `test/services/`, `test/models/`, etc.

### CI/CD

- GitHub Actions workflow in `.github/workflows/test.yml`
- Runs on macOS for golden test consistency
- Steps: format check → analyze → unit tests → golden tests
- Failed goldens upload artifacts with before/after images

## Security Considerations

**Key Storage**: Nostr private keys stored in Flutter Secure Storage (platform keychain). Never log or expose private keys.

**Encryption**: Uses NIP-44 gift-wrapping for peer-to-peer Nostr events. All shard distribution and recovery messages are encrypted.

**Shamir Constraints**: Min threshold 1, max total keys 10 (see `VaultBackupConstraints`).

**Deep Links**: Invitation links use format `horcrux://join/{inviteCode}`. Handle via `DeepLinkService` with validation.

## Important Cursor Rules (from .cursorrules)

**Service/Repository Pattern**: Only create repositories for complex data access (caching, streams, 100+ lines). Use service-only pattern for simple CRUD.

**No Thin Wrappers**: Don't create repositories that just delegate to services. Use service directly with providers.

**Nostr Conventions**:

- Hex format for internal data, bech32 for display
- Snake_case in Nostr event payloads
- NIP-40 expiration tags on all events

**Design System**: Orange only on RowButton. Check DESIGN_GUIDE.md before UI work.

## Debugging

**Logging**: Use `Log` class from `lib/services/logger.dart`:

```dart
Log.info('Message');
Log.error('Error occurred', exception);
Log.debug('Debugging info');
```

**Debug Sheet**: `DebugInfoSheet` widget shows current pubkey, relay status, and app state.

**Relay Issues**: Check `RelayScanService` logs for connection failures. Default relays in `RelayConfiguration`.

## Project Status

**Alpha Software**: Not production-ready. Do not use for real secrets.

**Funding**: OpenSats.org (Bitcoin/Nostr open-source development)

**License**: MIT
