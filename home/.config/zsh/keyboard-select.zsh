# Warp-style keyboard selection for the zsh command line.
# Works with Ghostty on macOS and WezTerm -> WSL on Windows.

zle_highlight=(region:bg=blue,fg=white)

_ks-select() {
  (( REGION_ACTIVE )) || zle set-mark-command
  zle .${WIDGET#ks-select-}
}

_ks-deselect() {
  # With a selection, Left/Right just collapse it to its start/end (as in
  # editors); any other movement clears it and then moves.
  if (( REGION_ACTIVE )) && [[ $WIDGET == (backward|forward)-char ]]; then
    local -i start=$(( MARK < CURSOR ? MARK : CURSOR )) end=$(( MARK < CURSOR ? CURSOR : MARK ))
    REGION_ACTIVE=0
    [[ $WIDGET == backward-char ]] && CURSOR=$start || CURSOR=$end
    return
  fi
  REGION_ACTIVE=0
  zle .$WIDGET
}

_ks-delete-region() {
  local start=$(( MARK < CURSOR ? MARK : CURSOR ))
  local end=$(( MARK < CURSOR ? CURSOR : MARK ))
  BUFFER=${BUFFER[1,start]}${BUFFER[end+1,-1]}
  CURSOR=$start
  REGION_ACTIVE=0
}

_ks-system-clipboard() {
  if (( $+commands[pbcopy] )); then
    pbcopy
  elif (( $+commands[clip.exe] )); then
    clip.exe
  elif (( $+commands[wl-copy] )); then
    wl-copy
  elif (( $+commands[xclip] )); then
    xclip -selection clipboard
  else
    return 1
  fi
}

_ks-copy() {
  (( REGION_ACTIVE )) || return 0
  local start=$(( MARK < CURSOR ? MARK : CURSOR ))
  local end=$(( MARK < CURSOR ? CURSOR : MARK ))
  print -rn -- "${BUFFER[start+1,end]}" | _ks-system-clipboard
}

_ks-cut() {
  (( REGION_ACTIVE )) || return 0
  _ks-copy
  _ks-delete-region
}

_ks-select-all() {
  MARK=0
  CURSOR=$#BUFFER
  REGION_ACTIVE=1
}

# Ctrl+C at the prompt: copy the selection, or abort the line like a plain ^C.
_ks-copy-or-break() {
  if (( REGION_ACTIVE )); then
    _ks-copy
  else
    zle send-break
  fi
}

# Esc: drop an active selection; otherwise enter vi command mode as usual.
_ks-escape() {
  if (( REGION_ACTIVE )); then
    REGION_ACTIVE=0
  else
    zle vi-cmd-mode
  fi
}

# Undo by word: remember the change number where each word starts, so
# Ctrl+Z removes the last word typed rather than a single character.
typeset -ga _ks_undo_marks _ks_redo_targets

_ks-replace() {
  (( REGION_ACTIVE )) && _ks-delete-region
  if [[ $WIDGET == self-insert && $KEYS != ' ' && ( -z $LBUFFER || $LBUFFER[-1] == ' ' ) ]]; then
    _ks_undo_marks+=($UNDO_CHANGE_NO)
  fi
  zle .$WIDGET
}

_ks-undo() {
  REGION_ACTIVE=0
  while (( ${#_ks_undo_marks} )) && (( _ks_undo_marks[-1] >= UNDO_CHANGE_NO )); do
    _ks_undo_marks[-1]=()
  done
  _ks_redo_targets+=("$BUFFER")
  if (( ${#_ks_undo_marks} )); then
    zle undo $_ks_undo_marks[-1]
    _ks_undo_marks[-1]=()
  else
    zle undo
  fi
}

# Redo replays single steps until the line is back to what the matching undo
# took away (a whole word).
_ks-redo() {
  (( ${#_ks_redo_targets} )) || { zle redo; return }
  local target=$_ks_redo_targets[-1]
  local -i guard=0
  _ks_redo_targets[-1]=()
  while [[ $BUFFER != "$target" ]] && (( guard++ < 500 )); do
    zle redo || break
  done
}

_ks-reset-undo() { _ks_undo_marks=() _ks_redo_targets=() }
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init _ks-reset-undo

_ks-delete() {
  if (( REGION_ACTIVE )); then
    _ks-delete-region
  else
    zle .$WIDGET
  fi
}

for w in backward-char forward-char backward-word forward-word \
         beginning-of-line end-of-line; do
  zle -N ks-select-$w _ks-select
done
for w in backward-char forward-char backward-word forward-word \
         beginning-of-line end-of-line \
         up-line-or-history down-line-or-history \
         up-line-or-search down-line-or-search; do
  zle -N $w _ks-deselect
done
zle -N self-insert          _ks-replace
zle -N bracketed-paste      _ks-replace
zle -N backward-delete-char _ks-delete
zle -N delete-char          _ks-delete
# The vi keymap binds Backspace to the vi-* variants, so wrap those too.
zle -N vi-backward-delete-char _ks-delete
zle -N vi-delete-char          _ks-delete
zle -N ks-copy              _ks-copy
zle -N ks-cut               _ks-cut
zle -N ks-select-all        _ks-select-all
zle -N ks-copy-or-break     _ks-copy-or-break
zle -N ks-escape            _ks-escape
zle -N ks-undo              _ks-undo
zle -N ks-redo              _ks-redo
unset w

bindkey '^[[1;2D' ks-select-backward-char
bindkey '^[[1;2C' ks-select-forward-char
bindkey '^[[1;4D' ks-select-backward-word
bindkey '^[[1;4C' ks-select-forward-word
bindkey '^[[1;2H' ks-select-beginning-of-line
bindkey '^[[1;2F' ks-select-end-of-line
bindkey '^[[3~'   delete-char
bindkey '^[[120;9u' ks-cut
bindkey '^[[99;10u' ks-copy
# WezTerm sends these for Ctrl+A / Ctrl+C only while zsh is at the prompt.
bindkey '^[[97;5u' ks-select-all
bindkey '^[[99;5u' ks-copy-or-break
# WezTerm sends these for Ctrl+Z / Ctrl+Y only at the prompt (running programs
# still get a real ^Z to suspend).
bindkey '^[[122;5u' ks-undo
bindkey '^[[121;5u' ks-redo
bindkey '^[[3;5~'   kill-word             # Ctrl+Delete: delete the next word
bindkey -M viins '^[' ks-escape

# Arrows use the plain widgets (wrapped above to clear a selection). Unlike the
# vi-* ones they cross lines of a multi-line command: Left at a line's start
# goes to the end of the previous line, Right at a line's end to the next.
for k in '^[[D' '^[OD'; do bindkey "$k" backward-char; done
for k in '^[[C' '^[OC'; do bindkey "$k" forward-char; done

# Home / End (the vi keymap leaves them unbound). All terminal variants.
for k in '^[[H' '^[OH' '^[[1~'; do bindkey "$k" beginning-of-line; done
for k in '^[[F' '^[OF' '^[[4~'; do bindkey "$k" end-of-line; done
unset k
