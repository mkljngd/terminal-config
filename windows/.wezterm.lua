local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Windows-native WezTerm, with the shell and files living in WSL.
-- Prefer an Ubuntu WSL domain automatically. Override by setting the
-- Windows environment variable WEZTERM_WSL_DOMAIN, e.g. WSL:Ubuntu-24.04.
local wsl_domains = wezterm.default_wsl_domains()
config.wsl_domains = wsl_domains

local preferred = os.getenv('WEZTERM_WSL_DOMAIN')
local chosen = nil

local function choose_named(name)
  if not name then return nil end
  for _, dom in ipairs(wsl_domains) do
    if dom.name == name then return dom.name end
  end
  return nil
end

chosen = choose_named(preferred)

if not chosen then
  for _, dom in ipairs(wsl_domains) do
    if dom.name:match('^WSL:Ubuntu') then
      chosen = dom.name
      break
    end
  end
end

if not chosen and #wsl_domains > 0 then
  chosen = wsl_domains[1].name
end

if chosen then
  config.default_domain = chosen
end

-- Match the Ghostty font setup.
-- 'Custom Prompt Icons' (in ~/.wezterm-fonts) holds the Iron Man prompt icon
-- at U+E900; built by projects/tools/wsl/prompt-icon/build_icon_font.py.
config.font_dirs = { wezterm.home_dir .. '/.wezterm-fonts' }
config.font = wezterm.font_with_fallback {
  { family = 'FiraCode Nerd Font', weight = 'Medium' },
  -- Color fonts are treated as emoji-only unless told otherwise.
  { family = 'Custom Prompt Icons', assume_emoji_presentation = false },
}
config.font_size = 14
config.line_height = 1.2

-- Warp theme: black background, cyan text, magenta accent, "darker" details.
local accent = '#ff00ff'
local dim    = '#475569'   -- inactive tabs

config.colors = {
  background = '#000000',
  foreground = '#0abdc6',

  -- ANSI order: black, red, green, yellow, blue, magenta, cyan, white
  ansi = {
    '#18181b', '#be185d', '#22c55e', '#facc15',
    '#0284c7', '#db2777', '#2dd4bf', '#e4e4e7',
  },
  brights = {
    '#475569', '#db2777', '#4ade80', '#fde047',
    '#38bdf8', '#f472b6', '#99f6e4', '#f4f4f5',
  },

  -- Accent drives the cursor, selection and active tab, as in Warp.
  cursor_bg     = accent,
  cursor_border = accent,
  cursor_fg     = '#000000',
  selection_bg  = 'rgba(255, 0, 255, 0.35)',
  selection_fg  = 'none',
  split         = '#27272a',
  scrollbar_thumb = '#27272a',

  tab_bar = {
    background = '#000000',
    active_tab = { bg_color = '#000000', fg_color = accent, intensity = 'Bold' },
    inactive_tab = { bg_color = '#000000', fg_color = '#475569' },
    inactive_tab_hover = { bg_color = '#18181b', fg_color = '#0abdc6' },
    new_tab = { bg_color = '#000000', fg_color = '#475569' },
    new_tab_hover = { bg_color = '#18181b', fg_color = accent },
  },
}

-- Keep it opaque for maximum rendering performance. For Windows 11 Mica,
-- see the commented alternative below.
config.window_background_opacity = 1.0
-- config.window_background_opacity = 0
-- config.win32_system_backdrop = 'Mica'

config.window_padding = {
  left = 14,
  right = 14,
  top = 10,
  bottom = 10,
}

config.default_cursor_style = 'BlinkingBar'
config.hide_mouse_cursor_when_typing = true
config.window_close_confirmation = 'AlwaysPrompt'
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 0.85,
}

-- Simple tabs; avoids a heavy/chrome-like tab treatment.
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.enable_scroll_bar = false

-- Keep xterm-256color for broad SSH compatibility, like your Ghostty
-- ssh-env intent. No remote wezterm terminfo install is required.
config.term = 'xterm-256color'

-- Smart copy: if WezTerm has a mouse/copy-mode selection, copy that.
-- Otherwise send your custom ZLE sequence so the selected command-line text
-- is copied by ~/.config/zsh/keyboard-select.zsh.
local smart_copy = wezterm.action_callback(function(window, pane)
  local selected = window:get_selection_text_for_pane(pane)
  if selected ~= '' then
    window:perform_action(act.CopyTo 'Clipboard', pane)
    window:perform_action(act.ClearSelection, pane)
  else
    window:perform_action(act.SendString '\x1b[99;10u', pane)
  end
end)

