# zsh loads $ZDOTDIR/.zshrc (~/.config/zsh/.zshrc, set in /etc/zsh/zshenv).
# This shim only runs if ZDOTDIR is unset.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
[[ -r "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
source "$ZDOTDIR/.zshrc"
