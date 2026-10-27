#!/bin/zsh
#MISE description="Mount NFS shares"
#USAGE arg "<host>" help="Host folder in hosts/"
#USAGE flag "-n --dry-run" help="Only show what would change, write and restart nothing"
set -eu -o pipefail

zparseopts -D -E -F -- n=dry -dry-run=dry

source lib/host.sh "$1"
source lib/apt.sh

# Required, so a typo in the key does not unmount everything. `nfs_shares: []` does that on purpose.
[[ $(config 'has("nfs_shares")') == true ]] || { echo "No nfs_shares in $host_file" >&2; exit 1 }
[[ $(config '[.nfs_shares[] | select(.source == null or .mountpoint == null)] | length') == 0 ]] ||
  { echo "nfs_shares: every entry needs source and mountpoint" >&2; exit 1 }

begin='# BEGIN nfs-shares'
end='# END nfs-shares'

# Wanted fstab lines, by mountpoint, in file order. Checked completely before fstab is touched.
mountpoints=()
typeset -A wanted
shares=(${(f)"$(config '.nfs_shares[] | .source + " " + .mountpoint + " " + (.options // "rw")')"})
for share in $shares; do
  fields=(${=share})
  (( ! ${+wanted[$fields[2]]} )) || { echo "nfs_shares: $fields[2] is listed twice" >&2; exit 1 }
  mountpoints+=($fields[2])
  wanted[$fields[2]]="$fields[1] $fields[2] nfs $fields[3] 0 0"
done

# Current fstab without the managed block. Everything outside of it stays as it is.
fstab=()
managed=()
typeset -A previous
inside=0
# Read into a variable first: a failure inside the for list would go unnoticed and fstab would be rewritten empty.
current=$(remote cat /etc/fstab)
[[ -n $current ]] || { echo "/etc/fstab on $1 is empty, not touching it" >&2; exit 1 }
for line in "${(@f)current}"; do
  if [[ $line == "$begin" ]]; then inside=1; continue; fi
  if [[ $line == "$end" ]]; then inside=0; continue; fi
  fields=(${=line})
  if (( inside )); then
    # Only entries count, the block is rewritten anyway.
    [[ -n ${fields[2]:-} && $fields[1] != \#* ]] || continue
    managed+=($fields[2])
    previous[$fields[2]]="$fields"
  else
    fstab+=("$line")
  fi
done
while (( $#fstab )) && [[ -z $fstab[-1] ]]; do fstab[-1]=(); done
if (( $#mountpoints )); then
  fstab+=("" "$begin")
  for m in $mountpoints; do fstab+=("$wanted[$m]"); done
  fstab+=("$end")
fi

removed=(${managed:|mountpoints})
# Shares whose source or options changed, they need a remount to pick that up.
modified=()
for m in $mountpoints; do
  if [[ -n ${previous[$m]:-} && $previous[$m] != $wanted[$m] ]]; then modified+=($m); fi
done

# Prints "mount|umount|remount <dir>" for every share whose state has to change.
pending() {
  remote "for m in ${(j: :)${(@qq)mountpoints}}; do mountpoint -q \"\$m\" || echo \"mount \$m\"; done
    for m in ${(j: :)${(@qq)removed}}; do ! mountpoint -q \"\$m\" || echo \"umount \$m\"; done
    for m in ${(j: :)${(@qq)modified}}; do ! mountpoint -q \"\$m\" || echo \"remount \$m\"; done"
}

# The NFS client is only needed while there are shares.
installed=()
(( ! $#mountpoints )) || installed=(${(f)"$(apt_install nfs-common)"})

if (( $#dry )); then
  report nfs-shares $installed ${(f)"$(print -rl -- "${fstab[@]}" | put /etc/fstab 644)"} ${(f)"$(pending)"}
  exit 0
fi

todo=(${(f)"$(pending)"})
# Unmount first: if a share is busy, fstab stays as it was. A remount is umount + mount,
# because many NFS options cannot be changed with mount -o remount.
for m in ${${(M)todo:#(umount|remount) *}#* }; do remote "umount '$m'"; done
changed=(${(f)"$(print -rl -- "${fstab[@]}" | put /etc/fstab 644)"})
(( ! $#changed )) || remote 'systemctl daemon-reload'
for m in ${${(M)todo:#(mount|remount) *}#* }; do remote "mkdir -p '$m' && mount '$m'"; done
report nfs-shares $installed $changed $todo
