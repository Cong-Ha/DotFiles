#!/usr/bin/env bash
# Provider: GlazeWM. Prints Group<TAB>Key<TAB>Action from the keybindings section.
# Source: ~/.glzr/glazewm/config.yaml. Override with KEYS_GLAZEWM_CONFIG.
set -u

cfg="${KEYS_GLAZEWM_CONFIG:-$HOME/.glzr/glazewm/config.yaml}"
[ -f "$cfg" ] || exit 0

awk '
function quoted(s,   out, item) {
	out = ""
	while (match(s, /'\''[^'\'']*'\''|"[^"]*"/)) {
		item = substr(s, RSTART + 1, RLENGTH - 2)
		out = (out == "" ? item : out SUBSEP item)
		s = substr(s, RSTART + RLENGTH)
	}
	return out
}
/^keybindings:/ { in_section = 1; next }
in_section && /^[A-Za-z_]+:/ { in_section = 0 }
!in_section { next }
{ trimmed = $0; gsub(/^[ \t]+|[ \t]+$/, "", trimmed) }
trimmed ~ /^(- )?commands:/ {
	cmds = quoted(trimmed)
	n = split(cmds, c, SUBSEP)
	action = ""
	for (i = 1; i <= n; i++) action = (action == "" ? c[i] : action "; " c[i])
	group = c[1]
	sub(/[ -].*/, "", group)          # first word, cut at the first dash
	if (group == "wm") group = "WM"
	else group = toupper(substr(group, 1, 1)) substr(group, 2)
	next
}
trimmed ~ /^bindings:/ {
	if (action == "") next
	keys = quoted(trimmed)
	n = split(keys, k, SUBSEP)
	for (i = 1; i <= n; i++) printf "%s\t%s\t%s\n", group, k[i], action
	action = ""
}
'  "$cfg"
