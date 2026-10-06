# Troubleshooting / Solución de problemas

## Installed applications / Aplicaciones instaladas

Existing apps (including manual installs in /Applications and ~/Applications), commands, NVM and user fonts are reused. Their installation choices are disabled. Appearance/configuration remains separately selectable. No forced upgrades or package-manager adoption.

Apps existentes, comandos, NVM y fuentes se reutilizan. Sus opciones de instalación se omiten. La configuración visual se puede elegir por separado. No hay actualizaciones forzadas.

## Linux boundaries / Límites Linux

Only EndeavourOS / Arch with pacman is supported. AUR package recipes are community-maintained and are reviewed through yay's interactive prompts. Package availability and supported architectures may change; failed installs are reported and remaining choices continue. Steam requires multilib; enable it manually. Docker installation does not automatically enable its service or change docker-group membership. After reviewing your setup, use `sudo systemctl enable --now docker` to start it and enable it at boot. This installer does not modify Hyprland or desktop portals.

Solo EndeavourOS / Arch. AUR se revisa mediante yay. Steam requiere multilib. Docker no se habilita como servicio ni modifica grupos automáticamente; `sudo systemctl enable --now docker` inicia y habilita el servicio. No se modifica Hyprland ni sus portales.

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
