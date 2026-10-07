#!/usr/bin/env bash
# Provider: Zellij. Prints Group<TAB>Key<TAB>Action, one group per input mode.
# Source: `zellij setup --dump-config`. Override with KEYS_ZELLIJ_CMD.
set -u

cmd="${KEYS_ZELLIJ_CMD:-}"
if [ -z "$cmd" ]; then
	command -v zellij >/dev/null 2>&1 || exit 0
	cmd="zellij setup --dump-config"
fi

eval "$cmd" 2>/dev/null | awk '
{ line = $0 }
{ trimmed = line; gsub(/^[ \t]+|[ \t]+$/, "", trimmed) }
trimmed ~ /^\/\// { next }                       # commented-out binding
!in_keybinds && trimmed ~ /^keybinds[ \t]*\{/ { in_keybinds = 1; depth = 1; next }
!in_keybinds { next }
{
	# Track nesting so the section ends at its own closing brace.
	opens = gsub(/\{/, "{", trimmed)
	closes = gsub(/\}/, "}", trimmed)
}
trimmed ~ /^bind / {
	keypart = trimmed
	sub(/\{.*/, "", keypart)
	keys = ""
	while (match(keypart, /"[^"]*"/)) {
		k = substr(keypart, RSTART + 1, RLENGTH - 2)
		keys = (keys == "" ? k : keys " / " k)
		keypart = substr(keypart, RSTART + RLENGTH)
	}
	action = trimmed
	sub(/^[^{]*\{[ \t]*/, "", action)
	sub(/[ \t]*\}[ \t]*$/, "", action)
	gsub(/;[ \t]*$/, "", action)
	if (keys != "" && action != "") printf "%s\t%s\t%s\n", mode, keys, action
	next
}
{
	# A mode opens a block one level inside keybinds.
	if (opens > closes && depth == 1 && trimmed ~ /^[A-Za-z_]+[ \t]*\{/) {
		mode = trimmed
		sub(/[ \t]*\{.*/, "", mode)
	}
	depth += opens - closes
	if (depth <= 0) exit
}
'
