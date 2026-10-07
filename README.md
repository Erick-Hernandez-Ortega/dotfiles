# Ramón's dotfiles · macOS + EndeavourOS + Zorin 18

English · [Español](README.es.md)

An interactive wizard to set up my terminal and choose applications on a new Unix computer. No Hyprland, Office or editor extensions are installed.

## Linux compatibility

Arch/EndeavourOS and Zorin 18 (Ubuntu 24.04/noble), x86_64, have separate catalog routes. See the [complete Linux matrix](docs/linux-compatibility.md). macOS retains its existing package routes and appearance.

Arch performs one full upgrade before the first selected package install; AUR requires yay and adds base-devel only when needed. APT refreshes metadata without a general upgrade. Vendor repositories are shown before confirmation; manual entries print upstream instructions and remain pending. Flatpak uses a user Flathub installation. Existing installations are reused.

Linux recognizes XDG/system NVM, localized Documents paths, batcat/fdfind and optional rbenv/fzf/zoxide initialization. NVM still installs no Node. Optional actions enable Docker without changing groups, apply portable Fastfetch and set Ghostty's Linux appearance with JetBrains Mono Nerd Font. Desktop and IDE settings remain outside this repository.

Restore one backed-up file with `bash scripts/restore.sh --backup <run-directory> --file zshrc [--dry-run]`; `--list` shows manifests. Restore backs up the current state and replaces the target itself without writing through its symlink. Older backups without a manifest require manual recovery.

Validation: `python3 -m unittest discover -s tests -v`, `python3 scripts/generate-catalog.py --check`, and the disposable-container checks described in [validation](docs/validation.md). Runtime installs and GUI behavior have separate validation status.

## Quick start

Keep this repository in a permanent location. Installed dotfiles link back to it: do not move or delete it after applying the configuration.

```bash
bash bootstrap.sh --list          # Read-only inventory and option descriptions.
bash bootstrap.sh --dry-run       # Preview actions without changing files.
bash bootstrap.sh                 # Choose options, review and execute.
bash bootstrap.sh --lang en       # English wizard.
bash scripts/doctor.sh            # Read-only verification.
```

The wizard guides you through nine categorized steps. **↑/↓** moves the cursor, **Space** toggles, **Enter** continues, and **← / B** goes back. **Q** cancels without installing. Existing options appear as locked `[x] · already installed` rows. The focused option's description appears below the list.

Going back preserves choices within this run. The final step reviews all actions; Enter confirms installation (or simulation). **D** changes the Dev path from the review screen.

No selection files are persisted. `--list` keeps the detailed inventory. Noninteractive `--dry-run` prints text using defaults; basic terminals (`TERM=dumb`) retain a plain text fallback.

## Behavior

- Intel/Apple Silicon macOS: Homebrew formulae and casks. If Apple developer tools are missing, run `xcode-select --install` and start again.
- EndeavourOS/Arch: pacman and yay for AUR. Ensure yay is available (`sudo pacman -Syu --needed yay`). Zorin 18 has separate APT, vendor and Flatpak routes; other Linux distributions and Zorin 17 are unsupported.
- New installations request the latest available stable release. No version pins, automatic updates or saved selections. Installed apps are preserved; update them through their normal managers.
- NVM only: no Node version is installed. Later, `nvm install --lts` downloads the available Node LTS through NVM.
- Bun/pnpm/Deno and coding agents use standalone installs, without adding Node through Brew/npm.
- OpenCode exclusively uses its official web installer.
- Existing Git is reused; name/email are hardcoded, authentication tokens are never copied.
- Editor snapshots remain reference-only. No settings or extensions are restored; use cloud sync.
- Detection checks commands, files, apps, fonts and packages. Presence does not prove license, login or complete application health.

## Terminal appearance

Choose Zsh configuration to restore robbyrussell, the Git plugin, suggestions, highlighting and these aliases:

