#!/usr/bin/env bash
# Registra um aprendizado em docs/PROGRESS.md (append-only, uma linha ≤ 300 chars, sem narrativa).
# Uso: scripts/note.sh N.M "Filament 5 usa X em vez de Y"
set -euo pipefail
cd "$(dirname "$0")/.."
id=${1:?uso: note.sh N.M "texto"}
text=$(printf '%s' "${2:?texto obrigatório}" | tr '\n' ' ' | sed -E 's/^ +| +$//g' | cut -c1-300)
[ -z "$text" ] && exit 0
printf -- '- [%s] %s\n' "$id" "$text" >> docs/PROGRESS.md
echo "anotado: $text"
