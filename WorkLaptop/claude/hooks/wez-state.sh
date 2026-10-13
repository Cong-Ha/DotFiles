#!/usr/bin/env bash
# Usage: wez-state.sh <working|waiting|done>
# Sets a badge as the WezTerm tab title of the current pane.
# Hooks have no tty on Windows, so this uses the WezTerm CLI and not OSC 1337.
# The format-tab-title handler in ~/.wezterm.lua shows the badge in front of the pane title.
[ -n "${WEZTERM_PANE:-}" ] || exit 0          # no-op outside WezTerm
command -v wezterm >/dev/null 2>&1 || exit 0

case "${1:-working}" in
  waiting) badge="🔴" ;;
  done)    badge="🟢" ;;
  *)       badge="" ;;
esac

wezterm cli set-tab-title --pane-id "$WEZTERM_PANE" "$badge" >/dev/null 2>&1 || true
exit 0
