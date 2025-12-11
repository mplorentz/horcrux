/// Represents a Nostr relay configuration for scanning
class RelayConfiguration {
  final String id;
  final String url;
  final String name;
  final bool isEnabled;
  final DateTime? lastScanned;
  final Duration scanInterval;
  final bool isTrusted;

  const RelayConfiguration({
    required this.id,
    required this.url,
    required this.name,
    this.isEnabled = true,
    this.lastScanned,
    this.scanInterval = const Duration(minutes: 5),
    this.isTrusted = false,
  });

  /// Validate the relay configuration
  bool get isValid {
    // ID must be non-empty
    if (id.isEmpty) return false;

    // URL must be valid WebSocket URL
    if (url.isEmpty || !_isValidWebSocketUrl(url)) return false;

    // Name must be non-empty
    if (name.isEmpty) return false;

    // ScanInterval must be positive
    if (scanInterval.inSeconds <= 0) return false;

    return true;
  }

  /// Check if relay should be scanned now
  bool get shouldScan {
    if (!isEnabled) return false;
    if (lastScanned == null) return true;

    final nextScanTime = lastScanned!.add(scanInterval);
    return DateTime.now().isAfter(nextScanTime);
  }

  /// Get time until next scan
  Duration? get timeUntilNextScan {
    if (lastScanned == null) return Duration.zero;

    final nextScanTime = lastScanned!.add(scanInterval);
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
      'scanInterval': scanInterval.inSeconds,
      'isTrusted': isTrusted,
    };
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

  RelayConfiguration copyWith({
    String? id,
    String? url,
    String? name,
    bool? isEnabled,
    DateTime? lastScanned,
    Duration? scanInterval,
    bool? isTrusted,
  }) {
    return RelayConfiguration(
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      lastScanned: lastScanned ?? this.lastScanned,
      scanInterval: scanInterval ?? this.scanInterval,
      isTrusted: isTrusted ?? this.isTrusted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelayConfiguration && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RelayConfiguration(id: $id, name: $name, url: $url, enabled: $isEnabled)';
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
