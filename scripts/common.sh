#!/usr/bin/env bash
# Shared installer utilities. Compatible with the Bash 3.2 shipped by macOS.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/catalog/options.sh"
source "$ROOT/scripts/linux.sh"
DRY_RUN=0
LANGUAGE=es
LIST_ONLY=0
SELECTED=()
FAILED=()
INSTALLED=()
TEMP_DIR=''
BACKUP_DIR=''
MAX_CLEAN=1
PREVIOUS_PACKAGES=''
BREW_READY=0
DEV_ROOT="$HOME/Documents/Dev"
ACTIVE_PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.bun/bin:$HOME/.deno/bin:$HOME/Library/pnpm:$HOME/.local/share/pnpm:/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH="$ACTIVE_PATH"
msg() { if [[ "$LANGUAGE" == es ]]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi; }
run() {
  if (( DRY_RUN )); then printf '  [dry-run]'; printf ' %q' "$@"; printf '\n'; else "$@"; fi
}
ask() {
  local es="$1" en="$2" default="${3:-0}" answer hint
  if (( default )); then hint='Y/n'; else hint='y/N'; fi
  if [[ ! -t 0 ]]; then (( default )); return; fi
  if [[ "$LANGUAGE" == es ]]; then printf '%s [%s] ' "$es" "$hint"; else printf '%s [%s] ' "$en" "$hint"; fi
  IFS= read -r answer || return 1
  case "$answer" in y|Y|s|S|yes|si|sí) return 0;; n|N|no) return 1;; '') (( default ));; *) msg 'Respuesta inválida; se omite.' 'Invalid answer; skipped.'; return 1;; esac
}
parse_args() {
  while (( $# )); do
    case "$1" in
      --dry-run) DRY_RUN=1;;
      --list) LIST_ONLY=1;;
      --lang) shift; LANGUAGE="${1:-}"; [[ "$LANGUAGE" == es || "$LANGUAGE" == en ]] || { echo 'Use --lang es|en'; exit 2; };;
      --help|-h) printf '%s\n' 'bash bootstrap.sh [--dry-run] [--list] [--lang es|en]' 'Interactive setup / Configuración interactiva.' '--dry-run: print actions without changing files / muestra acciones sin modificar archivos.' '--list: inventory and descriptions only / solo inventario y descripciones.'; exit 0;;
      *) echo "Unknown option: $1"; exit 2;;
    esac
    shift
  done
  case "$(uname -s)" in
    Darwin) OS=mac; PLATFORM_FAMILY=mac;;
    Linux) OS=linux; detect_linux || exit 1;;
    *) echo 'Supported systems: macOS, EndeavourOS / Arch Linux, Zorin 18.'; exit 1;;
  esac
}
row() {
  local line
  while IFS= read -r line; do
    IFS='|' read -r ID LABEL ES EN DEFAULT KIND CMD MAC LINUX APP FAMILY UBUNTU FLATPAK_ID SOURCE_URL <<< "$line"
    [[ "$ID" == "$1" ]] && return 0
  done <<< "$CATALOG"
  return 1
}
route() {
  if [[ "$OS" == mac ]]; then printf '%s' "$MAC"
  elif [[ "$PLATFORM_FAMILY" == ubuntu ]]; then printf '%s' "$UBUNTU"
  else printf '%s' "$LINUX"; fi
}
has_packages() {
  local names="$1" package
  for package in $names; do
    if [[ "$PLATFORM_FAMILY" == ubuntu ]]; then
      [[ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null)" == 'install ok installed' ]] || return 1
    else pacman -Q "$package" >/dev/null 2>&1 || return 1; fi
  done
}
is_installed() {
  local selected_route package brew_location brew_prefix font_pattern font_dir
  selected_route="$(route)"
  case "$ID" in
    omz) [[ -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; return;;
    nvm)
      if [[ "$OS" == mac ]]; then [[ -s "$HOME/.nvm/nvm.sh" ]]; return; fi
      [[ -n "${NVM_DIR:-}" && -s "$NVM_DIR/nvm.sh" ]] && return 0
      [[ -s "$HOME/.nvm/nvm.sh" || -s "${XDG_CONFIG_HOME:-$HOME/.config}/nvm/nvm.sh" || -s /usr/share/nvm/nvm.sh ]] && return 0
      return 1;;
    cursor-cli) command -v agent >/dev/null 2>&1 || command -v cursor-agent >/dev/null 2>&1; return;;
    autosuggestions|syntax-highlighting)
      for package in /opt/homebrew /usr/local /usr; do
        [[ -r "$package/share/zsh-${ID}/zsh-${ID}.zsh" ]] && return 0
      done
      # The catalog ID differs from the package name for autosuggestions.
      [[ "$ID" == autosuggestions ]] && [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh || -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && return 0
      ;;
  esac
  if [[ "$OS" == linux ]]; then
    if [[ -n "$FLATPAK_ID" ]]; then
      # flatpak info initializes user data even in inventory/dry-run mode.
      # Read deployment metadata directly to keep detection strictly read-only.
      [[ -r "${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/app/$FLATPAK_ID/current/active/metadata" ||
         -r "/var/lib/flatpak/app/$FLATPAK_ID/current/active/metadata" ]] && return 0
    fi
    if [[ "$ID" == docker ]]; then
      command -v docker >/dev/null && command -v dockerd >/dev/null && docker compose version >/dev/null 2>&1
      return
    fi
    case "$ID" in
      bat) command -v bat >/dev/null || command -v batcat >/dev/null; return;;
      fd) command -v fd >/dev/null || command -v fdfind >/dev/null; return;;
      zed) command -v zed >/dev/null || command -v zeditor >/dev/null || [[ -x "$HOME/.local/bin/zed" ]]; return;;
      java17)
        if [[ "$PLATFORM_FAMILY" == ubuntu ]]; then has_packages openjdk-17-jdk
        else has_packages jdk17-openjdk; fi; return;;
    esac
  fi
  if [[ "$KIND" == font ]]; then
    if [[ "$OS" == mac ]]; then
      case "$ID" in
        jetbrains) compgen -G "$HOME/Library/Fonts/JetBrainsMono-Regular.*" >/dev/null && return 0;;
        jetbrains-nerd) compgen -G "$HOME/Library/Fonts/JetBrainsMonoNerdFont-Regular.*" >/dev/null && return 0;;
        hack-nerd) compgen -G "$HOME/Library/Fonts/HackNerdFont-Regular.*" >/dev/null && return 0;;
      esac
    else
      case "$ID" in
        jetbrains) font_pattern='JetBrainsMono-Regular.*';;
        jetbrains-nerd) font_pattern='JetBrainsMonoNerdFont-Regular.*';;
        hack-nerd) font_pattern='HackNerdFont-Regular.*';;
      esac
      for font_dir in "${XDG_DATA_HOME:-$HOME/.local/share}/fonts" "$HOME/.local/share/fonts" "$HOME/.fonts" /usr/local/share/fonts /usr/share/fonts; do
        if [[ -d "$font_dir" ]] && [[ -n "$(find "$font_dir" -iname "$font_pattern" -print -quit 2>/dev/null)" ]]; then return 0; fi
      done
    fi
  fi
  if [[ "$OS" == mac ]]; then
    if [[ -n "$APP" ]] && { [[ -d "/Applications/$APP" ]] || [[ -d "$HOME/Applications/$APP" ]]; }; then return 0; fi
    if [[ "$selected_route" == brew:* || "$selected_route" == cask:* ]] && command -v brew >/dev/null; then
      package="${selected_route#*:}"
      # Inspect installation directories directly: running brew can create caches even for list.
      brew_location="$(command -v brew)"
      brew_prefix="${brew_location%/bin/brew}"
      for brew_prefix in "$brew_prefix" /opt/homebrew /usr/local; do
        if [[ "$selected_route" == cask:* ]]; then
          [[ -d "$brew_prefix/Caskroom/${package##*/}" ]] && return 0
        else [[ -d "$brew_prefix/Cellar/${package##*/}" ]] && return 0; fi
      done
    fi
  elif [[ "$selected_route" == pacman:* || "$selected_route" == aur:* || "$selected_route" == apt:* ]]; then
    has_packages "${selected_route#*:}" && return 0
  fi
  # A Docker CLI alone does not satisfy the selected Linux Engine + Compose bundle.
  if [[ "$OS" == linux && "$ID" == docker ]]; then return 1; fi
  [[ -n "$CMD" ]] && command -v "$CMD" >/dev/null 2>&1 && return 0
  return 1
}
show_inventory() {
  local line selected_route status
  msg '╭─ RAMON · UNIX SETUP ─╮' '╭─ RAMON · UNIX SETUP ─╮'
  printf 'OS: %s | Architecture: %s | Shell: %s\n' "${DISTRO_ID:-$OS}" "$(uname -m)" "${SHELL:-unknown}"
  msg 'Git: se reutiliza si está disponible.' 'Git: reuse the existing installation when available.'
  command -v git >/dev/null && command -v git || true
  while IFS= read -r line; do
    IFS='|' read -r ID LABEL ES EN DEFAULT KIND CMD MAC LINUX APP FAMILY UBUNTU FLATPAK_ID SOURCE_URL <<< "$line"
    selected_route="$(route)"
    [[ -n "$selected_route" ]] || continue
    if is_installed; then status='✓ installed / instalado'; elif [[ "$selected_route" == manual:* ]]; then status='↗ manual'; else status='○ selectable / seleccionable'; fi
    printf '\n%s — %s\n' "$LABEL" "$status"
    if [[ "$LANGUAGE" == es ]]; then printf '  %s\n' "$ES"; else printf '  %s\n' "$EN"; fi
    printf '  Method / Método: %s\n' "$selected_route"
  done <<< "$CATALOG"
}
choose_group() {
  local group="$1" title_es="$2" title_en="$3" line selected_route n=0 input token i valid
  local ids=() flags=()
  printf "\n"
  msg "$title_es" "$title_en"
  while IFS= read -r line; do
    IFS='|' read -r ID LABEL ES EN DEFAULT KIND CMD MAC LINUX APP FAMILY UBUNTU FLATPAK_ID SOURCE_URL <<< "$line"
    [[ "$KIND" == "$group" ]] || continue
    selected_route="$(route)"
    [[ -n "$selected_route" ]] || continue
    if is_installed; then
      printf '  ✓ %s — installed / ya instalado; omitted / se omite\n' "$LABEL"
      continue
    fi
    ids[$n]="$ID"; flags[$n]="$DEFAULT"; n=$((n+1))
    printf '  %2s [%s] %s\n' "$n" "$(if (( DEFAULT )); then printf x; else printf ' '; fi)" "$LABEL"
    if [[ "$LANGUAGE" == es ]]; then printf '         %s\n' "$ES"; else printf '         %s\n' "$EN"; fi
  done <<< "$CATALOG"
  (( n > 0 )) || return 0
  if [[ -t 0 ]]; then
    while :; do
      msg 'Escribe números separados por espacios para cambiar la selección; Enter acepta, 0 desmarca todo.' 'Enter space-separated numbers to toggle; Enter accepts, 0 clears all.'
      IFS= read -r input || return 1
      [[ -n "$input" ]] || break
      valid=1
      for token in $input; do
        if [[ ! "$token" =~ ^[0-9]+$ ]] || (( ${#token} > 3 )); then valid=0; break; fi
        i=$((10#$token))
        if (( i < 0 || i > n )); then valid=0; break; fi
      done
      if (( ! valid )); then msg 'Selección inválida.' 'Invalid selection.'; continue; fi
      for token in $input; do
        i=$((10#$token))
        if (( i == 0 )); then for ((i=0;i<n;i++)); do flags[$i]=0; done
        else i=$((i-1)); flags[$i]=$((1-${flags[$i]})); fi
      done
      for ((i=0;i<n;i++)); do printf '  %s [%s] %s\n' "$((i+1))" "${flags[$i]}" "${ids[$i]}"; done
    done
  fi
  for ((i=0;i<n;i++)); do (( ${flags[$i]} )) && SELECTED+=("${ids[$i]}"); done
  return 0
}
ensure_temp() {
  (( DRY_RUN )) && return 0
  [[ -n "$TEMP_DIR" ]] && return 0
  local temporary_root="${TMPDIR:-/tmp}"
  [[ "$OS" != linux ]] || temporary_root=/tmp
  TEMP_DIR="$(mktemp -d "$temporary_root/ramon-dotfiles.XXXXXX")" || return 1
  # pacman/alpm and APT/_apt need traversal, but cannot list this run's directory.
  [[ "$OS" != linux ]] || chmod 711 "$TEMP_DIR" || return 1
  mkdir -p "$TEMP_DIR/downloads" "$TEMP_DIR/cache" "$TEMP_DIR/pacman" "$TEMP_DIR/aur" "$TEMP_DIR/apt/partial" || return 1
  export HOMEBREW_CACHE="$TEMP_DIR/cache" HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1
}
finish_temp() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" && "$TEMP_DIR" == */ramon-dotfiles.* ]]; then
    du -sh "$TEMP_DIR" 2>/dev/null || true
    # Temp contents are exclusively owned by this run, never general user caches.
    rm -rf -- "$TEMP_DIR"
  fi
}
trap finish_temp EXIT
fetch_install() {
  local name="$1" url="$2" interpreter="$3" script
  if (( DRY_RUN )); then printf '  [dry-run] download %s; execute with %s; delete installer afterwards\n' "$url" "$interpreter"; return; fi
  ensure_temp
  script="$TEMP_DIR/downloads/$name.sh"
  curl --fail --location --silent --show-error --proto '=https' "$url" -o "$script" || return 1
  "$interpreter" "$script" || return 1
}
ensure_brew() {
  (( BREW_READY )) && return 0
  if ! command -v brew >/dev/null; then
    fetch_install homebrew https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh /bin/bash || return 1
    if (( ! DRY_RUN )); then
      for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [[ -x "$brew_bin" ]] && { eval "$("$brew_bin" shellenv)"; break; }
      done
      command -v brew >/dev/null || return 1
    fi
  fi
  run brew update || return 1
  BREW_READY=1
}

git_ready() {
  local git_location
  git_location="$(command -v git || true)"
  [[ -n "$git_location" ]] || return 1
  # The Apple shim may open a GUI installer even on `git --version`.
  if [[ "$OS" == mac && "$git_location" == /usr/bin/git ]]; then
    xcode-select -p >/dev/null 2>&1 || return 1
  fi
  git --version >/dev/null 2>&1
}
ensure_git() {
  git_ready && return 0
  if [[ "$OS" == mac ]]; then
    msg 'Faltan las herramientas de Apple. Instalarlas y volver a ejecutar: xcode-select --install' 'Apple developer tools are missing. Install them and rerun: xcode-select --install'
    (( DRY_RUN )) && return 0
    return 1
  fi
  linux_packages git curl || return 1
}
install_native() {
  local name="$1" tag metadata
  case "$name" in
    omz)
      if [[ -d "$HOME/.oh-my-zsh" ]]; then msg 'La carpeta de Oh My Zsh ya existe; no se reemplaza.' 'Oh My Zsh directory already exists; refusing to replace it.'; return 1; fi
      run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh";;
    nvm)
      if (( DRY_RUN )); then printf '  [dry-run] resolve latest stable nvm-sh/nvm release; run official install.sh with PROFILE=/dev/null; no Node installation\n'; return; fi
      metadata="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest)" || return 1
      tag="$(printf '%s' "$metadata" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)"
      [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Cannot resolve latest stable NVM release'; return 1; }
      PROFILE=/dev/null METHOD=script fetch_install nvm "https://raw.githubusercontent.com/nvm-sh/nvm/$tag/install.sh" bash;;
    bun) fetch_install bun https://bun.sh/install bash;;
    pnpm) SHELL="$(command -v zsh || command -v bash)" fetch_install pnpm https://get.pnpm.io/install.sh sh;;
    deno) fetch_install deno https://deno.land/install.sh sh;;
    opencode) fetch_install opencode https://opencode.ai/install bash;;
    cursor-cli) fetch_install cursor-cli https://cursor.com/install bash;;
    codex) fetch_install codex https://chatgpt.com/codex/install.sh sh;;
    claude-code) fetch_install claude-code https://claude.ai/install.sh bash;;
    uv) fetch_install uv https://astral.sh/uv/install.sh sh;;
    zed) fetch_install zed https://zed.dev/install.sh sh;;
    jetbrains-nerd|hack-nerd) linux_nerd_font "$name";;
    *) echo "Unknown native installer: $name"; return 1;;
  esac
}
install_option() {
  local id="$1" selected_route package
  row "$id" || return 1
  if is_installed; then printf '✓ %s — already installed / ya instalado\n' "$LABEL"; return; fi
  selected_route="$(route)"; package="${selected_route#*:}"
  [[ -n "$selected_route" ]] || { echo "Unavailable on this platform: $id"; return 1; }
  if [[ "$OS" == linux && "$(uname -m)" != x86_64 ]]; then
    echo 'Automatic Linux installs currently support x86_64 only.'; return 1
  fi
  if [[ "$OS" == linux && "$selected_route" == native:* && "$ID" != jetbrains-nerd && "$ID" != hack-nerd ]]; then
    linux_prerequisites curl unzip || return 1
    [[ "$ID" != omz ]] || ensure_git || return 1
  fi
  printf '\n→ %s\n' "$LABEL"
  if [[ "$OS" == linux && "$PLATFORM_FAMILY" == arch && "$ID" == steam ]] && ! pacman -Si steam >/dev/null 2>&1; then
    echo 'Steam needs the multilib repository enabled. Enable it manually and rerun.'; return 1
  fi
  case "$selected_route" in
    brew:*) ensure_brew || return 1; run brew install "$package" || return 1;;
    cask:*) ensure_brew || return 1; run brew install --cask "$package" || return 1;;
    pacman:*|apt:*) linux_packages $package || return 1;;
    deb:*) linux_deb "$package" || return 1;;
    repo:*) linux_repo "$package" || return 1;;
    flatpak:*) linux_flatpak "$package" || return 1;;
    aur:*)
      ensure_temp
      if ! command -v yay >/dev/null; then
        msg 'Se necesita yay; en EndeavourOS: sudo pacman -Syu --needed yay' 'yay is required; on EndeavourOS: sudo pacman -Syu --needed yay'
        return 1
      fi
      linux_packages base-devel || return 1
      # yay remains interactive so source/build reviews stay visible.
      run yay -S --needed --builddir "${TEMP_DIR:-/tmp/ramon-dotfiles-simulation}/aur" --cachedir "${TEMP_DIR:-/tmp/ramon-dotfiles-simulation}/pacman" "$package" || return 1;;
    native:*) install_native "$package" || return 1;;
    manual:xcode) msg 'Instala Xcode desde App Store y completa su primera apertura. El asistente no lo descarga.' 'Install Xcode from the App Store and finish its first launch. The assistant does not download it.'; return 2;;
    manual:*)
      printf 'Manual installation / Instalación manual: %s\n' "$package"
      MANUAL+=("$id")
      return 0;;
    *) echo "Unsupported route: $selected_route"; return 1;;
  esac
  if (( ! DRY_RUN )); then
    hash -r
    row "$id"
    is_installed || { echo "Installation verification failed: $id"; return 1; }
  fi
}
backup() {
  local target="$1" name="$2"
  [[ -e "$target" || -L "$target" ]] || return 0
  if (( DRY_RUN )); then printf '  [dry-run] backup %s\n' "$target"; return; fi
  if [[ -z "$BACKUP_DIR" ]]; then
    BACKUP_DIR="$HOME/.local/state/ramon-dotfiles/backups/$(date +%Y%m%d-%H%M%S)-$$"
    mkdir -p "$BACKUP_DIR"
  fi
  cp -pPR "$target" "$BACKUP_DIR/$name" || return 1
  # Tab-separated manifest permits safe restore of only files backed up by this run.
  [[ "$target" != *$'\t'* && "$target" != *$'\n'* ]] || return 1
  printf '%s\t%s\n' "$name" "$target" >> "$BACKUP_DIR/manifest.tsv"
}
link_file() {
  local source="$1" target="$2" name="$3"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then return 0; fi
  if [[ -d "$target" && ! -L "$target" ]]; then echo "Refusing to replace directory: $target"; return 1; fi
  backup "$target" "$name" || return 1
  run mkdir -p "$(dirname "$target")" || return 1
  run ln -sfn "$source" "$target"
}
configure_shell() {
  local selected_source
  if [[ "$OS" == linux ]]; then linux_prerequisites zsh || return 1; fi
  link_file "$ROOT/shell/.zshrc" "$HOME/.zshrc" zshrc || return 1
  # Preserve unrelated login-shell settings in an existing zprofile.
  if [[ ! -e "$HOME/.zprofile" && ! -L "$HOME/.zprofile" ]]; then
    link_file "$ROOT/shell/.zprofile" "$HOME/.zprofile" zprofile || return 1
  elif [[ -L "$HOME/.zprofile" && "$(readlink "$HOME/.zprofile")" == "$ROOT/shell/.zprofile" ]]; then
    : # Already linked: never append a source of itself.
  elif ! grep -F 'ramon-dotfiles zprofile' "$HOME/.zprofile" >/dev/null 2>&1; then
    backup "$HOME/.zprofile" zprofile || return 1
    if (( DRY_RUN )); then printf '  [dry-run] append portable Homebrew initialization to ~/.zprofile\n'
    else printf '\n# ramon-dotfiles zprofile\nsource %q\n' "$ROOT/shell/.zprofile" >> "$HOME/.zprofile"; fi
  fi
  for selected_source in tools.zsh aliases.zsh; do
    link_file "$ROOT/shell/$selected_source" "$HOME/.config/ramon-dotfiles/$selected_source" "$selected_source" || return 1
  done
}
change_shell() {
  local zsh_path
  zsh_path="$(command -v zsh || true)"
  if [[ -z "$zsh_path" ]]; then
    if [[ "$OS" == linux ]]; then linux_packages zsh || return 1
    else echo 'Zsh is missing on this Mac.'; return 1; fi
    zsh_path="$(command -v zsh || true)"
    (( DRY_RUN )) && zsh_path=/usr/bin/zsh
  fi
  if [[ "$OS" == mac ]]; then
    default_shell="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}')"
  else default_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"; fi
  if [[ "$default_shell" != "$zsh_path" ]]; then
    if ! grep -Fx "$zsh_path" /etc/shells >/dev/null; then echo "Register $zsh_path in /etc/shells manually first."; return 1; fi
    run chsh -s "$zsh_path"
  fi
}
configure_git() {
  local current_include
  if [[ -d "$HOME/.gitconfig" ]]; then echo 'Refusing to replace .gitconfig directory'; return 1; fi
  current_include="$(git config --global --get-all include.path || true)"
  if ! printf '%s\n' "$current_include" | grep -Fx "$ROOT/git/config" >/dev/null; then
    backup "$HOME/.gitconfig" gitconfig
    run git config --global --add include.path "$ROOT/git/config"
  fi
  # Set explicitly too, so a later existing user section cannot override the approved identity.
  run git config --global user.name 'Erick Ramon Hernandez Ortega'
  run git config --global user.email 'erickramon47@live.com.mx'
}
auth_git() {
  if ! command -v gh >/dev/null && (( ! DRY_RUN )); then echo 'Install GitHub CLI first to authenticate.'; return 1; fi
  if (( DRY_RUN )); then printf '  [dry-run] verify GitHub account Erick-Hernandez-Ortega; if needed gh auth login --hostname github.com --git-protocol https --web; gh auth setup-git\n'; return; fi
  local account
  account="$(gh api user --jq .login 2>/dev/null || true)"
  if [[ "$account" != Erick-Hernandez-Ortega ]]; then
    msg 'Inicia sesión con Erick-Hernandez-Ortega en el navegador.' 'Sign in as Erick-Hernandez-Ortega in the browser.'
    gh auth login --hostname github.com --git-protocol https --web || return 1
    account="$(gh api user --jq .login)" || return 1
    [[ "$account" == Erick-Hernandez-Ortega ]] || { echo "Unexpected GitHub account: $account"; return 1; }
  fi
  gh auth setup-git --hostname github.com
}
create_dev_folders() {
  local folder
  for folder in Frontend/Next Frontend/React Frontend/Astro Backend/NestJS Backend/Node Backend/Python Mobile/ReactNative Mobile/Flutter Mobile/Android Desktop/Electron Desktop/Tauri Libraries Scripts Playground Others; do
    run mkdir -p "$DEV_ROOT/$folder"
  done
}
cleanup_run() {
  (( DRY_RUN )) && { echo '  [dry-run] remove run-owned installers and temporary build/download files; maximum-space mode removes run-owned package cache'; return; }
  [[ -n "$TEMP_DIR" ]] || return 0
  if (( ! MAX_CLEAN )); then
    # Opt-out retains only package downloads for reinstalling, not installer scripts or build trees.
    local destination="$HOME/.cache/ramon-dotfiles/packages-$(date +%Y%m%d-%H%M%S)-$$"
    mkdir -p "$destination"
    [[ -d "$TEMP_DIR/cache" ]] && cp -R "$TEMP_DIR/cache" "$destination/homebrew"
    [[ -d "$TEMP_DIR/pacman" ]] && cp -R "$TEMP_DIR/pacman" "$destination/pacman"
    [[ -d "$TEMP_DIR/apt" ]] && cp -R "$TEMP_DIR/apt" "$destination/apt"
    printf 'Package downloads retained: %s\n' "$destination"
  fi
  if [[ "$OS" == linux && "$PLATFORM_FAMILY" == arch && -n "$PREVIOUS_PACKAGES" && -f "$PREVIOUS_PACKAGES" ]]; then
    local package
    local new_orphans=()
    while IFS= read -r package; do
      [[ -n "$package" ]] || continue
      if ! grep -Fx "$package" "$PREVIOUS_PACKAGES" >/dev/null; then new_orphans+=("$package"); fi
    done < <(pacman -Qdtq 2>/dev/null || true)
    if (( ${#new_orphans[@]} )); then
      msg 'Dependencias nuevas sin uso; pacman comprobará antes de retirarlas:' 'New unused dependencies; pacman checks before removing them:'
      # Only dependencies absent before this run; no recursive removal of other packages.
      sudo pacman -R -- "${new_orphans[@]}" || msg 'No se retiraron esas dependencias.' 'Those dependencies were not removed.'
    fi
  fi
  msg 'Espacio temporal recuperado:' 'Temporary space reclaimed:'
  finish_temp
  TEMP_DIR=''
}
