#!/usr/bin/env bash
# Normaliza docs/reports/fase-N.md: primeira linha "Review #k", última "Veredito: X".
# k = 2 se já existe um review dessa fase commitado no git (HEAD), senão 1. O cabeçalho que o
# coordinator escreve no corpo NÃO conta (senão o 1º review sempre viraria #2).
# Uso: scripts/mark-review.sh N APROVADA|REPROVADA   (o corpo já deve estar gravado no arquivo)
set -euo pipefail
cd "$(dirname "$0")/.."
n=${1:?uso: mark-review.sh N APROVADA|REPROVADA}
v=$(printf '%s' "${2:?}" | tr a-z A-Z)
case "$v" in APROVADA|REPROVADA) ;; *) echo "veredito inválido: $2"; exit 1;; esac
f="docs/reports/fase-$n.md"
[ -f "$f" ] || { echo "$f não existe — grave o corpo do review antes"; exit 1; }
k=1
git cat-file -e "HEAD:$f" 2>/dev/null && k=2
body=$(grep -viE '^(#* *)?review #[0-9]+' "$f" | grep -viE '^(#* *)?\**veredito:' || true)
{ echo "Review #$k"; echo; printf '%s\n' "$body"; echo; echo "Veredito: $v"; } > "$f"
echo "$f: Review #$k, Veredito: $v"
