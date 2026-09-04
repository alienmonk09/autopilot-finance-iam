Review #1


## Resultado do check
`bash scripts/check.sh` (2026-09-03, sem edição):
```
{"tool":"pint","result":"passed"}{"tool":"phpstan","result":"passed","errors":0}
{"tool":"pest","result":"passed","tests":613,"passed":613,"assertions":2538,"duration_ms":13101}
CHECK: PASS
```
Resumido: pint passed, phpstan passed (0 erros), pest 613/613 passed (2538 assertions) — CHECK: PASS.

## Aceite da fase (item → OK/FALHA + evidência)
- job idempotente → OK. Implementação: `app/Domain/Recurrences/GenerateRecurrenceOccurrences.php:98-114` (pula quando existe `recurrence_id` + `recurrence_occurrence_date` não-deletada; `is_detached` nunca sobrescrita), `app/Jobs/GenerateRecurrenceOccurrencesJob.php:25-28` (só delega), `app/Console/Commands/GenerateRecurrencesCommand.php:20-27`, agendado em `bootstrap/app.php:18` (`recurrences:generate` daily). Testes: `tests/Feature/Recurrences/GenerateRecurrencesTest.php:117-128` (segunda execução `created=0 skipped=7`), `:349-356` (dois dispatches não duplicam), `:358-370` (command idempotente), `:372-380` (scheduler `0 0 * * *`).
- dia 31 e fevereiro tratados → OK. Implementação: `app/Domain/Recurrences/RecurrenceScheduler.php:290-303` (`min(day, daysInMonth)` + `addMonthsNoOverflow`). Testes: `tests/Feature/Recurrences/RecurrenceSchedulerTest.php:76-84` (31→30), `:86-98` (fev bissexto 2024/2028), `:136-144` (anual 29/02 → 28 fora de bissexto), `tests/Feature/Recurrences/GenerateRecurrencesTest.php:232-259` (dia 31 via job: `2026-02-28` e `2024-02-29`), `tests/Feature/Recurrences/ProjectedOccurrencesTest.php:116-128` (clamp na projeção).
- editar "esta/futuras/todas" → OK. Implementação: `app/Domain/Recurrences/UpdateRecurrenceCascade.php:198-220` (Single: edita + `is_detached`, reconciled lança), `:225-249` (Future: só `pending >= target`, detacha), `:254-289` (All: template + pendentes não-detached + regenera deletadas). Testes: `tests/Feature/Recurrences/UpdateRecurrenceCascadeTest.php:86-117` (esta), `:119-142` (esta pending/cleared ok, reconciled lança), `:161-194` (futuras preserva resto + cleared/reconciled), `:205-254` (futuras troca cartão realoca invoice), `:256-295` (todas preserva detached/cleared/reconciled), `:297-319` (todas regenera deletada), `:321-358` (todas troca cartão, Σ faturas = 7×valor).
- confirmação de pendentes com valor ajustado → OK. Implementação: `app/Domain/Recurrences/ResolvePendingOccurrence.php:48-66` (confirm → `cleared` + valor opcional + `is_detached`), `app/Filament/App/Pages/PendingRecurrences.php:67-94` (confirma com texto BR, pular, adiar — só via domínio). Testes: `tests/Feature/Recurrences/ResolvePendingOccurrenceTest.php:77-90` (confirma), `:92-100` (valor `'210,50'` → 21050), `:130-152` (pular/adiar, `recurrence_occurrence_date` imutável), `:169-210` (adiar no cartão realoca fatura para `2026-11`), `tests/Feature/Filament/RecurrenceResourceTest.php:197-216` (UI confirma com `210,50` → cleared/21050), `:218-243` (UI pula/adia).
- pausa remove só futuras pendentes → OK. Implementação: `app/Domain/Recurrences/PauseRecurrence.php:52-74` (`is_active=false` + delete só `pending` com `recurrence_occurrence_date > hoje`; resume só reativa), orquestrado em `app/Filament/App/Resources/Pages/ViewRecurrence.php:102-133` e encerrar em `:163-206` (pausa + trava `end_type=on_date` hoje). Testes: `tests/Feature/Recurrences/UpdateRecurrenceCascadeTest.php:420-447` (remove 1 futura, restantes `06-10..09-10,11-10,12-10`), `:449-474` (resume não recria; job recria), `tests/Feature/Filament/RecurrenceResourceTest.php:104-129` (ação pausar via UI), `:131-141` (retomar), `:143-171` (encerrar trava `end_date=2026-09-15`).
- Itens implícitos do aceite cobertos (5.4/5.5): toggle "Repetir" + Resource + calendário + saldo previsto → OK. `app/Domain/Recurrences/CreateRecurrence.php:51-109` (cria regra + materializa via gerador), `app/Filament/App/Pages/RecurrenceCalendar.php:108-118` (só materializadas), `app/Domain/Recurrences/ProjectedOccurrences.php:51-96` + `app/Domain/Accounts/AccountBalanceService.php:65-72` + `app/Filament/App/Resources/Pages/ViewAccount.php:118` (forecast soma projetadas). Testes: `tests/Feature/Recurrences/CreateRecurrenceTest.php:66-92`, `tests/Feature/Filament/RecurrenceToggleFormTest.php:127-156` (criar com Repetir gera regra + 4 ocorrências), `tests/Feature/Filament/RecurrenceResourceTest.php:73-82` (lista: Mensal/R$ 189,90/próxima/origem/Ativa), `:173-186` (calendário navega), `tests/Feature/Recurrences/ProjectedOccurrencesTest.php:61-81` (previsto −555000, atual 0), `:83-105` (sem dupla contagem).