| Command | Purpose |
|---|---|
| `ls` | eza listing with icons and directories first. |
| `ll` | Detailed eza listing including hidden files and Git status. |
| `lt` | eza tree limited to two levels. |
| `cat` | bat file viewer with syntax highlighting and paging. |
| `command cat file` | Original cat, bypassing the alias. |
| `fastfetch` | System summary, shown when opening an interactive terminal. |
| `nvm` | Manage Node versions; a shell function rather than a PATH executable. |
| `exec zsh` | Reload the terminal in Zsh after applying dotfiles. |

Default-shell changes are optional and separate. Modified files are backed up under `~/.local/state/ramon-dotfiles/backups/`. Add private settings to `~/.zshrc.local`. Ghostty and btop configuration are separate selections; font installs never modify editors.

## Dev directories

Only missing directories are created; no cloning, moving, Git initialization or project generation. On macOS the default is `~/Documents/Dev`; Linux uses the localized XDG Documents directory when available. It is editable in the wizard.

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

## Git and GitHub access

Identity: **Erick Ramon Hernandez Ortega**, **erickramon47@live.com.mx**. Account: **Erick-Hernandez-Ortega**. Optional HTTPS authentication uses `gh auth login` and `gh auth setup-git`; an existing valid session for this account is reused. A different account is rejected. Select GitHub CLI if missing. Each computer authorizes its own access.

## Cleanup

Downloads use a run-owned temporary directory. Downloaded scripts and build leftovers are removed on completion. Maximum-space mode also removes package caches created by this run; disabling it retains those downloads under `~/.cache/ramon-dotfiles/`.

AUR runs interactively for source review. Only newly added orphan dependencies are considered for removal; required and pre-existing packages stay. General caches, projects, Node versions, Docker data and backups stay untouched. Official installers may maintain their own files outside the temporary directory; necessary data and managed versions are not purged. Homebrew manages the disk images it mounts.

## Catalog

Defaults apply only when a tool is missing. Every application and font is optional.

