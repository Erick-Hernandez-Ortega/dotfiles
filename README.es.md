# Dotfiles de Ramón · Windows + macOS + EndeavourOS + Zorin 18

[English](README.md) · Español

Un asistente interactivo para preparar mi terminal y seleccionar mis aplicaciones en una nueva computadora Windows o Unix. No instala Hyprland, Office ni extensiones de editores.

## Windows: tu setup y el SSD que elijas

```powershell
powershell -NoProfile -File .\bootstrap.ps1 -List       # Inventario sin cambios.
powershell -NoProfile -File .\bootstrap.ps1 -DryRun     # Simulación sin instalar.
powershell -NoProfile -File .\bootstrap.ps1             # Elegir disco, apps y configuración.
powershell -NoProfile -File .\bootstrap.ps1 -TargetDrive E:
```

Windows 10/11 x64: Chocolatey es el gestor principal, con WinGet e instaladores oficiales para rutas específicas. El asistente propone E: si existe, permite elegir cualquier unidad local montada y editar las carpetas Software, Development y Data. Usa el destino elegido donde exista soporte comprobado; el resumen muestra las excepciones. Conserva las instalaciones y datos existentes en sus ubicaciones actuales.

Reproduce PowerShell con Oh My Posh/robbyrussell y Terminal-Icons. La apariencia de Windows Terminal es opcional. Respeta Documentos en OneDrive y NVM for Windows; no instala Node automáticamente. Git Bash delega en PowerShell; WSL configura Linux.

Consulta [Windows: uso, destinos y recuperación](docs/windows.md) y la [matriz Windows](docs/windows-compatibility.md). Diagnóstico: `powershell -NoProfile -File .\scripts\windows\doctor.ps1`.

## Inicio rápido

Coloca este repositorio en una ubicación permanente. Los dotfiles se enlazan a él: no lo borres ni lo muevas después de aplicar la configuración.

```bash
bash bootstrap.sh --list          # Inventario: qué existe y qué hace cada opción.
bash bootstrap.sh --dry-run       # Simulación: muestra acciones, no cambia archivos.
bash bootstrap.sh                 # Asistente: elegir, revisar y ejecutar.
bash bootstrap.sh --lang en       # El mismo asistente en inglés.
bash scripts/doctor.sh            # Comprobaciones de solo lectura.
```

El asistente presenta nueve pasos con categorías claras. **↑/↓** mueve el cursor, **Espacio** marca/desmarca, **Enter** continúa y **← / B** vuelve. **Q** cancela sin instalar. Las opciones instaladas aparecen como `[x] · ya instalado`, bloqueadas para evitar reinstalarlas. La descripción del elemento enfocado aparece debajo de la lista.

Puedes volver a los pasos anteriores y conservar tus selecciones durante esa ejecución. En el último paso se revisa el resumen; Enter confirma la instalación (o la simulación). **D** permite cambiar la ruta Dev desde el resumen. En Linux también se muestra el método de instalación y si se añadirán fuentes del fabricante.

No hay archivos de selección persistente. `--list` conserva el inventario detallado. Sin una terminal interactiva, `--dry-run` muestra texto y usa los valores predeterminados. En terminales básicas (`TERM=dumb`) se mantiene un menú de texto como alternativa.

## Comportamiento

- macOS Intel/Apple Silicon: Brew para fórmulas/casks. Si faltan las herramientas de Apple, ejecuta `xcode-select --install` y vuelve a empezar.
- EndeavourOS/Arch: pacman, y yay para AUR. Antes de usar AUR, verifica que yay esté instalado. La primera instalación de paquetes hace una actualización completa; las siguientes reutilizan los índices. base-devel se añade solo para AUR. Zorin 18 tiene rutas propias de APT, fuentes oficiales y Flatpak. Otras distribuciones y Zorin 17 no se admiten.
- Usa la versión disponible en el gestor seleccionado; los instaladores oficiales resuelven su versión estable. No hay versiones fijadas, actualizaciones automáticas ni selección persistente. Una app instalada se conserva; actualízala con su gestor habitual.
- NVM se instala sin Node. Más adelante puedes ejecutar `nvm install --lts`: instala el Node LTS disponible y lo administra NVM.
- Bun/pnpm/Deno y agentes CLI tienen instalación independiente; no se añade Node por Brew/npm.
- En Unix, OpenCode usa exclusivamente su instalador oficial web. Windows usa su distribución portable oficial para admitir el disco elegido.
- Git existente se reutiliza. Nombre y correo quedan fijos; los tokens nunca se copian al repo.
- No se aplican respaldos de editores ni se instalan extensiones. Usa tu sincronización de nube.
- La detección consulta comandos, archivos, aplicaciones, fuentes y paquetes. `doctor` también consulta runtimes, enlaces rotos y acceso a Docker/Compose. Es una comprobación de presencia, no de licencia, sesión o funcionamiento completo.