## Regras da seção 3 tocadas (regra → OK/FALHA + teste)
- 3.8 Recorrência (job, idempotência, detached, dia 31/fev, end_type, pausa) → OK. Testes: `tests/Feature/Recurrences/RecurrenceSchedulerTest.php` (todas as frequências), `tests/Feature/Recurrences/GenerateRecurrencesTest.php:117-149` (idempotência/detached), `:197-230` (horizonte/end), `tests/Feature/Recurrences/UpdateRecurrenceCascadeTest.php:420-489` (pausa/resume).
- 3.1 Saldo previsto com não-materializadas → OK. Testes: `tests/Feature/Recurrences/ProjectedOccurrencesTest.php:61-81`, `:83-105` (não duplica), `:107-114` (pausada projeta []), `:151-171` (transfer projeta −/+), `:189-197` (cartão nunca entra).
- 3.2/3.6 Alocação em fatura via recorrência (compra no cartão, adiar/trocar cartão realoca, totais recalculados) → OK. Testes: `tests/Feature/Recurrences/GenerateRecurrencesTest.php:286-315`, `tests/Feature/Recurrences/CreateRecurrenceTest.php:122-148`, `tests/Feature/Recurrences/ResolvePendingOccurrenceTest.php:169-210`, `tests/Feature/Recurrences/UpdateRecurrenceCascadeTest.php:205-254`.
- 3.9 Transferência (não é despesa/receita; template recorrente origem≠destino; sinais opostos no previsto) → OK. Testes: `tests/Feature/Recurrences/CreateRecurrenceTest.php:150-168`, `tests/Feature/Recurrences/ProjectedOccurrencesTest.php:151-171`.
- 3.11 Reconciliação (reconciled bloqueia edição) → OK. Teste: `tests/Feature/Recurrences/UpdateRecurrenceCascadeTest.php:119-142` (single em reconciled lança; SPEC 3.11).
- 3.14 Datas/timezone (DATE puro America/Sao_Paulo, Y-m-d estrito, overflow rejeitado) → OK. Implementação: `app/Domain/Recurrences/RecurrenceScheduler.php:106-132`. Testes: `tests/Feature/Recurrences/UpdateRecurrenceCascadeTest.php:144-159` (`2026-02-30` lança), `tests/Feature/Recurrences/ResolvePendingOccurrenceTest.php:154-167`.
- 3.15 Dinheiro em centavos, nunca float (parse BR, float lança) → OK. Testes: `tests/Feature/Recurrences/CreateRecurrenceTest.php:170-203` (texto `189,90` ok, float lança), `tests/Feature/Recurrences/UpdateRecurrenceCascadeTest.php:360-418`, `tests/Feature/Recurrences/ResolvePendingOccurrenceTest.php:92-128`.
- Regras 3.3, 3.4, 3.5, 3.7, 3.10, 3.12, 3.13: não tocadas diretamente pela fase 5 (reuso do `InvoiceService`/domínio das fases 2–4, sem alteração) — sem veredito.

## Sinais de contorno encontrados
- Teste `skip`: nenhum (ocorrências de `skip` são o método de domínio `ResolvePendingOccurrence::skip` e `skipped` do resumo idempotente, não `markTestSkipped`).
- Asserção trivial: nenhuma (todas as asserções verificam estado/valores/datas/totais; ex.: Σ faturas, datas exatas, status, detached).
- Código de produção citando mock/teste: nenhum em `app/Domain/Recurrences/*`, `app/Models/Recurrence.php`, `app/Jobs/GenerateRecurrenceOccurrencesJob.php`, `app/Console/Commands/GenerateRecurrencesCommand.php`, Filament de recorrências (matches de "test" são só comentários de SPEC/task).
- Float em dinheiro: nenhum (float só aparece em guardas que *rejeitam* float: `CreateRecurrence.php:148-149`, `UpdateRecurrenceCascade.php:670-671`, `ResolvePendingOccurrence.php:145-146`; valores em `amount_cents` int + `Money::parse`).
- Lógica de negócio em Resource/Controller/Livewire: nenhuma (Resources/Pages só formatam labels e orquestram o domínio: `RecurrenceResource.php` só leitura/formatação, `PendingRecurrences.php:67-157` delega a `ResolvePendingOccurrence`, `ViewRecurrence.php:111-189` delega a `PauseRecurrence`/`UpdateRecurrenceCascade` com `DB::transaction` de orquestração).
- `TODO` sem entrada no ROADMAP: nenhum em arquivos da fase.

## Gaps e tasks corretivas sugeridas (formato `- [ ] N.Fx descrição (aceite: ...)`)
Nenhum gap. Tasks `[!]`/`[-]` da fase: nenhuma (5.1–5.5 todas `[x]`). Nenhuma task corretiva proposta.

Veredito: APROVADA
