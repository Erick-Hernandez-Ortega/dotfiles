# Windows compatibility / Compatibilidad Windows

Generated from catalog/*.json. Windows 10/11 x64; PowerShell 5.1 or 7.

Choose a drive and edit Software, Development and Data roots in the wizard.
Custom destinations use verified installer switches or official portable releases; settings/shared components may remain on C:.
System routes have no verified custom switch. Manual entries remain pending. Existing applications/data are never migrated.
Package availability and live installer behavior are separate checks; see windows.md and validation.md.

| Option | Method | Destination | Source |
|---|---|---|---|
| Fastfetch | `zip:fastfetch-cli/fastfetch` | SoftwareRoot/Fastfetch | [Source](https://github.com/fastfetch-cli/fastfetch/releases) |
| eza | `zip:eza-community/eza` | SoftwareRoot/eza | [Source](https://github.com/eza-community/eza/releases) |
| bat | `zip:sharkdp/bat` | SoftwareRoot/bat | [Source](https://github.com/sharkdp/bat/releases) |
| lazydocker | `zip:jesseduffield/lazydocker` | SoftwareRoot/lazydocker | [Source](https://github.com/jesseduffield/lazydocker/releases) |
| GitHub CLI | `choco:gh` | System/user default | [Source](https://community.chocolatey.org/packages/gh) |
| ripgrep | `zip:BurntSushi/ripgrep` | SoftwareRoot/ripgrep | [Source](https://github.com/BurntSushi/ripgrep/releases) |
| fd | `zip:sharkdp/fd` | SoftwareRoot/fd | [Source](https://github.com/sharkdp/fd/releases) |
| uv | `zip:astral-sh/uv` | SoftwareRoot/uv | [Source](https://github.com/astral-sh/uv/releases) |
| NVM | `winget:CoreyButler.NVMforWindows` | SoftwareRoot/nvm | [Source](https://github.com/coreybutler/nvm-windows) |
| Bun | `native:bun` | SoftwareRoot/Bun | [Source](https://bun.sh/docs/installation) |
| pnpm | `native:pnpm` | SoftwareRoot/pnpm | [Source](https://pnpm.io/installation) |
| Deno | `native:deno` | SoftwareRoot/Deno | [Source](https://docs.deno.com/runtime/getting_started/installation/) |
| OpenCode CLI | `zip:anomalyco/opencode` | SoftwareRoot/OpenCode | [Source](https://opencode.ai/docs/) |
| Cursor CLI / Agent | `native:cursor-cli` | System/user default | [Source](https://cursor.com/docs/cli/installation) |
| Codex CLI | `manual:https://developers.openai.com/codex/windows` | Manual | [Source](https://developers.openai.com/codex/windows) |
| Claude Code CLI | `native:claude-code` | System/user default | [Source](https://code.claude.com/docs/en/setup) |
| jq | `choco:jq` | System/user default | [Source](https://community.chocolatey.org/packages/jq) |
| fzf | `zip:junegunn/fzf` | SoftwareRoot/fzf | [Source](https://github.com/junegunn/fzf/releases) |
| zoxide | `choco:zoxide` | System/user default | [Source](https://community.chocolatey.org/packages/zoxide) |
| Java 17 JDK | `choco:microsoft-openjdk17` | System/user default | [Source](https://community.chocolatey.org/packages/microsoft-openjdk17) |
| ngrok | `choco:ngrok` | System/user default | [Source](https://community.chocolatey.org/packages/ngrok) |
| Git | `choco:git.install` | SoftwareRoot/Git | [Source](https://docs.chocolatey.org/en-us/choco/commands/install/) |
| Oh My Posh | `choco:oh-my-posh` | System/user default | [Source](https://community.chocolatey.org/packages/oh-my-posh) |
| Terminal-Icons | `module:Terminal-Icons` | System/user default | [Source](https://www.powershellgallery.com/packages/Terminal-Icons) |
| PSReadLine | `module:PSReadLine` | System/user default | [Source](https://www.powershellgallery.com/packages/PSReadLine) |
| PowerShell 7 | `choco:powershell-core` | System/user default | [Source](https://community.chocolatey.org/packages/powershell-core) |
| Python 3 | `choco:python3` | SoftwareRoot/Python | [Source](https://community.chocolatey.org/packages/python3) |
| Visual Studio Build Tools | `manual:https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio` | Manual | [Source](https://visualstudio.microsoft.com/downloads/) |
| Warp | `choco:warp-terminal` | System/user default | [Source](https://community.chocolatey.org/packages/warp-terminal) |
| Visual Studio Code | `choco:vscode` | SoftwareRoot/Microsoft VS Code | [Source](https://community.chocolatey.org/packages/vscode) |
| Cursor | `choco:cursoride` | SoftwareRoot/Cursor | [Source](https://community.chocolatey.org/packages/cursoride) |
| Zed | `native-exe:zed` | SoftwareRoot/Zed | [Source](https://zed.dev/docs/windows) |
| Sublime Text | `choco:sublimetext4` | SoftwareRoot/Sublime Text | [Source](https://community.chocolatey.org/packages/sublimetext4) |
| ChatGPT | `manual:https://chatgpt.com/download` | Manual | [Source](https://chatgpt.com/download) |
| Claude Desktop | `manual:https://claude.ai/download` | Manual | [Source](https://claude.ai/download) |
| Bruno | `choco:bruno` | System/user default | [Source](https://community.chocolatey.org/packages/bruno) |
| Postman | `choco:postman` | System/user default | [Source](https://community.chocolatey.org/packages/postman) |
| Tabularis | `manual:https://github.com/debba/tabularis` | Manual | [Source](https://github.com/debba/tabularis) |
| MongoDB Compass | `choco:mongodb-compass` | System/user default | [Source](https://community.chocolatey.org/packages/mongodb-compass) |
| DBeaver | `choco:dbeaver` | SoftwareRoot/DBeaver | [Source](https://dbeaver.com/docs/dbeaver/Windows-Silent-Install/) |
| Docker | `choco:docker-desktop` | System/user default | [Source](https://community.chocolatey.org/packages/docker-desktop) |
| Google Chrome | `choco:googlechrome` | System/user default | [Source](https://community.chocolatey.org/packages/googlechrome) |
| Helium | `manual:https://helium.com/` | Manual | [Source](https://helium.com/) |
| Slack | `choco:slack` | System/user default | [Source](https://community.chocolatey.org/packages/slack) |
| Discord | `choco:discord` | System/user default | [Source](https://community.chocolatey.org/packages/discord) |
| WhatsApp | `winget:9NKSQGP7F2NH` | System/user default | [Source](https://apps.microsoft.com/detail/9nksqgp7f2nh) |
| Notion | `choco:notion` | System/user default | [Source](https://community.chocolatey.org/packages/notion) |
| Linear | `manual:https://linear.app/download` | Manual | [Source](https://linear.app/download) |
| Spotify | `choco:spotify` | System/user default | [Source](https://community.chocolatey.org/packages/spotify) |
| Steam | `choco:steam` | System/user default | [Source](https://community.chocolatey.org/packages/steam) |
| Android Studio | `choco:androidstudio` | System/user default | [Source](https://community.chocolatey.org/packages/androidstudio) |
| TablePlus | `manual:https://tableplus.com/windows` | Manual | [Source](https://tableplus.com/windows) |
| Firefox | `choco:firefox` | System/user default | [Source](https://community.chocolatey.org/packages/firefox) |
| VLC | `choco:vlc` | System/user default | [Source](https://community.chocolatey.org/packages/vlc) |
| Windows Terminal | `choco:microsoft-windows-terminal` | System/user default | [Source](https://community.chocolatey.org/packages/microsoft-windows-terminal) |
| HeidiSQL | `choco:heidisql` | SoftwareRoot/HeidiSQL | [Source](https://community.chocolatey.org/packages/heidisql) |
| MariaDB | `choco:mariadb` | System/user default | [Source](https://community.chocolatey.org/packages/mariadb) |
| PyCharm | `choco:pycharm-community` | System/user default | [Source](https://community.chocolatey.org/packages/pycharm-community) |
| WebStorm | `choco:webstorm` | System/user default | [Source](https://community.chocolatey.org/packages/webstorm) |
| WinRAR | `choco:winrar` | System/user default | [Source](https://community.chocolatey.org/packages/winrar) |
| Yaak | `manual:https://yaak.app/` | Manual | [Source](https://yaak.app/) |
| Windsurf | `manual:https://windsurf.com/download` | Manual | [Source](https://windsurf.com/download) |
| Trae | `manual:https://www.trae.ai/download` | Manual | [Source](https://www.trae.ai/download) |
| Comet | `manual:https://www.perplexity.ai/comet` | Manual | [Source](https://www.perplexity.ai/comet) |
| Ollama | `native-exe:ollama` | SoftwareRoot/Ollama; new data: DataRoot/Ollama | [Source](https://docs.ollama.com/windows) |
| JetBrains Mono | `choco:jetbrainsmono` | System/user default | [Source](https://community.chocolatey.org/packages/jetbrainsmono) |
| JetBrains Mono Nerd Font | `choco:nerd-fonts-JetBrainsMono` | System/user default | [Source](https://community.chocolatey.org/packages/nerd-fonts-JetBrainsMono) |
| Hack Nerd Font | `choco:nerd-fonts-Hack` | System/user default | [Source](https://community.chocolatey.org/packages/nerd-fonts-Hack) |
| FiraCode Nerd Font | `choco:nerd-fonts-FiraCode` | System/user default | [Source](https://community.chocolatey.org/packages/nerd-fonts-FiraCode) |
