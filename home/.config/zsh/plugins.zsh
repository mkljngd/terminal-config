# Cross-platform plugin loader: Homebrew on macOS, local clones/packages on WSL.

export FZF_DEFAULT_OPTS='--height=50% --layout=reverse --border=rounded --info=inline --prompt="❯ " --pointer="▌"'

_ZSH_PLUGIN_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

_source_first() {
  local f
  for f in "$@"; do
    if [[ -n "$f" && -r "$f" ]]; then
      source "$f"
      return 0
    fi
  done
  return 1
}

# Homebrew prefix only when Homebrew exists.
_HOMEBREW_PREFIX=''
if (( $+commands[brew] )); then
  _HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null)"
elif [[ -d /opt/homebrew ]]; then
  _HOMEBREW_PREFIX=/opt/homebrew
fi

# fzf key bindings/completion.
if (( $+commands[fzf] )); then
  if fzf --help 2>&1 | grep -q -- '--zsh'; then
    source <(fzf --zsh)
  else
    _source_first \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      /usr/share/fzf/key-bindings.zsh
    _source_first \
      /usr/share/doc/fzf/examples/completion.zsh \
      /usr/share/fzf/completion.zsh
  fi
fi

# fzf-tab.
_source_first \
  "$_ZSH_PLUGIN_HOME/fzf-tab/fzf-tab.plugin.zsh" \
  "$_ZSH_PLUGIN_HOME/fzf-tab/fzf-tab.zsh" \
  "${_HOMEBREW_PREFIX:+$_HOMEBREW_PREFIX/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh}"

# Autosuggestions.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=100
_source_first \
  "$_ZSH_PLUGIN_HOME/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  "${_HOMEBREW_PREFIX:+$_HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh}"

if (( $+widgets[autosuggest-accept] )); then
  bindkey '^ ' autosuggest-accept
  bindkey '^@' autosuggest-accept
fi
bindkey '^f' forward-word
bindkey '^[f' forward-word

# zoxide.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# Atuin owns Ctrl+R; arrow history stays with zsh.
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# Syntax highlighting must load last.
_source_first \
  "$_ZSH_PLUGIN_HOME/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
  /usr/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh \
  "${_HOMEBREW_PREFIX:+$_HOMEBREW_PREFIX/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh}"

unfunction _source_first
unset _ZSH_PLUGIN_HOME _HOMEBREW_PREFIX
