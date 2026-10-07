#!/usr/bin/env bash
# Run inside a disposable Ubuntu 24.04 or Arch container, with /repo mounted read-only.
set -Eeuo pipefail
trap 'echo "Failed at line $LINENO: $BASH_COMMAND" >&2' ERR
[[ -e /.dockerenv || -e /run/.containerenv ]] || { echo 'This smoke check is for disposable containers only.'; exit 2; }
export HOME=/root
export DEBIAN_FRONTEND=noninteractive
case "${1:-}" in
  ubuntu)
    apt-get update -qq
    apt-get install -y -qq bash curl git zsh unzip gnupg ca-certificates
    ;;
  arch)
    printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf
    pacman -Syu --noconfirm --needed bash curl git zsh unzip gnupg ca-certificates
    ;;
  *) echo 'Use ubuntu or arch'; exit 2;;
esac
source /repo/scripts/common.sh
OS=linux
sudo() { "$@"; }
if [[ "$1" == ubuntu ]]; then
  PLATFORM_FAMILY=ubuntu; BASE_CODENAME=noble
  apt-get() { command apt-get -y "$@"; }
  # Verify every APT route against the real Ubuntu base, including optional bundles.
  while IFS= read -r line; do
    IFS='|' read -r ID LABEL ES EN DEFAULT KIND CMD MAC LINUX APP FAMILY UBUNTU FLATPAK_ID SOURCE_URL <<< "$line"
    if [[ "$UBUNTU" == apt:* ]]; then
      for package in ${UBUNTU#apt:}; do
        apt-cache show "$package" >/dev/null || { echo "Missing Ubuntu package: $package"; exit 1; }
      done
    fi
  done <<< "$CATALOG"
  for id in autosuggestions syntax-highlighting eza bat fd; do install_option "$id"; done
else
  PLATFORM_FAMILY=arch
  pacman() { command pacman --noconfirm "$@"; }
  while IFS= read -r line; do
    IFS='|' read -r ID LABEL ES EN DEFAULT KIND CMD MAC LINUX APP FAMILY UBUNTU FLATPAK_ID SOURCE_URL <<< "$line"
    if [[ "$LINUX" == pacman:* ]]; then
      for package in ${LINUX#pacman:}; do pacman -Si "$package" >/dev/null; done
    fi
  done <<< "$CATALOG"
  for id in autosuggestions syntax-highlighting eza bat fd; do install_option "$id"; done
fi
install_option nvm
echo "NVM installation verified"
row nvm; is_installed
configure_shell
echo "Shell links installed"
zsh -ic '(( $+functions[nvm] )); [[ "$ZSH_THEME" == robbyrussell ]]; alias ls; alias cat' </dev/null
# NVM was installed, but Node was not introduced by the installer.
[[ ! -d /root/.nvm/versions/node ]]
cleanup_run
echo 'Container smoke checks passed'
