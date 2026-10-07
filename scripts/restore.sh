#!/usr/bin/env bash
# Restore exactly one file listed in a run's backup manifest.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
restore_directory=''; restore_name=''; restore_list=0
while (( $# )); do
  case "$1" in
    --backup) shift; restore_directory="${1:-}";;
    --file) shift; restore_name="${1:-}";;
    --dry-run) DRY_RUN=1;;
    --list) restore_list=1;;
    --help|-h) echo 'restore.sh --list | --backup <directory> --file <name> [--dry-run]'; exit 0;;
    *) echo "Unknown argument: $1"; exit 2;;
  esac
  (( $# )) || { echo 'Missing argument'; exit 2; }
  shift
done
backup_root="$HOME/.local/state/ramon-dotfiles/backups"
if (( restore_list )); then
  if [[ -d "$backup_root" ]]; then
    find "$backup_root" -mindepth 2 -maxdepth 2 -name manifest.tsv -type f -print -exec cat {} \;
  else echo 'No backups / Sin respaldos'; fi
  exit 0
fi
[[ -d "$restore_directory" && ! -L "$restore_directory" ]] || { echo 'Choose a backup directory with --backup'; exit 2; }
restore_directory="$(cd "$restore_directory" && pwd -P)"
[[ "$restore_directory" == "$backup_root/"* && "$restore_name" != */* && -n "$restore_name" ]] || { echo 'Invalid backup selection'; exit 2; }
[[ -f "$restore_directory/manifest.tsv" && ! -L "$restore_directory/manifest.tsv" ]] || { echo 'No manifest; older backups must be restored manually.'; exit 2; }
restore_target=''
while IFS=$'\t' read -r name target; do
  [[ "$name" == "$restore_name" ]] && restore_target="$target"
done < "$restore_directory/manifest.tsv"
[[ "$restore_target" == "$HOME/"* && "$restore_target" != *'/../'* && "$restore_target" != */.. ]] || { echo 'Invalid restore target'; exit 2; }
restore_source="$restore_directory/$restore_name"
[[ -f "$restore_source" || -L "$restore_source" ]] || { echo 'Backup file missing'; exit 2; }
[[ ! -d "$restore_target" || -L "$restore_target" ]] || { echo 'Refusing to replace a directory'; exit 2; }
[[ -d "$(dirname "$restore_target")" ]] || { echo 'Restore parent directory must exist'; exit 2; }
restore_parent="$(cd "$(dirname "$restore_target")" && pwd -P)"
[[ "$restore_parent" == "$HOME" || "$restore_parent" == "$HOME/"* ]] || { echo 'Parent resolves outside HOME'; exit 2; }
printf 'Restore / Restaurar: %s → %s\n' "$restore_source" "$restore_target"
if (( ! DRY_RUN )); then
  [[ -t 0 ]] || { echo 'Interactive input required'; exit 2; }
  ask '¿Restaurar este archivo? Se respalda el estado actual.' 'Restore this file? Current state will be backed up.' 0 || exit 0
fi
backup "$restore_target" "before-restore-$restore_name" || exit 1
if (( DRY_RUN )); then
  printf '  [dry-run] replace target itself; never write through its symlink\n'
else
  staged="$(mktemp "$restore_parent/.ramon-restore.XXXXXX")"
  trap '[[ -z "${staged:-}" ]] || rm -f -- "$staged"; finish_temp' EXIT
  cp -pP "$restore_source" "$staged"
  [[ ! -L "$restore_target" ]] || unlink "$restore_target"
  mv -f "$staged" "$restore_target"
  staged=''
  printf 'Restored; previous state: %s\n' "$BACKUP_DIR"
fi
