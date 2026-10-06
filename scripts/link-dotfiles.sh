#!/usr/bin/env bash
# Back up and link the portable Zsh theme, aliases and runtime initialization.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
parse_args "$@"
(( LIST_ONLY )) && { show_inventory; exit 0; }
if (( ! DRY_RUN && ! LIST_ONLY )) && [[ ! -t 0 ]]; then echo 'Interactive input required'; exit 2; fi
if (( ! DRY_RUN )); then ask "¿Ejecutar esta acción?" "Execute this action?" 0 || exit 0; fi
configure_shell
