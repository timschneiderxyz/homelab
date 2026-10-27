#!/bin/zsh
#MISE description="Install packages"
#USAGE arg "<host>" help="Host folder in hosts/"
#USAGE flag "-n --dry-run" help="Only show what would change, write and restart nothing"
set -eu -o pipefail

zparseopts -D -E -F -- n=dry -dry-run=dry

source lib/host.sh "$1"
source lib/apt.sh

[[ $(config 'has("packages")') == true ]] || { echo "No packages in $host_file" >&2; exit 1 }

packages=(${(f)"$(config '.packages[]')"})
installed=(${(f)"$(apt_install $packages)"})
report packages $installed