-- ~/.config/zsh/wezterm.zsh sets ZSH_AT_PROMPT=1 while zsh edits a command
-- and 0 while a program runs.
local function at_zsh_prompt(pane)
  return pane:get_user_vars().ZSH_AT_PROMPT == '1'
end

-- Ctrl+C: copy a mouse selection; at the prompt, copy the command-line
-- selection (or abort the line); otherwise a normal interrupt.
local ctrl_c = wezterm.action_callback(function(window, pane)
  if window:get_selection_text_for_pane(pane) ~= '' then
    window:perform_action(act.CopyTo 'Clipboard', pane)
    window:perform_action(act.ClearSelection, pane)
  elseif at_zsh_prompt(pane) then
    window:perform_action(act.SendString '\x1b[99;5u', pane)
  else
    window:perform_action(act.SendKey { key = 'c', mods = 'CTRL' }, pane)
  end
end)

-- Ctrl+A: select the whole command line at the prompt; otherwise a plain ^A.
local ctrl_a = wezterm.action_callback(function(window, pane)
  if at_zsh_prompt(pane) then
    window:perform_action(act.SendString '\x1b[97;5u', pane)
  else
    window:perform_action(act.SendKey { key = 'a', mods = 'CTRL' }, pane)
  end
end)

-- Ctrl+Z / Ctrl+Y: undo / redo at the prompt; otherwise plain ^Z (suspend) / ^Y.
local function prompt_or_key(seq, key)
  return wezterm.action_callback(function(window, pane)
    if at_zsh_prompt(pane) then
      window:perform_action(act.SendString(seq), pane)
    else
      window:perform_action(act.SendKey { key = key, mods = 'CTRL' }, pane)
    end
  end)
end
local ctrl_z = prompt_or_key('\x1b[122;5u', 'z')
local ctrl_y = prompt_or_key('\x1b[121;5u', 'y')

-- Right-click (Windows Terminal style): copy the selection if there is one,
-- otherwise paste. Selecting with the mouse already copies (WezTerm default).
local right_click = wezterm.action_callback(function(window, pane)
  if window:get_selection_text_for_pane(pane) ~= '' then
    window:perform_action(act.CopyTo 'Clipboard', pane)
    window:perform_action(act.ClearSelection, pane)
  else
    window:perform_action(act.PasteFrom 'Clipboard', pane)
  end
end)

-- zsh turns on mouse reporting while you edit a command (mouse.zsh: click,
-- drag, double-click on the command line). These keep the wheel, right-click
-- with WezTerm there; `alt_screen = false` leaves full-screen apps (vim,
-- less, htop, Claude Code) in charge of their own mouse.
-- Shift+drag still selects terminal text while zsh has the mouse.
local function at_prompt(binding)
  binding.mouse_reporting = true
  binding.alt_screen = false
  return binding
end

-- mouse.zsh hands a press above the command line back to WezTerm by setting
-- the user var ZSH_MOUSE_HANDOFF to Cell / Word / Line: start a normal
-- selection there, so earlier output can be selected with a plain drag.
wezterm.on('user-var-changed', function(window, pane, name, value)
  if name == 'ZSH_MOUSE_HANDOFF' and (value == 'Cell' or value == 'Word' or value == 'Line') then
    window:perform_action(act.SelectTextAtMouseCursor(value), pane)
  end
end)

