<h1 align="center">Homelab</h1>

<p align="center">
  Documentation, configuration and administration of my Homelab.<br>
  Powered by Ansible. Always a work in progress.
</p>

<p align="center">
  <a aria-label="Apache 2.0 License" href="https://github.com/timschneiderxyz/homelab/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-apache 2.0-7aa2f7?style=for-the-badge&labelColor=1a1b26" alt="Apache 2.0 License">
  </a>
</p>

## Setup

This project uses Ansible Vault to store sensitive data in `vars/vault.yaml`. To prevent accidentally committing unencrypted secrets, a git pre-commit hook is available.

To install the hook, which checks if `vars/vault.yaml` is encrypted before each commit, run the following commands:

```bash
chmod u+x ./git-vault-hook.sh
./git-vault-hook.sh
```
