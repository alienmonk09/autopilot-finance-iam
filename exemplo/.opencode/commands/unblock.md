---
description: Destrava uma task marcada [!] quebrando-a em subtasks menores (uso — /unblock 3.2)
agent: coordinator
---
Execute o "Destravamento" de AGENTS.md para a task $ARGUMENTS. Não pergunte nada.

Histórico de travamentos dessa task (docs/BLOCKED.md):
!`perl -ne 'BEGIN{$id=shift} if(/^## \Q$id\E( |$)/){$p=1;print;next} $p=0 if /^## /; print if $p' "$1" docs/BLOCKED.md`

Linha atual no ROADMAP:
!`grep -E "^- \[!\] $1 " docs/ROADMAP.md || echo "(não encontrada como [!])"`

Ao terminar, responda em até 5 linhas: diagnóstico, subtasks criadas (ids), ou "DESISTIDA" se for o segundo travamento.
