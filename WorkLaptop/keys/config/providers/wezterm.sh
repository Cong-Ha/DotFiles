#!/usr/bin/env bash
# Provider: WezTerm. Prints Group<TAB>Key<TAB>Action for the default key table.
# Source: `wezterm show-keys`. Override with KEYS_WEZTERM_CMD (used by the tests).
set -u

cmd="${KEYS_WEZTERM_CMD:-}"
if [ -z "$cmd" ]; then
	command -v wezterm >/dev/null 2>&1 || exit 0
	cmd="wezterm show-keys"
fi

eval "$cmd" 2>/dev/null | awk -F' -> ' '
/^Default key table/ { in_default = 1; next }
/^Key Table:/        { in_default = 0; next }
!in_default          { next }
$0 !~ / -> /         { next }
{
	left = $1
	action = $2
	gsub(/^[ 	]+|[ 	]+$/, "", action)

	# --- key: "SHIFT | ALT | CTRL   LeftArrow" -> "Ctrl+Shift+Alt+LeftArrow"
	gsub(/\|/, " ", left)
	n = split(left, t, /[ \t]+/)
	key = ""
	ctrl = shift = alt = super = 0
	for (i = 1; i <= n; i++) {
		if (t[i] == "")           continue
		else if (t[i] == "CTRL")  ctrl = 1
		else if (t[i] == "SHIFT") shift = 1
		else if (t[i] == "ALT")   alt = 1
		else if (t[i] == "SUPER") super = 1
		else                      key = t[i]
	}
	if (key == "") next
	# WezTerm prints an uppercase letter for a binding that needs Shift.
	if (key ~ /^[A-Z]$/) shift = 1
	mods = ""
	if (ctrl)  mods = mods "Ctrl+"
	if (shift) mods = mods "Shift+"
	if (alt)   mods = mods "Alt+"
	if (super) mods = mods "Super+"

	# --- action: drop the noisy argument lists
	sub(/\(SpawnCommand domain=[^)]*\)/, "", action)
	if (action ~ /^PaneSelect/) {
		mode = action
		sub(/.*mode: /, "", mode)
		sub(/[,}].*/, "", mode)
		action = "PaneSelect(" mode ")"
	}
	if (action ~ /\{ confirm: true \}/) {
		sub(/ *\{ confirm: true \}/, "(confirm)", action)
	}
	gsub(/^[ \t]+|[ \t]+$/, "", action)

	# --- group, from the action name only: SpawnTab(CurrentPaneDomain) is a tab
	head = action
	sub(/[( {].*/, "", head)
	if (head ~ /Pane|Split/)      group = "Panes"
	else if (head ~ /Tab/)        group = "Tabs"
	else if (head ~ /Paste|Copy/) group = "Clipboard"
	else                          group = "Other"

	printf "%s\t%s%s\t%s\n", group, mods, key, action
}
'
