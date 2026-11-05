# dotfiles: WezTerm + zsh + starship (Windows / WSL)

A Warp-inspired terminal for Windows with the shell in WSL: **WezTerm** on the
Windows side, **zsh** + **starship** in Ubuntu. Black background, cyan text,
magenta accent, a prompt of cyan-shaded blocks, and Windows-style keys
(Ctrl+C/V/A, Ctrl+T/W) that stay out of the way of running programs.

```
🦾 user │ …/project │  main ?3 │  v3.12.3 ──────────── 󱦟 5s │ 󰍛 5% │ 21:45
❯
```

## Install

On a fresh Windows machine:

1. `wsl --install -d Ubuntu` in PowerShell, then open Ubuntu.
2. Clone this repo inside WSL and run:
   ```sh
   bash setup.sh
   ```
   Installs the apt tools (fzf, fd, ripgrep, bat, eza, zoxide, neovim, gh…),
   starship, the zsh plugins, WezTerm (winget) and FiraCode Nerd Font, makes zsh
   the login shell, then runs `install.sh`.
3. Open WezTerm.

On a Mac (or Linux) with Ghostty instead of WezTerm, follow [GHOSTTY.md](GHOSTTY.md).

`bash install.sh` re-applies just the config files. Anything replaced is backed
up as `*.pre-dotfiles-<timestamp>`.

## Layout

