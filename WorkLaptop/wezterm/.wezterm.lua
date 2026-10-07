local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- Persisted theme: the Ctrl+Shift+S switcher writes the chosen scheme here,
-- and it is read back on startup so the choice survives restarts.
local theme_file = wezterm.config_dir .. "/.wezterm-theme"

local function read_saved_scheme()
  local f = io.open(theme_file, "r")
  if not f then return nil end
  local name = f:read("*l")
  f:close()
  if name and name ~= "" then return name end
  return nil
end

local function save_scheme(name)
  local f = io.open(theme_file, "w")
  if not f then return end
  f:write(name)
  f:close()
end

-- Launch Git Bash directly. Zellij is no longer the default program, because a
-- multiplexer layer blocks the terminal image protocol that yazi needs for
-- previews. Zellij is still installed: type `zellij` to start a session,
-- `zellij ls` to list detached ones, and `zellij a` to reattach.
-- To go back to the old behavior, use this line instead:
--   config.default_prog = { "C:/Users/CongHa/AppData/Local/zellij/zellij.exe" }
config.default_prog = { "C:/Program Files/Git/bin/bash.exe", "-i", "-l" }
config.default_cwd = "C:/Users/CongHa"

-- Color scheme: saved choice (Ctrl+Shift+S) wins, else this default.
config.color_scheme = read_saved_scheme() or "Ayu Mirage"

-- Font: Hack Nerd Font (installed via oh-my-posh)
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

-- Theme switcher: fuzzy-search and apply any built-in color scheme.
-- Inlined (no external module). The chosen scheme applies immediately via
-- config overrides and is saved to disk so it persists across restarts.
local function theme_switcher(window, pane)
  local choices = {}
  for name, _ in pairs(wezterm.color.get_builtin_schemes()) do
    table.insert(choices, { label = name })
  end
  table.sort(choices, function(a, b) return a.label < b.label end)

  window:perform_action(
    act.InputSelector({
      title = "Pick a color scheme",
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(inner_window, _, _, label)
        if label then
          inner_window:set_config_overrides({ color_scheme = label })
          save_scheme(label)
        end
      end),
    }),
    pane
  )
end

-- oh-my-posh prompt theme switcher: fuzzy-pick an installed .omp.json theme,
-- apply it live in the focused bash pane, and persist it to ~/.poshtheme so
-- future shells use it. The pane must be at a bash prompt when triggered
-- (this types a command into it).
local function posh_theme_switcher(window, pane)
  local choices = {}
  for _, path in ipairs(wezterm.glob("C:/Program Files (x86)/oh-my-posh/themes/*.omp.json")) do
    local name = path:match("([^/\\]+)%.omp%.json$")
    if name then
      table.insert(choices, { label = name })
    end
  end
  table.sort(choices, function(a, b) return a.label < b.label end)

  window:perform_action(
    act.InputSelector({
      title = "Pick an oh-my-posh prompt theme",
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(_, inner_pane, _, label)
        if label then
          inner_pane:send_text(
            "echo '" .. label .. "' > ~/.poshtheme && "
              .. 'eval "$(oh-my-posh init bash --config "$POSH_THEMES_PATH/'
              .. label .. '.omp.json")"\r'
          )
        end
      end),
    }),
    pane
  )
end

-- Disable all default keybindings and define custom ones
config.disable_default_key_bindings = true
config.keys = {
  -- Clipboard: paste from system clipboard
  { key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },

  -- Panes: WezTerm owns them again, because Zellij is no longer the default
  -- program. Splits use the same CTRL|SHIFT prefix as the other bindings.
  -- Physical keys, because SHIFT changes the mapped key to "|" and "_".
  { key = "phys:Backslash", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "phys:Minus", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Move focus between panes
  { key = "LeftArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },

  -- Resize the focused pane
  { key = "LeftArrow", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Left", 3 }) },
  { key = "RightArrow", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Right", 3 }) },
  { key = "UpArrow", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Up", 3 }) },
  { key = "DownArrow", mods = "CTRL|SHIFT|ALT", action = act.AdjustPaneSize({ "Down", 3 }) },

  -- Zoom the focused pane to full window, and back
  { key = "Z", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState },

  -- Pick a pane by label, then focus it
  { key = "I", mods = "CTRL|SHIFT", action = act.PaneSelect({ mode = "Activate" }) },

  -- Swap the focused pane with a pane you pick
  { key = "X", mods = "CTRL|SHIFT", action = act.PaneSelect({ mode = "SwapWithActive" }) },

  -- Tab navigation: cycle through open tabs
  { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
  { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },

  -- Command palette: search and run any WezTerm command
  { key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },

  -- Close the current pane (prompts for confirmation)
  { key = "W", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },

  -- Theme switcher: fuzzy-search and apply a built-in color scheme
  { key = "S", mods = "CTRL|SHIFT", action = wezterm.action_callback(theme_switcher) },

  -- oh-my-posh prompt theme switcher (types into the focused bash prompt)
  { key = "O", mods = "CTRL|SHIFT", action = wezterm.action_callback(posh_theme_switcher) },

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
