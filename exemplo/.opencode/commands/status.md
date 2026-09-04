---
description: Mostra progresso do roadmap, próxima task, bloqueios e último commit
agent: coordinator
---
Apenas resuma o estado abaixo em até 6 linhas. Não execute nenhuma task.

!`scripts/status.sh`

Próxima task:
!`scripts/next-task.sh`

Bloqueio:
!`cat docs/BLOCKED.md 2>/dev/null || echo "(vazio)"`

Último commit:
!`git log -1 --oneline 2>/dev/null || echo "(sem commits)"`
