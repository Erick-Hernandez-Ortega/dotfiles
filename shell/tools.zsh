# Unique PATH entries prevent duplication when the shell is reloaded.
typeset -U path PATH
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
export BUN_INSTALL="$HOME/.bun"
path=("$BUN_INSTALL/bin" "$HOME/.local/bin" "$HOME/.opencode/bin" $path)
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
if [[ "$OSTYPE" == darwin* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi
[[ -d "$PNPM_HOME" ]] && path=("$PNPM_HOME" $path)
[[ -s "$HOME/.deno/env" ]] && source "$HOME/.deno/env"
[[ -d "$HOME/.deno/bin" ]] && path=("$HOME/.deno/bin" $path)
# Preserve the optional tools already present on your Mac, without installing them.
for directory in "$HOME/.antigravity/antigravity/bin" "$HOME/.antigravity-ide/antigravity-ide/bin"; do
  [[ -d "$directory" ]] && path=("$directory" $path)
done
unset directory
