#!/bin/bash

# Script that installs a Git pre-commit hook that prevents an unencrypted
# Ansible Vault file from being committed.

if [ -d .git/ ]; then
[ -f .git/hooks/pre-commit ] && rm .git/hooks/pre-commit
cat <<EOT >> .git/hooks/pre-commit
if ( cat vars/vault.yaml | grep -q "\$ANSIBLE_VAULT;" ); then
  echo "\033[0;32mVault encrypted.\033[0m"
else
  echo "\033[0;31mVault not encrypted!\033[0m"
  exit 1
fi
EOT
fi

chmod u+x .git/hooks/pre-commit
echo "Ansible Vault Pre-Commit Hook installed."
