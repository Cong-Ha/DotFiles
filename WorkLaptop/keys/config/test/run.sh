#!/usr/bin/env bash
# Tests for the `keys` command. Run: bash ~/.config/keys/test/run.sh
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX="$HERE/fixtures"
KEYS="$HOME/.local/bin/keys"
PROVIDERS="$HOME/.config/keys/providers"

pass=0; fail=0

ok() { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
no() { fail=$((fail+1)); printf '  FAIL %s\n     %s\n' "$1" "$2"; }

assert_eq() { # name expected actual
	if [ "$2" = "$3" ]; then ok "$1"; else no "$1" "expected [$2] got [$3]"; fi
}
assert_has() { # name needle haystack
	case "$3" in *"$2"*) ok "$1" ;; *) no "$1" "missing [$2] in output" ;; esac
}
assert_not() { # name needle haystack
	case "$3" in *"$2"*) no "$1" "unexpected [$2] in output" ;; *) ok "$1" ;; esac
}

export KEYS_WEZTERM_CMD="cat $FIX/wezterm-show-keys.txt"
export KEYS_ZELLIJ_CMD="cat $FIX/zellij-config.kdl"
export KEYS_GLAZEWM_CONFIG="$FIX/glazewm-config.yaml"

echo "== core =="

out="$(KEYS_NO_COLOR=1 "$KEYS" -l 2>&1)"
assert_eq "lists every provider, sorted" "glazewm
wezterm
yazi
zellij" "$out"

out="$(KEYS_NO_COLOR=1 "$KEYS" -p wezterm 2>&1)"
cols="$(printf '%s\n' "$out" | awk -F'\t' 'NF!=4{print NF; exit}')"
assert_eq "plain output has 4 tab columns" "" "$cols"

"$KEYS" nosuchprogram >/dev/null 2>&1
assert_eq "unknown provider exits 1" "1" "$?"

out="$(KEYS_WEZTERM_CMD="false" "$KEYS" -p wezterm 2>/dev/null; echo "rc=$?")"
assert_eq "absent program yields no rows, exit 0" "rc=0" "$out"

out="$(KEYS_NO_COLOR=1 "$KEYS" -p -s split wezterm 2>&1)"
bad="$(printf '%s\n' "$out" | grep -civ split)"
assert_eq "filter keeps only matching rows" "0" "$bad"
assert_has "filter is case-insensitive" "SplitVertical" "$out"

out="$(KEYS_NO_COLOR=1 "$KEYS" wezterm 2>&1)"
assert_has "table shows the program name" "wezterm" "$out"
assert_has "table shows a key" 'Ctrl+Shift+\' "$out"
assert_has "table draws a border" "─" "$out"

out="$(KEYS_NO_COLOR=1 "$KEYS" -p wezterm 2>&1 | cut -f2 | uniq | sort | uniq -d)"
assert_eq "each group forms one block" "" "$out"

out="$(KEYS_WIDTH=46 KEYS_NO_COLOR=1 "$KEYS" glazewm 2>&1)"
assert_not "wraps an action that does not fit" "move --direction right; focus --direction right" "$out"
full="$(KEYS_NO_COLOR=1 "$KEYS" -p glazewm 2>&1 | cut -f4 | tr -d ' 
')"
cells="$(printf '%s
' "$out" | awk -F'│' 'NF>3 {print $4}' | grep -v "^ *Action *$" | tr -d ' 
')"
assert_eq "wrapping loses no text" "$full" "$cells"
out="$(KEYS_WIDTH=200 KEYS_NO_COLOR=1 "$KEYS" glazewm 2>&1)"
assert_has "leaves a fitting action on one line" "move --direction right; focus --direction right" "$out"

echo "== wezterm provider =="

out="$(bash "$PROVIDERS/wezterm.sh" 2>&1)"
assert_has "joins modifiers with the key" "Ctrl+Shift+\\" "$out"
assert_has "keeps single-modifier bindings" "Ctrl+Tab" "$out"
assert_has "three modifiers stay in order" "Ctrl+Shift+Alt+LeftArrow" "$out"
assert_has "drops the SpawnCommand noise" "SplitVertical" "$out"
assert_not "drops the SpawnCommand argument" "SpawnCommand" "$out"
assert_has "shortens PaneSelect" "PaneSelect(Activate)" "$out"
assert_has "shortens CloseCurrentPane" "CloseCurrentPane(confirm)" "$out"
assert_not "ignores the copy_mode table" "MoveForwardWord" "$out"
assert_has "groups splits under Panes" "$(printf 'Panes\tCtrl+Shift+\')" "$out"
assert_has "groups tab actions under Tabs" "$(printf 'Tabs\tCtrl+Tab')" "$out"
assert_has "groups paste under Clipboard" "$(printf 'Clipboard\tCtrl+Shift+V')" "$out"
assert_has "groups by the action name, not its arguments" "$(printf 'Tabs	Ctrl+Shift+T	SpawnTab')" "$out"

echo "== zellij provider =="

out="$(bash "$PROVIDERS/zellij.sh" 2>&1)"
assert_has "uses the mode as the group" "$(printf 'pane\tCtrl p')" "$out"
assert_has "joins alternative keys" "h / Left" "$out"
assert_has "keeps the action" 'MoveFocus "Left"' "$out"
assert_has "joins chained actions" "NewPane; SwitchToMode" "$out"
assert_not "ignores commented binds" "Alt c" "$out"
assert_not "ignores non-keybind sections" "tab-bar" "$out"

echo "== glazewm provider =="

out="$(bash "$PROVIDERS/glazewm.sh" 2>&1)"
assert_has "pairs a binding with its command" "$(printf 'alt+h\tfocus --direction left')" "$out"
assert_has "lists every binding of a pair" "alt+shift+right" "$out"
assert_has "joins multiple commands" "move --direction right; focus --direction right" "$out"
assert_not "ignores keys outside keybindings" "startup_commands" "$out"

echo "== yazi provider =="

out="$(bash "$PROVIDERS/yazi.sh" 2>&1)"
assert_has "reads the bundled table" "$(printf 'Search\ts\t')" "$out"
assert_has "covers the tool-backed keys" "ripgrep" "$out"
rows="$(printf '%s\n' "$out" | awk -F'\t' 'NF!=3' | wc -l)"
assert_eq "every row has 3 columns" "0" "$rows"

echo
printf 'passed %d, failed %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
