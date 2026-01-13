import 'package:freezed_annotation/freezed_annotation.dart';

part 'relay_configuration.freezed.dart';

/// Represents a Nostr relay configuration for scanning
@freezed
class RelayConfiguration with _$RelayConfiguration {
  const RelayConfiguration._();

  const factory RelayConfiguration({
    required String id,
    required String url,
    required String name,
    @Default(true) bool isEnabled,
    DateTime? lastScanned,
    Duration? scanInterval,
    @Default(false) bool isTrusted,
  }) = _RelayConfiguration;

  /// Factory with default scanInterval
  factory RelayConfiguration.withDefaults({
    required String id,
    required String url,
    required String name,
    bool isEnabled = true,
    DateTime? lastScanned,
    Duration scanInterval = const Duration(minutes: 5),
    bool isTrusted = false,
  }) {
    return RelayConfiguration(
      id: id,
      url: url,
      name: name,
      isEnabled: isEnabled,
      lastScanned: lastScanned,
      scanInterval: scanInterval,
      isTrusted: isTrusted,
    );
  }

  /// Create from JSON
  factory RelayConfiguration.fromJson(Map<String, dynamic> json) {
    return RelayConfiguration(
      id: json['id'] as String,
      url: json['url'] as String,
      name: json['name'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      lastScanned:
          json['lastScanned'] != null ? DateTime.parse(json['lastScanned'] as String) : null,
      scanInterval: Duration(seconds: json['scanInterval'] as int? ?? 300),
      isTrusted: json['isTrusted'] as bool? ?? false,
    );
  }
}

/// Extension methods for RelayConfiguration
extension RelayConfigurationExtension on RelayConfiguration {
  /// Validate the relay configuration
  bool get isValid {
    // ID must be non-empty
    if (id.isEmpty) return false;

    // URL must be valid WebSocket URL
    if (url.isEmpty || !_isValidWebSocketUrl(url)) return false;

    // Name must be non-empty
    if (name.isEmpty) return false;

    // ScanInterval must be positive
    final interval = scanInterval ?? const Duration(minutes: 5);
    if (interval.inSeconds <= 0) return false;

    return true;
  }

  /// Check if relay should be scanned now
  bool get shouldScan {
    if (!isEnabled) return false;
    if (lastScanned == null) return true;

    final interval = scanInterval ?? const Duration(minutes: 5);
    final nextScanTime = lastScanned!.add(interval);
    return DateTime.now().isAfter(nextScanTime);
  }

  /// Get time until next scan
  Duration? get timeUntilNextScan {
    final interval = scanInterval ?? const Duration(minutes: 5);
    if (lastScanned == null) return Duration.zero;

    final nextScanTime = lastScanned!.add(interval);
    final now = DateTime.now();

    if (now.isAfter(nextScanTime)) {
      return Duration.zero;
    }

    return nextScanTime.difference(now);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'isEnabled': isEnabled,
      'lastScanned': lastScanned?.toIso8601String(),
      'scanInterval': (scanInterval ?? const Duration(minutes: 5)).inSeconds,
      'isTrusted': isTrusted,
    };
  }
}

/// Helper to validate WebSocket URLs
bool _isValidWebSocketUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.scheme == 'ws' || uri.scheme == 'wss';
  } catch (e) {
    return false;
  }
}
