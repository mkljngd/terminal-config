# Minimal WezTerm shell integration needed for WSL cwd tracking.
# This lets new tabs/splits inherit the current Linux directory.

# Tab/window title = current folder (~ at home), instead of wslhost.exe.
_title_cwd() { print -Pn '\e]2;%1~\a' }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _title_cwd

if [[ "$TERM_PROGRAM" == WezTerm || -n "$WEZTERM_PANE" ]]; then
  _wezterm_osc7() {
    local host="${HOST:-localhost}"
    local path="${PWD// /%20}"
    printf '\e]7;file://%s%s\e\\' "$host" "$path"
  }

  # User var ZSH_AT_PROMPT ("1"/"0", base64-encoded) tells WezTerm whether
  # zsh is editing a command, so Ctrl+C/Ctrl+A only become copy/select-all
  # at the prompt and still interrupt running programs.
  _wezterm_at_prompt() { printf '\e]1337;SetUserVar=ZSH_AT_PROMPT=MQ==\a' }
  _wezterm_running()   { printf '\e]1337;SetUserVar=ZSH_AT_PROMPT=MA==\a' }

  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _wezterm_osc7
  add-zsh-hook chpwd _wezterm_osc7
  add-zsh-hook precmd _wezterm_at_prompt
  add-zsh-hook preexec _wezterm_running
fi
