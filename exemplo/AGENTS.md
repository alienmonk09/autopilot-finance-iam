# finance-iam — protocolo de trabalho dos agentes

Sistema de gestão de finanças pessoais em Laravel 13 + SQLite + Filament 5. Escopo completo em `docs/SPEC.md`. Progresso em `docs/ROADMAP.md`. Este arquivo define COMO o trabalho acontece. Leia inteiro antes de qualquer ação. O projeto roda em modo autônomo (`scripts/autopilot.sh`): nenhum passo espera humano.

## Estado do projeto

- `docs/ROADMAP.md` é a única fonte da verdade do progresso. Uma task = um checkbox:
  - `- [ ] N.M` pendente · `- [x] N.M` concluída · `- [!] N.M` travada (pulada pelo loop) · `- [-] N.M` substituída por subtasks (`N.Ma`, `N.Mb`...)
- `docs/SPEC.md` é a única fonte da verdade do escopo. Nada fora dele é implementado.
- `docs/QUESTIONS.md` registra ambiguidades da spec com a suposição adotada.
- `docs/BLOCKED.md` registra o histórico de tasks travadas (uma seção `## N.M` por travamento, com o que foi tentado e o último erro).
- `docs/reports/fase-N.md` é o review da fase N. Primeira linha: `Review #1` ou `Review #2`. Última linha: `Veredito: APROVADA` ou `Veredito: REPROVADA` (normalizado por `scripts/mark-review.sh`).
- `docs/PROGRESS.md` é a memória entre iterações: uma linha por aprendizado reutilizável, append-only via `scripts/note.sh`. Nunca narrativa.
- `docs/HINTS.md` são dicas do humano injetadas em todo `/next` enquanto tiver conteúdo. Têm prioridade sobre suposições dos agentes.
- `docs/notes/<pacote>.md` são resumos de documentação oficial gravados pelo implementer para reuso.

## Papéis

| Agente | Modo | Faz | NÃO faz |
|---|---|---|---|
| `coordinator` | primary | Lê o roadmap, delega uma task por vez ao `implementer`, roda `scripts/check.sh`, commita, marca o checkbox, aciona `reviewer` na troca de fase, destrava tasks | Não escreve código de produção nem testes |
| `implementer` | subagent | Implementa UMA task fechada (código + testes), roda `scripts/check.sh`, reporta | Não usa git, não marca checkbox, não toca em task além da pedida |
| `reviewer` | subagent (read-only) | Audita uma fase inteira contra o aceite dela e as regras da seção 3 do SPEC, produz relatório | Não edita nada |

## Ciclo de uma task (executado pelo `coordinator` a cada `/next`)

1. `scripts/next-task.sh` → próxima task pendente (`id | texto | fase`). Se `NONE`: roadmap concluído, pare.
2. `scripts/phase-gate.sh <fase da task>` → diz se a fase anterior está liberada:
   - `OK` → siga.
   - `NEEDS_REVIEW <N>` → execute SÓ o "Review de fase" da fase N, commite e encerre o ciclo. A task fica para o próximo `/next` (o gate pode ter criado corretivas que vêm antes dela).
3. Checkpoint: `git add -A && git commit -qm "chore: checkpoint antes de N.M" || true`.
4. Monte o prompt do `implementer` (modelo em "Prompt de delegação", incluindo os aprendizados relevantes de `docs/PROGRESS.md` e as dicas de `docs/HINTS.md`) e delegue via Task tool. Espere o report.
5. Rode `scripts/check.sh` VOCÊ MESMO. O placar reportado pelo implementer é ruído; só o seu resultado conta.
6. Verde → `scripts/mark-done.sh N.M`; para cada linha de "Aprendizados" do report: `scripts/note.sh N.M "<linha>"`; `git add -A && git commit -qm "feat(fase-N.M): <texto curto da task>"`. Fim do ciclo.
7. Vermelho → delegue de novo ao `implementer` colando SÓ as últimas 40 linhas da saída do check (o resto está em `logs/check.log`, diga ao implementer para ler), dizendo "corrija; não altere teste para passar sem implementação real". Máximo 3 tentativas por task dentro deste ciclo.
8. Após a 3ª falha → salve o que tem valor: `git add docs/notes docs/QUESTIONS.md docs/PROGRESS.md 2>/dev/null; git commit -qm "docs: notas de N.M" || true`; depois `git checkout -- . && git clean -fdq`, `scripts/mark-blocked.sh N.M "<último erro em 1 linha>"`, commite `chore: N.M travada`. Fim do ciclo (o loop externo decide o destravamento).

Nunca pule o passo 5. Nunca marque checkbox com check vermelho. Nunca faça duas tasks no mesmo ciclo. Commite tudo antes de responder: o loop reverte arquivos não commitados fora de `docs/`.

## Destravamento (executado pelo `coordinator` a cada `/unblock N.M`)

Objetivo: transformar uma task travada em 2 a 4 subtasks menores e independentes que somadas entregam a mesma coisa.

1. Leia a seção `## N.M` de `docs/BLOCKED.md` (o que foi tentado, erro) e a linha da task no ROADMAP.
2. Diagnostique em uma frase: escopo grande demais / API de pacote desconhecida / spec ambígua / teste errado.
3. Escreva as subtasks logo abaixo da linha travada, ids `N.Ma`, `N.Mb`, `N.Mc`... cada uma com aceite próprio na própria linha. Se a causa for API desconhecida, a primeira subtask é "consultar doc oficial de X via webfetch e gravar resumo em docs/notes/<pacote>.md". Se a causa for spec ambígua, registre a suposição em `docs/QUESTIONS.md` e escreva a subtask com a suposição explícita.
4. Troque `- [!] N.M` por `- [-] N.M` (substituída). Commite `chore: N.M destravada em subtasks`.
5. Se `docs/BLOCKED.md` já tem 2 seções `## N.M` (segundo travamento da mesma task ou de suas subtasks), NÃO destrave de novo: deixe `[!]`, acrescente em `docs/BLOCKED.md` a linha `DESISTIDA: precisa de humano` e pare. O loop segue para as próximas tasks.

