#!/usr/bin/env bash
# Decide se a fase da próxima task está liberada.
# Saída: OK | NEEDS_REVIEW <N>   (N = fase que precisa de review antes de seguir)
# Uso: scripts/phase-gate.sh [fase]   (sem argumento: fase da próxima task pendente)
set -uo pipefail
cd "$(dirname "$0")/.."

phase=${1:-}
if [ -z "$phase" ]; then
  next=$(scripts/next-task.sh)
  [ "$next" = "NONE" ] && { echo "OK"; exit 0; }
  phase=$(printf '%s' "$next" | sed -E 's/^([0-9]+)\..*/\1/')
fi
[ "$phase" -eq 0 ] && { echo "OK"; exit 0; }

prev=$((phase - 1))
report="docs/reports/fase-$prev.md"

# Fase anterior ainda tem task pendente (corretiva N.Fx ou normal)? Então segue nela, sem review.
if grep -qE "^- \[ \] $prev\.[A-Za-z]*[0-9]+[A-Za-z]* " docs/ROADMAP.md; then echo "OK"; exit 0; fi

[ -f "$report" ] || { echo "NEEDS_REVIEW $prev"; exit 0; }

# Tolerante a heading/negrito: "Veredito: APROVADA", "## Veredito: **REPROVADA**"...
verdict=$(grep -oiE 'veredito:[^A-Za-z]*(APROVADA|REPROVADA)' "$report" | tail -1 | grep -oiE 'APROVADA|REPROVADA' | tr a-z A-Z || true)
k=$(grep -m1 -oE 'Review #[0-9]+' "$report" | tr -dc '0-9' || true)
k=${k:-1}

[ -z "$verdict" ] && { echo "NEEDS_REVIEW $prev"; exit 0; }
[ "$verdict" = "APROVADA" ] && { echo "OK"; exit 0; }
# REPROVADA: se já houve 2 reviews, segue; se houve 1 e as corretivas acabaram, pede o segundo.
[ "$k" -ge 2 ] && { echo "OK"; exit 0; }
echo "NEEDS_REVIEW $prev"
