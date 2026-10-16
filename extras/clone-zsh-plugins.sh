#!/usr/bin/env bash
set -euo pipefail

plugin_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
mkdir -p "$plugin_dir"

clone_or_update() {
  repo="$1"
  dest="$2"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only
  else
    git clone --depth 1 "$repo" "$dest"
  fi
}

clone_or_update https://github.com/Aloxaf/fzf-tab "$plugin_dir/fzf-tab"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/zsh-autosuggestions"
clone_or_update https://github.com/zdharma-continuum/fast-syntax-highlighting "$plugin_dir/fast-syntax-highlighting"

echo "Zsh plugins are ready in $plugin_dir"
