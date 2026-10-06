# Installation sources / Fuentes

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
