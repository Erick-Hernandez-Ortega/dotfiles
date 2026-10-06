# Personal Zsh entry point. Files are linked into ~/.config/ramon-dotfiles.
export DOTFILES_CONFIG_DIR="${DOTFILES_CONFIG_DIR:-$HOME/.config/ramon-dotfiles}"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"  # Your current Oh My Zsh prompt.
plugins=(git)           # Git shortcuts provided by Oh My Zsh.
[[ -d "$HOME/.zsh/completions" ]] && fpath=("$HOME/.zsh/completions" $fpath)
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit && compinit
fi
[[ -r "$DOTFILES_CONFIG_DIR/tools.zsh" ]] && source "$DOTFILES_CONFIG_DIR/tools.zsh"
[[ -r "$DOTFILES_CONFIG_DIR/aliases.zsh" ]] && source "$DOTFILES_CONFIG_DIR/aliases.zsh"
# Private, machine-specific settings are kept outside the public repo.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
# Keep highlighting last so it can see widgets created above.
for prefix in /opt/homebrew /usr/local /usr; do
  file="$prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  if [[ -r "$file" ]]; then source "$file"; break; fi
done
for prefix in /opt/homebrew /usr/local /usr; do
  file="$prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  if [[ -r "$file" ]]; then source "$file"; break; fi
done
unset prefix file
# Match your existing terminal: show Fastfetch only in an interactive TTY.
if [[ -o interactive && -t 1 ]] && (( $+commands[fastfetch] )); then
  fastfetch
fi
