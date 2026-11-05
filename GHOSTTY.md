# Ghostty (macOS)

The zsh + starship half of this repo works in [Ghostty](https://ghostty.org)
too. Ghostty has no official Windows version, so this guide is for **macOS**
(Linux notes at the end). It gives Ghostty the same look and the same keys as
the WezTerm setup, with **Cmd** where WezTerm uses Ctrl.

## Install (about 10 minutes)

1. Install Ghostty, the font and the command-line tools:
   ```sh
   brew install --cask ghostty font-fira-code-nerd-font
   brew install starship fzf fd ripgrep bat eza zoxide neovim gh
   ```
2. Clone this repo and fetch the zsh plugins:
   ```sh
   git clone https://github.com/mkljngd/terminal-config.git ~/terminal-config
   cd ~/terminal-config
   bash extras/clone-zsh-plugins.sh
   ```
3. Copy the shell config (backs up anything it replaces as `*.pre-dotfiles-<time>`):
   ```sh
   ts=$(date +%Y%m%d-%H%M%S)
   for f in ~/.zshenv ~/.zshrc ~/.config/zsh ~/.config/starship.toml; do
     [ -e "$f" ] && cp -a "$f" "$f.pre-dotfiles-$ts"
   done
   mkdir -p ~/.config/zsh ~/.cache/zsh ~/.local/state/zsh ~/.local/bin
   cp home/.zshenv home/.zshrc ~/
   cp -a home/.config/zsh/. ~/.config/zsh/
   cp home/.config/starship.toml ~/.config/
   ```
4. Adjust for macOS:
   ```sh
   # The config uses Debian's names for fd and bat.
   ln -sf "$(brew --prefix)/bin/fd"  ~/.local/bin/fdfind
   ln -sf "$(brew --prefix)/bin/bat" ~/.local/bin/batcat
   ```
   Then open `~/.config/zsh/.zshenv` and:
   - delete the `TZ="Asia/Kolkata"` line (macOS already knows your timezone);
   - set `JAVA_HOME` to `$(/usr/libexec/java_home -v 17)`, or delete the Java lines if you don't use Java.
5. Install the prompt icon font (the Iron Man icon at the start of the prompt):
   ```sh
   cp windows/.wezterm-fonts/CustomPromptIcons.ttf ~/Library/Fonts/
   ```
6. Create `~/.config/ghostty/config` with the config below.
7. Quit Ghostty (Cmd+Q) and open it again.

zsh is already the macOS login shell, so there is no `chsh` step.

## Ghostty config

`~/.config/ghostty/config`:

```ini
# Font. The prompt icon (U+E900) comes from the fallback font (step 5).
font-family = FiraCode Nerd Font
font-family = Custom Prompt Icons
font-size = 14
adjust-cell-height = 20%

# Theme: same colors as .wezterm.lua (black, cyan text, magenta accent).
background = #000000
foreground = #0abdc6
palette = 0=#18181b
palette = 1=#be185d
palette = 2=#22c55e
palette = 3=#facc15
palette = 4=#0284c7
palette = 5=#db2777
palette = 6=#2dd4bf
palette = 7=#e4e4e7
palette = 8=#475569
palette = 9=#db2777
palette = 10=#4ade80
palette = 11=#fde047
palette = 12=#38bdf8
palette = 13=#f472b6
palette = 14=#99f6e4
palette = 15=#f4f4f5
cursor-color = #ff00ff
cursor-text = #000000
selection-background = #590059
selection-foreground = cell-foreground
split-divider-color = #27272a
unfocused-split-opacity = 0.85
cursor-style = bar
cursor-style-blink = true
mouse-hide-while-typing = true
window-padding-x = 14
window-padding-y = 10

# Selecting text copies it; right-click copies a selection or pastes.
copy-on-select = clipboard
right-click-action = copy-or-paste

# Option acts as Alt: Alt+T / Alt+C for fzf; Alt+←/→ by word (sent as
# Alt+B / Alt+F, like the WezTerm config does).
macos-option-as-alt = true
keybind = alt+left=esc:b
keybind = alt+right=esc:f

# Keep zsh's folder-name tab titles; ssh sessions get TERM=xterm-256color.
shell-integration-features = no-title,ssh-env

# New line without running (zsh and Claude Code).
keybind = shift+enter=text:\x1b\r
keybind = alt+enter=text:\x1b\r

# Cut / copy a Shift+arrow selection on the command line (keyboard-select.zsh).
keybind = cmd+x=csi:120;9u
keybind = cmd+shift+c=csi:99;10u

# Tabs
keybind = cmd+t=new_tab
keybind = cmd+w=close_surface
keybind = cmd+shift+e=prompt_tab_title
keybind = cmd+shift+alt+left=move_tab:-1
keybind = cmd+shift+alt+right=move_tab:1
keybind = ctrl+tab=next_tab
keybind = ctrl+shift+tab=previous_tab

# Splits
keybind = cmd+shift+d=new_split:right
keybind = cmd+shift+alt+d=new_split:down
keybind = cmd+shift+left=goto_split:left
keybind = cmd+shift+right=goto_split:right
keybind = cmd+shift+up=goto_split:up
keybind = cmd+shift+down=goto_split:down
keybind = cmd+alt+left=resize_split:left,20
keybind = cmd+alt+right=resize_split:right,20
keybind = cmd+alt+up=resize_split:up,20
keybind = cmd+alt+down=resize_split:down,20
keybind = cmd+shift+z=toggle_split_zoom

# Clear, search, command palette
keybind = cmd+k=clear_screen
keybind = cmd+shift+f=start_search
keybind = cmd+shift+p=toggle_command_palette
```

## Keys

| WezTerm (Windows) | Ghostty (macOS) | Action |
|---|---|---|
| Ctrl+T / Ctrl+W | Cmd+T / Cmd+W | new / close tab |
| Ctrl+Shift+E | Cmd+Shift+E | rename tab |
| Ctrl+Shift+Alt+← / → | Cmd+Shift+Alt+← / → | move tab |
| Ctrl+Shift+D / Ctrl+Shift+Alt+D | Cmd+Shift+D / Cmd+Shift+Alt+D | split right / down |
| Ctrl+Shift+arrows / Ctrl+Alt+arrows | Cmd+Shift+arrows / Cmd+Alt+arrows | move between / resize panes |
| Ctrl+K | Cmd+K | clear |
| Ctrl+V | Cmd+V | paste |
| Ctrl+C (with a command-line selection) | Cmd+Shift+C | copy the Shift+arrow selection |
| Ctrl+Shift+X | Cmd+X | cut the Shift+arrow selection |
| Ctrl+click | Cmd+click | open a link |

Unchanged: Shift+arrows select, Alt+←/→ move by word (macOS uses Ctrl+←/→ to
switch desktops), Shift/Alt+Enter new line, Alt+T / Alt+C / Ctrl+R fzf, Ctrl+X Ctrl+E edit in nvim,
Tab completion, ↑/↓ history.

## WezTerm-only features

| Feature | Why it's missing in Ghostty |
|---|---|
| Ctrl+C / Ctrl+A / Ctrl+Z / Ctrl+Y as copy / select all / undo / redo at the prompt | WezTerm sends them only while zsh is at the prompt. Ghostty can't tell, so Ctrl+C stays interrupt. Use Cmd+Shift+C, Cmd+X and Shift+Home/End instead. |
| Click, drag and double-click editing on the command line (`mouse.zsh`) | It relies on WezTerm handing the mouse back and forth; it switches itself off in other terminals. |
| Tab colors (Ctrl+Shift+O and automatic by title) | Ghostty has no tab colors. |
| Workflows (Ctrl+Shift+L) | No Ghostty equivalent; open the tabs yourself. |

## Linux

Ghostty runs on Linux too ([install guide](https://ghostty.org/docs/install)).
Differences from the macOS steps:

- Install the tools with `apt` (the list is in `setup.sh`). Debian and Ubuntu
  already call them `fdfind` and `batcat`, so skip the symlinks in step 4.
- Put the icon font in `~/.local/share/fonts/` and run `fc-cache -f`.
- In the config, drop `macos-option-as-alt` and change `cmd` to `ctrl` in the
  keybinds, except `cmd+x` → `ctrl+shift+x` and `cmd+k` → `ctrl+shift+k`
  (plain Ctrl+X and Ctrl+K are shell keys).
