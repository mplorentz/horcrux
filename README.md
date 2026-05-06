# Horcrux

_Horcrux is alpha software, do not use it to back up real secrets at this time._

Horcrux is an app for backup and recovery of sensitive data like digital wills, passwords, and cryptographic keys. Rather than backing the data up to the cloud, Horcrux uses advanced cryptography to distribute the data to the devices of the people you choose. All data is encrypted and can only be decrypted when most or all of these people provide their consent. The result is a virtual vault that no single person or key can open.

## Privacy

Horcrux is designed to protect your data and metadata, but all software comes with inherent risks. To help you understand whether Horcrux is appropriate for your individual threat model here are some of the security tradeoffs we have made:

Horcrux is built on the Nostr protocol which makes strong guarantees about the authorship and integrity of data. All messages between users are end-to-end encrypted using NIP-44 gift wraps, which hides both the content and the sender's public key from relays. Your vault contents and cryptographic keys are always encrypted at rest. Horcrux allows you to choose the relay servers you use to exchange data with your stewards. While these servers act as middlemen who can never decrypt your vault data the following metadata is observable:

- A malicious relay can associate your IP address with your Nostr identity. Using a network-layer anonymizer like Tor or I2P can be used to mitigate this risk.
- A malicious relay could observe the timing of published gift-wrap events to build a list of stewards (identified by their Nostr identity) for a given vault.
- Horcrux allows vault owners to enable push notifications on a per-vault basis. For any vault that has it enabled Horcrux uses its own notification server, Google's Firebase Cloud Messaging service, and Apple's Push Notification Service in order to deliver push notifications for recovery events to stewards. These notification servers can see the content of notifications which sometimes contain steward and vault names, and could deduce who is stewarding a vault with whom. You can limit this metadata leakage by disabling push notifications, but be aware taht you will need to manually notify stewards to open the app when distributing keys or making recovery requests.

## Development

This project is in active development. See [CONTRIBUTING.md](CONTRIBUTING.md) for information about contributing.

## Funding

This project is funded by [OpenSats.org](https://opensats.org/) - supporting open-source Bitcoin and Nostr development.

## License

MIT License - see [LICENSE](LICENSE) for details.
