#!/bin/zsh
#MISE description="Deploy containers"
#USAGE arg "<host>" help="Host folder in hosts/"
#USAGE arg "[containers]" var=#true help="Only these containers (default: all)"
#USAGE flag "-n --dry-run" help="Only show what would change, write and restart nothing"
set -eu -o pipefail

zparseopts -D -E -F -- n=dry -dry-run=dry

host=$1
shift
dir="hosts/$host/containers"
secrets_file="hosts/$host/secrets.sops.yaml"
[[ -d $dir ]] || { echo "No containers for host: $host" >&2; exit 1 }
source lib/host.sh "$host"

if (( $# )); then
  names=("$@")
else
  names=($dir/*(N/:t))
  for name in ${(f)"$(remote 'ls -1p /opt/containers 2>/dev/null | sed -n "s:/\$::p"')"}; do
    [[ -d $dir/$name ]] || echo "! containers/$name: in /opt/containers on $host, but not in $dir" >&2
  done
fi

for name in $names; do
  [[ -f $dir/$name/compose.yaml ]] || { echo "Unknown container: $name" >&2; exit 1 }
done

secrets=
if [[ -f $secrets_file ]]; then
  secrets=$(sops decrypt $secrets_file)

  invalid=(${(f)"$(yq '.[] | to_entries | .[] | select(.value | tag != "!!str") | .key' - <<< $secrets)"})
  (( ! $#invalid )) || { echo "Not a string in $secrets_file, quote it: $invalid" >&2; exit 1 }
  invalid=(${(f)"$(yq '.[] | to_entries | .[] | select(.value | contains("\n")) | .key' - <<< $secrets)"})
  (( ! $#invalid )) || { echo "A .env value cannot span lines in $secrets_file: $invalid" >&2; exit 1 }
  for name in ${(f)"$(yq 'keys | .[]' - <<< $secrets)"}; do
    [[ -d $dir/$name ]] || echo "! containers/$name: secrets in $secrets_file, but no container" >&2
  done
fi

for name in $names; do
  src="$dir/$name"
  dest="/opt/containers/$name"
  changed=(${(f)"$(put "$dest/compose.yaml" 644 < "$src/compose.yaml")"})

  env=(${(f)"$(container=$name yq '(.[strenv(container)] // {}) | to_entries | .[] | .key + "=" + .value' - <<< $secrets)"})
  if (( $#env )); then
    changed+=(${(f)"$(print -rl -- $env | put "$dest/.env" 600)"})
  else
    changed+=(${(f)"$(drop "$dest/.env")"})
    if grep -q '\${' "$src/compose.yaml"; then
      echo "! containers/$name uses variables but has no secrets in $secrets_file" >&2
    fi
  fi

  if (( ! $#changed )); then
    echo "  containers/$name: unchanged"
  elif (( $#dry )); then
    echo "→ containers/$name: would restart (${changed:t})"
  else
    echo "→ containers/$name: restarting (${changed:t})"
    remote "cd '$dest' && docker compose pull --quiet && docker compose up -d --remove-orphans"
  fi
done