-- Releasing the button finishes (copies) the selection; links open only with
-- Ctrl+click. After a handoff it also gives the mouse back to zsh (ESC[1999~).
local function finish_selection(mode)
  return wezterm.action_callback(function(window, pane)
    window:perform_action(act.CompleteSelection(mode), pane)
    local handoff = pane:get_user_vars().ZSH_MOUSE_HANDOFF
    if handoff and handoff ~= '0' and at_zsh_prompt(pane) then
      window:perform_action(act.SendString '\x1b[1999~', pane)
    end
  end)
end

config.mouse_bindings = {
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'NONE', action = finish_selection 'ClipboardAndPrimarySelection' },
  { event = { Up = { streak = 2, button = 'Left' } }, mods = 'NONE', action = finish_selection 'ClipboardAndPrimarySelection' },
  { event = { Up = { streak = 3, button = 'Left' } }, mods = 'NONE', action = finish_selection 'ClipboardAndPrimarySelection' },
  { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE', action = right_click },
  at_prompt { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE', action = right_click },
  at_prompt { event = { Down = { streak = 1, button = { WheelUp = 1 } } }, mods = 'NONE', action = act.ScrollByCurrentEventWheelDelta },
  at_prompt { event = { Down = { streak = 1, button = { WheelDown = 1 } } }, mods = 'NONE', action = act.ScrollByCurrentEventWheelDelta },
}

-- Ctrl+click opens links everywhere: plain output, the zsh prompt, and apps
-- that grab the mouse full-screen (Claude Code's fullscreen TUI, vim).
for _, reporting in ipairs { false, true } do
  table.insert(config.mouse_bindings, { event = { Down = { streak = 1, button = 'Left' } }, mods = 'CTRL', mouse_reporting = reporting, action = act.Nop })
  table.insert(config.mouse_bindings, { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL', mouse_reporting = reporting, action = act.OpenLinkAtMouseCursor })
end

-- Clear viewport and scrollback, then have zsh redraw the prompt at the bottom.
local clear_terminal = act.Multiple {
  act.ClearScrollback 'ScrollbackAndViewport',
  act.SendKey { key = 'L', mods = 'CTRL' },
}

-- Ctrl+K: clear at the prompt; otherwise a plain ^K (e.g. nano's cut line).
local ctrl_k = wezterm.action_callback(function(window, pane)
  if at_zsh_prompt(pane) then
    window:perform_action(clear_terminal, pane)
  else
    window:perform_action(act.SendKey { key = 'k', mods = 'CTRL' }, pane)
  end
end)

-- ── Tab titles and colors ──────────────────────────────────────
-- A renamed tab keeps its name; otherwise it shows the folder zsh reports.
-- Colors live in wezterm.GLOBAL so they survive config reloads.
local tab_color_hex = {
  blue    = '#38bdf8',
  green   = '#4ade80',
  yellow  = '#fde047',
  magenta = '#f472b6',
  red     = '#db2777',
  cyan    = '#99f6e4',
  orange  = '#d97757',   -- Claude
}

wezterm.GLOBAL.tab_colors = wezterm.GLOBAL.tab_colors or {}

-- color: a key of tab_color_hex, or 'none' to go back to the default.
-- '' marks "no color" because nil can't be stored in wezterm.GLOBAL.
local function set_tab_color(tab, color)
  wezterm.GLOBAL.tab_colors[tostring(tab:tab_id())] = tab_color_hex[color] or ''
end

-- Automatic tab colors: first match wins, on the lowercased tab title.
-- Patterns are Lua patterns (plain words work; '%-' for a literal '-').
-- A color picked with Ctrl+Shift+O (or a workflow) overrides these.
local tab_color_rules = {
  { 'prod',   'red' },
  { 'server', 'green' },
  { 'shell',  'yellow' },
  { 'claude', 'orange' },
  -- Claude Code titles the tab "<spinner> <session name>" while it runs.
  { '^✳', 'orange' }, { '^✻', 'orange' }, { '^✽', 'orange' },
  { '^✶', 'orange' }, { '^✢', 'orange' }, { '^·', 'orange' },
  { 'git',    'magenta' },
}

local function auto_tab_color(title)
  title = title:lower()
  for _, rule in ipairs(tab_color_rules) do
    if title:find(rule[1]) then return tab_color_hex[rule[2]] end
  end
end

-- color: a key of tab_color_hex, or 'none' to go back to the default.
-- '' marks "no color" because nil can't be stored in wezterm.GLOBAL.
local function set_tab_color(tab, color)
  wezterm.GLOBAL.tab_colors[tostring(tab:tab_id())] = tab_color_hex[color] or ''
end

wezterm.on('format-tab-title', function(tab, _, _, _, _, max_width)
  local title = tab.tab_title ~= '' and tab.tab_title or tab.active_pane.title
  local label = string.format(' %d: %s ', tab.tab_index + 1, title)
  local color = wezterm.GLOBAL.tab_colors[tostring(tab.tab_id)]
  if color == nil then color = auto_tab_color(title) end   -- '' = picked "none"
  if color == '' then color = nil end
  local fg = color or (tab.is_active and accent or dim)
  return {
    { Foreground = { Color = fg } },
    { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
    { Attribute = { Underline = tab.is_active and 'Single' or 'None' } },
    { Text = wezterm.truncate_right(label, max_width) },
  }
end)

-- Ctrl+Shift+E: rename the tab. An empty name goes back to the folder name.
local rename_tab = act.PromptInputLine {
  description = 'Rename tab (empty = folder name)',
  action = wezterm.action_callback(function(window, _, line)
    if line then
      window:active_tab():set_title(line)
    end
  end),
}

-- Ctrl+Shift+O: pick a color for the current tab (each shown as a swatch).
local tab_color_order = { 'blue', 'green', 'yellow', 'magenta', 'red', 'cyan', 'orange' }
local pick_tab_color = act.InputSelector {
  title = 'Tab color',
  choices = (function()
    local choices = { { id = 'none', label = '  none (default)' } }
    for _, name in ipairs(tab_color_order) do
      table.insert(choices, {
        id = name,
        label = wezterm.format {
          { Foreground = { Color = tab_color_hex[name] } },
          { Text = '● ' .. name },
        },
      })
    end
    return choices
  end)(),
  action = wezterm.action_callback(function(window, _, id)
    if id then
      local tab = window:active_tab()
      set_tab_color(tab, id)
      tab:set_title(tab:get_title())   -- nudge the tab bar to redraw now
    end
  end),
}

-- ── Workflows (Warp launch configurations) ─────────────────────
-- Each tab: title, color (key of tab_color_hex), cwd, optional command, and
-- optional split = { direction = 'Right' | 'Bottom', cwd, command }.
-- Commands are typed into an interactive zsh, so aliases like djserver work
-- and the shell stays open after the command exits.
local workflows = {
  {
    name = 'Example: project + server',
    active_tab = 1,
    tabs = {
      { title = 'Editor', color = 'blue',  cwd = '~', command = 'nvim .' },
      { title = 'Server', color = 'green', cwd = '~', command = 'echo start your server here' },
      {
        title = 'Git', color = 'magenta', cwd = '~', command = 'git status',
        split = { direction = 'Right', cwd = '~', command = 'git log --oneline -20' },
      },
    },
  },
}

-- Machine-specific workflows live in ~/.wezterm-local.lua (not in git), which
-- returns { workflows = { ... } } in the same shape; they replace the example.
do
  local ok, extra = pcall(dofile, wezterm.home_dir .. '/.wezterm-local.lua')
  if ok and type(extra) == 'table' and extra.workflows then
    workflows = extra.workflows
  end
end

local wsl_domain = chosen and { DomainName = chosen } or 'DefaultDomain'

local function run_in(pane, command)
  if command then
    pane:send_text(command .. '\r')
  end
end

-- Opens the workflow in a new window, one tab per entry.
local function launch_workflow(workflow)
  local window, tabs = nil, {}
  for i, spec in ipairs(workflow.tabs) do
    local tab, pane
    if i == 1 then
      tab, pane, window = wezterm.mux.spawn_window { domain = wsl_domain, cwd = spec.cwd }
    else
      tab, pane = window:spawn_tab { domain = wsl_domain, cwd = spec.cwd }
    end
    tab:set_title(spec.title)
    set_tab_color(tab, spec.color)
    run_in(pane, spec.command)
    if spec.split then
      local split_pane = pane:split { direction = spec.split.direction, cwd = spec.split.cwd }
      run_in(split_pane, spec.split.command)
      pane:activate()
    end
    tabs[i] = tab
  end
  local active = tabs[workflow.active_tab or 1]
  if active then
    active:activate()
  end
end

-- Ctrl+Shift+L: pick a workflow to launch.
local pick_workflow = act.InputSelector {
  title = 'Launch workflow',
  fuzzy = true,
  choices = (function()
    local choices = {}
    for i, workflow in ipairs(workflows) do
      choices[i] = { id = tostring(i), label = workflow.name }
    end
    return choices
  end)(),
  action = wezterm.action_callback(function(_, _, id)
    if id then
      launch_workflow(workflows[tonumber(id)])
    end
  end),
}

-- Also list the workflows and rename in the command palette (Ctrl+Shift+P).
wezterm.on('augment-command-palette', function()
  local entries = {
    { brief = 'Rename tab', icon = 'md_rename_box', action = rename_tab },
    { brief = 'Tab color', icon = 'md_palette', action = pick_tab_color },
  }
  for _, workflow in ipairs(workflows) do
    table.insert(entries, {
      brief = 'Workflow: ' .. workflow.name,
      icon = 'md_rocket_launch',
      action = wezterm.action_callback(function()
        launch_workflow(workflow)
      end),
    })
  end
  return entries
end)

config.keys = {
  -- Ghostty Alt+Enter behavior: insert a literal newline in zsh.
  -- This intentionally replaces WezTerm's default Alt+Enter fullscreen key.
  { key = 'Enter', mods = 'ALT', action = act.SendString '\x1b\r' },

  -- Shift+Enter: same newline sequence. Claude Code reads ESC+CR as "new line";
  -- by default WezTerm sends Shift+Enter as a plain Enter, which submits.
  { key = 'Enter', mods = 'SHIFT', action = act.SendString '\x1b\r' },

  -- Tabs and splits. New tabs/panes stay in the current WSL domain and,
  -- with the included OSC 7 hook, in the current WSL directory.
  { key = 'T', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 't', mods = 'CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL', action = act.CloseCurrentTab { confirm = true } },

  -- Ctrl+W is close-tab now, so Ctrl+Backspace sends ^W (delete previous word).
  { key = 'Backspace', mods = 'CTRL', action = act.SendString '\x17' },
  {
    key = 'D',
    mods = 'CTRL|SHIFT',
    action = act.SplitPane { direction = 'Right', size = { Percent = 50 } },
  },
  {
    key = 'D',
    mods = 'CTRL|SHIFT|ALT',
    action = act.SplitPane { direction = 'Down', size = { Percent = 50 } },
  },

  -- Pane navigation. This leaves Shift+Alt+Left/Right free for your
  -- Warp-style command-line word selection.
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },

  -- Close the current pane (the tab closes with its last pane).
  { key = 'W', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },

  -- Rename tab and launch workflows.
  { key = 'E', mods = 'CTRL|SHIFT', action = rename_tab },
  { key = 'O', mods = 'CTRL|SHIFT', action = pick_tab_color },

  -- Rearrange tabs (Ctrl+Shift+PageUp/PageDown also still work).
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT|ALT', action = act.MoveTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|SHIFT|ALT', action = act.MoveTabRelative(1) },

  -- Pane resize moved here from its Ctrl+Shift+Alt+arrow default.
  { key = 'LeftArrow',  mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'RightArrow', mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'UpArrow',    mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Up', 2 } },
  { key = 'DownArrow',  mods = 'CTRL|ALT', action = act.AdjustPaneSize { 'Down', 2 } },
  { key = 'L', mods = 'CTRL|SHIFT', action = pick_workflow },

  -- Word movement, matching macOS Option+Arrow muscle memory.
  { key = 'LeftArrow',  mods = 'ALT', action = act.SendKey { key = 'b', mods = 'ALT' } },
  { key = 'RightArrow', mods = 'ALT', action = act.SendKey { key = 'f', mods = 'ALT' } },

  -- Warp-style ZLE command-line selection.
  { key = 'LeftArrow',  mods = 'SHIFT', action = act.SendString '\x1b[1;2D' },
  { key = 'RightArrow', mods = 'SHIFT', action = act.SendString '\x1b[1;2C' },
  { key = 'LeftArrow',  mods = 'SHIFT|ALT', action = act.SendString '\x1b[1;4D' },
  { key = 'RightArrow', mods = 'SHIFT|ALT', action = act.SendString '\x1b[1;4C' },
  { key = 'Home', mods = 'SHIFT', action = act.SendString '\x1b[1;2H' },
  { key = 'End',  mods = 'SHIFT', action = act.SendString '\x1b[1;2F' },

  -- Copy/cut the active ZLE selection. Ctrl+Shift+C still copies ordinary
  -- terminal output when WezTerm itself has a selection.
  { key = 'C', mods = 'CTRL|SHIFT', action = smart_copy },
  { key = 'X', mods = 'CTRL|SHIFT', action = act.SendString '\x1b[120;9u' },

  -- Windows-style clipboard keys.
  { key = 'c', mods = 'CTRL', action = ctrl_c },
  { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
  { key = 'a', mods = 'CTRL', action = ctrl_a },
  { key = 'z', mods = 'CTRL', action = ctrl_z },
  { key = 'y', mods = 'CTRL', action = ctrl_y },

  -- Move WezTerm copy mode away from Ctrl+Shift+X, which is now shell cut.
  { key = 'X', mods = 'CTRL|SHIFT|ALT', action = act.ActivateCopyMode },

  -- Clear the terminal. Ctrl+Shift+K always clears, even while a program runs.
  { key = 'k', mods = 'CTRL', action = ctrl_k },
  { key = 'K', mods = 'CTRL|SHIFT', action = clear_terminal },

  -- Explicitly retain the two shortcuts you already rely on in Ghostty.
  { key = 'F', mods = 'CTRL|SHIFT', action = act.Search { CaseSensitiveString = '' } },
  { key = 'P', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
}

return config
