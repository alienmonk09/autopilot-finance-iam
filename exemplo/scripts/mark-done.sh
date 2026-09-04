#!/usr/bin/env bash
# Marca a task N.M como concluída no ROADMAP. Uso: scripts/mark-done.sh 0.3
set -euo pipefail
cd "$(dirname "$0")/.."
id=${1:?uso: mark-done.sh N.M}
esc=${id//./\\.}
grep -qE "^- \[ \] $esc " docs/ROADMAP.md || { echo "task $id não encontrada como pendente"; exit 1; }
perl -pi -e "s/^- \[ \] ($esc )/- [x] \$1/" docs/ROADMAP.md
echo "marcada: $id"
