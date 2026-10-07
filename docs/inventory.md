# Initial inventory / Inventario inicial

Inspected on 2026-10-05 on macOS Apple Silicon. EndeavourOS is the Linux target; it has not been executed or inspected from this computer.

Inspección del 2026-10-05 en Mac Apple Silicon. EndeavourOS es el objetivo Linux; no se inspeccionó ni ejecutó desde este equipo.

- Zsh + Oh My Zsh, robbyrussell, Git plugin; autosuggestions and syntax highlighting.
- NVM with an existing default Node and another existing Node version. Versions are not restored or pinned.
- Bun, pnpm and Deno detected. New installs request the latest stable available release.
- OpenCode, Cursor Agent and standalone Codex CLI detected. Claude Code was not on the inspected PATH.
- Git identity: Erick Ramon Hernandez Ortega / erickramon47@live.com.mx.
- GitHub account: Erick-Hernandez-Ortega; HTTPS, credentials stored in OS keyring. No token is included.
- JetBrains Mono and Hack Nerd Font found in user fonts.
- Ghostty: background #23262e, opacity 0.80, blur 80.
- VS Code, Cursor and Zed preferences archived for reference only.
- VS Code preferences reference Prettier/SCSS formatters not found in its extension list. Cloud sync remains responsible for restoration.
- Docker, Xcode and Android SDK detected. No Docker data or SDK contents are copied.
- ripgrep currently resolves inside ChatGPT.app; an independent installation is recommended, but existing commands are reused.

## Deliberately excluded / Excluidos

Office; Hyprland installation/configuration; lazygit; git-quick-stats; npm global tsx/Corepack/@humanlayer/cli; auth files; private keys; histories; .env; projects; browser profiles; editor extension binaries.

No packages, active dotfiles, development folders or user caches were changed while preparing this repository.

## Linux inspection · 2026-10-06

Inspected this EndeavourOS x86_64 computer: Hyprland/HyDE with Wayland; development under `~/Documentos/Dev`; NVM from pacman plus XDG versions; Node, Bun, pnpm, Deno, Ruby/rbenv and Java 17; Docker and Compose; Ghostty, Warp, VS Code, Cursor, Zed, Postman, Tabularis, MongoDB Compass, TablePlus, lazyworktree, ngrok, Watchman, Firefox, VLC, Spotify and Steam.

Existing rbenv initialization was repeated in the active `.zshrc`. This update does not edit that active file; applying the repo shell supplies a single guarded initialization. Linux desktop configs, IDE configs, credentials and application data are not imported.

## Windows inspection · 2026-10-06

Read-only inspection of the current x64 Windows computer found Windows PowerShell 5.1, Chocolatey and WinGet. E: is labeled `SSD externo`; applications are distributed between `E:\Software`, Program Files and per-user directories. Development uses `E:\Development`, with Frontend/{Angular,Next,React,Vue}, Backend/{Nest,Node}, Mobile/React Native, Desktop, AI/OpenCode and Others. Existing Models data is not copied or moved.

The PowerShell profile is under OneDrive Documents. It initializes Oh My Posh with robbyrussell, Terminal-Icons and Chocolatey completions. Windows Terminal uses One Half Dark and FiraCode Nerd Font Mono; its existing elevation setting is not applied to new installations. JetBrains Mono is also installed.

NVM for Windows uses `E:\Software\nvm` and `C:\nvm4w\nodejs`. Bun, pnpm, Deno, Java 17, Android SDK, Docker Desktop/Compose, OpenCode, Cursor Agent, Codex and Ollama are present. Detected development apps include VS Code, Cursor, Zed, Warp, Postman, DBeaver, MongoDB Compass, HeidiSQL, MariaDB, Android Studio, PyCharm, WebStorm, Windsurf and Trae. User apps include Chrome, Comet, Discord, WhatsApp, Notion, Linear, Claude, Spotify, Steam, VLC and WinRAR.

The `python` command resolves to Python 2; `python3` resolves to a Microsoft Store alias rather than a verified interpreter. Docker Compose responds, but the Docker daemon was not accessible during inspection. Portable apps can escape registry detection; Yaak was found as an application directory and remains a manual catalog option unless its executable is recognized.

No host applications, active profiles, Git configuration, persistent environment variables or existing development directories were changed while implementing Windows support. A Python 3 portable runtime was downloaded inside the ignored workspace `.state` directory solely for maintenance checks.
