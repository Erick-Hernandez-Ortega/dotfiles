#!/usr/bin/env bash
# Interactive personal setup; no Node, Python or jq required to start.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/scripts/common.sh"
parse_args "$@"
(( LIST_ONLY )) && { show_inventory; exit 0; }
if [[ ! -t 0 ]] && (( ! DRY_RUN )); then
  echo 'Interactive input is required. Use --dry-run or --list for unattended inspection.'
  exit 2
fi
if [[ -t 0 && -t 1 && "${TERM:-dumb}" != dumb ]]; then
  source "$ROOT/scripts/ui.sh"
  keyboard_wizard
  WIZARD_CONFIRMED=1
else
  # Plain output remains available for dry-run pipelines and basic terminals.
  WIZARD_CONFIRMED=0
choose_group tool 'Herramientas de terminal' 'Terminal tools'
choose_group app 'Aplicaciones opcionales' 'Optional applications'
choose_group font 'Fuentes opcionales; ninguna cambia el editor automáticamente' 'Optional fonts; editors are never changed automatically'
CONFIG_SHELL=0; SWITCH_SHELL=0; CONFIG_GIT=0; AUTH_GIT=0; CONFIG_GHOSTTY=0; CONFIG_BTOP=0; CREATE_DEV=0
ask '¿Aplicar tu configuración de Zsh, tema, alias y Fastfetch? Se respalda la actual.' 'Apply your Zsh theme, aliases and Fastfetch? Existing files are backed up.' 1 && CONFIG_SHELL=1
ask '¿Comprobar/cambiar tu shell predeterminada a Zsh?' 'Check/change the default login shell to Zsh?' 0 && SWITCH_SHELL=1
ask '¿Configurar tu nombre y correo de Git?' 'Configure your Git name and email?' 1 && CONFIG_GIT=1
ask '¿Configurar acceso HTTPS a GitHub con gh? Requiere inicio de sesión.' 'Configure GitHub HTTPS access with gh? Requires sign-in.' 0 && AUTH_GIT=1
ask '¿Aplicar el fondo, transparencia y desenfoque de Ghostty?' 'Apply Ghostty background, transparency and blur?' 0 && CONFIG_GHOSTTY=1
ask '¿Aplicar tus preferencias de btop?' 'Apply your btop preferences?' 0 && CONFIG_BTOP=1
ask '¿Crear solamente la estructura de carpetas Dev?' 'Create only the Dev directory structure?' 1 && CREATE_DEV=1
if (( CREATE_DEV )) && [[ -t 0 ]]; then
  printf 'Dev path / Ruta Dev [%s]: ' "$DEV_ROOT"
  IFS= read -r entered_path
  if [[ -n "$entered_path" ]]; then
    [[ "$entered_path" == /* ]] || { echo 'Use an absolute path / Usa una ruta absoluta'; exit 2; }
    DEV_ROOT="$entered_path"
  fi
fi
ask '¿Máximo ahorro de espacio? Borrar cachés de paquetes descargados por esta ejecución.' 'Maximum space savings? Remove package caches downloaded by this run.' 1 || MAX_CLEAN=0
fi
printf '\n'; msg '◆ Tu selección' '◆ Your selection'
if (( ${#SELECTED[@]} )); then
  for id in "${SELECTED[@]}"; do row "$id"; printf '  + %s\n' "$LABEL"; done
else msg '  Sin programas nuevos: se conserva lo instalado.' '  No new programs: existing installations are kept.'; fi
(( CONFIG_SHELL )) && msg '  ✓ Tu configuración de Zsh' '  ✓ Your Zsh configuration'
(( SWITCH_SHELL )) && msg '  ✓ Shell predeterminada Zsh' '  ✓ Default Zsh shell'
(( CONFIG_GIT )) && msg '  ✓ Tu identidad de Git' '  ✓ Your Git identity'
(( AUTH_GIT )) && msg '  ✓ Acceso a GitHub por HTTPS' '  ✓ GitHub access over HTTPS'
(( CONFIG_GHOSTTY )) && msg '  ✓ Apariencia de Ghostty' '  ✓ Ghostty appearance'
(( CONFIG_BTOP )) && msg '  ✓ Preferencias de btop' '  ✓ btop preferences'
(( CREATE_DEV )) && printf '  ✓ Dev: %s\n' "$DEV_ROOT"
if (( MAX_CLEAN )); then msg '  ✓ Limpiar las cachés de esta ejecución' '  ✓ Clean caches from this run'
else msg '  ✓ Conservar descargas de paquetes' '  ✓ Retain package downloads'; fi
if (( DRY_RUN )); then msg 'SIMULACIÓN: ninguna modificación.' 'SIMULATION: no changes.'
elif (( ! WIZARD_CONFIRMED )); then ask '¿Ejecutar este resumen?' 'Execute this summary?' 0 || exit 0; fi
ensure_git || { echo 'Git prerequisite failed'; exit 1; }
if [[ "$OS" == linux ]] && (( ! DRY_RUN )); then
  ensure_temp
  PREVIOUS_PACKAGES="$TEMP_DIR/packages-before.txt"
  pacman -Qq > "$PREVIOUS_PACKAGES"
  # AUR builds and official scripts need these standard prerequisites.
  run sudo pacman -Syu --needed base-devel curl git unzip || exit 1
fi
# Official installers can append shell PATH entries; preserve the original first.
if (( ! DRY_RUN )); then
  for startup_file in .zshrc .zprofile .bashrc .bash_profile .profile; do
    backup "$HOME/$startup_file" "pre-install-${startup_file#.}"
  done
fi
if (( ${#SELECTED[@]} )); then
  for id in "${SELECTED[@]}"; do
    if install_option "$id"; then INSTALLED+=("$id")
    else FAILED+=("$id"); msg "No se completó: $id. Continúa el resto." "Not completed: $id. Continuing."; fi
  done
fi
apply_action() { if ! "$@"; then FAILED+=("$1"); fi; }
(( SWITCH_SHELL )) && apply_action change_shell
(( CONFIG_SHELL )) && apply_action configure_shell
(( CONFIG_GIT )) && apply_action configure_git
(( AUTH_GIT )) && apply_action auth_git
if (( CONFIG_GHOSTTY )); then
  if [[ "$OS" == mac ]]; then ghostty_target="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  else ghostty_target="$HOME/.config/ghostty/config"; fi
  apply_action link_file "$ROOT/config/ghostty/config" "$ghostty_target" ghostty-config
fi
(( CONFIG_BTOP )) && apply_action link_file "$ROOT/config/btop/btop.conf" "$HOME/.config/btop/btop.conf" btop-config
(( CREATE_DEV )) && apply_action create_dev_folders
cleanup_run
[[ -z "$BACKUP_DIR" ]] || printf 'Existing configuration backups: %s\n' "$BACKUP_DIR"
if (( ${#FAILED[@]} )); then printf 'Incomplete actions: %s\n' "${FAILED[*]}"; exit 1; fi
if (( DRY_RUN )); then msg 'Simulación terminada. No se modificó ningún archivo.' 'Simulation complete. No files were modified.'; exit 0; fi
msg 'Listo. Abre una terminal nueva para cargar Zsh. No se modificaron editores ni se instalaron extensiones.' 'Done. Open a new terminal to load Zsh. Editors and extensions were not changed.'
