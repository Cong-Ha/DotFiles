# WorkLaptop

Snapshot of the configs on the work laptop (Windows 11, user `CongHa`). The files are copied verbatim, so some contain `C:\Users\CongHa` and `C:\Program Files` paths.

Sync is manual. To apply a file, copy it to its live path.

## File map

| Repo file | Live path |
|---|---|
| `wezterm/.wezterm.lua` | `%USERPROFILE%\.wezterm.lua` |
| `wezterm/.wezterm-theme` | `%USERPROFILE%\.wezterm-theme` |
| `glazewm/config.yaml` | `%USERPROFILE%\.glzr\glazewm\config.yaml` |
| `glazewm/dynamic-bindings.ps1` | `%USERPROFILE%\.glzr\glazewm\dynamic-bindings.ps1` |
| `zebar/settings.json` | `%USERPROFILE%\.glzr\zebar\settings.json` |
| `zebar/.marketplace/*.json` | `%USERPROFILE%\.glzr\zebar\.marketplace\` |
| `keys/bin/keys` | `%USERPROFILE%\.local\bin\keys` |
| `keys/config/` | `%USERPROFILE%\.config\keys\` |
| `bash/.bashrc` | `%USERPROFILE%\.bashrc` |
| `bash/.bash_profile` | `%USERPROFILE%\.bash_profile` |
| `bash/.poshtheme` | `%USERPROFILE%\.poshtheme` |
| `powershell/Microsoft.PowerShell_profile.ps1` | `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| `powershell/powershell.config.json` | `%USERPROFILE%\Documents\PowerShell\powershell.config.json` |
| `zellij/config.kdl` | `%APPDATA%\Zellij\config\config.kdl` |
| `git/.gitconfig` | `%USERPROFILE%\.gitconfig` |
| `git/ignore` | `%USERPROFILE%\.config\git\ignore` |
| `windows-terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| `claude/statusline.mjs` | `%USERPROFILE%\.claude\statusline.mjs` |
| `claude/skills/*` | `%USERPROFILE%\.claude\skills\` |
| `claude/plugins.json` | Merge into `%USERPROFILE%\.claude\settings.json` |

Notes:
- `git/.gitconfig` has the email replaced with `<your-email>`. Set it after you copy the file.
- `wezterm/.wezterm-theme` and `bash/.poshtheme` are state files. The theme pickers in WezTerm (Ctrl+Shift+S and Ctrl+Shift+O) write them.
- Yazi has no config files. See `yazi/README.md`.
- To install the tools, see `packages.md`.

## Claude Code plugins

`claude/plugins.json` holds the plugin, marketplace, and status line keys from `settings.json`. To install the plugins from the command line:

```sh
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add ayghri/i-have-adhd
claude plugin install superpowers@claude-plugins-official
claude plugin install claude-md-management@claude-plugins-official
claude plugin install csharp-lsp@claude-plugins-official
claude plugin install typescript-lsp@claude-plugins-official
claude plugin install clangd-lsp@claude-plugins-official
claude plugin install i-have-adhd@i-have-adhd
```

The status line needs `node` on PATH.

## Not in this folder

- Secrets: the Zellij `tokens.db`, `.config\containers\auth.json`, `.claude\.credentials.json`, and `.claude.json`.
- Generated files: logs, `.bak` copies, Zebar downloads, and oh-my-posh caches.
- Company data: work skills, commands, rules, MCP servers, telemetry settings, and work plugins.
