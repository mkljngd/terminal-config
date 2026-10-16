# ─────────────────────────────────────────────────────────────
#  Prompt at the bottom of the window (like Warp)
#
#  New tabs and cleared screens put the prompt on the last line, so
#  output grows upward from where you type. Once output fills the
#  window, every terminal already works this way.
#
#  Ctrl+L, the clear command and Ghostty's ⌘K all keep the prompt at the bottom
#  (at a prompt, ⌘K clears the window, then sends Ctrl+L to zsh).
#  Turn off: remove the prompt-bottom line in ~/.zshrc.
# ─────────────────────────────────────────────────────────────

# Move the cursor to the last row. The prompt then draws from there.
_prompt_bottom() { print -n "\e[${LINES};1H" }

# First prompt of a new tab or window
[[ -t 1 ]] && _prompt_bottom

# Ctrl+L / ⌘K: clear the visible screen, then redraw the prompt at the bottom
_prompt_bottom_clear() {
  print -n "\e[H\e[2J"
  _prompt_bottom
  zle .reset-prompt
}
zle -N clear-screen _prompt_bottom_clear

# `clear` command: clear as usual, then start the next prompt at the bottom
clear() { command clear "$@" && _prompt_bottom }
