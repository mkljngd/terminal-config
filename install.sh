#!/usr/bin/env bash
# Copy this terminal setup into place (zsh + starship + WezTerm).
# Backs up whatever is live now as *.pre-dotfiles-<timestamp> first.
# On a fresh machine run setup.sh instead; it installs packages, then calls this.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
ts="$(date +%Y%m%d-%H%M%S)"

# Windows home (for .wezterm.lua and fonts), e.g. /mnt/c/Users/<you>.
win_profile="$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')"
win_home="$(wslpath "$win_profile")"
[[ -d "$win_home" ]] || { echo "Windows home not found ($win_profile)" >&2; exit 1; }

backup() { [[ -e "$1" ]] && cp -a "$1" "$1.pre-dotfiles-$ts"; return 0; }

backup "$HOME/.zshenv"
backup "$HOME/.zshrc"
backup "$HOME/.config/zsh"
backup "$HOME/.config/starship.toml"
backup "$HOME/.ipython/profile_default/ipython_config.py"
backup "$win_home/.wezterm.lua"
backup "$win_home/.wezterm-local.lua"

# zsh + starship + IPython (WSL side). local.zsh is copied only if you have one.
mkdir -p "$HOME/.config/zsh" "$HOME/.cache/zsh" "$HOME/.local/state/zsh" "$HOME/.ipython/profile_default"
cp "$here/home/.zshenv" "$HOME/.zshenv"
cp "$here/home/.zshrc" "$HOME/.zshrc"
cp -a "$here/home/.config/zsh/." "$HOME/.config/zsh/"
cp "$here/home/.config/starship.toml" "$HOME/.config/starship.toml"
cp "$here/home/.ipython/profile_default/ipython_config.py" "$HOME/.ipython/profile_default/"

# WezTerm (Windows side): config, optional local workflows, fonts.
cp "$here/windows/.wezterm.lua" "$win_home/.wezterm.lua"
[[ -f "$here/windows/.wezterm-local.lua" ]] && cp "$here/windows/.wezterm-local.lua" "$win_home/.wezterm-local.lua"
fonts="$win_home/.wezterm-fonts"
mkdir -p "$fonts"
# WezTerm locks fonts it has loaded; skip ones that are already identical.
for font in "$here/windows/.wezterm-fonts/"*.ttf; do
  dest="$fonts/${font##*/}"
  cmp -s "$font" "$dest" || cp "$font" "$dest" \
    || echo "Could not replace ${font##*/} (in use?); close WezTerm and rerun." >&2
done

# FiraCode Nerd Font: downloaded (not stored in git) unless already present.
if ! compgen -G "$fonts/FiraCodeNerdFont-*.ttf" >/dev/null \
   && ! compgen -G "$win_home/AppData/Local/Microsoft/Windows/Fonts/FiraCodeNerdFont-*.ttf" >/dev/null; then
  echo "Downloading FiraCode Nerd Font..."
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/FiraCode.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
  unzip -q -o "$tmp/FiraCode.zip" 'FiraCodeNerdFont-*.ttf' -d "$fonts"
  rm -rf "$tmp"
fi

[[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/fzf-tab" ]] || echo "Plugins missing: run extras/clone-zsh-plugins.sh"
command -v starship >/dev/null || [[ -x "$HOME/.local/bin/starship" ]] || echo "starship missing: run setup.sh"
echo "Installed. Open a new WezTerm tab (or run: exec zsh)."
