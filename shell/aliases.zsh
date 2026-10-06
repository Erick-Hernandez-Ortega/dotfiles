# eza: file listing with icons, directories first, Git status and tree view.
if (( $+commands[eza] )); then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -la --icons --git --group-directories-first"
  alias lt="eza --tree --level=2 --icons"
fi
# bat: syntax-highlighted file viewer. Use `command cat` for the original command.
(( $+commands[bat] )) && alias cat="bat"