| Option | Purpose | Default | macOS | EndeavourOS |
|---|---|---|---|---|
| Oh My Zsh | Robbyrussell prompt and Git shortcuts for Zsh. | Yes | native:omz | native:omz |
| Zsh autosuggestions | Suggests commands from your shell history. | Yes | brew:zsh-autosuggestions | pacman:zsh-autosuggestions |
| Zsh syntax highlighting | Highlights shell commands and typing errors. | Yes | brew:zsh-syntax-highlighting | pacman:zsh-syntax-highlighting |
| Fastfetch | Displays system information when a terminal opens. | Yes | brew:fastfetch | pacman:fastfetch |
| eza | Lists files with icons, Git status and tree views. | Yes | brew:eza | pacman:eza |
| bat | Displays files with syntax highlighting and paging. | Yes | brew:bat | pacman:bat |
| btop | Interactive CPU, memory and process monitor. | No | brew:btop | pacman:btop |
| lazydocker | Terminal interface for Docker containers; requires Docker. | No | brew:lazydocker | pacman:lazydocker |
| GitHub CLI | Signs in to GitHub and manages repositories and pull requests. | No | brew:gh | pacman:github-cli |
| ripgrep | Searches text quickly inside files and projects. | No | brew:ripgrep | pacman:ripgrep |
| fd | Finds files and directories with simple syntax. | No | brew:fd | pacman:fd |
| uv | Manages Python tools, environments and versions. | No | brew:uv | pacman:uv |
| NVM | Node version manager; installs NVM only. | Yes | native:nvm | native:nvm |
| Bun | JavaScript and TypeScript runtime and package manager. | Yes | native:bun | native:bun |
| pnpm | JavaScript package manager with a standalone installation. | No | native:pnpm | native:pnpm |
| Deno | JavaScript and TypeScript runtime with explicit permissions. | No | native:deno | native:deno |
| OpenCode CLI | Terminal coding agent; official web installer. | Yes | native:opencode | native:opencode |
| Cursor CLI / Agent | Cursor terminal agent, independent of the editor. | Yes | native:cursor-cli | native:cursor-cli |
| Codex CLI | OpenAI coding agent for the terminal. | No | native:codex | native:codex |
| Claude Code CLI | Anthropic coding agent for the terminal. | No | native:claude-code | native:claude-code |
| Ghostty | Fast GPU-accelerated terminal. | No | cask:ghostty | pacman:ghostty |
| Warp | Terminal with assistance and organization features. | No | cask:warp | aur:warp-terminal-bin |
| Visual Studio Code | Extensible editor; use your cloud settings sync. | No | cask:visual-studio-code | aur:visual-studio-code-bin |
| Cursor | Code editor with AI assistance. | No | cask:cursor | aur:cursor-bin |
| Zed | Fast collaborative code editor. | No | cask:zed | pacman:zed |
| Sublime Text | Lightweight code and text editor. | No | cask:sublime-text | aur:sublime-text-4 |
| ChatGPT | ChatGPT desktop application. | No | cask:chatgpt | — |
| Claude Desktop | Claude desktop app, separate from Claude Code. | No | cask:claude | — |
| Bruno | API client with file-based collections. | No | cask:bruno | aur:bruno-bin |
| Postman | Tests and organizes API requests and collections. | No | cask:postman | aur:postman-bin |
| Tabularis | Graphical database exploration and management tool. | No | cask:tabularis | aur:tabularis-bin |
| MongoDB Compass | Graphical client for MongoDB databases. | No | cask:mongodb-compass | aur:mongodb-compass |
| DBeaver | SQL client for multiple databases. | No | cask:dbeaver-community | pacman:dbeaver |
| Docker | Docker Desktop on Mac; Engine and Compose on Linux. | No | cask:docker-desktop | pacman:docker docker-compose |
| Google Chrome | Browser with web development tools. | No | cask:google-chrome | aur:google-chrome |
| Helium | Chromium-based browser. | No | cask:helium-browser | aur:helium-browser-bin |
| Slack | Team messaging and collaboration. | No | cask:slack | aur:slack-desktop |
| Discord | Community chat and calls. | No | cask:discord | pacman:discord |
| WhatsApp | Official messaging client for Mac. | No | cask:whatsapp | — |
| Notion | Notes, documentation and personal organization. | No | cask:notion | — |
| Linear | Task and issue management. | No | cask:linear | — |
| Spotify | Music and podcast player. | No | cask:spotify | aur:spotify |
| Steam | Game library and installer; Linux requires multilib. | No | cask:steam | pacman:steam |
| Android Studio | Android IDE; manage additional SDKs inside the app. | No | cask:android-studio | aur:android-studio |
| Xcode | Apple IDE; install manually from the App Store. | No | manual:xcode | — |
| Rectangle | Arranges Mac windows using keyboard shortcuts. | No | cask:rectangle | — |
| AppCleaner | Helps uninstall Mac apps and their associated files. | No | cask:appcleaner | — |
| Clipy | Clipboard history on Mac. | No | cask:clipy | — |
| JetBrains Mono | Monospaced programming font. | No | cask:font-jetbrains-mono | pacman:ttf-jetbrains-mono |
| JetBrains Mono Nerd Font | JetBrains Mono with symbols for eza and terminal prompts. | No | cask:font-jetbrains-mono-nerd-font | pacman:ttf-jetbrains-mono-nerd |
| Hack Nerd Font | Hack font with extra terminal symbols. | No | cask:font-hack-nerd-font | pacman:ttf-hack-nerd |

## Structure / Estructura

- `catalog/`: bilingual descriptions and verified package routes; `options.sh` is generated for Bash startup without Python/Node.
- `shell/`: portable Zsh theme, initialization and aliases.
- `git/`: public identity only.
- `config/`: Ghostty and btop preferences.
- `backups/editors/`: sanitized, reference-only snapshots.
- `packages/`: descriptive manifests; the wizard does not install them wholesale.
- `scripts/`: detection, installation, configuration, cleanup and checks.
- `docs/`: initial inventory, troubleshooting and sources.

See / Ver [Troubleshooting](docs/troubleshooting.md), [Inventory / Inventario](docs/inventory.md), [Sources / Fuentes](docs/sources.md).

To change catalog entries, edit the JSON files and run `python3 scripts/generate-catalog.py`. Python is only required for maintenance, never to start the installer.

Para cambiar el catálogo, edita los JSON y ejecuta `python3 scripts/generate-catalog.py`. Python solo se requiere para mantenimiento, no para iniciar el instalador.
