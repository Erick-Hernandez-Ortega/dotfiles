# Homebrew PATH: Apple Silicon, Intel Mac, or an existing Linuxbrew installation.
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x "$brew_bin" ]]; then
    eval "$("$brew_bin" shellenv)"
    break
  fi
done
unset brew_bin
