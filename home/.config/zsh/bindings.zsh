# =========================================================
# Keybindings
# =========================================================
# No vi-mode plugin anymore, so bind directly (no zvm_after_init hook needed).

# Ctrl+Right -> move forward one word (^[[1;5C is the terminal escape code)
bindkey '^[[1;5C' forward-word

# Ctrl+Left -> move backward one word (^[[1;5D is the terminal escape code)
bindkey '^[[1;5D' backward-word

# fzf file picker on Alt+T; WezTerm uses Ctrl+T for new tab.
bindkey -r '^T'
bindkey '^[t' fzf-file-widget

# Alt+Enter / Shift+Enter (WezTerm sends ESC+CR): insert a newline instead of running.
bindkey -M emacs '^[^M' self-insert-unmeta
bindkey -M viins '^[^M' self-insert-unmeta

# Edit the current command line in $EDITOR (nvim): save and quit puts the text
# back on the prompt (it doesn't run until you press Enter).
#   Ctrl+X Ctrl+E   while typing (bash's shortcut)
#   v               in vi command mode (after Esc), like bash vi-mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M viins '^X^E' edit-command-line
bindkey -M vicmd 'v' edit-command-line
