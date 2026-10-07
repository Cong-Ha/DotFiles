# Packages

These tools are installed on the work laptop. The configs in this folder need them.

## winget

```powershell
winget install sxyazi.yazi
winget install junegunn.fzf
winget install sharkdp.fd
winget install jqlang.jq
winget install Gyan.FFmpeg
winget install oschwartz10612.Poppler
winget install BurntSushi.ripgrep.MSVC
```

## Other sources

- WezTerm: installed to `C:\Program Files\WezTerm` (https://wezterm.org).
- GlazeWM and Zebar: installed to `C:\Program Files\glzr.io` (https://glazewm.com).
- Zellij: `%LOCALAPPDATA%\Zellij\zellij.exe` (https://zellij.dev).
- oh-my-posh: installed to `C:\Program Files (x86)\oh-my-posh`. The bash and PowerShell profiles use this path.
- zoxide: chocolatey (`choco install zoxide`).
- Git for Windows: WezTerm starts `C:\Program Files\Git\bin\bash.exe`.
- Hack Nerd Font: install it with `oh-my-posh font install Hack`. WezTerm uses it.
- Node.js: installed with nvm4w. The Claude Code status line needs it.
