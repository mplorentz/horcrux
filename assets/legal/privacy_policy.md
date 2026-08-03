# Horcrux Privacy Policy

**Effective date:** July 31, 2026
**Operator:** Single Origin Software LLC
**Contact:** support@horcruxbackup.com

This Privacy Policy describes how Single Origin Software LLC ("we") handles information when you use Horcrux. It applies alongside the Nostr protocol's own privacy properties, which we describe below.

## What we collect

- Your Nostr public key (npub) — used to identify your account.
- Your email address — **only if you choose to provide it** on the consent screen.
- Your analytics opt-in preference.
- Your mailing-list preference.
- A record that you accepted these Terms (version + timestamp).
- Push notification tokens (Apple Push Notification service token, Firebase Cloud Messaging token) — **only if you enable push notifications for a vault**.

## What we never collect

- Your vault contents (always encrypted before they leave your device).
- Your Nostr private key.
- Your steward list in unencrypted form (only encoded inside encrypted gift-wraps).

## We do not sell your data

We do not sell, rent, or share your personal data in exchange for money or other valuable consideration. 

## How Nostr works and its privacy tradeoffs

Horcrux communicates over the Nostr protocol. All messages between you and your stewards are end-to-end encrypted using NIP-44 gift wraps, which hide both message content and the sender's public key from relay servers.

Nostr relays — including our operator-run relay — can observe the following metadata:

- Your IP address, associated with your Nostr identity. Using a network anonymizer such as Tor can mitigate this.
- The timing of your gift-wrapped events, which could let a relay infer which stewards belong to which vault.
- Your Nostr public key and the public keys of your stewards, as required by the protocol.

You may choose which relays you use. Using relays you do not trust increases your metadata exposure.

## Push notifications

If you enable push notifications for a vault, Horcrux uses Firebase Cloud Messaging and, where applicable, Apple Push Notification Services to deliver recovery alerts to your stewards. These services can see notification content, which may include vault and steward names. You can disable push notifications at any time, but you will then need to manually notify stewards to open the app.

## Analytics

If you opt in to analytics on the consent screen, we use PostHog to collect anonymized product-usage events (for example: screens viewed, vault created, recovery initiated, errors encountered). We do not send your vault contents, your Nostr private key, or your shards to PostHog. Analytics is strictly opt-in and you can turn it off at any time from Settings → Account.

## Third-party services

| Provider | Data received | Purpose |
|----------|---------------|---------|
| Apple Push Notification service (APNs) | Push token, notification content (vault/steward names) | Delivering push notifications to stewards (iOS) |
| Firebase Cloud Messaging (FCM) | Push token, notification content (vault/steward names) | Delivering push notifications to stewards (Android, where applicable) |
| Nostr relays (operator-run and user-chosen) | Encrypted gift-wrapped events, timing metadata, public keys | Relaying shards and recovery messages per the Nostr protocol |
| PostHog | Anonymized product-usage events (if you opt in) | Product analytics and improvement |

## Data retention

| Data category | Retention |
|---------------|-----------|
| horcrux-api account record (npub, email, preferences, ToS acceptance) | Retained while your account is active, plus 30 days after deletion, then permanently removed |
| Push notification tokens | Retained while push notifications are enabled for at least one vault; removed when you disable push for all vaults or delete your account |
| PostHog analytics events (if opted in) | Retained while your account is active, plus 30 days after deletion, then permanently removed |
| Nostr public events you publish | Persist on relays per relay policy; NIP-62 Request to Vanish on deletion requests removal but relays we do not control may retain them |
| Your private key and vault contents | Never leave your device; deleting the app deletes them |

## Your privacy rights

Depending on where you live, you may have rights regarding your personal data. You can exercise any of the rights below by emailing support@horcruxbackup.com. We will respond within 45 days (with a possible 45-day extension, of which we will notify you).

- **Access and know** — request a copy of the personal data we hold about you.
- **Delete** — request deletion of your personal data. You can also delete your account directly at any time from Settings → Account, which publishes a NIP-62 Request to Vanish and clears your account record on operator-run services.
- **Correct** — request correction of inaccurate personal data.
- **Portability** — request your personal data in a portable, machine-readable format.
- **Opt out of analytics** — turn off analytics at any time from Settings → Account.
- **Opt out of push notifications** — disable push for any or all vaults at any time.

If we deny a request, you may appeal by replying to our denial email. We will respond to appeals within 45 days.

We do not currently process opt-out preference signals (such as Global Privacy Control), because we do not sell personal data or use it for targeted advertising.

## Children's privacy

The Service is not directed to children under 13, and we do not knowingly collect personal information from children under 13. If you believe a child under 13 has provided us personal information, contact support@horcruxbackup.com and we will delete it.

## Changes to this Privacy Policy

We may update this Privacy Policy from time to time. When we do, the version number increases and we will publish the updated Policy on our website at horcruxbackup.com. The updated Policy takes effect 30 days after it is published. If you continue to use the Service after that 30-day period, you are deemed to have accepted the updated Policy. Material changes will be summarized at the top of the updated Policy.

## Contact

Privacy questions: support@horcruxbackup.com.
