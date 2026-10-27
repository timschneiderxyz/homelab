#!/bin/zsh
#MISE description="Install dotfiles"
#USAGE arg "<host>" help="Host folder in hosts/"
#USAGE flag "-n --dry-run" help="Only show what would change, write and restart nothing"
set -eu -o pipefail

zparseopts -D -E -F -- n=dry -dry-run=dry

source lib/host.sh "$1"

remote 'command -v zsh > /dev/null' || { echo "zsh is not installed on $1" >&2; exit 1 }

files=(${(f)"$(git ls-files shared/dotfiles)"})
(( $#files )) || { echo "No tracked files in shared/dotfiles" >&2; exit 1 }

changed=()
for src in $files; do
  changed+=(${(f)"$(put ${src#shared/dotfiles/} 644 < $src)"})
done
for leftover in .profile .bashrc .bash_logout .bash_history .lesshst; do
  changed+=(${(f)"$(drop $leftover)"})
done

if [[ $(remote 'getent passwd "$(id -un)" | cut -d: -f7') != */zsh ]]; then
  (( $#dry )) || remote 'chsh -s "$(command -v zsh)"'
  changed+=('login shell → zsh')
fi
(( $#dry )) || remote 'mkdir -p .cache/zsh .local/bin .local/share .local/state'

report dotfiles $changed
