import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper class for mocking SharedPreferences in tests.
///
/// This class provides a simple way to set up and tear down SharedPreferences
/// mocking across multiple test files. It maintains an in-memory Map to
/// simulate SharedPreferences operations.
///
/// Usage:
/// ```dart
/// final sharedPreferencesMock = SharedPreferencesMock();
///
/// setUpAll(() {
///   sharedPreferencesMock.setUpAll();
/// });
///
/// tearDownAll(() {
///   sharedPreferencesMock.tearDownAll();
/// });
///
/// setUp(() {
///   sharedPreferencesMock.clear();
///   SharedPreferences.setMockInitialValues({});
/// });
/// ```
class SharedPreferencesMock {
  static const MethodChannel _sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  final Map<String, dynamic> _store = {};

  /// Gets the in-memory store for direct access (e.g., for assertions)
  Map<String, dynamic> get store => Map<String, dynamic>.from(_store);

  /// Sets up the SharedPreferences mock handler.
  ///
  /// Call this in setUpAll() to register the mock handler for all tests.
  void setUpAll() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_sharedPreferencesChannel, _handleMethodCall);
  }

  /// Tears down the SharedPreferences mock handler.
  ///
  /// Call this in tearDownAll() to clean up the mock handler.
  void tearDownAll() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_sharedPreferencesChannel, null);
  }

  /// Clears the in-memory store.
  ///
  /// Call this in setUp() to reset the store before each test.
  void clear() {
    _store.clear();
  }

  /// Handles method calls from SharedPreferences.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    final args = call.arguments as Map? ?? {};
    switch (call.method) {
      case 'getAll':
        return Map<String, dynamic>.from(_store);
      case 'setString':
        _store[args['key']] = args['value'];
        return true;
      case 'getString':
        return _store[args['key']];
      case 'remove':
        _store.remove(args['key']);
        return true;
      case 'getStringList':
        final value = _store[args['key']];
        return value is List ? value : null;
      case 'setStringList':
        _store[args['key']] = args['value'];
        return true;
      case 'clear':
        _store.clear();
        return true;
      default:
        return null;
    }
  }
}
