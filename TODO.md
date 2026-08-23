# TODO

## Replace copies with symlinks

The files under `glazewm/`, `zebar/`, and `wezterm/` are currently **copies**
of the live configs. Any change you make here must be manually synced to the
real paths (or vice versa). To make this repo the single source of truth,
replace the live files with symbolic links back to here.

### Requirements

Windows Developer Mode must be enabled (so `New-Item -ItemType SymbolicLink`
works without needing an Administrator shell):

- Settings → Privacy & security → For developers → **Developer Mode = On**

### One-time setup (PowerShell)

```powershell
$repo = "$env:USERPROFILE\RiderProjects\DotFiles"

# Back up live files, just in case
Copy-Item "$env:USERPROFILE\.glzr\glazewm\config.yaml"  "$env:TEMP\glazewm.config.yaml.bak"
Copy-Item "$env:USERPROFILE\.glzr\zebar\settings.json"  "$env:TEMP\zebar.settings.json.bak"
Copy-Item "$env:USERPROFILE\.wezterm.lua"               "$env:TEMP\wezterm.lua.bak"

# Remove live files
Remove-Item "$env:USERPROFILE\.glzr\glazewm\config.yaml"
Remove-Item "$env:USERPROFILE\.glzr\zebar\settings.json"
Remove-Item "$env:USERPROFILE\.wezterm.lua"

# Create symlinks pointing at the repo
New-Item -ItemType SymbolicLink `
  -Path   "$env:USERPROFILE\.glzr\glazewm\config.yaml" `
  -Target "$repo\glazewm\config.yaml"

New-Item -ItemType SymbolicLink `
  -Path   "$env:USERPROFILE\.glzr\zebar\settings.json" `
  -Target "$repo\zebar\settings.json"

New-Item -ItemType SymbolicLink `
  -Path   "$env:USERPROFILE\.wezterm.lua" `
  -Target "$repo\wezterm\.wezterm.lua"
```

### Verify

```powershell
Get-Item "$env:USERPROFILE\.glzr\glazewm\config.yaml",
         "$env:USERPROFILE\.glzr\zebar\settings.json",
         "$env:USERPROFILE\.wezterm.lua" |
  Select-Object Name, LinkType, Target
```

Each row should show `LinkType = SymbolicLink` and `Target` pointing into
`RiderProjects\DotFiles\`.

Reload GlazeWM (`lalt+ralt+shift+r`), restart Zebar, and relaunch WezTerm to
confirm they pick up the linked files correctly.
