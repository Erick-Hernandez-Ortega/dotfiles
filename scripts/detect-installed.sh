#!/usr/bin/env bash
# Read-only inventory: recognize existing commands, packages, GUI apps and fonts.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
parse_args "$@"
(( LIST_ONLY )) && { show_inventory; exit 0; }
if (( ! DRY_RUN && ! LIST_ONLY )) && [[ ! -t 0 ]]; then echo 'Interactive input required'; exit 2; fi
show_inventory
