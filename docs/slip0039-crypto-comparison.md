# SLIP-0039 Crypto Comparison: Horcrux vs. NanaVault

A line-by-line comparison of the secret-sharing cryptography in **Horcrux**
(this repo, Flutter/Dart) and **NanaVault** (`pepina-dev/nanavault`, Rust/Tauri).

## Headline

These are **not the same algorithm**, despite both being "GF(256) Shamir."

- **Horcrux** borrows the SLIP-0039 *field* but implements plain textbook Shamir
  wrapped in a ChaCha20-Poly1305 AEAD layer.
- **NanaVault** implements *actual* SLIP-0039 — Feistel encryption of the master
  secret, an embedded integrity digest, mnemonic word encoding, an RS1024
  checksum, a two-level group hierarchy, and it passes the official Trezor test
  vectors.

Horcrux does **not** and **could not** interoperate with a SLIP-0039 wallet.

## Source locations

| Concern | Horcrux | NanaVault |
|---|---|---|
| Field arithmetic | `lib/utils/shamir_gf256/gf256_field.dart` | `src-tauri/src/crypto/slip39/gf256.rs` |
| Interpolation | `lib/utils/shamir_gf256/lagrange_interpolation.dart` | `src-tauri/src/crypto/slip39/gf256.rs` |
| Split / combine | `lib/utils/shamir_gf256/secret_scheme.dart` | `src-tauri/src/crypto/slip39/sss.rs` |
| Polynomial | `lib/utils/shamir_gf256/byte_polynomial.dart` | (folded into sss.rs) |
| AEAD / integrity | `lib/utils/crypto/aead.dart` | `src-tauri/src/crypto/slip39/sss.rs` (digest) + `cipher.rs` |
| Feistel / passphrase | — (none) | `src-tauri/src/crypto/slip39/feistel.rs` |
| Mnemonic encoding | — (none, uses base64url) | `src-tauri/src/crypto/slip39/mnemonic.rs` |
| Checksum | — (none) | `src-tauri/src/crypto/slip39/rs1024.rs` |
| Orchestration | `lib/services/backup_service.dart` | `src-tauri/src/crypto/slip39/mod.rs` |

---

## 1. The finite field — same field, opposite implementation strategy

