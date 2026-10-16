# Interactive zsh config. /etc/zsh/zshenv sets ZDOTDIR=~/.config/zsh, so this
# file (not ~/.zshrc) is what zsh loads. Env vars live in .zshenv.

# =========================================================
# PATH
# =========================================================

[[ -s "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# =========================================================
# Completion init
# =========================================================

for _zdir in \
  "$HOME/.docker/completions" \
  /usr/share/zsh/vendor-completions \
  /usr/local/share/zsh/site-functions; do
  [[ -d "$_zdir" ]] && fpath=("$_zdir" $fpath)
done
unset _zdir

# Dump goes to the cache, not ZDOTDIR. completion.zsh skips its own compinit.
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# =========================================================
# History
# =========================================================

source "$ZDOTDIR/history.zsh"
HISTFILE="$XDG_STATE_HOME/zsh/history"  # keep the existing XDG history file
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# =========================================================
# Shell behavior
# =========================================================

setopt NOBEEP
setopt NUMERIC_GLOB_SORT

# =========================================================
# Completion, selection, plugins
# =========================================================

source "$ZDOTDIR/completion.zsh"
source "$ZDOTDIR/keyboard-select.zsh"
source "$ZDOTDIR/mouse.zsh"            # click / drag / double-click on the command line (WezTerm)
source "$ZDOTDIR/plugins.zsh"          # fzf, fzf-tab, autosuggestions, zoxide, atuin, highlighting

# Without fzf-tab, fall back to zsh's own arrow-key menu.
(( $+widgets[fzf-tab-complete] )) || zstyle ':completion:*' menu select

# fzf: fd for file search and bat previews (overrides plugins.zsh's FZF_DEFAULT_OPTS)
source "$ZDOTDIR/fzf.zsh"

# =========================================================
# Dev tooling
# =========================================================

# nvm — lazy-loaded so it doesn't slow every shell start.
# First call to nvm/node/npm/npx sources nvm.sh, then runs the real command.
_load_nvm() {
  unset -f nvm node npm npx git 2>/dev/null
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}
nvm()  { _load_nvm; nvm "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm "$@"; }
npx()  { _load_nvm; npx "$@"; }

# git hooks (husky etc.) run under `sh`, not this zsh — they never see the
# lazy-load functions above, so if nvm hasn't been loaded yet this session,
# a hook's `npx` falls through to WSL's appendWindowsPath interop and picks
# up Windows' node.exe/npx.cmd instead of nvm's, which then breaks entirely
# (cmd.exe can't cd into a \\wsl.localhost UNC path). Load nvm before any
# git command runs so $PATH is already fixed by the time a hook spawns.
# _load_nvm removes this wrapper, so only the first git call pays for it.
git() { _load_nvm; command git "$@"; }

# =========================================================
# Personal
# =========================================================

source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/functions.zsh"
source "$ZDOTDIR/bindings.zsh"

# Machine-specific aliases/functions (hosts, clusters, company tooling).
# Not in git; see local.zsh.example.
[[ -r "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

# =========================================================
# Terminal and prompt
# =========================================================

source "$ZDOTDIR/wezterm.zsh"          # OSC 7 so new WezTerm tabs keep the cwd
source "$ZDOTDIR/prompt.zsh"           # starship, when installed
source "$ZDOTDIR/prompt-bottom.zsh"    # prompt starts on the last row

# bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
