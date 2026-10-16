# ─────────────────────────────────────────────────────────────
#  Tab completion: fuzzy popup (fzf-tab), case-insensitive
#
#  Tab       open popup, type to filter, Enter to pick
#  < / >     switch group (e.g. commands vs files)
#  cd + Tab  preview shows folder contents
# ─────────────────────────────────────────────────────────────

# Docker Desktop's block in ~/.zshrc usually runs compinit already.
autoload -Uz compinit
(( $+functions[compdef] )) || compinit -i

zstyle ':completion:*' menu no                            # fzf-tab shows the menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'    # "doc" matches "Documents"
zstyle ':completion:*' list-colors ''                     # colour files by type
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'         # plain text: fzf-tab needs it for groups
zstyle ':completion:*:git-checkout:*' sort false          # keep git's own order

setopt AUTO_CD   # type a folder name on its own to cd into it

# ── fzf-tab popup ────────────────────────────────────────────
zstyle ':fzf-tab:*' fzf-flags '--height=50%' '--layout=reverse' '--border=rounded' '--info=inline'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath 2>/dev/null'
