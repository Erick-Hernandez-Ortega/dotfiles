#!/usr/bin/env bash
# Read-only checks: installed programs, Zsh syntax and Git identity.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
parse_args "$@"
show_inventory
if command -v zsh >/dev/null; then
  zsh -n "$ROOT/shell/.zshrc" "$ROOT/shell/.zprofile" "$ROOT/shell/tools.zsh" "$ROOT/shell/aliases.zsh"
  echo '✓ Zsh syntax'
fi
printf '\nGit identity / Identidad de Git:\n'
if git_ready; then
  git config --global --get user.name || true
  git config --global --get user.email || true
else echo 'Git is not ready; install developer tools / Git no está listo; instala las herramientas de desarrollo.'; fi
printf '\nInstalled Zsh configuration / Configuración Zsh instalada:\n'
if [[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$ROOT/shell/.zshrc" ]]; then echo '✓ linked / enlazada'; else echo 'Current configuration preserved / configuración actual conservada'; fi
