#!/bin/zsh
#MISE description="Install Docker and create the dockernet network"
#USAGE arg "<host>" help="Host folder in hosts/"
#USAGE flag "-n --dry-run" help="Only show what would change, write and restart nothing"
set -eu -o pipefail

zparseopts -D -E -F -- n=dry -dry-run=dry

source lib/host.sh "$1"
source lib/apt.sh

codename=$(debian_codename)
changed=(${(f)"$(apt_repo docker $codename https://download.docker.com/linux/debian/gpg /etc/apt/keyrings/docker.asc https://download.docker.com/linux/debian/ stable)"})
changed+=(${(f)"$(apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)"})

if ! remote 'docker network inspect dockernet > /dev/null 2>&1'; then
  (( $#dry )) || remote 'docker network create dockernet > /dev/null'
  changed+=('network dockernet')
fi

report docker $changed