## Linux: Arch y Zorin 18

Consulta la [matriz completa de compatibilidad](docs/linux-compatibility.md) para ver el método de cada app. `--list` muestra si una opción está instalada, es seleccionable o requiere instalación manual; la disponibilidad del servidor se comprueba al instalar.

Zorin 18 requiere la base Ubuntu 24.04 (`noble`) y arquitectura x86_64. APT actualiza índices y solo instala lo seleccionado, sin una actualización general. VS Code, Cursor, Warp y Docker usan repositorios firmados del fabricante. Los paquetes `.deb` también pueden registrar sus propias fuentes de actualización. Spotify, Firefox y ZapZap utilizan Flatpak de usuario; el resumen identifica las fuentes antes de confirmar.

Ghostty, algunos clientes de bases de datos, Android Studio y otras opciones muestran enlaces oficiales para instalación manual en Zorin. Se listan como pendientes; no se anuncian como instaladas. Snap no se usa para nuevas instalaciones; sus comandos existentes se reconocen cuando están en PATH.

Las nuevas opciones de Linux son jq, fzf, zoxide, rsync, rbenv, Java 17, Watchman, ngrok, lazyworktree, TablePlus, Firefox, VLC y ZapZap. Todas son opcionales. DBeaver también está habilitado en Linux. ZapZap es un cliente comunitario, distinto de la app oficial de WhatsApp para Mac.

NVM reconoce instalaciones personales, XDG y `/usr/share/nvm`; conserva el directorio de versiones existente. No instala Node. rbenv se inicializa una vez si está disponible; sus paquetes pueden traer un Ruby del sistema como dependencia, pero no se instalan versiones administradas automáticamente. En Zorin se reconocen `batcat` y `fdfind`.

“Personalización” añade dos acciones independientes: iniciar/habilitar Docker sin cambiar grupos y aplicar un Fastfetch portable. Ghostty tiene una apariencia Linux opcional con JetBrains Mono Nerd Font, fondo oscuro y transparencia; el desenfoque lo controla el escritorio. No se modifica HyDE/Hyprland ni se restauran ajustes de IDE.

## Recuperar un respaldo

```bash
bash scripts/restore.sh --list
bash scripts/restore.sh --backup "$HOME/.local/state/ramon-dotfiles/backups/<ejecución>" --file zshrc --dry-run
bash scripts/restore.sh --backup "$HOME/.local/state/ramon-dotfiles/backups/<ejecución>" --file zshrc
```

Selecciona el directorio y nombre que aparecen en `--list`. La restauración pide confirmación, respalda el estado actual y reemplaza el enlace mismo; no escribe sobre el archivo del repo al que apunta. Los respaldos antiguos sin `manifest.tsv` conservan su recuperación manual.

## Tu terminal

Selecciona aplicar Zsh para recuperar `robbyrussell`, plugin Git, sugerencias, resaltado y los siguientes alias:

| Comando | Qué hace |
|---|---|
| `ls` | eza: archivos con iconos y directorios primero. |
| `ll` | eza: listado detallado, archivos ocultos y estado Git. |
| `lt` | eza: árbol de directorios de dos niveles. |
| `cat` | bat: lectura con colores y paginación. |
| `command cat archivo` | Usa el cat original, evitando el alias. |
| `fastfetch` | Resumen del equipo; se ejecuta al abrir una terminal interactiva. |
| `nvm` | Administra Node; no es un programa independiente en PATH. |
| `exec zsh` | Recarga la terminal usando Zsh después de aplicar los dotfiles. |

Se detecta la shell; cambiar la shell predeterminada a Zsh es una opción aparte. El asistente respalda los archivos que modifica en `~/.local/state/ramon-dotfiles/backups/`. `~/.zshrc.local` permite ajustes privados. Ghostty y btop se configuran solo si eliges esas acciones; instalar una fuente no cambia editores.

## Carpetas Dev

Crea únicamente directorios faltantes; no clona, mueve, inicializa Git ni genera proyectos. En macOS la ruta predeterminada es `~/Documents/Dev`. En Linux se consulta `xdg-user-dir DOCUMENTS`: en esta computadora resulta `~/Documentos/Dev`. Si no existe una ruta válida, se usa `~/Documents/Dev`. Siempre es editable durante el asistente.

