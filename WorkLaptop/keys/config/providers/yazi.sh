#!/usr/bin/env bash
# Provider: yazi. Prints Group<TAB>Key<TAB>Action.
# yazi has no dump command, so the table is a data file kept next to this script.
# The file, not PATH, decides: if the table exists, the keys are shown.
# Override with KEYS_YAZI_TSV.
set -u

tsv="${KEYS_YAZI_TSV:-${KEYS_HOME:-$HOME/.config/keys}/yazi.tsv}"
[ -f "$tsv" ] || exit 0

grep -v '^[[:space:]]*$' -- "$tsv"
