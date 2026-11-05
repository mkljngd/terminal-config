# Mouse editing on the command line (WezTerm), like a text editor:
#   click          place the cursor
#   drag           select (Backspace / Delete / typing / Ctrl+C then act on it)
#   double-click   select a word          triple-click   select the line
# A finished mouse selection is copied to the clipboard, like WezTerm does.
#
# While zsh waits for input it turns on terminal mouse reporting, so clicks on
# the command line come here. A press anywhere ABOVE the command line (earlier
# output, the prompt line) is handed straight back to WezTerm: zsh stops
# reporting and sets the user var ZSH_MOUSE_HANDOFF (Cell / Word / Line), and
# .wezterm.lua starts a normal selection there; releasing the button makes
# WezTerm send ESC[1999~, which gives the mouse back to zsh. Reporting is also
# off while commands run. Right-click and Ctrl+click stay with WezTerm.
#
# Wheel up hands the mouse over too (ZSH_MOUSE_HANDOFF=WheelUp): WezTerm
# jumps to the bottom on every mouse event while zsh reports the mouse, so it
# can only scroll back once zsh lets go. A key press or click takes it back.
#
# Off: `export ZLE_MOUSE=0` in .zshenv.

[[ "${ZLE_MOUSE:-1}" == 1 && ( "$TERM_PROGRAM" == WezTerm || -n "$WEZTERM_PANE" ) ]] || return 0
# Only real interactive editing: not `zsh -c`, scripts, or shells without a tty.
[[ -o interactive && -o zle && -z "$ZSH_EXECUTION_STRING" && -t 0 && -t 1 ]] || return 0

zmodload zsh/datetime                          # EPOCHREALTIME for multi-clicks

typeset -gi _km_c0=4          # screen column of the buffer's first char (refined per click)
typeset -gi _km_top=0         # screen row of the buffer's first line (set on each press)
typeset -gi _km_dragging=0 _km_clicks=0 _km_last_index=-1
typeset -gF _km_last_time=0
typeset -gi _km_handed_off=0 _km_out_clicks=0 _km_out_x=0 _km_out_y=0
typeset -gF _km_out_time=0
typeset -ga _km_row _km_col

_km_on()  { print -n '\e[?1000h\e[?1002h\e[?1006h' >/dev/tty }
_km_off() { print -n '\e[?1006l\e[?1002l\e[?1000l' >/dev/tty }

