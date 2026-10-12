# Bazzite

Snapshot of the configs on the Bazzite desktop (Fedora Atomic, GNOME on Wayland). They are adapted from `WorkLaptop/`.

Sync is manual. To apply a file, copy it to its live path.

## File map

| Repo file | Live path |
|---|---|
| `wezterm/wezterm.lua` | `~/.config/wezterm/wezterm.lua` |
| `wezterm/.wezterm-theme` | `~/.config/wezterm/.wezterm-theme` |
| `bash/dotfiles.sh` | `~/.bashrc.d/dotfiles.sh` |
| `bash/.poshtheme` | `~/.poshtheme` |
| `git/.gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `claude/statusline.mjs` | `~/.claude/statusline.mjs` |
| `claude/plugins.json` | Merge into `~/.claude/settings.json` |
| `gnome/paperwm.ini` | dconf `/org/gnome/shell/extensions/paperwm/` (see below) |
| `WorkLaptop/keys/bin/keys` | `~/.local/bin/keys` |
| `WorkLaptop/keys/config/` | `~/.config/keys/` |
| `WorkLaptop/claude/skills/pr-description/`, `simple-english/` | `~/.claude/skills/` |

Notes:
- `git/.gitconfig` has the email replaced with `<your-email>`. Set it after you copy the file.
- `bash/dotfiles.sh` goes in `~/.bashrc.d/`, because Bazzite's `~/.bashrc` sources every file there. Do not replace `~/.bashrc`.
- `wezterm/.wezterm-theme` and `bash/.poshtheme` are state files. The theme pickers in WezTerm (Ctrl+Shift+S and Ctrl+Shift+O) write them.
- `gnome/paperwm.ini` is a `dconf dump`, not a file on disk. It opens every new window at full width and sets a 5px active-window border with rounded corners.
- The `dotfiles-backup` skill is not installed here. It backs up the Windows paths into `WorkLaptop/`.

## Differences from WorkLaptop

- WezTerm: no `default_prog` (the Flatpak starts the host bash), no Windows backdrop or GlazeWM renderer settings, and `window_background_opacity = 0.85`.
- WezTerm: `enable_wayland = false`. The 20240203 Flatpak crashes on GNOME Wayland with "Error while flushing display: Broken pipe".
- bash: sets `POSH_THEMES_PATH`, because newer oh-my-posh does not set it.
- Not used here: GlazeWM, Zebar, PowerShell, Windows Terminal, and Zellij.

## Install

### Flatpak

```sh
flatpak install flathub org.wezfurlong.wezterm
# X11 access, needed for enable_wayland = false
flatpak override --user --socket=x11 org.wezfurlong.wezterm
# read the oh-my-posh themes for the Ctrl+Shift+O picker
flatpak override --user --filesystem=/home/linuxbrew:ro org.wezfurlong.wezterm
```

### Homebrew

```sh
brew install zoxide oh-my-posh yazi fd node
```

fzf, ripgrep, jq, FFmpeg, and Poppler come with Bazzite.

### Font

Hack Nerd Font, in `~/.local/share/fonts`:

```sh
mkdir -p ~/.local/share/fonts/HackNerdFont
curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz \
  | tar -xJ -C ~/.local/share/fonts/HackNerdFont --wildcards '*.ttf'
fc-cache -f
```

### PaperWM

PaperWM is a scrolling window manager for GNOME. Windows sit in a row from left to right. Each new window opens at full width next to the current window, and the view scrolls to it. Windows do not shrink to fit.

1. Turn off Tiling Shell, which comes with Bazzite. The two extensions conflict.
2. Install PaperWM from https://extensions.gnome.org/extension/6099/paperwm/ or the Extension Manager app.
3. Load the settings.

```sh
gnome-extensions disable tilingshell@ferrarodomenico.com
# load
dconf load /org/gnome/shell/extensions/paperwm/ < gnome/paperwm.ini
# save
dconf dump /org/gnome/shell/extensions/paperwm/ > gnome/paperwm.ini
```

After you save, keep only the `selection-border-*` and `winprops` lines. PaperWM writes the `restore-*`, `last-used-display-server`, and `[workspaces]` entries, and they are specific to one install.

The border color is the GNOME accent color (Settings > Appearance). While PaperWM is on, it replaces some GNOME shortcuts, for example Super+Left and Super+Right. It puts them back when you turn it off.

#### PaperWM shortcuts

These are the PaperWM defaults. Super is the Windows key.

Move between windows:

| Shortcut | Action |
|---|---|
| Super+Left / Super+Right | Go to the window on the left / right |
| Super+Up / Super+Down | Go to the window above / below (in a stacked column) |
| Super+, / Super+. | Go to the previous / next window |
| Super+Home / Super+End | Go to the first / last window |
| Super+Tab / Alt+Tab | Switch windows (add Shift to go back) |

Move windows:

| Shortcut | Action |
|---|---|
| Super+Ctrl+Left / Super+Ctrl+Right | Move the window left / right in the row (also Super+Shift+, and Super+Shift+.) |
| Super+Ctrl+Up / Super+Ctrl+Down | Move the window up / down in a stacked column |
| Super+[ / Super+] | Drift the window left / right |
| Super+I | Stack the next window into this column (slurp in) |
| Super+O | Take the bottom window out of this column (barf out) |
| Super+Shift+O | Take the active window out of its column |
| Super+T | Take the window: it follows you to another place, press again to drop it |

Size and position:

| Shortcut | Action |
|---|---|
| Super+F | Toggle full width |
| Super+Shift+F | Toggle fullscreen |
| Super+R | Cycle width: 38%, 50%, 62% (Super+Alt+R goes back) |
| Super+Shift+R | Cycle height in a stacked column (Super+Alt+Shift+R goes back) |
| Super+- / Super++ | Make the window narrower / wider |
| Super+Shift+- / Super+Shift++ | Make the window shorter / taller |
| Super+C | Center the window horizontally |
| Super+V | Center the window vertically |
| Super+Shift+C | Switch focus mode (default or centered) |
| Super+Shift+W | Change where new windows open |

Windows and workspaces:

| Shortcut | Action |
|---|---|
| Super+Return / Super+N | Open a new window of the current app |
| Super+Backspace | Close the window (Alt+F4 also works) |
| Super+Page Up / Super+Page Down | Go to the workspace above / below |
| Super+Ctrl+Page Up / Super+Ctrl+Page Down | Move the window to the workspace above / below |
| Super+\` (the key above Tab) | Go to the previous workspace (add Shift to go back) |
| Super+Ctrl+\` (the key above Tab) | Move the window to the previous workspace |
| Super+Ctrl+B | Toggle the top bar and position bar |

Scratch layer (floating windows on top of the row):

| Shortcut | Action |
|---|---|
| Super+Escape | Move the window to or from the scratch layer |
| Super+Shift+Escape | Show or hide the scratch layer |
| Super+Ctrl+Escape | Show or hide the most recent scratch window |
| Alt+Ctrl+Tab | Switch between scratch windows (add Shift to go back) |

Multiple monitors:

| Shortcut | Action |
|---|---|
| Super+Shift+Arrow | Go to the monitor in that direction |
| Super+Shift+Ctrl+Arrow | Move the window to the monitor in that direction |
| Super+Alt+Arrow | Swap workspaces with the monitor in that direction |
| Ctrl+Alt+Shift+Arrow | Move the workspace to the monitor in that direction |

### Claude Code plugins

Same as WorkLaptop. See `WorkLaptop/README.md`. The status line needs `node` on PATH.