Both use the Rijndael field (`0x1b` is the low byte of Horcrux's `0x11b`).

**Horcrux** — precomputed log/exp tables (generator `0x03`):

```dart
static int multiply(int a, int b) {
  if (a == 0 || b == 0) return 0;
  return exp3[(log3[a] + log3[b]) % 255];   // table lookups
}
static int divide(int dividend, int divisor) {
  return multiply(dividend, exp3[(255 - log3[divisor]) % 255]);
}
```

**NanaVault** — table-free bitwise carry-less multiply + Fermat inverse:

```rust
pub fn mul(mut a: u8, mut b: u8) -> u8 {
    let mut product = 0u8;
    for _ in 0..8 {
        if b & 1 != 0 { product ^= a; }
        let carry = a & 0x80;
        a <<= 1;
        if carry != 0 { a ^= 0x1b; }   // same field as Horcrux's 0x11b
        b >>= 1;
    }
    product
}
fn inv(a: u8) -> u8 { /* a^254 via square-and-multiply */ }
```

**Trade-off:**
- Horcrux's tables are fast but are the classic AES cache-timing side-channel
  surface (a lookup indexed by secret data can leak via cache).
- NanaVault's bitwise loop avoids table lookups entirely (no cache leak), though
  its `if b & 1` branch is still data-dependent, so it's not strictly
  constant-time either. For splitting a one-shot key this is largely academic,
  but NanaVault's choice is the more defensive one.

---

## 2. Interpolation — nearly identical Lagrange

Both compute `Σ yᵢ · Πⱼ≠ᵢ (x−xⱼ)/(xᵢ−xⱼ)` with XOR as subtraction.

Only structural difference: Horcrux hardcodes the target to `x=0`
(`constantAtZero`); NanaVault interpolates at an arbitrary `x` and short-circuits
when `x` hits a known point (because SLIP-0039 evaluates at 254 **and** 255):

```rust
if let Some((_, value)) = points.iter().find(|(xi, _)| *xi == x) {
    return value.clone();   // avoids divide-by-zero on the secret/digest indices
}
```

Functionally the same math.

---

## 3. Where the secret lives — the core divergence

**Horcrux** — textbook Shamir, secret at **f(0)**:

```dart
final poly = BytePolynomial(degree);
poly.generateCoefficients(secret[i], _random);   // secret is the constant term
for (final x in xCoords) shares[x]![i] = poly.evaluateAt(x);  // x ∈ 1..255, 0 reserved
```

**NanaVault** — SLIP-0039 dialect, secret at **f(255)**, integrity digest at **f(254)**:

```rust
const SECRET_INDEX: u8 = 255;
const DIGEST_INDEX: u8 = 254;
// threshold-2 random shares at x=0.., then digest at 254, secret at 255
base.push((DIGEST_INDEX, digest_share));
base.push((SECRET_INDEX, secret.to_vec()));
for x in (threshold - 2)..count {
    shares.push((x, gf256::interpolate(x, &base)));  // remaining shares interpolated
}
```

Generation strategy also differs: Horcrux picks random **coefficients** then
evaluates; NanaVault picks random **shares** then interpolates the rest.
Mathematically equivalent, but NanaVault's is the SLIP-0039-mandated construction
because it needs the digest at a fixed point.

---

## 4. Integrity — both layered, but in different places

**NanaVault** gets integrity for free at the SSS layer via a truncated
HMAC-SHA256 digest:

```rust
let digest_share = gf256::interpolate(DIGEST_INDEX, shares);
let (claimed, random) = digest_share.split_at(DIGEST_LEN);
if &digest(random, &secret)[..] != claimed {
    return Err(Error::DigestMismatch);   // catches wrong/tampered shares pre-decrypt
}
```

**Horcrux's raw SSS has zero integrity** (the code says so explicitly), so it
bolts on ChaCha20-Poly1305: it splits the AEAD *key* (not the content), ships an
identical encrypted blob with every share, and relies on the Poly1305 tag:

```dart
// "Plain SSS over the content bytes ... returned garbage on tampered shares with no signal."
final aeadKey = Aead.generateKey();
final blobBundle = Aead.encrypt(aeadKey, secretBytes);
final sharesMap = scheme.createShares(aeadKey);   // split the 32-byte key
```

Plus a pre-reconstruction cross-check that all stewards' blobs are byte-identical.

Net: NanaVault has integrity at *two* layers (SLIP digest + its own XChaCha20
file cipher in `cipher.rs`); Horcrux has it at *one* layer (Poly1305) and uses
that AEAD specifically to compensate for SSS having none.

---

## 5. What Horcrux simply doesn't implement

NanaVault implements three SLIP-0039 subsystems with **no Horcrux counterpart**:

**(a) Feistel encryption of the master secret** (`feistel.rs`) — 4-round network,
PBKDF2-HMAC-SHA256 round function, folds in a passphrase:

```rust
const ROUNDS: [u8; 4] = [0, 1, 2, 3];
const BASE_ITERATIONS: u32 = 2500;
pbkdf2_hmac::<Sha256>(&password, &salt, BASE_ITERATIONS << e, &mut output);
```

Makes fewer-than-threshold shares reveal *nothing* and binds an optional
passphrase. Horcrux splits the raw key directly with none of this.

**(b) Mnemonic encoding + RS1024 checksum** (`mnemonic.rs`, `rs1024.rs`) — packs
shares into 10-bit words, a 1024-word list, and a Reed-Solomon checksum that
detects any 3-word error. Shares are human-transcribable. Horcrux shares are
`base64url([x, y0..yn])` machine blobs delivered over Nostr — no words, no
checksum.

**(c) Two-level group hierarchy** (`mod.rs`) — `recover_encrypted_master_secret`
rebuilds group shares from member shares, then the master from group shares.
Production uses 1-of-1, but the machinery exists. Horcrux is strictly
single-level.

---

## 6. Conformance & hygiene

| | Horcrux | NanaVault |
|---|---|---|
| Test oracle | draft-mcgrew-tss-03 KAT | **Official SLIP-0039 vectors** (`test_vectors.json`, passphrase `TREZOR`) |
| Interoperable with Trezor/SLIP wallets | No | Yes (by construction) |
| Secret-size rule | any non-empty | ≥128 bits, multiple of 16 bits |
| threshold=1 | disallowed (min ≥2) | allowed, shares = plaintext copies |
| Memory zeroization | none (Dart GC) | `Zeroizing<Vec<u8>>` on recovered secret |
| RNG | `Random.secure()` | `getrandom` |

---

## Bottom line

- **Horcrux** = "Shamir in the SLIP-0039 *field*, plus ChaCha20-Poly1305 for
  integrity." Minimal, machine-to-machine, Nostr-delivered. The AEAD layer exists
  precisely because bare SSS has no integrity and produces silent garbage on bad
  shares.
- **NanaVault** = "real SLIP-0039" — Feistel + passphrase + digest + mnemonic
  words + RS1024 + groups, validated against the official vectors. Integrity is
  native to the scheme.

### Practical takeaways for Horcrux

1. If interop or external auditability ever matters, NanaVault's digest-at-f(254)
   gives SSS-layer integrity *without* needing the AEAD blob shipped on every
   share — a real architectural simplification worth considering.
2. NanaVault's table-free field multiply is the more side-channel-conservative
   choice than Horcrux's log/exp tables.
3. Conversely, Horcrux's blobs are far more compact for a network protocol than
   word-list mnemonics, and the Poly1305 cross-check catches an attack class
   (stewards disagreeing on the ciphertext) that bare SLIP-0039 doesn't address.