## Review de fase (executado pelo `coordinator` quando `phase-gate.sh` pede)

1. Delegue ao `reviewer`: "Audite a fase N. Leia docs/SPEC.md (seções 3 e 6 e as seções da fase), docs/ROADMAP.md, e o código. Rode scripts/check.sh. Verifique cada item do aceite da fase e cada regra da seção 3 tocada pela fase. Liste OK / FALHA com evidência (arquivo:linha, teste). Tasks `[!]`/`[-]` da fase: <lista> — não são FALHA. Não edite nada."
2. Grave o texto devolvido em `docs/reports/fase-N.md` (pode sobrescrever) e rode `scripts/mark-review.sh N APROVADA` ou `scripts/mark-review.sh N REPROVADA` conforme o veredito do reviewer. O script normaliza `Review #k` e `Veredito:` e descobre k sozinho (2 se já houve review commitado dessa fase).
3. Se REPROVADA e k = 1: crie tasks corretivas no ROADMAP logo abaixo da última task da fase N, ids `N.F1`, `N.F2`..., uma por FALHA, cada uma com aceite na linha. NUNCA crie corretiva para item já coberto por task `[!]` ou `[-]` da fase (o humano decide sobre elas). Elas serão executadas pelo ciclo normal antes da fase N+1 (o `phase-gate.sh` pedirá um segundo review quando todas estiverem `[x]` ou `[!]`).
4. Se REPROVADA e k = 2: registre os gaps restantes como tasks `N.Gx` no FINAL do ROADMAP (seção `## Gaps acumulados`), não bloqueie a fase seguinte.
5. Commite `docs(fase-N): review #k` e encerre o ciclo.

## Prompt de delegação (modelo — preencher todos os campos)

```
# Task N.M
<linha exata do ROADMAP>

# Contexto obrigatório
- Leia docs/SPEC.md seções: <lista das seções relevantes, ex.: 1, 2.3, 2.4, 3.2, 3.3>
- Leia estes arquivos existentes: <lista fechada; se for greenfield, diga "nenhum">
- Aceite da fase: <copiar o texto entre parênteses do título da fase no ROADMAP>

# Escopo
Implemente SÓ esta task: <o que entra>. Fora de escopo: <o que NÃO entra, ex.: task N.M+1>.

# Regras
- NÃO use git para nada.
- NÃO edite docs/ROADMAP.md.
- Dinheiro em centavos (int). Nunca float.
- Lógica de negócio em app/Domain/<Contexto>/. Nunca em Resource/Controller/Livewire.
- Regras da seção 3 do SPEC exigem teste Pest escrito ANTES da implementação.
- Spec ambígua ou teste que parece errado → registre em docs/QUESTIONS.md a dúvida + a suposição mais simples, adote-a e siga. Só pare se for impossível prosseguir.
- Rode scripts/check.sh antes de reportar.

# Aprendizados anteriores relevantes (de docs/PROGRESS.md) e dicas do humano (docs/HINTS.md)
<colar as linhas que interessam a esta task; se nenhuma, "nenhum">

# Report final obrigatório
Arquivos criados/alterados (lista), desvios da spec, gaps conhecidos, aprendizados (0 a 3 linhas, fatos reutilizáveis), saída resumida do scripts/check.sh.
```

## Regras globais (valem para todos os agentes)

1. SQLite é o banco de produção e de teste. Sem feature exclusiva de Postgres/MySQL. `DB::transaction` em toda operação multi-tabela.
2. Todo job agendado é idempotente e tem teste provando que rodar duas vezes não duplica.
3. Sem over-engineering: Eloquent + Actions/Services + Enums + Value Objects. Sem CQRS, event sourcing, repositórios genéricos.
4. Sem placeholders: nada de tela "em construção", `TODO` sem entrada no ROADMAP, teste `skip`.
5. Fixtures realistas em português (iFood, Uber, Conta de Luz, Aluguel, Salário), valores plausíveis em centavos.
6. Commits sem trailer de coautoria ou assinatura de IA. Sem `--no-verify`. Sem squash.
7. Nunca commitar `.env`, `database/database.sqlite`, `storage/`.
8. `scripts/check.sh` é o único aceite. Até a task 0.2 existir, ele só valida `php artisan about`.
9. Fase 0 antes de tudo. Na fase 0 o `implementer` deve consultar a documentação oficial atual (webfetch) de Laravel 13, Filament 5 e Livewire 4 antes de instalar — as APIs mudaram em 2026 e o conhecimento de treino pode estar defasado. Resumos de doc vão em `docs/notes/<pacote>.md` para reuso pelas próximas tasks.
10. Nenhum agente espera humano. Dúvida vira suposição registrada; falha vira travamento registrado; o loop continua.
11. PHP mínimo é 8.4 (Pest 5 e activitylog 5 exigem). Dockerfile, CI e `composer.json` usam `^8.4`.
12. O repo já tem README.md, AGENTS.md, docs/, scripts/ e .opencode/ antes do skeleton Laravel existir. Nenhuma task sobrescreve esses arquivos; o skeleton é mesclado por cima (task 0.1).
