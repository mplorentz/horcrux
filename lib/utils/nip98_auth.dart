import 'package:crypto/crypto.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../models/nostr_kinds.dart';
import 'date_time_extensions.dart';

/// Builds `Authorization: Nostr <base64>` values per
/// [NIP-98 HTTP Auth](https://github.com/nostr-protocol/nips/blob/master/98.md).
///
/// Each authenticated request is stamped with a freshly-signed kind-27235
/// event whose pubkey is the authenticated principal. The event binds the
/// request's HTTP method, absolute URL, and (for POST/PUT) a SHA-256 of the
/// body, so a valid header cannot be replayed against a different request.
///
/// Pure helper — no I/O, no Riverpod. Callers load their key pair (typically
/// via `LoginService.getStoredNostrKey()`) and pass it in.
///
/// ```dart
/// final keyPair = await loginService.getStoredNostrKey();
/// final body = utf8.encode(jsonEncode(payload));
/// final header = Nip98Auth.buildAuthorizationHeader(
///   keyPair: keyPair!,
///   method: 'POST',
///   url: Uri.parse('https://notify.example.com/push'),
///   body: body,
/// );
/// final resp = await http.post(
///   uri,
///   headers: {'Authorization': header, 'Content-Type': 'application/json'},
///   body: body,
/// );
/// ```
class Nip98Auth {
  Nip98Auth._();

  /// Construct and sign a kind-27235 event for the given request and return
  /// the value for the HTTP `Authorization` header (e.g. `"Nostr eyJ...=="`).
  ///
  /// - [keyPair]: The caller's Nostr key pair. `privateKey` must be present.
  /// - [method]: HTTP method. Uppercased before being written to the
  ///   `method` tag so the server can compare case-insensitively.
  /// - [url]: Absolute URL of the request, serialised verbatim into the `u`
  ///   tag. Must match the server's view of the URL exactly (including
  ///   scheme, host, port, path, and query) or the auth will fail.
  /// - [body]: Raw request body bytes for POST/PUT; pass `null` (or empty)
  ///   for GET/DELETE. When present, the SHA-256 digest is attached as a
  ///   `payload` tag so the server can bind the auth to the body contents.
  /// - [createdAt]: Override for the event's `created_at`. Defaults to
  ///   now. The server must only accept recent timestamps (NIP-98 recommends
  ///   within 60 seconds) so callers typically leave this unset.
  ///
  /// Throws [ArgumentError] if [keyPair] has no private key.
  static String buildAuthorizationHeader({
    required KeyPair keyPair,
    required String method,
    required Uri url,
    List<int>? body,
    DateTime? createdAt,
  }) {
    final privateKey = keyPair.privateKey;
    if (privateKey == null || privateKey.isEmpty) {
      throw ArgumentError.value(
        keyPair,
        'keyPair',
        'NIP-98 auth requires a key pair with a private key (read-only '
            'public-key-only pairs cannot sign).',
      );
    }

    final tags = <List<String>>[
      ['u', url.toString()],
      ['method', method.toUpperCase()],
    ];
    if (body != null && body.isNotEmpty) {
      final digest = sha256.convert(body).toString();
      tags.add(['payload', digest]);
    }

    final event = Nip01Event(
      pubKey: keyPair.publicKey,
      kind: NostrKind.httpAuth.value,
      tags: tags,
      content: '',
      createdAt: (createdAt ?? DateTime.now()).secondsSinceEpoch,
    );
    // Local Schnorr signing via the raw private key the caller already
    // holds; equivalent to what Bip340EventSigner.sign does internally.
    event.sign(privateKey);

    return 'Nostr ${event.toBase64()}';
  }
}
