#!/usr/bin/env bash
# Explain run-scoped cleanup; never delete general system or user caches.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
parse_args "$@"
(( LIST_ONLY )) && { show_inventory; exit 0; }
echo 'Cleanup is scoped to the current installer run. No global caches are deleted.'
echo 'Run bootstrap.sh and select maximum-space cleanup.'
