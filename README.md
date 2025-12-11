# Horcrux

*Horcrux is alpha software, do not use it to back up real secrets at this time.*

What's the most secure and resilient way to backup sensitive files? Splitting them into pieces and distributing them to trusted parties, like friends and family. No single person has full access to your data, but in an emergency the pieces can be reassembled and decrypted.

Horcrux is an app for backup and recovery of sensitive data like digital wills, passwords, and cryptographic keys. Rather than backing the data up to the cloud, horcrux uses Shamir's Secret Sharing algorithm to distribute the sensitive data in pieces to your friends and family's devices. Recovery is accomplished by getting consent from these friends and family to reassemble your data.

This is more private than backing up to the cloud, because no single party has all your data. It's more secure than storing a full copy of the data in a password manager or physical safe because even if one or more devices are compromised the data will not be leaked. And you can still recover your data even if some parties have lost their share.

## Development

This project is in active development. See [CONTRIBUTING.md](CONTRIBUTING.md) for information about contributing.

## Funding

This project is funded by [OpenSats.org](https://opensats.org/) - supporting open-source Bitcoin and Nostr development.

## License

MIT License - see [LICENSE](LICENSE) for details.
