# Troubleshooting / Solución de problemas

## Installed applications / Aplicaciones instaladas

Existing apps (including manual installs in /Applications and ~/Applications), commands, NVM and user fonts are reused. Their installation choices are disabled. Appearance/configuration remains separately selectable. No forced upgrades or package-manager adoption.

Apps existentes, comandos, NVM y fuentes se reutilizan. Sus opciones de instalación se omiten. La configuración visual se puede elegir por separado. No hay actualizaciones forzadas.

## Linux boundaries / Límites Linux

Linux targets are EndeavourOS / Arch with pacman and Zorin 18 with APT (Ubuntu noble base), x86_64. AUR package recipes are community-maintained and are reviewed through yay's interactive prompts. Package availability and supported architectures may change; failed installs are reported and remaining choices continue. Steam requires multilib; enable it manually. Docker installation does not change docker-group membership. The separate optional Docker action starts/enables the service. After reviewing your setup, use `sudo systemctl enable --now docker` to start it and enable it at boot. This installer does not modify Hyprland or desktop portals.

EndeavourOS / Arch y Zorin 18 (base noble), x86_64. AUR se revisa mediante yay. Steam requiere multilib. Docker no modifica grupos; la acción opcional independiente inicia/habilita el servicio; `sudo systemctl enable --now docker` inicia y habilita el servicio. No se modifica Hyprland ni sus portales.

Claude Desktop, ChatGPT, WhatsApp, Notion, Linear, DBeaver and Mac utilities have no Linux option in this initial catalog. Use their websites where appropriate. Unofficial wrappers are not silently substituted. Xcode is a manual App Store step. Some Mac apps may require a newer OS or Rosetta; Homebrew reports their requirements.

Estas opciones no se sustituyen por clientes no oficiales en Linux. Xcode se instala manualmente. Homebrew informa requisitos de macOS y Rosetta.

## Rollback / Restaurar

Configuration backups are stored under `~/.local/state/ramon-dotfiles/backups/<timestamp>-<pid>/`. Copy the original back over its symlink to restore it (remove the symlink first). Preserve the repository while using linked files. Private additions go in `~/.zshrc.local`. A failed application install is reported and can be retried by rerunning the wizard. No existing backups are cleaned.

Los respaldos se guardan en esa ruta; elimina el enlace y restaura el archivo original. Conserva el repo mientras uses sus enlaces. Una instalación fallida se puede reintentar.

## Versions / Versiones

Latest means latest stable exposed by the selected official installer or distribution repository, not prerelease/nightly. No versions are pinned. Installed tools are skipped; update them separately when wanted. NVM never installs Node during setup. pnpm uses its standalone installer, which may include its own embedded runtime; no separate Node installation is requested.

Se usa la última estable disponible por el método elegido. pnpm independiente puede incluir un runtime interno; no se solicita una instalación separada de Node.

## Validation limits / Límites de validación

Syntax, dry-run, catalog consistency and isolated file operations are tested on macOS. No applications are installed on the author's active computer during repository preparation. Linux routes need execution on a real EndeavourOS machine; API package checks cannot verify application behavior under Wayland.

Se comprueba sintaxis, simulación, coherencia y operaciones aisladas en Mac. Hace falta ejecutar en EndeavourOS para validar instalación y comportamiento bajo Wayland.

## Zorin 18

`manual:` entries are instructions, not failed automatic installs. After installing from upstream, rerun the wizard to detect their commands. `repo:` adds keys under `/etc/apt/keyrings/ramon-*.gpg` and sources under `/etc/apt/sources.list.d/ramon-*.list`. APT errors are reported; other selected options continue. If universe/multiverse is unavailable, enable the appropriate Ubuntu component through Zorin's Software Sources and retry (Steam requires multiverse).

An existing `docker.io` installation is kept; missing Compose uses `docker-compose-v2` rather than removing Docker to switch vendors. A reachable Docker daemon is diagnosed separately from CLI/Compose presence. Permission failures inside a sandbox do not prove that the host service is stopped.

NVM already installed through Arch can live in `/usr/share/nvm` with versions under `~/.config/nvm`; the shell keeps those locations instead of reinstalling under `~/.nvm`. User-provided `NVM_DIR` takes precedence. Node remains a manual choice.

Backups made by the updated installer have `manifest.tsv`; use `restore.sh --list` to select the exact file. A missing restore parent directory must be recreated first. Recovery refuses directory targets and parents that resolve outside HOME.

Debian package maintainer scripts may start or enable services during installation according to system policy. The separate Docker action explicitly enables the service; it does not alter access groups.
