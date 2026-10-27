#!/bin/zsh
#MISE description="Install Tailscale"
#USAGE arg "<host>" help="Host folder in hosts/"
#USAGE flag "-n --dry-run" help="Only show what would change, write and restart nothing"
set -eu -o pipefail

zparseopts -D -E -F -- n=dry -dry-run=dry

source lib/host.sh "$1"
source lib/apt.sh

codename=$(debian_codename)
changed=(${(f)"$(apt_repo tailscale $codename https://pkgs.tailscale.com/stable/debian/$codename.noarmor.gpg /usr/share/keyrings/tailscale-archive-keyring.gpg https://pkgs.tailscale.com/stable/debian/ main)"})
changed+=(${(f)"$(apt_install tailscale)"})

report tailscale $changed

if ! remote 'tailscale status > /dev/null 2>&1'; then
  echo "! tailscale is not logged in, run: ssh $target tailscale up" >&2
fi
