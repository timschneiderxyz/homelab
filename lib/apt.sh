# Apt helpers for modules that install packages. Sourced after lib/host.sh.

# debian_codename: the host's Debian codename
debian_codename() { remote '. /etc/os-release && echo "$VERSION_CODENAME"' }

# apt_repo <name> <suite> <key url> <key file> <uri> <components>: keyring and deb822 source.
# Prints the changed files.
apt_repo() {
  local name=$1 suite=$2 key_url=$3 key_file=$4 uri=$5 components=$6
  # Download first, so a failed download never ends up as an empty keyring on the host.
  local key=$(mktemp)
  curl -fsSL -o $key $key_url || { rm -f $key; return 1 }
  put $key_file 644 < $key
  rm -f $key
  print -l "Types: deb" "URIs: $uri" "Suites: $suite" "Components: $components" "Signed-By: $key_file" \
    | put /etc/apt/sources.list.d/$name.sources 644
}

# apt_install <package…>: installs the missing packages, after refreshing the package lists.
# Waits up to 2 minutes for the dpkg lock, e.g. while unattended-upgrades runs. Prints "install <package>" for each.
apt_install() {
  # Declared apart from the assignment, `local x=$(…)` would hide a failed SSH call.
  local -a missing
  missing=(${(f)"$(remote "for p in $*; do dpkg-query -W -f='\${Status}' \$p 2> /dev/null | grep -q 'ok installed' || echo \$p; done")"})
  (( $#missing )) || return 0
  local apt='apt-get -o DPkg::Lock::Timeout=120'
  (( $#dry )) || remote "$apt update -qq && DEBIAN_FRONTEND=noninteractive $apt install -y -qq $missing" >&2
  print -l "install "${^missing}
}
