# ─────────────────────────────────────────────────────────────
#  History: large, shared across tabs, no duplicates
#
#  ↑ / ↓     step through past commands that start with what you typed
#  Ctrl+R    Atuin history search (see plugins.zsh)
# ─────────────────────────────────────────────────────────────

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY       # save when each command ran
setopt SHARE_HISTORY          # new commands show up in every tab
setopt HIST_IGNORE_ALL_DUPS   # keep only the newest copy of a command
setopt HIST_IGNORE_SPACE      # start a command with a space to keep it out
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # show !! expansions before running them

# Prefix search on ↑ / ↓. The wrappers also clear any keyboard selection.
# Their names must end in "-line-or-beginning-search" so repeated presses
# keep searching with the same prefix.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
ks-up-line-or-beginning-search()   { REGION_ACTIVE=0; zle up-line-or-beginning-search }
ks-down-line-or-beginning-search() { REGION_ACTIVE=0; zle down-line-or-beginning-search }
zle -N ks-up-line-or-beginning-search
zle -N ks-down-line-or-beginning-search
bindkey '^[[A' ks-up-line-or-beginning-search
bindkey '^[OA' ks-up-line-or-beginning-search
bindkey '^[[B' ks-down-line-or-beginning-search
bindkey '^[OB' ks-down-line-or-beginning-search
