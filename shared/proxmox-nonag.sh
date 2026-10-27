#!/bin/sh
# Removes the "No valid subscription" dialog from Proxmox VE and Proxmox Backup Server.
# Installed to /usr/local/sbin/proxmox-nonag and run by apt after every package change.

js=/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

[ -f "$js" ] || exit 0
grep -q '//nonag' "$js" && exit 0

sed -Ei 's/^(\s*checked_command: function ?\(orig_cmd\) \{)\s*$/\1 orig_cmd(); return; \/\/nonag/' "$js"

if grep -q '//nonag' "$js"; then
  if [ -d /etc/pve ]; then
    systemctl reload-or-restart pveproxy
  else
    systemctl reload-or-restart proxmox-backup-proxy
  fi
  echo "proxmox-nonag: subscription dialog removed"
else
  echo "proxmox-nonag: pattern not found, proxmoxlib.js may have changed" >&2
  exit 1
fi
