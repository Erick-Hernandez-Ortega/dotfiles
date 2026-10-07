# Installation sources / Fuentes

## Windows sources

Every Windows catalog option includes its package/upstream source; the [generated matrix](windows-compatibility.md) lists them. Chocolatey package identifiers were checked against their community pages where available; installation success is verified separately at runtime. Official portable release routes are used when a package would keep its binaries in Chocolatey's directory instead of the chosen drive.

- [Chocolatey installation and arguments](https://docs.chocolatey.org/en-us/choco/commands/install/): package parameters and installer arguments are distinct; no universal custom-directory switch is assumed.
- [WinGet installation options](https://learn.microsoft.com/en-us/windows/package-manager/winget/install): exact ID/source and location when supported.
- [NVM for Windows](https://github.com/coreybutler/nvm-windows): separate manager/symlink directories; no managed Node is installed by this repo.
- [Inno Setup parameters](https://jrsoftware.org/ishelp/topic_setupcmdline.htm): `/DIR` for compatible installers. [DBeaver](https://dbeaver.com/docs/dbeaver/Windows-Silent-Install/) documents its final `/D` parameter instead.
- [Bun](https://bun.sh/install.ps1), [pnpm](https://get.pnpm.io/install.ps1), [Deno](https://deno.land/install.ps1), [Cursor CLI](https://cursor.com/docs/cli/installation) and [Claude Code](https://code.claude.com/docs/en/setup): official PowerShell scripts.
- [Ollama Windows](https://docs.ollama.com/windows): binary install directory and `OLLAMA_MODELS` for new model storage.
- The robbyrussell appearance is reproduced from the inspected user theme; [Oh My Posh](https://github.com/JanDeDobbeleer/oh-my-posh) provides the prompt engine.

## Unix sources

Commands below explain installation methods; the wizard uses temporary downloaded scripts rather than piping directly where practical. Latest stable versions are resolved at installation time.

| Component | Source | Method / Método |
|---|---|---|
| Homebrew | https://brew.sh | Official install script; formulae and casks |
| NVM | https://github.com/nvm-sh/nvm | Resolve latest release, run official install.sh with PROFILE=/dev/null; no Node |
| Oh My Zsh | https://github.com/ohmyzsh/ohmyzsh | Shallow clone of official repository; setup config supplied here |
| Bun | https://bun.sh/docs/installation | https://bun.sh/install |
| pnpm | https://pnpm.io/installation | https://get.pnpm.io/install.sh |
| Deno | https://docs.deno.com/runtime/getting_started/installation/ | https://deno.land/install.sh |
| OpenCode | https://opencode.ai/docs/ | https://opencode.ai/install |
| Cursor CLI | https://cursor.com/cli | https://cursor.com/install |
| Codex CLI | https://github.com/openai/codex | https://chatgpt.com/codex/install.sh |
| Claude Code | https://code.claude.com/docs/en/setup | https://claude.ai/install.sh |
| Mac applications/fonts | https://formulae.brew.sh/cask/ | Homebrew casks, official upstream distributions |
| Arch packages | https://archlinux.org/packages/ | pacman |
| AUR recipes | https://aur.archlinux.org/ | yay, interactive review |
| Homebrew cleanup | https://docs.brew.sh/Manpage | Run-owned cache directory only |
| Arch cache control | https://man.archlinux.org/man/pacman.8.en | --cachedir points at run-owned temporary folder |

Package routes checked on 2026-10-05; live availability may change. The installer reports errors instead of downloading alternative unofficial clients.

All macOS cask identifiers and Linux package routes in the current catalog were checked against Homebrew/Arch/AUR APIs. This verifies names and availability at inspection time, not installation success.

## Linux routes added · 2026-10-06

- Zorin's package model/base: https://help.zorin.com/docs/apps-games/install-apps/
- APT package availability: https://packages.ubuntu.com/noble/
- VS Code: https://code.visualstudio.com/docs/setup/linux
- Cursor signed APT source: https://cursor.com/docs/get-started/quickstart
- Warp signed APT source: https://docs.warp.dev/getting-started/quickstart/installation-and-setup
- Docker Ubuntu source: https://docs.docker.com/engine/install/ubuntu/ (uses Ubuntu base codename, not the derivative codename)
- Fastfetch release DEB: https://github.com/fastfetch-cli/fastfetch/releases/latest
- Zed Linux installer: https://zed.dev/docs/linux
- uv: https://docs.astral.sh/uv/getting-started/installation/
- Nerd Fonts release archives: https://github.com/ryanoasis/nerd-fonts/releases/latest
- Ghostty platform-specific blur: https://ghostty.org/docs/config/reference#background-blur
- Lazyworktree: https://github.com/chmouel/lazyworktree
- ZapZap community client: https://github.com/rtosta/zapzap

Manual routes retain their exact upstream links in the generated Linux compatibility matrix. These links are installation guidance, not automatic downloads of wrappers or unofficial desktop clients.
