#!/usr/bin/env bash
# Marca a task N.M como travada ([!]) e registra em docs/BLOCKED.md.
# Uso: scripts/mark-blocked.sh N.M "último erro em uma linha"
set -euo pipefail
cd "$(dirname "$0")/.."
id=${1:?uso: mark-blocked.sh N.M "erro"}
err=${2:-"(sem detalhe)"}
esc=${id//./\\.}
grep -qE "^- \[ \] $esc " docs/ROADMAP.md || { echo "task $id não encontrada como pendente"; exit 1; }
perl -pi -e "s/^- \[ \] ($esc )/- [!] \$1/" docs/ROADMAP.md
{
  echo
  echo "## $id"
  echo "- quando: $(date '+%Y-%m-%d %H:%M')"
  echo "- erro: $err"
} >> docs/BLOCKED.md
echo "travada: $id"
