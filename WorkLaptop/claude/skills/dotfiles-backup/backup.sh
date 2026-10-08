#!/usr/bin/env bash
# Copy the live configs into DotFiles/WorkLaptop, remove company data, and scan.
# It does not commit or push. Exit 1 if a file is missing, exit 2 if the scan finds a match.
set -euo pipefail

REPO="${1:-$HOME/Documents/DotFiles}"
DEST="$REPO/WorkLaptop"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$SKILL_DIR/manifest.tsv"

missing=0
while IFS=$'\t' read -r live repo; do
  [[ -z "$live" || "$live" == \#* ]] && continue
  src="$HOME/$live"
  dst="$DEST/$repo"
  if [[ "$live" == */ ]]; then
    if [[ ! -d "$src" ]]; then
      # Optional folders (for example the yazi config) can be absent.
      echo "skip (no folder): $live"
      continue
    fi
    rm -rf "$dst"
    mkdir -p "$(dirname "$dst")"
    cp -r "${src%/}" "$dst"
  else
    if [[ ! -f "$src" ]]; then
      echo "MISSING: $live"
      missing=1
      continue
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
done < "$MANIFEST"

# Remove company data from the repo copies. The live files do not change.
sed -i -E 's/^(\s*email\s*=).*/\1 <your-email>/' "$DEST/git/.gitconfig"
if [[ -f "$DEST/claude/skills/pr-description/SKILL.md" ]]; then
  sed -i 's/ (`getJiraIssue`, cloudId from CLAUDE.md)//' "$DEST/claude/skills/pr-description/SKILL.md"
fi

# Keep only public plugins and GitHub marketplaces from settings.json.
python - "$HOME/.claude/settings.json" "$DEST/claude/plugins.json" <<'EOF'
import json, re, sys
src, dst = sys.argv[1], sys.argv[2]
s = json.load(open(src, encoding="utf-8"))
deny = re.compile(r"korterra|atlassian", re.I)
markets = {
    name: m for name, m in s.get("extraKnownMarketplaces", {}).items()
    if m.get("source", {}).get("source") == "github" and not deny.search(name)
}
allowed_markets = set(markets) | {"claude-plugins-official"}
# Sorted, so that the file changes only when the plugin set changes.
plugins = {
    p: v for p, v in sorted(s.get("enabledPlugins", {}).items())
    if not deny.search(p) and p.split("@")[-1] in allowed_markets
}
out = {"statusLine": s.get("statusLine"), "enabledPlugins": plugins, "extraKnownMarketplaces": markets}
with open(dst, "w", encoding="utf-8", newline="\n") as f:
    json.dump(out, f, indent=2)
EOF

# Scan for company data and secrets.
pattern='korterra|kordev|@korterra|cloudId|accountId|OTEL_|9b1431bd|712020|token\s*[=:]|password\s*[=:]|apikey|bearer '
if grep -rinE "$pattern" "$DEST" --exclude=backup.sh; then
  echo "SCAN FAILED: remove the matches above before you commit."
  exit 2
fi
echo "scan clean"
exit "$missing"
