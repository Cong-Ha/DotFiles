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
| `WorkLaptop/keys/bin/keys` | `~/.local/bin/keys` |
| `WorkLaptop/keys/config/` | `~/.config/keys/` |
| `WorkLaptop/claude/skills/pr-description/`, `simple-english/` | `~/.claude/skills/` |

Notes:
- `git/.gitconfig` has the email replaced with `<your-email>`. Set it after you copy the file.
- `bash/dotfiles.sh` goes in `~/.bashrc.d/`, because Bazzite's `~/.bashrc` sources every file there. Do not replace `~/.bashrc`.
- `wezterm/.wezterm-theme` and `bash/.poshtheme` are state files. The theme pickers in WezTerm (Ctrl+Shift+S and Ctrl+Shift+O) write them.
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

### Claude Code plugins

Same as WorkLaptop. See `WorkLaptop/README.md`. The status line needs `node` on PATH.