| Path | Installed to | What |
|---|---|---|
| `home/.zshenv` | `~/.zshenv` | points zsh at `~/.config/zsh` |
| `home/.zshrc` | `~/.zshrc` | fallback shim |
| `home/.config/zsh/` | `~/.config/zsh/` | the zsh config (below) |
| `home/.config/starship.toml` | `~/.config/starship.toml` | prompt |
| `home/.ipython/profile_default/ipython_config.py` | same | IPython / `manage.py shell` colors (needs `ipython` in the venv) |
| `windows/.wezterm.lua` | `C:\Users\<you>\.wezterm.lua` | WezTerm: theme, keys, tabs, workflows |
| `windows/.wezterm-fonts/` | `C:\Users\<you>\.wezterm-fonts\` | prompt icon font (FiraCode is downloaded here too) |
| `extras/` | not installed | plugin installer, prompt-icon font builder |

| zsh file | Does |
|---|---|
| `.zshenv` | XDG dirs, `EDITOR=nvim`, PATH, Node/Java env, timezone |
| `history.zsh` | 100k shared history, ↑/↓ prefix search |
| `completion.zsh` | case-insensitive fzf-tab completion |
| `keyboard-select.zsh` | Shift+arrow selection, copy/cut/select-all, word undo/redo on the command line |
| `mouse.zsh` | click, drag, double/triple-click on the command line (WezTerm). Off: `ZLE_MOUSE=0` |
| `plugins.zsh` | fzf, fzf-tab, autosuggestions, zoxide, atuin (optional), syntax highlighting |
| `fzf.zsh` | fzf with `fd` and bat previews |
| `aliases.zsh`, `functions.zsh` | eza/bat/rg aliases, git helpers (`mkcd`, `gltag`, `tagpush`, `gitmr`) |
| `bindings.zsh` | Ctrl+arrows by word, Alt+T fzf, Alt/Shift+Enter newline, edit in nvim |
| `wezterm.zsh` | tab title = folder, cwd for new tabs, tells WezTerm when zsh is at the prompt |
| `prompt.zsh` | starship; narrow panes (< 100 cols) drop the right-hand info |
| `prompt-bottom.zsh` | prompt starts at the bottom of the window |

### Machine-specific overrides (not committed)

- `home/.config/zsh/local.zsh`: sourced last by `.zshrc`. Put hosts, cluster
  logins, VPN aliases and company tooling here. Start from `local.zsh.example`.
- `windows/.wezterm-local.lua`: returns `{ workflows = { ... } }` to replace the
  example workflow (same shape as in `.wezterm.lua`).

Both are in `.gitignore`; `install.sh` copies them when present.

## Keyboard shortcuts

**Command line**

| Keys | Action |
|---|---|
| Ctrl+A | select the whole line (at the prompt) |
| Ctrl+C | copy selection; nothing selected → cancel line; program running → interrupt |
| Ctrl+V | paste |
| Ctrl+Shift+X | cut selection |
| Backspace / Delete / typing | delete / replace the selection |
| Ctrl+Z / Ctrl+Y | undo / redo by word (at the prompt; running programs still get Ctrl+Z to suspend) |
| Home / End | start / end of line |
| Ctrl+Delete | delete next word |
| Ctrl+X Ctrl+E, or Esc then v | edit the command line in nvim (`:wq` puts it back) |
| Click / drag on the command line | place the cursor / select |
| Double-click / triple-click | select word / line of the command |
| Mouse select (output) | copies automatically; right-click copies the selection or pastes |
| Ctrl+click a link | open it (also inside Claude Code and vim; a plain click only selects) |
| Shift+←/→, Shift+Alt+←/→, Shift+Home/End | select by char / word / to line edge |
| Ctrl+←/→, Alt+←/→ | move by word |
| Ctrl+Backspace | delete previous word |
| Shift+Enter, Alt+Enter | newline without running (works in Claude Code too) |
| ↑ / ↓ | history matching what you've typed |
| Ctrl+Space, Ctrl+F | accept autosuggestion (whole / next word) |
| Tab | fuzzy completion popup |
| Alt+T / Alt+C / Ctrl+R | fzf file picker / cd / history |
| Ctrl+K | clear screen and scrollback (at the prompt) |
| Esc | clear the selection; nothing selected → vi command mode (zsh uses the vi keymap because `EDITOR=nvim`); `i` to go back |

**Tabs and panes**

| Keys | Action |
|---|---|
| Ctrl+T / Ctrl+W | new / close tab |
| Ctrl+Shift+E | rename tab |
| Ctrl+Shift+O | tab color (blue/green/yellow/magenta/red/cyan/orange, or none) |
| Ctrl+Shift+Alt+← / → | move tab left / right (also Ctrl+Shift+PageUp/PageDown) |
| Ctrl+Tab, Ctrl+PageUp/PageDown | switch tab |
| Ctrl+Shift+D / Ctrl+Shift+Alt+D | split right / down |
| Ctrl+Shift+←/→/↑/↓ | move between panes |
| Ctrl+Alt+←/→/↑/↓ | resize pane |
| Ctrl+Shift+W | close pane |
| Ctrl+Shift+Z | zoom pane |
| Ctrl+Shift+L | launch a workflow (tabs + commands, like Warp launch configs) |
| Ctrl+Shift+K | clear, even while a program runs |
| Ctrl+Shift+F / Ctrl+Shift+P | search scrollback / command palette |

## Customising

- **Prompt colors**: `[palettes.cyan_shades]` in `starship.toml`.
- **Terminal colors**: `config.colors` in `.wezterm.lua`.
- **Automatic tab colors**: `tab_color_rules` in `.wezterm.lua` (title pattern → color;
  Claude Code tabs are orange). Ctrl+Shift+O overrides.
- **Prompt icon**: `extras/prompt-icon/build_icon_font.py image.png CustomPromptIcons.ttf E900`
  (needs `uv`: `uv run --with pillow --with fonttools python ...`), then copy the
  `.ttf` into `C:\Users\<you>\.wezterm-fonts\`. Use a small flat PNG.
- **Narrow-pane cutoff**: `export STARSHIP_NARROW_COLUMNS=120` in `.zshenv`.

## Notes

- The prompt icon (`extras/prompt-icon/ironman.png`, baked into
  `CustomPromptIcons.ttf`) is a third-party Iron Man icon from Icons8
  ("Those Icons" flat set). Icons8's free license requires attribution
  (https://icons8.com); replace it with your own image before publishing if you
  don't want that.
- FiraCode Nerd Font is © The Fira Code Project Authors / Nerd Fonts (OFL-1.1)
  and is downloaded at install time, not stored here.
