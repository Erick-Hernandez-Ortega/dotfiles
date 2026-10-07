#!/usr/bin/env bash
# Read-only diagnostics. Optional missing tools are reported, not installed.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
parse_args "$@"
show_inventory
CHECK_FAILURES=0
if command -v zsh >/dev/null; then
  for file in "$ROOT/shell/.zshrc" "$ROOT/shell/.zprofile" "$ROOT/shell/tools.zsh" "$ROOT/shell/aliases.zsh"; do
    if ! zsh -n "$file"; then CHECK_FAILURES=$((CHECK_FAILURES+1)); fi
  done
  echo 'Zsh syntax checks complete / Sintaxis Zsh comprobada'
else echo '○ Zsh missing / Falta Zsh'; fi
printf '\nGit identity / Identidad de Git:\n'
if git_ready; then
  git config --global --get user.name || true
  git config --global --get user.email || true
else echo 'Git is not ready / Git no está listo'; fi
printf '\nConfiguration links / Enlaces de configuración:\n'
for file in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.config/ramon-dotfiles/tools.zsh" "$HOME/.config/ramon-dotfiles/aliases.zsh"; do
  if [[ -L "$file" && ! -e "$file" ]]; then
    printf '✗ Broken link / Enlace roto: %s\n' "$file"
    CHECK_FAILURES=$((CHECK_FAILURES+1))
  elif [[ -L "$file" ]]; then printf '✓ %s → %s\n' "$file" "$(readlink "$file")"
  else printf '○ Existing configuration / Configuración existente: %s\n' "$file"; fi
done
printf '\nDev: %s\n' "$DEV_ROOT"
if [[ "$OS" == linux ]]; then
  printf '\nLinux runtimes / Runtimes Linux:\n'
  row nvm
  if is_installed; then
    echo '✓ NVM found (Node is intentionally not installed automatically) / NVM encontrado (Node no se instala automáticamente)'
    printf 'NVM_DIR: %s\n' "${NVM_DIR:-auto: ~/.nvm, ~/.config/nvm, /usr/share/nvm}"
  else echo '○ NVM missing / Falta NVM'; fi
  for runtime in node bun pnpm deno ruby javac; do
    if command -v "$runtime" >/dev/null; then
      printf '%s: %s\n' "$runtime" "$(command -v "$runtime")"
      "$runtime" --version 2>&1 | head -n 2 || echo "Could not run / No se pudo ejecutar: $runtime"
    fi
  done
  printf '\nDocker:\n'
  if command -v docker >/dev/null; then
    if docker compose version; then :; else echo '○ Compose unavailable / Compose no disponible'; fi
    if systemctl is-active docker.service 2>/dev/null; then :
    else echo '○ Docker service inactive or cannot be queried / Servicio inactivo o no consultable'; fi
    if docker info --format '{{.ServerVersion}}' 2>/dev/null; then echo '✓ Daemon accessible / Daemon accesible'
    else echo '○ Daemon inaccessible: check service, context and user permissions / Revisa servicio, contexto y permisos'; fi
  else echo '○ Docker missing / Falta Docker'; fi
fi
printf '\nConfiguration errors / Errores de configuración: %s\n' "$CHECK_FAILURES"
(( CHECK_FAILURES == 0 ))
