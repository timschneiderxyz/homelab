<h1 align="center">Homelab</h1>

<p align="center">
  Setup and configuration of my homelab.<br>
  Always a work in progress.
</p>

<p align="center">
  <a aria-label="Apache 2.0 License" href="https://github.com/timschneiderxyz/homelab/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-apache 2.0-7aa2f7?style=for-the-badge&labelColor=1a1b26" alt="Apache 2.0 License">
  </a>
</p>

## Structure

```
hosts/<host>/
├── host.yaml            # host configuration
├── secrets.sops.yaml    # secrets, encrypted with sops
├── motd/                # motd scripts
└── containers/<name>/   # compose.yaml and config files
shared/                  # content used by several hosts
tasks/                   # mise tasks
lib/                     # helpers sourced by the tasks
.sops.yaml               # which age key encrypts *.sops.yaml
git-sops-hook.sh         # installs the pre-commit hook
mise.toml                # mise configuration
```

## Requirements

- `age`, `sops` and `yq` need to be installed.
- A valid age key needs to be in `~/.config/sops/age/keys.txt`.
- The repository needs to be trusted by mise: `mise trust`

## Tasks

| Command                         | Does                                              |
| ------------------------------- | ------------------------------------------------- |
| `mise run setup <host> [-n]`    | Runs the host's `modules`                         |
| `mise run <module> <host> [-n]` | Runs a single module, e.g. `motd` or `containers` |

`mise tasks` lists all modules. `-n` is a dry run: it shows what would change, but writes and restarts nothing.

## Secrets

Secrets are edited with `sops edit hosts/<host>/secrets.sops.yaml`. Values must be strings, so quote anything YAML would read as a number or boolean, e.g. `"0123"` or `"true"`.
