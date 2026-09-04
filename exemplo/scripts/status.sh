#!/usr/bin/env bash
# Progresso por fase. [ ] pendente · [x] feita · [!] travada · [-] substituída (não conta)
cd "$(dirname "$0")/.."
total=$(grep -cE '^- \[[ x!]\] [0-9]+\.[A-Za-z]*[0-9]+' docs/ROADMAP.md)
done_=$(grep -cE '^- \[x\] [0-9]+\.[A-Za-z]*[0-9]+' docs/ROADMAP.md)
blocked=$(grep -cE '^- \[!\] [0-9]+\.[A-Za-z]*[0-9]+' docs/ROADMAP.md)
echo "Total: $done_/$total tasks (travadas: $blocked)"
awk '/^## /{if(t)printf "%s: %d/%d%s\n",f,d,t,(b?" ["b" travada(s)]":""); f=$0; sub(/ \(.*/,"",f); t=0; d=0; b=0; next}
     /^- \[[ x!]\] [0-9]+\./{t++; if($0 ~ /^- \[x\]/)d++; if($0 ~ /^- \[!\]/)b++}
     END{if(t)printf "%s: %d/%d%s\n",f,d,t,(b?" ["b" travada(s)]":"")}' docs/ROADMAP.md
ls docs/reports/fase-*.md 2>/dev/null | while read -r f; do echo "review: $f — $(grep -E '^Veredito' "$f" | tail -1)"; done
