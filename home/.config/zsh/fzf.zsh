# =========================================================
# fzf
# =========================================================

export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --strip-cwd-prefix'  # fdfind: Debian binary name for fd; aliases don't apply in fzf's sh -c. strip-cwd-prefix removes the leading ./ from results

# Ctrl-T uses fd
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# UI
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

export _FZF_PREVIEW_CMD='batcat --color=always --style=plain,numbers --line-range=:500 {}'  # batcat: Debian binary name for bat
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"
