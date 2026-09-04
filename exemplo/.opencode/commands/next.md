---
description: Executa UM ciclo de task do roadmap (gate de fase → delegar → check → commit → marcar)
agent: coordinator
---
Execute exatamente UM "Ciclo de uma task" conforme AGENTS.md. Não pergunte nada; não espere humano.

Próxima task:
!`scripts/next-task.sh`

Gate da fase dessa task:
!`scripts/phase-gate.sh`

Se o gate disser `NEEDS_REVIEW N`: faça SÓ o "Review de fase" da fase N, commite e encerre (a task será executada no próximo ciclo). Se disser `OK`: execute a task.

Tasks travadas/substituídas (não geram corretiva no review; não são implementadas):
!`grep -E '^- \[[!-]\] ' docs/ROADMAP.md || echo "(nenhuma)"`

Aprendizados recentes (docs/PROGRESS.md, use ao montar o prompt de delegação):
!`tail -n 40 docs/PROGRESS.md 2>/dev/null || echo "(nenhum)"`

Dicas do humano (docs/HINTS.md — têm prioridade sobre suposições suas):
!`[ -s docs/HINTS.md ] && cat docs/HINTS.md || echo "(nenhuma)"`

Ao terminar, responda em até 5 linhas: task, resultado do check, commit feito, próxima task.
