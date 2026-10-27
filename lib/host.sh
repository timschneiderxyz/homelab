# Reads hosts/<host>/host.yaml and provides helpers to change files on it. Sourced by every task.
# Usage: source lib/host.sh <host>
# A task sets dry=(-n) before sourcing for a dry run: put/drop then only report.

host_file=hosts/$1/host.yaml
[[ -f $host_file ]] || { echo "Unknown host: $1" >&2; exit 1 }

# config <expression>: a value from this host's host.yaml, empty if missing. Lists give one item per line.
config() { yq "($1) // \"\"" $host_file }

ssh_user=$(config .ssh.user)
ssh_host=$(config .ssh.host)
[[ -n $ssh_user && -n $ssh_host ]] || { echo "ssh.user or ssh.host missing in $host_file" >&2; exit 1 }
target="$ssh_user@$ssh_host"
# One connection per host, reused by every following ssh call.
ssh_opts=(-o ControlMaster=auto -o ControlPath="$HOME/.ssh/control-%C" -o ControlPersist=60s -o StrictHostKeyChecking=accept-new)

(( ${+dry} )) || dry=()

# remote <command…>: runs a command on the host
remote() { ssh $ssh_opts "$target" "$@" }

# put <file> <mode>: writes stdin to a remote file if content or mode differ. Prints the file if it changed.
# Relative paths are relative to the SSH user's home.
put() {
  local file=$1 mode=$2
  if (( $#dry )); then
    remote "cmp -s - '$file' && [ \"\$(stat -c %a '$file')\" = $mode ] || echo '$file'"
  else
    # The trap removes the temporary file if the transfer breaks, so no half-written secret stays behind.
    remote "set -e; mkdir -p '${file:h}'; t=\$(mktemp '$file.XXXXXX')
      trap 'rm -f \"\$t\"' EXIT; trap 'rm -f \"\$t\"; exit 1' HUP INT TERM
      cat > \"\$t\"; chmod $mode \"\$t\"
      if cmp -s \"\$t\" '$file' && [ \"\$(stat -c %a '$file')\" = $mode ]; then rm \"\$t\"; else mv \"\$t\" '$file'; echo '$file'; fi"
  fi
}

# drop <file>: removes a remote file if it exists. Prints the file if it was there.
drop() {
  local file=$1
  if (( $#dry )); then
    remote "[ ! -e '$file' ] || echo '$file (remove)'"
  else
    remote "[ ! -e '$file' ] || { rm '$file'; echo '$file (removed)'; }"
  fi
}

# report <name> [changes…]: one summary line for a step
report() {
  local name=$1
  shift
  if (( ! $# )); then
    echo "  $name: unchanged"
  elif (( $#dry )); then
    echo "→ $name: would change ${(j:, :)@}"
  else
    echo "→ $name: changed ${(j:, :)@}"
  fi
}