```text
Dev/
├── Frontend/{Next,React,Astro}/
├── Backend/{NestJS,Node,Python}/
├── Mobile/{ReactNative,Flutter,Android}/
├── Desktop/{Electron,Tauri}/
├── Libraries/
├── Scripts/
├── Playground/
└── Others/
```

## Git y acceso a GitHub

Identidad: **Erick Ramon Hernandez Ortega**, **erickramon47@live.com.mx**. Cuenta: **Erick-Hernandez-Ortega**. Autenticación opcional por HTTPS mediante `gh auth login` y `gh auth setup-git`. Una cuenta diferente no se acepta como resultado. Si ya existe una sesión correcta, se reutiliza. Selecciona GitHub CLI si falta. Cada máquina autoriza su propio acceso.

## Limpieza

Los instaladores y paquetes se descargan en una carpeta temporal exclusiva de la ejecución. Al finalizar se eliminan scripts descargados y restos de compilación. “Máximo ahorro” también elimina las cachés de paquetes creadas por esa ejecución; si lo desactivas, se conservan en `~/.cache/ramon-dotfiles/`.

AUR se ejecuta de forma interactiva para revisar sus fuentes. Solo se consideran para retirar dependencias nuevas que hayan quedado huérfanas; se conservan dependencias necesarias y todo paquete previo. No se borran cachés generales, proyectos, versiones de Node, datos Docker ni respaldos. Los instaladores oficiales pueden manejar sus propios archivos fuera del temporal; sus datos necesarios y versiones administradas no se purgan. Las imágenes que Homebrew monta son administradas por Homebrew.

## Catálogo

`Sí` indica preselección únicamente si la herramienta no existe. Todas las aplicaciones y fuentes son opcionales.

