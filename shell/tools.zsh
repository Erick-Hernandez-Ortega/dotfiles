# Unique PATH entries prevent duplication when the shell is reloaded.
typeset -U path PATH
if [[ "$OSTYPE" == linux* ]]; then
  # Keep an explicit NVM_DIR; reuse existing XDG data instead of creating a second install.
  if [[ -z "${NVM_DIR:-}" ]]; then
    if [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/nvm" && ! -s "$HOME/.nvm/nvm.sh" ]]; then
      export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
    else export NVM_DIR="$HOME/.nvm"; fi
  fi
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
  elif [[ -s /usr/share/nvm/nvm.sh ]]; then
    source /usr/share/nvm/nvm.sh
  fi
  if [[ -s "$NVM_DIR/bash_completion" ]]; then source "$NVM_DIR/bash_completion"
  elif [[ -s /usr/share/nvm/bash_completion ]]; then source /usr/share/nvm/bash_completion; fi
  [[ ! -d "$HOME/.rbenv/bin" ]] || path=("$HOME/.rbenv/bin" $path)
  (( ! $+commands[rbenv] )) || eval "$(rbenv init - zsh)"
  (( ! $+commands[zoxide] )) || eval "$(zoxide init zsh)"
  # Ubuntu's package installs fd under the fdfind name.
  if (( ! $+commands[fd] && $+commands[fdfind] )); then alias fd=fdfind; fi
  if (( $+commands[fzf] )); then
    for integration in /usr/share/fzf/key-bindings.zsh /usr/share/doc/fzf/examples/key-bindings.zsh; do
      if [[ -r "$integration" ]]; then source "$integration"; break; fi
    done
    unset integration
  fi
else
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi
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
