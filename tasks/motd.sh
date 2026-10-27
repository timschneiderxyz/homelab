#!/bin/zsh
#MISE description="Install the login message"
#USAGE arg "<host>" help="Host folder in hosts/"
#USAGE flag "-n --dry-run" help="Only show what would change, write and restart nothing"
set -eu -o pipefail

zparseopts -D -E -F -- n=dry -dry-run=dry

source lib/host.sh "$1"

scripts=(hosts/$1/motd/*(N.))
(( $#scripts )) || { echo "No scripts in hosts/$1/motd/" >&2; exit 1 }

changed=(${(f)"$(put /etc/motd 644 < /dev/null)"})
for script in $scripts; do
  changed+=(${(f)"$(put /etc/update-motd.d/${script:t:r} 755 < $script)"})
done
report motd $changed
