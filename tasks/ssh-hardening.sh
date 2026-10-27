#!/bin/zsh
#MISE description="Harden SSH"
#USAGE arg "<host>" help="Host folder in hosts/"
#USAGE flag "-n --dry-run" help="Only show what would change, write and restart nothing"
set -eu -o pipefail

zparseopts -D -E -F -- n=dry -dry-run=dry

source lib/host.sh "$1"

file=/etc/ssh/sshd_config.d/10-hardening.conf
sshd_config='PermitRootLogin prohibit-password
PasswordAuthentication no'

(( $#dry )) || remote "[ ! -e '$file' ] || cp -p '$file' '$file.prev'"
changed=(${(f)"$(print -r -- $sshd_config | put $file 644)"})
report ssh-hardening $changed

if (( $#changed && ! $#dry )); then
  remote "if ! sshd -t; then
      if [ -e '$file.prev' ]; then mv '$file.prev' '$file'; else rm -f '$file'; fi
      echo 'sshd -t failed, $file reverted' >&2; exit 1
    fi
    systemctl reload ssh"
fi
(( $#dry )) || remote "rm -f '$file.prev'"
