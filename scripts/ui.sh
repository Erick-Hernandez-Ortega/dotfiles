#!/usr/bin/env bash
# Dependency-free keyboard wizard for the Bash 3.2 shipped with macOS.
# Arrows move, Space toggles, Enter advances, Left/B returns, Q cancels.
UI_ACTIVE=0
UI_STTY=''
UI_STEP=0
UI_CURSOR=0
UI_OFFSET=0
UI_NOTICE=''
UI_STATE_IDS=()
UI_STATE_FLAGS=()
UI_IDS=()
UI_LABELS=()
UI_DESCS=()
UI_FLAGS=()
UI_LOCKED=()
UI_STATUSES=()
UI_TITLES_ES=('Esenciales' 'Runtimes' 'Agentes de IA' 'Editores' 'Desarrollo' 'Tu día a día' 'Fuentes' 'Personalización' 'Revisar y comenzar')
UI_TITLES_EN=('Essentials' 'Runtimes' 'AI agents' 'Editors' 'Development' 'Everyday apps' 'Fonts' 'Personalization' 'Review and start')
UI_GROUPS=(
  'git omz autosuggestions syntax-highlighting fastfetch eza bat btop gh ripgrep fd uv lazydocker jq fzf zoxide rsync'
  'nvm bun pnpm deno rbenv'
  'opencode cursor-cli codex claude-code'
  'vscode cursor zed sublime'
  'ghostty warp bruno postman tabularis compass dbeaver docker android xcode java17 watchman ngrok lazyworktree tableplus'
  'chrome helium slack discord whatsapp notion linear spotify steam rectangle appcleaner clipy firefox vlc zapzap'
  'jetbrains jetbrains-nerd hack-nerd'
)
ui_text() { if [[ "$LANGUAGE" == es ]]; then printf '%s' "$1"; else printf '%s' "$2"; fi; }
ui_end() {
  if (( UI_ACTIVE )); then
    stty "$UI_STTY" 2>/dev/null || true
    printf '\033[?25h\033[?1049l'
    UI_ACTIVE=0
  fi
}
ui_exit() { ui_end; finish_temp; }
ui_begin() {
  UI_STTY="$(stty -g)"
  UI_ACTIVE=1
  trap ui_exit EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'UI_KEY=resize' WINCH
  stty -echo -icanon min 1 time 0
  printf '\033[?1049h\033[?25l'
}
ui_key() {
  local first='' second='' third=''
  UI_KEY=''
  if ! IFS= read -r -s -n 1 first; then
    [[ "$UI_KEY" == resize ]] || UI_KEY=quit
    return 0
  fi
  UI_CHAR="$first"
  case "$first" in
    $'\033')
      if IFS= read -r -s -n 1 -t 1 second; then
        if [[ "$second" == '[' || "$second" == O ]]; then
          IFS= read -r -s -n 1 -t 1 third || true
          case "$third" in A) UI_KEY=up;; B) UI_KEY=down;; C) UI_KEY=next;; D) UI_KEY=back;; H) UI_KEY=home;; F) UI_KEY=end;; esac
        fi
      else UI_KEY=back; fi;;
    ' ') UI_KEY=toggle;;
    ''|$'\r') UI_KEY=enter;;
    k) UI_KEY=up;; j) UI_KEY=down;; b|B) UI_KEY=back;;
    q|Q) UI_KEY=quit;;
    *) UI_KEY=other;;
  esac
}
ui_dimensions() {
  local size
  size="$(stty size 2>/dev/null || true)"
  UI_ROWS="${size%% *}"; UI_COLS="${size##* }"
  [[ "$UI_ROWS" =~ ^[0-9]+$ ]] || UI_ROWS=24
  [[ "$UI_COLS" =~ ^[0-9]+$ ]] || UI_COLS=80
  (( UI_ROWS >= 16 )) || UI_ROWS=16
  (( UI_COLS >= 40 )) || UI_COLS=40
  UI_WINDOW=$((UI_ROWS-15))
}
ui_clip() {
  local text="$1" width="$2"
  if (( ${#text} > width )); then printf '%s…' "${text:0:$((width-1))}"; else printf '%s' "$text"; fi
}
ui_header() {
  local title i
  ui_dimensions
  if [[ "$LANGUAGE" == es ]]; then title="${UI_TITLES_ES[$UI_STEP]}"; else title="${UI_TITLES_EN[$UI_STEP]}"; fi
  printf '\033[H\033[2J\n  \033[1;35m◆ RAMON\033[0m  \033[2m/ DOTFILES\033[0m\n'
  printf '  \033[2m%s · %s · %s\033[0m\n\n' "$OS" "$(uname -m)" "$(ui_text 'Configura tu próxima computadora' 'Set up your next computer')"
  printf '  \033[35m'
  for ((i=0;i<9;i++)); do if ((i<=UI_STEP)); then printf '━'; else printf '─'; fi; done
  printf '\033[0m  \033[2m%s / 9\033[0m\n' "$((UI_STEP+1))"
  printf '  \033[1m%s\033[0m\n\n' "$title"
}
ui_description() {
  local text="$1" width="$((UI_COLS-4))" first_line=''
  if (( ${#text} > width )); then
    first_line="${text:0:$width}"
    if [[ "$first_line" == *' '* ]]; then first_line="${first_line% *}"; fi
    printf '  %s\n' "$first_line"
    text="${text:${#first_line}}"; text="${text# }"
    printf '  '; ui_clip "$text" "$width"; printf '\n'
  else printf '  %s\n\n' "$text"; fi
}
ui_state_get() {
  local id="$1" default="$2" i
  UI_VALUE="$default"
  for ((i=0;i<${#UI_STATE_IDS[@]};i++)); do
    if [[ "${UI_STATE_IDS[$i]}" == "$id" ]]; then UI_VALUE="${UI_STATE_FLAGS[$i]}"; return; fi
  done
}
ui_state_set() {
  local id="$1" value="$2" i
  for ((i=0;i<${#UI_STATE_IDS[@]};i++)); do
    if [[ "${UI_STATE_IDS[$i]}" == "$id" ]]; then UI_STATE_FLAGS[$i]="$value"; return; fi
  done
  UI_STATE_IDS+=("$id"); UI_STATE_FLAGS+=("$value")
}
ui_add() {
  local id="$1" label="$2" description="$3" default="$4" locked="$5" status="$6"
  ui_state_get "$id" "$default"
  (( locked )) && UI_VALUE=1
  UI_IDS+=("$id"); UI_LABELS+=("$label"); UI_DESCS+=("$description")
  UI_FLAGS+=("$UI_VALUE"); UI_LOCKED+=("$locked"); UI_STATUSES+=("$status")
}
ui_save() {
  local i
  for ((i=0;i<${#UI_IDS[@]};i++)); do
    # Existing programs are informational, never selected for reinstalling.
    if (( ! ${UI_LOCKED[$i]} )); then ui_state_set "${UI_IDS[$i]}" "${UI_FLAGS[$i]}"; fi
  done
}
ui_load_page() {
  local id status description locked
  UI_IDS=(); UI_LABELS=(); UI_DESCS=(); UI_FLAGS=(); UI_LOCKED=(); UI_STATUSES=()
  UI_CURSOR=0; UI_OFFSET=0; UI_NOTICE=''
  if (( UI_STEP < 7 )); then
    for id in ${UI_GROUPS[$UI_STEP]}; do
      if [[ "$id" == git ]]; then
        if git_ready; then status="$(ui_text 'ya instalado' 'already installed')"
        else status="$(ui_text 'requisito · se instalará' 'required · will be installed')"; fi
        ui_add git Git "$(ui_text 'Control de versiones. Se reutiliza el Git existente y se conserva su instalación.' 'Version control. Reuses the existing Git installation.')" 1 1 "$status"
        continue
      fi
      row "$id"
      [[ -n "$(route)" ]] || continue
      locked=0; status=''
      if is_installed; then locked=1; status="$(ui_text 'ya instalado' 'already installed')"
      elif [[ "$(route)" == manual:* ]]; then status="$(ui_text 'instalación manual' 'manual installation')"; fi
      if [[ "$LANGUAGE" == es ]]; then description="$ES"; else description="$EN"; fi
      ui_add "$id" "$LABEL" "$description" "$DEFAULT" "$locked" "$status"
    done
  else
    ui_add @shell "$(ui_text 'Tu configuración de Zsh' 'Your Zsh configuration')" "$(ui_text 'Aplica robbyrussell, alias y Fastfetch. Respalda antes los archivos actuales.' 'Apply robbyrussell, aliases and Fastfetch. Back up existing files first.')" 1 0 ''
    ui_add @switch "$(ui_text 'Usar Zsh como shell predeterminada' 'Use Zsh as the default shell')" "$(ui_text 'Detecta la shell de inicio y permite cambiarla a Zsh.' 'Detect the login shell and change it to Zsh if needed.')" 0 0 ''
    ui_add @git "$(ui_text 'Tu identidad de Git' 'Your Git identity')" 'Erick Ramon Hernandez Ortega · erickramon47@live.com.mx' 1 0 ''
    ui_add @auth "$(ui_text 'Conectar GitHub por HTTPS' 'Connect GitHub over HTTPS')" "$(ui_text 'Cuenta Erick-Hernandez-Ortega. Usa GitHub CLI; nunca copia tokens al repo.' 'Account Erick-Hernandez-Ortega. Uses GitHub CLI; never copies tokens to the repo.')" 0 0 ''
    ui_add @ghostty "$(ui_text 'Apariencia de Ghostty' 'Ghostty appearance')" "$(ui_text 'Fondo y transparencia; Linux usa JetBrains Mono Nerd Font. Desenfoque según escritorio.' 'Background and opacity; Linux uses JetBrains Mono Nerd Font. Blur depends on desktop.')" 0 0 ''
    if [[ "$OS" == linux ]]; then
      ui_add @docker "$(ui_text 'Iniciar y habilitar Docker' 'Start and enable Docker')" "$(ui_text 'Habilita el servicio al arrancar; no modifica grupos.' 'Enable the service at boot; does not change groups.')" 0 0 ''
      ui_add @fastfetch "$(ui_text 'Fastfetch portable' 'Portable Fastfetch')" "$(ui_text 'Resumen visual sin dependencias de HyDE; respalda tu configuración.' 'Visual summary without HyDE dependencies; backs up your configuration.')" 0 0 ''
    fi
    ui_add @btop "$(ui_text 'Preferencias de btop' 'btop preferences')" "$(ui_text 'Aplica el respaldo de tu monitor de recursos.' 'Apply your resource monitor preferences.')" 0 0 ''
    ui_add @dev "$(ui_text 'Estructura de carpetas Dev' 'Dev directory structure')" "$(ui_text 'Solo carpetas: Frontend, Backend, Mobile, Desktop, Libraries, Scripts, Playground y Others.' 'Directories only: Frontend, Backend, Mobile, Desktop, Libraries, Scripts, Playground and Others.')" 1 0 ''
    ui_add @clean "$(ui_text 'Máximo ahorro de espacio' 'Maximum space savings')" "$(ui_text 'Borra las descargas y cachés de esta instalación. Conserva datos y dependencias necesarias.' 'Remove downloads and caches from this run. Keep data and required dependencies.')" 1 0 ''
  fi
}
ui_render_page() {
  local i end mark color pointer width
  ui_header
  if (( UI_CURSOR < UI_OFFSET )); then UI_OFFSET="$UI_CURSOR"; fi
  if (( UI_CURSOR >= UI_OFFSET+UI_WINDOW )); then UI_OFFSET=$((UI_CURSOR-UI_WINDOW+1)); fi
  end=$((UI_OFFSET+UI_WINDOW)); ((end>${#UI_IDS[@]})) && end=${#UI_IDS[@]}
  for ((i=UI_OFFSET;i<end;i++)); do
    pointer=' '; color='0'; mark=' '
    (( ${UI_FLAGS[$i]} )) && mark=x
    (( ${UI_LOCKED[$i]} )) && color=2
    if (( i==UI_CURSOR )); then pointer='›'; color='1;35'; fi
    printf '  \033[%sm%s [%s] ' "$color" "$pointer" "$mark"
    width=$((UI_COLS-12))
    if [[ -n "${UI_STATUSES[$i]}" ]]; then
      ui_clip "${UI_LABELS[$i]} · ${UI_STATUSES[$i]}" "$width"
    else ui_clip "${UI_LABELS[$i]}" "$width"; fi
    printf '\033[0m\n'
  done
  # Fixed-height body prevents descriptions and controls from jumping as you scroll.
  for ((i=end-UI_OFFSET;i<UI_WINDOW;i++)); do printf '\n'; done
  printf '\n\033[2m'
  ui_description "${UI_DESCS[$UI_CURSOR]:-}"
  printf '\033[0m'
  if [[ -n "$UI_NOTICE" ]]; then printf '  \033[33m'; ui_clip "$UI_NOTICE" "$((UI_COLS-4))"; printf '\033[0m\n'
  else printf '  \033[2m%s\033[0m\n' "$(ui_text 'Los programas instalados se conservan.' 'Installed programs are kept.')"; fi
  printf '\n  \033[35m↑↓\033[0m %s   \033[35m%s\033[0m %s   \033[35mEnter\033[0m %s\n' "$(ui_text 'mover' 'move')" "$(ui_text 'Espacio' 'Space')" "$(ui_text 'marcar' 'toggle')" "$(ui_text 'continuar' 'continue')"
  printf '  \033[2m← / B %s · Q %s · %s/%s\033[0m' "$(ui_text 'volver' 'back')" "$(ui_text 'salir' 'quit')" "$((UI_CURSOR+1))" "${#UI_IDS[@]}"
}
ui_apply_choices() {
  local i id value
  SELECTED=()
  CONFIG_SHELL=0; SWITCH_SHELL=0; CONFIG_GIT=0; AUTH_GIT=0
  CONFIG_DOCKER=0; CONFIG_FASTFETCH=0; CONFIG_GHOSTTY=0; CONFIG_BTOP=0; CREATE_DEV=0; MAX_CLEAN=0
  for ((i=0;i<${#UI_STATE_IDS[@]};i++)); do
    id="${UI_STATE_IDS[$i]}"; value="${UI_STATE_FLAGS[$i]}"
    case "$id" in
      @shell) CONFIG_SHELL="$value";; @switch) SWITCH_SHELL="$value";;
      @git) CONFIG_GIT="$value";; @auth) AUTH_GIT="$value";;
      @docker) CONFIG_DOCKER="$value";; @fastfetch) CONFIG_FASTFETCH="$value";;
      @ghostty) CONFIG_GHOSTTY="$value";; @btop) CONFIG_BTOP="$value";;
      @dev) CREATE_DEV="$value";; @clean) MAX_CLEAN="$value";;
      *) (( value )) && SELECTED+=("$id");;
    esac
  done
  selection_dependencies
}
ui_summary_rows() {
  local id
  UI_SUMMARY=()
  if (( ${#SELECTED[@]} )); then
    for id in "${SELECTED[@]}"; do
      row "$id"
      if [[ "$OS" == linux ]]; then UI_SUMMARY+=("+ $LABEL · $(route)")
      else UI_SUMMARY+=("+ $LABEL"); fi
    done
    if [[ "$OS" == linux ]]; then
      if [[ "$PLATFORM_FAMILY" == arch ]]; then
        UI_SUMMARY+=("$(ui_text 'Paquetes: actualización completa de Arch; AUR requiere yay y base-devel.' 'Packages: full Arch upgrade; AUR requires yay and base-devel.')")
      else
        UI_SUMMARY+=("$(ui_text 'APT: actualizar índices; repo:* añade fuentes del fabricante.' 'APT: refresh metadata; repo:* adds vendor sources.')")
      fi
    fi
  else UI_SUMMARY+=("$(ui_text 'No hay programas nuevos seleccionados.' 'No new programs selected.')"); fi
  (( CONFIG_SHELL )) && UI_SUMMARY+=("$(ui_text '✓ Aplicar tu Zsh (con respaldo)' '✓ Apply your Zsh (with backup)')")
  (( SWITCH_SHELL )) && UI_SUMMARY+=("$(ui_text '✓ Comprobar la shell predeterminada' '✓ Check the default shell')")
  (( CONFIG_GIT )) && UI_SUMMARY+=("$(ui_text '✓ Configurar tu identidad de Git' '✓ Configure your Git identity')")
  (( AUTH_GIT )) && UI_SUMMARY+=("$(ui_text '✓ Conectar GitHub por HTTPS' '✓ Connect GitHub over HTTPS')")
  (( CONFIG_GHOSTTY )) && UI_SUMMARY+=('✓ Ghostty')
  (( CONFIG_DOCKER )) && UI_SUMMARY+=("$(ui_text '✓ Habilitar servicio Docker' '✓ Enable Docker service')")
  (( CONFIG_FASTFETCH )) && UI_SUMMARY+=('✓ Fastfetch portable')
  (( CONFIG_BTOP )) && UI_SUMMARY+=('✓ btop')
  (( CREATE_DEV )) && UI_SUMMARY+=("$(ui_text '✓ Crear carpetas' '✓ Create directories'): $DEV_ROOT")
  if (( MAX_CLEAN )); then UI_SUMMARY+=("$(ui_text '✓ Eliminar cachés de esta ejecución' '✓ Remove caches from this run')")
  else UI_SUMMARY+=("$(ui_text '✓ Conservar descargas de paquetes' '✓ Retain package downloads')"); fi
}
ui_render_summary() {
  local i end
  ui_header
  end=$((UI_OFFSET+UI_WINDOW)); ((end>${#UI_SUMMARY[@]})) && end=${#UI_SUMMARY[@]}
  for ((i=UI_OFFSET;i<end;i++)); do printf '  '; ui_clip "${UI_SUMMARY[$i]}" "$((UI_COLS-4))"; printf '\n'; done
  for ((i=end-UI_OFFSET;i<UI_WINDOW;i++)); do printf '\n'; done
  printf '\n  \033[2m%s\033[0m\n' "$(ui_text 'NVM sin Node · editores sin cambios · respaldos conservados' 'NVM without Node · editors unchanged · backups preserved')"
  if (( DRY_RUN )); then
    printf '  \033[35m%s\033[0m\n' "$(ui_text 'SIMULACIÓN · no se modificará ningún archivo' 'SIMULATION · no files will be changed')"
  else printf '  \033[33m%s\033[0m\n' "$(ui_text 'La instalación comienza únicamente al confirmar aquí.' 'Installation starts only when confirmed here.')"; fi
  printf '\n  \033[1;35m[ Enter · %s ]\033[0m  %s\n' "$(if ((DRY_RUN)); then ui_text 'Simular' 'Simulate'; else ui_text 'Instalar' 'Install'; fi)" "$(ui_text '← Volver · Q Cancelar' '← Back · Q Cancel')"
  printf '  \033[2m%s\033[0m' "$(ui_text '↑↓ desplazar resumen · D cambiar ruta Dev' '↑↓ scroll review · D change Dev path')"
}
ui_dev_path() {
  local entered=''
  stty "$UI_STTY"
  printf '\033[?25h\033[H\033[2J\n  %s\n\n  [%s]\n  > ' "$(ui_text 'Ruta absoluta para tus carpetas Dev; Enter conserva la actual.' 'Absolute path for Dev directories; Enter keeps the current path.')" "$DEV_ROOT"
  IFS= read -r entered || true
  if [[ -n "$entered" && "$entered" == /* ]]; then DEV_ROOT="$entered"; fi
  stty -echo -icanon min 1 time 0
  printf '\033[?25l'
}
keyboard_wizard() {
  ui_begin
  ui_load_page
  while :; do
    if (( UI_STEP == 8 )); then
      ui_apply_choices; ui_summary_rows; ui_render_summary; ui_key
      case "$UI_KEY" in
        enter) ui_end; return 0;;
        back) UI_STEP=7; ui_load_page;;
        up) ((UI_OFFSET>0)) && UI_OFFSET=$((UI_OFFSET-1));;
        down) ((UI_OFFSET+UI_WINDOW<${#UI_SUMMARY[@]})) && UI_OFFSET=$((UI_OFFSET+1));;
        quit) ui_end; msg 'Cancelado. No se modificó ningún archivo.' 'Cancelled. No files were changed.'; exit 0;;
      esac
      # ui_key exposes the raw character for the path shortcut.
      if [[ "${UI_CHAR:-}" == d || "${UI_CHAR:-}" == D ]]; then ui_dev_path; fi
    else
      ui_render_page; ui_key; UI_NOTICE=''
      case "$UI_KEY" in
        up) ((UI_CURSOR>0)) && UI_CURSOR=$((UI_CURSOR-1));;
        down) ((UI_CURSOR+1<${#UI_IDS[@]})) && UI_CURSOR=$((UI_CURSOR+1));;
        home) UI_CURSOR=0;; end) UI_CURSOR=$((${#UI_IDS[@]}-1));;
        toggle)
          if (( ${UI_LOCKED[$UI_CURSOR]} )); then UI_NOTICE="$(ui_text 'Este elemento se conserva; no se reinstalará.' 'This item is kept; it will not be reinstalled.')"
          else UI_FLAGS[$UI_CURSOR]=$((1-${UI_FLAGS[$UI_CURSOR]})); fi;;
        enter|next) ui_save; UI_STEP=$((UI_STEP+1)); UI_OFFSET=0; ((UI_STEP<8)) && ui_load_page;;
        back) ui_save; if ((UI_STEP>0)); then UI_STEP=$((UI_STEP-1)); ui_load_page; fi;;
        quit) ui_end; msg 'Cancelado. No se modificó ningún archivo.' 'Cancelled. No files were changed.'; exit 0;;
      esac
    fi
  done
}