| Opción | Qué hace | Predeterminada | macOS | EndeavourOS |
|---|---|---|---|---|
| Oh My Zsh | Tema robbyrussell y atajos de Git para Zsh. | Sí | native:omz | native:omz |
| Zsh autosuggestions | Sugiere comandos de tu historial mientras escribes. | Sí | brew:zsh-autosuggestions | pacman:zsh-autosuggestions |
| Zsh syntax highlighting | Colorea comandos y ayuda a detectar errores al escribir. | Sí | brew:zsh-syntax-highlighting | pacman:zsh-syntax-highlighting |
| Fastfetch | Muestra el resumen del equipo al abrir la terminal. | Sí | brew:fastfetch | pacman:fastfetch |
| eza | Listado de archivos con iconos, Git y vista de árbol. | Sí | brew:eza | pacman:eza |
| bat | Muestra archivos con colores de sintaxis y paginación. | Sí | brew:bat | pacman:bat |
| btop | Monitor interactivo de CPU, memoria y procesos. | No | brew:btop | pacman:btop |
| lazydocker | Interfaz de terminal para contenedores Docker; requiere Docker. | No | brew:lazydocker | pacman:lazydocker |
| GitHub CLI | Inicia sesión en GitHub y administra repositorios y PR. | No | brew:gh | pacman:github-cli |
| ripgrep | Busca texto rápidamente dentro de archivos y proyectos. | No | brew:ripgrep | pacman:ripgrep |
| fd | Busca archivos y carpetas con una sintaxis sencilla. | No | brew:fd | pacman:fd |
| uv | Administra herramientas, entornos y versiones de Python. | No | brew:uv | pacman:uv |
| NVM | Administrador de versiones de Node; instala NVM solamente. | Sí | native:nvm | native:nvm |
| Bun | Runtime y gestor de paquetes para JavaScript y TypeScript. | Sí | native:bun | native:bun |
| pnpm | Gestor de paquetes JavaScript con instalación independiente. | No | native:pnpm | native:pnpm |
| Deno | Runtime para JavaScript y TypeScript con permisos explícitos. | No | native:deno | native:deno |
| OpenCode CLI | Agente de programación en terminal; instalador oficial web. | Sí | native:opencode | native:opencode |
| Cursor CLI / Agent | Agente de Cursor en terminal, independiente del editor. | Sí | native:cursor-cli | native:cursor-cli |
| Codex CLI | Agente de OpenAI para programar desde la terminal. | No | native:codex | native:codex |
| Claude Code CLI | Agente de Anthropic para programar desde la terminal. | No | native:claude-code | native:claude-code |
| Ghostty | Terminal rápida con aceleración gráfica. | No | cask:ghostty | pacman:ghostty |
| Warp | Terminal con funciones de asistencia y organización. | No | cask:warp | aur:warp-terminal-bin |
| Visual Studio Code | Editor extensible; utiliza tu sincronización de nube. | No | cask:visual-studio-code | aur:visual-studio-code-bin |
| Cursor | Editor de código con asistentes de IA. | No | cask:cursor | aur:cursor-bin |
| Zed | Editor de código rápido y colaborativo. | No | cask:zed | pacman:zed |
| Sublime Text | Editor ligero para código y texto. | No | cask:sublime-text | aur:sublime-text-4 |
| ChatGPT | Aplicación de escritorio de ChatGPT. | No | cask:chatgpt | — |
| Claude Desktop | Aplicación de escritorio de Claude, distinta de Claude Code. | No | cask:claude | — |
| Bruno | Cliente de APIs con colecciones guardadas como archivos. | No | cask:bruno | aur:bruno-bin |
| Postman | Prueba y organiza peticiones y colecciones de APIs. | No | cask:postman | aur:postman-bin |
| Tabularis | Interfaz gráfica para explorar y administrar bases de datos. | No | cask:tabularis | aur:tabularis-bin |
| MongoDB Compass | Interfaz gráfica para consultar bases de datos MongoDB. | No | cask:mongodb-compass | aur:mongodb-compass |
| DBeaver | Cliente SQL para varias bases de datos. | No | cask:dbeaver-community | pacman:dbeaver |
| Docker | Docker Desktop en Mac; Engine y Compose en Linux. | No | cask:docker-desktop | pacman:docker docker-compose |
| Google Chrome | Navegador y herramientas de desarrollo web. | No | cask:google-chrome | aur:google-chrome |
| Helium | Navegador basado en Chromium. | No | cask:helium-browser | aur:helium-browser-bin |
| Slack | Mensajería y colaboración para equipos. | No | cask:slack | aur:slack-desktop |
| Discord | Comunidades, chat y llamadas. | No | cask:discord | pacman:discord |
| WhatsApp | Cliente oficial de mensajería para Mac. | No | cask:whatsapp | — |
| Notion | Notas, documentación y organización personal. | No | cask:notion | — |
| Linear | Gestión de tareas e incidencias. | No | cask:linear | — |
| Spotify | Reproductor de música y podcasts. | No | cask:spotify | aur:spotify |
| Steam | Biblioteca e instalación de juegos; Linux requiere multilib. | No | cask:steam | pacman:steam |
| Android Studio | IDE para Android; SDKs adicionales se administran en la app. | No | cask:android-studio | aur:android-studio |
| Xcode | IDE de Apple; instalación manual desde App Store. | No | manual:xcode | — |
| Rectangle | Organiza ventanas con atajos de teclado en Mac. | No | cask:rectangle | — |
| AppCleaner | Ayuda a desinstalar aplicaciones de Mac y sus archivos. | No | cask:appcleaner | — |
| Clipy | Historial del portapapeles en Mac. | No | cask:clipy | — |
| JetBrains Mono | Fuente monoespaciada para programar. | No | cask:font-jetbrains-mono | pacman:ttf-jetbrains-mono |
| JetBrains Mono Nerd Font | JetBrains Mono con símbolos para eza y terminales. | No | cask:font-jetbrains-mono-nerd-font | pacman:ttf-jetbrains-mono-nerd |
| Hack Nerd Font | Fuente Hack con símbolos adicionales. | No | cask:font-hack-nerd-font | pacman:ttf-hack-nerd |

## Structure / Estructura

- `catalog/`: bilingual descriptions and verified package routes; `options.sh` is generated for Bash startup without Python/Node.
- `shell/`: portable Zsh theme, initialization and aliases.
- `git/`: public identity only.
- `config/`: Ghostty and btop preferences.
- `backups/editors/`: sanitized, reference-only snapshots.
- `packages/`: generated Linux reference manifests; the wizard does not install them wholesale.
- `scripts/`: detection, installation, configuration, cleanup and checks.
- `docs/`: initial inventory, troubleshooting and sources.

See / Ver [Troubleshooting](docs/troubleshooting.md), [Inventory / Inventario](docs/inventory.md), [Sources / Fuentes](docs/sources.md).

To change catalog entries, edit the JSON files and run `python3 scripts/generate-catalog.py`. Python is only required for maintenance, never to start the installer.

Para cambiar el catálogo, edita los JSON y ejecuta `python3 scripts/generate-catalog.py`; genera también los manifiestos Linux y la matriz. `python3 scripts/generate-catalog.py --check` comprueba que coincidan sin escribir archivos. Python solo se requiere para mantenimiento, no para iniciar el instalador.
