export STARSHIP_CONFIG="$HOME/.config/starship.toml"
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# Narrow panes (e.g. WezTerm splits) drop the right-aligned part of the prompt
# (duration, RAM, time). The narrow config is generated from starship.toml by
# deleting the format lines from `$fill` up to `$line_break`, and is rebuilt
# whenever starship.toml is newer. Set STARSHIP_NARROW_COLUMNS to tune.
: ${STARSHIP_NARROW_COLUMNS:=100}
_starship_wide_config="$STARSHIP_CONFIG"
_starship_narrow_config="${XDG_CACHE_HOME:-$HOME/.cache}/starship/narrow.toml"

_starship_build_narrow() {
  [[ "$_starship_narrow_config" -nt "$_starship_wide_config" ]] && return
  mkdir -p "${_starship_narrow_config:h}"
  sed '/^\$fill\\$/,/^\$line_break/{/^\$line_break/!d}' \
    "$_starship_wide_config" > "$_starship_narrow_config"
}

_starship_pick_config() {
  if (( COLUMNS < STARSHIP_NARROW_COLUMNS )); then
    _starship_build_narrow
    export STARSHIP_CONFIG="$_starship_narrow_config"
  else
    export STARSHIP_CONFIG="$_starship_wide_config"
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _starship_pick_config
TRAPWINCH() { _starship_pick_config }   # re-pick when a pane is resized or split
