#!/bin/zsh
#MISE description="Run modules"
#USAGE arg "<host>" help="Host folder in hosts/"
#USAGE flag "-n --dry-run" help="Only show what would change, write and restart nothing"
set -eu -o pipefail

zparseopts -D -E -F -- n=dry -dry-run=dry

host=$1
source lib/host.sh "$host"

host_modules=(${(f)"$(config '.modules[]')"})
for module in $host_modules; do
  [[ -x tasks/$module.sh ]] || { echo "Unknown module: $module (no tasks/$module.sh)" >&2; exit 1 }
done

for module in $host_modules; do
  tasks/$module.sh "$host" $dry
done
