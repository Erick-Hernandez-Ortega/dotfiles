#!/usr/bin/env bash
# Linux backends. No system changes occur until a selected action calls an installer.
LINUX_READY=0
PLATFORM_FAMILY=''
DISTRO_ID=''
DISTRO_VERSION=''
BASE_CODENAME=''
MANUAL=()

detect_linux() {
  local release_file="${1:-/etc/os-release}" ID='' ID_LIKE='' VERSION_ID='' UBUNTU_CODENAME=''
  [[ -r "$release_file" ]] || { echo 'Cannot read Linux distribution information'; return 1; }
  source "$release_file"
  DISTRO_ID="$ID"; DISTRO_VERSION="$VERSION_ID"
  case "$ID" in
    arch|endeavouros) PLATFORM_FAMILY=arch; command -v pacman >/dev/null || return 1;;
    zorin)
      [[ "$VERSION_ID" == 18 || "$VERSION_ID" == 18.* ]] || { echo "Supported Zorin version: 18 (detected $VERSION_ID)"; return 1; }
      [[ "$UBUNTU_CODENAME" == noble ]] || { echo 'Zorin 18 requires Ubuntu base noble'; return 1; }
      PLATFORM_FAMILY=ubuntu; BASE_CODENAME=noble
      command -v apt-get >/dev/null || return 1;;
    *) echo "Unsupported Linux distribution: $ID. Supported: Arch, EndeavourOS, Zorin 18."; return 1;;
  esac
  if command -v xdg-user-dir >/dev/null; then
    local documents
    documents="$(xdg-user-dir DOCUMENTS 2>/dev/null || true)"
    [[ "$documents" == /* && "$documents" != "$HOME" ]] && DEV_ROOT="$documents/Dev"
  fi
  return 0
}

linux_packages() {
  ensure_temp || return 1
  local result=0 cache
  if [[ "$PLATFORM_FAMILY" == arch ]]; then
    cache="${TEMP_DIR:-/tmp/ramon-dotfiles-simulation}/pacman"
    if [[ -z "$PREVIOUS_PACKAGES" ]] && (( ! DRY_RUN )); then
      PREVIOUS_PACKAGES="$TEMP_DIR/packages-before.txt"
      pacman -Qq > "$PREVIOUS_PACKAGES" || return 1
    fi
    if (( ! LINUX_READY )); then
      run sudo pacman -Syu --needed --cachedir "$cache" "$@" || result=$?
    else
      run sudo pacman -S --needed --cachedir "$cache" "$@" || result=$?
    fi
  else
    cache="${TEMP_DIR:-/tmp/ramon-dotfiles-simulation}/apt"
    if (( ! LINUX_READY )); then run sudo apt-get update || return 1; fi
    run sudo apt-get -o "Dir::Cache::archives=$cache" install "$@" || result=$?
  fi
  # Download users may leave private, root-owned partial directories on failure.
  # Return only this run's cache to its owner so cleanup needs no root access.
  if (( ! DRY_RUN )); then
    sudo chown -R "$(id -u):$(id -g)" "$cache" || return 1
  fi
  (( result == 0 )) || return "$result"
  LINUX_READY=1
}

linux_prerequisites() {
  local command_name package missing=()
  for command_name in "$@"; do
    command -v "$command_name" >/dev/null && continue
    case "$command_name" in gpg) package=gnupg;; fc-cache) package=fontconfig;; *) package="$command_name";; esac
    missing+=("$package")
  done
  if (( ${#missing[@]} )); then linux_packages "${missing[@]}" || return 1; fi
  return 0
}

linux_deb() {
  local name="$1" url file
  case "$name" in
    fastfetch) url=https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb;;
    dbeaver) url=https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb;;
    chrome) url=https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb;;
    discord) url='https://discord.com/api/download?platform=linux&format=deb';;
    *) echo "Unknown Debian download: $name"; return 1;;
  esac
  linux_prerequisites curl || return 1
  ensure_temp || return 1
  file="${TEMP_DIR:-/tmp/ramon-dotfiles-simulation}/downloads/$name.deb"
  run curl --fail --location --proto '=https' --proto-redir '=https' "$url" -o "$file" || return 1
  # apt resolves dependencies; local package maintainer scripts may register vendor repositories.
  linux_packages "$file"
}

linux_repo_present() {
  local repo_url="$1" file
  for file in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
    [[ -f "$file" ]] || continue
    if grep -v '^[[:space:]]*#' "$file" | awk -v url="$repo_url" 'BEGIN { RS=""; found=0 } index($0,url) && $0 !~ /Enabled:[[:space:]]*no/ { found=1 } END { exit !found }'; then
      return 0
    fi
  done
  return 1
}

linux_repo() {
  local name="$1" key url packages repo_line
  case "$name" in
    vscode)
      key=https://packages.microsoft.com/keys/microsoft.asc
      url=https://packages.microsoft.com/repos/code
      repo_line="deb [arch=amd64 signed-by=/etc/apt/keyrings/ramon-vscode.gpg] $url stable main"
      packages=(code);;
    cursor)
      key=https://downloads.cursor.com/keys/anysphere.asc
      url=https://downloads.cursor.com/aptrepo
      repo_line="deb [arch=amd64 signed-by=/etc/apt/keyrings/ramon-cursor.gpg] $url stable main"
      packages=(cursor);;
    warp)
      key=https://releases.warp.dev/linux/keys/warp.asc
      url=https://releases.warp.dev/linux/deb
      repo_line="deb [arch=amd64 signed-by=/etc/apt/keyrings/ramon-warp.gpg] $url stable main"
      packages=(warp-terminal);;
    docker)
      key=https://download.docker.com/linux/ubuntu/gpg
      url=https://download.docker.com/linux/ubuntu
      repo_line="deb [arch=amd64 signed-by=/etc/apt/keyrings/ramon-docker.gpg] $url $BASE_CODENAME stable"
      packages=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
      # Do not remove an existing distribution Docker installation implicitly.
      if dpkg-query -W -f='${Status}' docker.io 2>/dev/null | grep -q 'install ok installed'; then
        echo 'Existing docker.io detected; keep it and install docker-compose-v2 using APT if needed.'
        linux_packages docker-compose-v2
        return
      fi;;
    *) echo "Unknown vendor repository: $name"; return 1;;
  esac
  if linux_repo_present "$url"; then
    printf 'Reusing vendor repository / Reutilizando repositorio: %s\n' "$url"
    LINUX_READY=0
    linux_packages "${packages[@]}"
    return
  fi
  linux_prerequisites curl gpg || return 1
  ensure_temp || return 1
  local key_file="${TEMP_DIR:-/tmp/ramon-dotfiles-simulation}/downloads/$name.asc"
  local gpg_file="${TEMP_DIR:-/tmp/ramon-dotfiles-simulation}/downloads/$name.gpg"
  local list_file="${TEMP_DIR:-/tmp/ramon-dotfiles-simulation}/downloads/$name.list"
  if (( DRY_RUN )); then
    printf '  [dry-run] add vendor repository: %s (key: %s)\n' "$repo_line" "$key"
  else
    curl --fail --location --proto '=https' --proto-redir '=https' "$key" -o "$key_file" || return 1
    gpg --batch --yes --dearmor --output "$gpg_file" "$key_file" || return 1
    printf '%s\n' "$repo_line" > "$list_file" || return 1
    sudo install -d -m 0755 /etc/apt/keyrings || return 1
    sudo install -m 0644 "$gpg_file" "/etc/apt/keyrings/ramon-$name.gpg" || return 1
    sudo install -m 0644 "$list_file" "/etc/apt/sources.list.d/ramon-$name.list" || return 1
  fi
  LINUX_READY=0 # The new repository requires refreshed metadata.
  linux_packages "${packages[@]}"
}

linux_flatpak() {
  local app_id="$1"
  linux_prerequisites flatpak || return 1
  run flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || return 1
  run flatpak install --user flathub "$app_id"
}

linux_nerd_font() {
  local name="$1" archive family
  case "$name" in jetbrains-nerd) archive=JetBrainsMono; family=JetBrainsMono;; hack-nerd) archive=Hack; family=Hack;; esac
  linux_prerequisites curl unzip fc-cache || return 1
  ensure_temp || return 1
  local file="${TEMP_DIR:-/tmp/ramon-dotfiles-simulation}/downloads/$archive.zip"
  local destination="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/$family-Nerd"
  run curl --fail --location --proto '=https' --proto-redir '=https' "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$archive.zip" -o "$file" || return 1
  run mkdir -p "$destination" || return 1
  run unzip -o "$file" '*.ttf' -d "$destination" || return 1
  run fc-cache -f "$destination"
}

configure_docker_service() {
  if (( ! DRY_RUN )); then
    command -v docker >/dev/null && docker compose version >/dev/null 2>&1 || { echo 'Install Docker and Compose before enabling the service.'; return 1; }
  fi
  run sudo systemctl enable --now docker.service || return 1
  if (( ! DRY_RUN )); then
    docker info >/dev/null 2>&1 || echo 'Docker service enabled; current user cannot access the daemon. Review Docker access separately.'
  fi
}

selection_dependencies() {
  local id selected_route dependency found item
  local dependencies=()
  (( ${AUTH_GIT:-0} )) && dependencies+=(gh)
  if [[ "$OS" == linux ]]; then
    (( ${CONFIG_DOCKER:-0} )) && dependencies+=(docker)
    (( ${CONFIG_FASTFETCH:-0} )) && dependencies+=(fastfetch)
    (( ${CONFIG_GHOSTTY:-0} )) && dependencies+=(jetbrains-nerd)
  fi
  (( ${#dependencies[@]} )) || return 0
  for dependency in "${dependencies[@]}"; do
    row "$dependency" || return 1
    is_installed && continue
    found=0
    if (( ${#SELECTED[@]} )); then
      for item in "${SELECTED[@]}"; do [[ "$item" == "$dependency" ]] && found=1; done
    fi
    (( found )) || SELECTED+=("$dependency")
  done
  return 0
}

linux_selection_summary() {
  [[ "$OS" == linux ]] || return 0
  local id selected_route has_packages=0 has_aur=0
  for id in "${SELECTED[@]}"; do
    row "$id"; selected_route="$(route)"
    printf '  %s: %s\n' "$LABEL" "$selected_route"
    case "$selected_route" in
      pacman:*|apt:*|deb:*|repo:*|aur:*|flatpak:*) has_packages=1;;
    esac
    [[ "$selected_route" == aur:* ]] && has_aur=1
  done
  (( ${CONFIG_SHELL:-0} || ${SWITCH_SHELL:-0} )) && ! command -v zsh >/dev/null && has_packages=1
  if (( has_packages )); then
    if [[ "$PLATFORM_FAMILY" == arch ]]; then
      msg '  Actualización completa de Arch antes de instalar paquetes; requisitos según selección.' '  Full Arch upgrade before installing packages; prerequisites depend on selection.'
    else
      msg '  APT actualiza índices; no ejecuta una actualización general del sistema.' '  APT refreshes metadata; no general system upgrade.'
    fi
  fi
  (( has_aur )) && msg '  AUR requiere yay y base-devel; revisión interactiva.' '  AUR requires yay and base-devel; interactive review.'
  return 0
}
