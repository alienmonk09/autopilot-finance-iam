---
description: Executa ciclos de task em sequência dentro de UMA sessão até fechar a fase atual (uso manual; o autopilot usa /next por processo)
agent: coordinator
---
Repita o "Ciclo de uma task" de AGENTS.md até que a fase atual não tenha mais checkbox `[ ]`. Tasks travadas (`[!]`) são puladas. Não inicie a fase seguinte. Não pergunte nada.

Estado atual:
!`scripts/next-task.sh`

Progresso:
!`scripts/status.sh`

Ao final, responda em até 10 linhas: tasks concluídas, tasks travadas, próxima task.
