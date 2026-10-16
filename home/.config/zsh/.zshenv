# ---------- Completion ----------
# Debian's /etc/zsh/zshrc runs a plain `compinit` before ~/.zshrc, writing
# stray dumps into ZDOTDIR. Skip it; ~/.zshrc runs compinit -d into the cache.
skip_global_compinit=1

# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- GPG ----------
export GPG_TTY=$(tty)

# ---------- PATH ----------
# Personal binaries/scripts
export PATH="$HOME/.local/bin:$PATH"

# ---------- Node ----------
export NODE_OPTIONS="--max-old-space-size=8192"
export NVM_DIR="$HOME/.nvm"  # used by the lazy nvm loader in .zshrc

# ---------- Java ----------
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export PATH="$JAVA_HOME/bin:$PATH"


# ---------- Timezone ----------
# WSL defaults to UTC; match Windows (India Standard Time).
export TZ="Asia/Kolkata"
