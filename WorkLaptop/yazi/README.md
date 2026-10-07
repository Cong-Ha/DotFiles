# Yazi

Yazi runs with its default settings. There are no config files: `%APPDATA%\yazi\config` does not exist.

The yazi setup is in these files:
- `bash/.bashrc`: the `y` function. When you quit yazi, the shell changes to the last directory.
- `powershell/Microsoft.PowerShell_profile.ps1`: the same `y` function for PowerShell.
- `keys/config/yazi.tsv`: the keybindings that the `keys` command shows for yazi.

For previews, yazi uses fd, ripgrep, fzf, jq, zoxide, FFmpeg, and Poppler. See `packages.md`.

To customize yazi, put `yazi.toml`, `keymap.toml`, or `theme.toml` in `%APPDATA%\yazi\config`.
