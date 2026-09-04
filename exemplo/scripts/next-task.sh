#!/usr/bin/env bash
# Imprime a próxima task pendente do ROADMAP: "N.M | texto | fase: <título>". Ou "NONE".
set -euo pipefail
cd "$(dirname "$0")/.."
line=$(grep -m1 -nE '^- \[ \] [0-9]+\.[A-Za-z]*[0-9]+[A-Za-z]* ' docs/ROADMAP.md || true)
[ -z "$line" ] && { echo "NONE"; exit 0; }
n=${line%%:*}
text=$(printf '%s' "$line" | sed -E 's/^[0-9]+:- \[ \] //')
id=${text%% *}
phase=$(head -n "$n" docs/ROADMAP.md | grep -E '^## Fase' | tail -1)
echo "$id | $text | $phase"
