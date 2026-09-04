---
description: Roda o review de uma fase já concluída e grava docs/reports/fase-N.md (uso — /review 2)
agent: coordinator
---
Execute o "Review de fase" de AGENTS.md para a fase $ARGUMENTS: delegue ao `reviewer`, grave o corpo do relatório em docs/reports/fase-$ARGUMENTS.md, rode `scripts/mark-review.sh $ARGUMENTS <APROVADA|REPROVADA>`, crie tasks corretivas no ROADMAP se houver FALHA (nunca para item já coberto por task `[!]` ou `[-]`), commite e pare.

Tasks travadas/substituídas na fase (não geram corretiva):
!`grep -E "^- \[[!-]\] $1\." docs/ROADMAP.md || echo "(nenhuma)"`

Progresso:
!`scripts/status.sh`
