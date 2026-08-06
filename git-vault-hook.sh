#!/bin/bash

# Script that installs a Git pre-commit hook that prevents an unencrypted Ansible Vault file from being committed.

if [ ! -d .git/ ]; then
  echo "Not a Git repository."
  exit 1
fi

[ -f .git/hooks/pre-commit ] && rm .git/hooks/pre-commit

cat <<'EOT' > .git/hooks/pre-commit
#!/bin/sh

if grep -q '^\$ANSIBLE_VAULT;' vars/vault.yaml 2>/dev/null; then
  printf '\033[0;32mVault encrypted.\033[0m\n'
else
  printf '\033[0;31mVault not encrypted!\033[0m\n'
  exit 1
fi
EOT

chmod u+x .git/hooks/pre-commit
echo "Ansible Vault Pre-Commit Hook installed."
