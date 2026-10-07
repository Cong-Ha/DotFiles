# oh-my-posh prompt (uses Hack Nerd Font glyphs; set font in your terminal)
# Theme name is read from ~/.poshtheme (written by WezTerm's Ctrl+Shift+O
# picker); falls back to tokyonight_storm. Available themes: ls "$POSH_THEMES_PATH"
if command -v oh-my-posh >/dev/null 2>&1; then
  _posh_theme="$(cat ~/.poshtheme 2>/dev/null)"
  [ -z "$_posh_theme" ] && _posh_theme="tokyonight_storm"
  eval "$(oh-my-posh init bash --config "$POSH_THEMES_PATH/$_posh_theme.omp.json")"
fi

# zoxide - smarter cd (defines the `z` command)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

# yazi - file manager; `y` exits into the last directory.
# yazi writes a Windows path (C:\...) to the cwd file, so convert it with
# cygpath before `cd`.
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  cwd="$(cat -- "$tmp")"
  if [ -n "$cwd" ]; then
    command -v cygpath >/dev/null 2>&1 && cwd="$(cygpath -u "$cwd")"
    [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ~/.local/bin holds personal scripts (the `keys` keybinding table, for example)
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac
