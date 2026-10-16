#!/usr/bin/env bash
# Fresh-machine setup for Windows + WSL (Ubuntu): installs the CLI tools the
# config uses, starship, zsh plugins, WezTerm (via winget), makes zsh the
# login shell, then runs install.sh. Safe to rerun.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

echo "==> apt packages"
sudo apt-get update
sudo apt-get install -y \
  zsh git curl unzip tzdata \
  fzf fd-find ripgrep bat eza zoxide neovim \
  gh openvpn

echo "==> starship"
if ! command -v starship >/dev/null && [[ ! -x "$HOME/.local/bin/starship" ]]; then
  mkdir -p "$HOME/.local/bin"
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

echo "==> zsh plugins (fzf-tab, autosuggestions, fast-syntax-highlighting)"
bash "$here/extras/clone-zsh-plugins.sh"

echo "==> WezTerm (Windows)"
if [[ ! -x "/mnt/c/Program Files/WezTerm/wezterm.exe" ]]; then
  if command -v winget.exe >/dev/null; then
    winget.exe install --id wez.wezterm -e --accept-source-agreements --accept-package-agreements
  else
    echo "winget not found: install WezTerm from https://wezterm.org/install/windows.html"
  fi
fi

echo "==> login shell"
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)"
fi

echo "==> config files"
bash "$here/install.sh"

cat <<'EOF'

Optional, used by some aliases/functions but not installed here:
  nvm (node), uv, google-cloud-cli (gcloud/kubectl), docker, lf, atuin
Machine-specific aliases/workflows: copy home/.config/zsh/local.zsh.example to local.zsh.
EOF