# Ask the terminal where the cursor is (CPR). Sets reply=(row col). Anything
# that arrives before the answer (keys, queued mouse events) is pushed back
# onto zle's input so it still gets handled, in order.
_km_cursor_pos() {
  emulate -L zsh -o extendedglob
  local c buf=''
  print -n '\e[6n' >/dev/tty
  while read -s -k 1 -t 0.5 c; do
    buf+=$c
    if [[ $buf == (#b)(*)$'\e['(<->)';'(<->)R ]]; then
      [[ -n $match[1] ]] && zle -U -- "$match[1]"
      reply=($match[2] $match[3])
      return 0
    fi
  done
  [[ -n $buf ]] && zle -U -- "$buf"
  return 1
}

# Screen layout of $BUFFER with its first char at column $_km_c0:
# _km_row[i] / _km_col[i] for cursor position i-1 (0..#BUFFER), rows counted
# from the buffer's first line. Lines after an embedded newline start at col 1.
_km_layout() {
  emulate -L zsh
  local -i row=0 col=_km_c0 i w
  local ch
  _km_row=() _km_col=()
  for (( i = 1; i <= ${#BUFFER}; i++ )); do
    ch=$BUFFER[i]
    if [[ $ch == $'\n' ]]; then
      _km_row+=($row) _km_col+=($col)
      (( row++ )); col=1
      continue
    fi
    w=${(m)#ch}
    (( w < 1 )) && w=1
    if (( col + w - 1 > COLUMNS )); then (( row++ )); col=1; fi
    _km_row+=($row) _km_col+=($col)
    (( col += w ))
  done
  if (( col > COLUMNS )); then (( row++ )); col=1; fi
  _km_row+=($row) _km_col+=($col)
}

# Pin the buffer to the screen: ask where the cursor is, fix the start column
# when the cursor is on the first line, and work back to the first row.
_km_anchor() {
  emulate -L zsh
  _km_cursor_pos || return 1
  local -i crow=$reply[1] ccol=$reply[2]
  if [[ $LBUFFER != *$'\n'* ]]; then
    local -i w=${(m)#LBUFFER}
    (( _km_c0 = (ccol - 1 - w) % COLUMNS ))
    (( _km_c0 < 0 )) && (( _km_c0 += COLUMNS ))
    (( _km_c0 += 1 ))
  fi
  _km_layout
  _km_top=$(( crow - _km_row[CURSOR + 1] ))
}

# Cursor position under screen cell (x, y) in REPLY; -1 above the command line.
_km_index_at() {
  emulate -L zsh
  local -i x=$1 y=$(( $2 - _km_top )) i n=${#_km_row}
  REPLY=-1
  (( y < 0 )) && return
  if (( y > _km_row[n] )); then REPLY=$(( n - 1 )); return; fi
  for (( i = 1; i <= n; i++ )); do
    if (( _km_row[i] != y )); then
      (( _km_row[i] > y )) && break
      continue
    fi
    (( REPLY < 0 || _km_col[i] <= x )) && REPLY=$(( i - 1 ))
    (( _km_col[i] > x )) && break
  done
}

# Give a press above the command line to WezTerm (see top of file).
# $1: Cell, Word or Line, i.e. how WezTerm should start its selection.
_km_handoff() {
  local b64
  case $1 in
    Word) b64=V29yZA== ;;
    Line) b64=TGluZQ== ;;
    WheelUp) b64=V2hlZWxVcA== ;;
    *)    b64=Q2VsbA== ;;
  esac
  _km_handed_off=1
  _km_off
  print -n "\e]1337;SetUserVar=ZSH_MOUSE_HANDOFF=${b64}\a" >/dev/tty
}

# WezTerm finished its selection (it sends ESC[1999~): take the mouse back.
_km-handback() {
  _km_handed_off=0
  print -n '\e]1337;SetUserVar=ZSH_MOUSE_HANDOFF=MA==\a' >/dev/tty   # "0"
  _km_on
}

# Select the word around cursor position $1 (paths and flags count as words).
_km_select_word() {
  emulate -L zsh
  local stop=$' \t\n"\'`()[]{}<>|;&,='
  local -i s=$1 e=$1
  while (( s > 0 )) && [[ $stop != *"${BUFFER[s]}"* ]]; do (( s-- )); done
  while (( e < ${#BUFFER} )) && [[ $stop != *"${BUFFER[e+1]}"* ]]; do (( e++ )); done
  MARK=$s CURSOR=$e
  REGION_ACTIVE=$(( e > s ))
}

# Select the whole line (of a multi-line command) around cursor position $1.
_km_select_line() {
  emulate -L zsh
  local -i s=$1 e=$1
  while (( s > 0 )) && [[ ${BUFFER[s]} != $'\n' ]]; do (( s-- )); done
  while (( e < ${#BUFFER} )) && [[ ${BUFFER[e+1]} != $'\n' ]]; do (( e++ )); done
  MARK=$s CURSOR=$e
  REGION_ACTIVE=$(( e > s ))
}

_km_copy_region() {
  local -i s=$(( MARK < CURSOR ? MARK : CURSOR )) e=$(( MARK < CURSOR ? CURSOR : MARK ))
  local text=${BUFFER[s+1,e]}
  ( print -rn -- "$text" | _ks-system-clipboard ) &!
}

# Bound to the start of an SGR mouse report (ESC [ <); reads "b;x;yM" / "...m".
_km-mouse() {
  emulate -L zsh -o extendedglob
  local c seq=''
  while read -s -k 1 -t 0.2 c; do
    seq+=$c
    [[ $c == [Mm] ]] && break
  done
  [[ $seq == (#b)(<->)';'(<->)';'(<->)([Mm]) ]] || return 0
  local -i b=$match[1] x=$match[2] y=$match[3]
  local kind=$match[4]
  (( b == 64 )) && { _km_handoff WheelUp; return 0 }   # scroll back: WezTerm's
  (( b & (64 | 8 | 16) )) && return 0           # wheel / Alt / Ctrl: not ours
  (( (b & 3) == 0 )) || return 0                # left button only

  if (( b & 32 )); then                         # drag
    (( _km_dragging )) || return 0
    _km_layout
    _km_index_at $x $y
    (( REPLY < 0 )) && REPLY=0
    CURSOR=$REPLY
    REGION_ACTIVE=$(( CURSOR != MARK ))
  elif [[ $kind == m ]]; then                   # release
    _km_dragging=0
    (( REGION_ACTIVE )) && _km_copy_region
  else                                          # press
    _km_anchor || return 0
    _km_index_at $x $y
    local -F now=$EPOCHREALTIME
    if (( REPLY < 0 )); then                    # above the command line: WezTerm's
      if (( x == _km_out_x && y == _km_out_y && now - _km_out_time < 0.4 )); then
        (( _km_out_clicks = _km_out_clicks % 3 + 1 ))
      else
        _km_out_clicks=1
      fi
      _km_out_x=$x _km_out_y=$y _km_out_time=$now
      local -a kinds=(Cell Word Line)
      _km_handoff $kinds[_km_out_clicks]
      return 0
    fi
    if (( REPLY == _km_last_index && now - _km_last_time < 0.4 )); then
      (( _km_clicks = _km_clicks % 3 + 1 ))
    else
      _km_clicks=1
    fi
    _km_last_index=$REPLY _km_last_time=$now
    case $_km_clicks in
      1) CURSOR=$REPLY MARK=$REPLY REGION_ACTIVE=0 _km_dragging=1 ;;
      2) _km_select_word $REPLY; _km_dragging=0 ;;
      3) _km_select_line $REPLY; _km_dragging=0 ;;
    esac
  fi
}
zle -N ks-mouse _km-mouse
zle -N ks-mouse-handback _km-handback
for km in viins vicmd emacs; do
  bindkey -M $km '^[[<' ks-mouse
  bindkey -M $km '^[[1999~' ks-mouse-handback
done
unset km

# Mouse reporting only while editing. pre-redraw re-enables it after tools
# like fzf-tab, which switch it off when they exit, but not while WezTerm owns
# the mouse after a handoff (any key you press ends that, as a fallback).
_km-enable() {
  if (( _km_handed_off )); then
    [[ $LASTWIDGET == ks-mouse* ]] && return
    _km_handed_off=0
  fi
  _km_on
}
_km-init()    { _km_handed_off=0; _km_on }
_km-disable() { _km_dragging=0; _km_off }
autoload -Uz add-zle-hook-widget add-zsh-hook
add-zle-hook-widget line-init       _km-init
add-zle-hook-widget line-pre-redraw _km-enable
add-zle-hook-widget line-finish     _km-disable
add-zsh-hook preexec _km_off
add-zsh-hook zshexit _km_off
