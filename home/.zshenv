# Point zsh at ~/.config/zsh (XDG layout), then load its .zshenv.
# On machines where /etc/zsh/zshenv already sets ZDOTDIR this file is never read.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
[[ -r "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
