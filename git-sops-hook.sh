#!/bin/zsh

# Installs a Git pre-commit hook that prevents an unencrypted secrets file from being committed.

set -eu -o pipefail

[[ -d .git ]] || { echo "Not a Git repository."; exit 1 }

cat <<'EOT' > .git/hooks/pre-commit
#!/bin/zsh

# Checks the staged version of every *.sops.yaml: sops metadata with a MAC, every other value encrypted.
failed=0
for file in ${(f)"$(git diff --cached --name-only --diff-filter=ACMR -- '*.sops.yaml' ':(exclude).sops.yaml')"}; do
  staged=$(git show ":$file")
  has_mac=$(yq '.sops.mac // "" | test("^ENC\[")' - <<< $staged)
  plain=$(yq '[del(.sops) | .. | select(kind == "scalar")] | map(select(tag != "!!str")) + map(select(tag == "!!str") | select(test("^ENC\[") | not)) | length' - <<< $staged)
  if [[ $has_mac != true || $plain != 0 ]]; then
    printf '\033[0;31mNot encrypted: %s\033[0m\n' $file
    failed=1
  fi
done
(( failed )) || printf '\033[0;32mSecrets encrypted.\033[0m\n'
exit $failed
EOT

chmod u+x .git/hooks/pre-commit
echo "Sops Pre-Commit Hook installed."
