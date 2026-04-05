local wezterm = require("wezterm")
local act = wezterm.action

-- Load custom modules from the wezterm-config repo
package.path = package.path .. ";C:/Users/Cong/Documents/Projects/wezterm-config/?.lua"
local theme_switcher = require("theme_switcher")

local config = wezterm.config_builder()

-- Use Git Bash as the default shell instead of PowerShell/CMD
config.default_prog = { "C:/Program Files/Git/bin/bash.exe", "--login", "-i" }
config.default_cwd = "C:/Users/Cong"

-- Color scheme (change with Ctrl+Shift+S theme switcher)
config.color_scheme = "Ayu Mirage"

-- Font: requires Hack Nerd Font to be installed (https://www.nerdfonts.com)
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 11

-- Cursor style: thin blinking line
config.default_cursor_style = "BlinkingBar"

-- Background settings
config.window_background_opacity = 0
config.win32_system_backdrop = 'Tabbed'

-- === GlazeWM compatibility ===
-- Force the OpenGL renderer (via EGL) instead of the default WebGpu/D3D
-- backend. WezTerm's default renderer races with GlazeWM's tiling: the
-- WM cloaks and resizes the window before the GPU surface finishes
-- initializing, which causes WezTerm to fail to launch silently.
-- Without these two lines, WezTerm must be added to GlazeWM's
-- `window_rules` as ignored in order to start at all.
config.front_end = "OpenGL"
config.prefer_egl = true

-- Adjust text hue, saturation, and brightness globally
-- Values of 1.0 are neutral (no adjustment)
config.foreground_text_hsb = {
  hue = 1.0,
  saturation = 1.0,
  brightness = 1.0,
}

-- Disable all default keybindings and define custom ones
config.disable_default_key_bindings = true
config.keys = {
  -- Clipboard: paste from system clipboard
  { key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },

  -- Pane splits: create side-by-side or stacked panes
  { key = "H", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "J", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Pane navigation: move focus between panes with arrow keys
  { key = "LeftArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },

  -- Tab navigation: cycle through open tabs
  { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },

  -- Command palette: search and run any WezTerm command
  { key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },

  -- Close the current pane (prompts for confirmation)
  { key = "W", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },

  -- Theme switcher: fuzzy-search and apply a built-in color scheme
  { key = "S", mods = "CTRL|SHIFT", action = wezterm.action_callback(theme_switcher.theme_switcher) },

  -- Open a new tab
  { key = "T", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
}

-- Mouse bindings: mimic Windows Terminal copy/paste behavior
config.mouse_bindings = {
  -- Triple-click selects the entire semantic zone (e.g. command output block)
  {
    event = { Down = { streak = 3, button = "Left" } },
    action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
    mods = "NONE",
  },
  -- Right-click: copy if text is selected, otherwise paste from clipboard
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action_callback(function(window, pane)
      local has_selection = window:get_selection_text_for_pane(pane) ~= ""
      if has_selection then
        window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
      end
    end),
  },
}

return config
