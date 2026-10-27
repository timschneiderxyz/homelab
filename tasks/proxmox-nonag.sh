#!/bin/zsh
#MISE description="Remove the Proxmox subscription dialog"
#USAGE arg "<host>" help="Host folder in hosts/"
#USAGE flag "-n --dry-run" help="Only show what would change, write and restart nothing"
set -eu -o pipefail

zparseopts -D -E -F -- n=dry -dry-run=dry

source lib/host.sh "$1"

hook='// Re-apply proxmox-nonag after every package change (installed to /etc/apt/apt.conf.d/).
DPkg::Post-Invoke { "/usr/local/sbin/proxmox-nonag || true"; };'
changed=(${(f)"$(put /usr/local/sbin/proxmox-nonag 755 < shared/proxmox-nonag.sh)"})
changed+=(${(f)"$(print -r -- $hook | put /etc/apt/apt.conf.d/99-proxmox-nonag 644)"})
changed+=(${(f)"$(remote "grep -qs '//nonag' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js || echo 'proxmoxlib.js (patch)'")"})
report proxmox-nonag $changed

(( $#dry )) || remote /usr/local/sbin/proxmox-nonag
