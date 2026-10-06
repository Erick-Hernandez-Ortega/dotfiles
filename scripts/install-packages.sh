#!/usr/bin/env bash
# Install one selected catalog item; use OPTION_ID or the main interactive wizard.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
parse_args "$@"
(( LIST_ONLY )) && { show_inventory; exit 0; }
if [[ ! -t 0 ]] && (( ! DRY_RUN )); then echo 'Interactive input required'; exit 2; fi
if [[ -z "${OPTION_ID:-}" ]]; then echo 'Select packages through bootstrap.sh; standalone installation requires OPTION_ID=<catalog-id>.'; exit 2; fi
row "$OPTION_ID" || { echo 'Unknown catalog id'; exit 2; }
show_inventory
if (( DRY_RUN )) || ask "¿Instalar $LABEL?" "Install $LABEL?" 0; then ensure_git; install_option "$OPTION_ID"; cleanup_run; fi
