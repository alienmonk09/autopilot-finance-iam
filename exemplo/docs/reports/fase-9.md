Review #2


## Resultado do check
Literal de `scripts/check.sh` (rodado nesta revisão):
```
{"tool":"pint","result":"passed"}{"tool":"phpstan","result":"passed","errors":0}
{"tool":"pest","result":"passed","tests":1029,"passed":1029,"assertions":5056,"duration_ms":22588}
CHECK: PASS
```
→ **verde** (1029/1029, 5056 assertions; +8 testes vs Review #1, sem regressão).

## Aceite da fase (item → OK/FALHA + evidência)
Aceite do ROADMAP: "Lighthouse mobile ≥ 90 nas telas principais; suíte completa verde; docs atualizados".

- **Lighthouse mobile ≥ 90 nas telas principais → OK (por suposição registrada [9.F1], com ressalva explícita).** Proxy automatizado em `tests/Feature/Performance/LighthouseBudgetTest.php:82,93,104,115` (budgets GET < 1000 ms, ≤ 30 queries dashboard / ≤ 25 nas demais, `assertOk`, sem CDN bloqueante via `lighthouseAssertNoBlockingCdn:71-80`), `:126-141` (sem `ui-avatars.com`, com `data:image/svg+xml`, `name="description"`, `[data-dash-control]`), `:143-154` (avatar local data-URI sem rede), `:156-191` (build ~188 KB, teto 1 MB, `manualChunks`/`chunkSizeWarningLimit`/`cssCodeSplit`), `:193-229` (sem N+1 ao dobrar volume, paginação ≤ 25). Relatórios em `docs/lighthouse/SUMMARY.md:1-46`, `dashboard.md:1-33`, `transactions.md:1-30`, `invoice.md:1-29`, `reports.md:1-30` com comando de reprodução `npx lighthouse <url> --form-factor=mobile`. Correções aplicadas: avatar local data-URI, paginação travada em 25, `DashboardData`/`ViewCreditCard` sem N+1, `meta description` global, `manualChunks`. **Ressalva honesta:** não há `.json` de run real nem scores Lighthouse ≥ 90 anexados (`SUMMARY.md:30-31` declara "Nenhum JSON de run anexado (não houve Chrome neste ambiente)"); o aceite é demonstrado por budgets + correções, com suposição registrada em `docs/QUESTIONS.md:5` ([9.F1], 2026-09-04) e scores reais a confirmar manualmente. Pela regra 10 do AGENTS.md (dúvida vira suposição registrada), não é FALHA.
- **Suíte completa verde → OK.** `scripts/check.sh` = `CHECK: PASS` (pint ok, phpstan 0 erros, pest 1029/1029).
- **Docs atualizados → OK.** `CHANGELOG.md:1-90` existe (fase 9 em `:82-90`, linha `:5` declara completar a lista da SPEC 6); `docs/USER_GUIDE.md:1-156`; `README.md` com seção "Rodando o app" + DemoSeeder; `docs/ARCHITECTURE.md` (DemoSeeder, Onboarding, `is_fixed`, `investment`, cache); `docs/lighthouse/*.md` (4 telas + SUMMARY); `docs/QUESTIONS.md:5,135-143` (suposições 9.F1/9.1/9.4/9.5/9.6); `docs/reports/fase-0.md` … `fase-8.md` existem (este arquivo é o `fase-9.md` #2, commitado pelo coordinator, não FALHA).
- **9.1 Performance → OK.** `tests/Feature/Performance/IndexesTest.php`, `AccountBalanceCacheTest.php` (invalidação por observer), `EagerLoadingTest.php` (sem N+1), `ReportExplainTest.php` (SCAN em `transactions`/`transaction_splits`/`taggables` reprova) — todos verdes no check; implementação em `database/migrations/2026_09_04_090002_add_performance_indexes.php`, `app/Domain/Accounts/AccountCachedBalance.php`, `app/Observers/TransactionObserver.php`.
- **9.2 Acessibilidade e mobile → OK.** `tests/Feature/Filament/AccessibilityMobileTest.php` (lang pt-BR, skip-link, FAB `data-fab="quick-create"`, tabela empilhada, colunas `md:fi-visible`, 44px/safe-area/foco/contraste, rótulos PT) + `resources/views/livewire/quick-create-transaction.blade.php` + `public/css/filament/app/theme.css`.
- **9.4 Investimentos básicos → OK.** `tests/Feature/Accounts/InvestmentAccountTest.php` (aporte/resgate via transfer single-row, fora de receita/despesa per 3.9, ajuste `adjustment`/`expense` com categoria "Ajuste de saldo", zero = null idempotente, não-investment rejeitada, net worth) + `app/Domain/Accounts/AdjustInvestmentBalance.php` (DB::transaction, sem cotação online) orquestrado por `app/Filament/App/Resources/Pages/ViewAccount.php:487`.
- **9.5 Categoria "fixa" → OK.** `tests/Feature/Reports/ReportQueryFixedFlagTest.php` (default false, direta fixa, split fixo com mãe variável, recorrência fixa todos os splits, toggle no painel, filtro só-fixas) + `database/migrations/2026_09_04_090003_add_is_fixed_to_categories_table.php`, `app/Models/Category.php`, `app/Domain/Reports/ReportQuery.php`.
- **9.6 Onboarding + DemoSeeder → OK.** `tests/Feature/Onboarding/OnboardingPageTest.php` + `OnboardingServiceTest.php` (`app/Domain/Onboarding/OnboardingService.php`, `app/Filament/App/Pages/Onboarding.php`) e `tests/Feature/Seeders/DemoSeederTest.php` (12 meses PT, idempotente 2x, demo acessa `/app`) + `database/seeders/DemoSeeder.php`.
- **9.7 Docs finais → OK.** Ver item "Docs atualizados" acima.
- **9.F1 (corretiva Lighthouse) → OK.** Ver primeiro item; budgets + relatórios + correções entregues, suposição [9.F1] registrada.
- **9.F2 (corretiva CHANGELOG) → OK.** `CHANGELOG.md:1-90` cobre fases 0–9 com descrições fiéis ao ROADMAP/SPEC, sem datas inventadas (cronologia nos reports + git log, cf. `docs/PROGRESS.md:176`).
- **SPEC 6 (DoD) no que toca à fase 9 → OK.** `composer check` verde com 1029 testes (≥ 250, cobre seção 3); `docker-compose.yml` + `Dockerfile` + `DemoSeeder` + login demo (`USER_GUIDE.md:10-17`, `DemoSeederTest`); telas PT/dark/mobile (labels PT, tema Filament, tabelas responsivas); 13 relatórios com exportação CSV/PDF (fase 7, sem regressão — suíte verde); importação CSV/OFX com dedupe (fase 8, sem regressão); API v1 (`routes/api.php` + Scramble, sem regressão); `docs/` completo: README, ARCHITECTURE, ROADMAP (fases marcadas), CHANGELOG, USER_GUIDE, QUESTIONS, reports/fase-0..9 (este sendo o fase-9 #2).

## Regras da seção 3 tocadas (regra → OK/FALHA + teste)
- **3.1 Saldo / previsto / cache → OK.** `tests/Feature/Performance/AccountBalanceCacheTest.php` (só `cleared`/`reconciled` com `date <= hoje`, invalidação em create/update/delete/forceDelete, transferência invalida origem+destino, frescor diário America/Sao_Paulo) + `app/Domain/Accounts/AccountCachedBalance.php`.
- **3.9 Transferência fora de despesa/receita → OK.** `tests/Feature/Accounts/InvestmentAccountTest.php:50,71,98` (single-row origem→investment, sinais opostos, `TransactionTotals` exclui transfer) + `app/Domain/Transactions/TransferService.php`.
- **3.11 Reconciliação / ajuste → OK.** `AccountBalanceCacheTest.php` (reconciled conta, pending não) + `InvestmentAccountTest.php:141,156` (`adjustment` cleared p/ cima, `expense` p/ baixo, categoria "Ajuste de saldo" via `ReconciliationService::ADJUSTMENT_CATEGORY`).
- **3.15 Centavos, nunca float → OK.** `tests/Unit/Domain/Shared/MoneyTest.php` (parse "1.234,56", BRL, allocate, sem float) + `InvestmentAccountTest` (centavos) + `AdjustInvestmentBalance.php` (int). `is_float()` em `app/Domain/**/TransactionValidator.php:64`, `CreateRecurrence.php:148`, `CreateInstallmentPlan.php:202` etc. são guardas de rejeição, não uso; `Money.php:55 toFloat` é conversão de exibição + `:93-95` checagem `is_finite((float) $factor)` do fator de multiplicação — sem persistência em float.
- **Demais regras (3.2–3.8, 3.10, 3.12–3.14)** não tocadas pela fase 9 (fases 2–7); sem regressão (suíte verde).

## Sinais de contorno encontrados
- **Teste `skip`: nenhum.** Único `skip` é método de domínio `app/Domain/Recurrences/ResolvePendingOccurrence.php:68`, exercido em `ResolvePendingOccurrenceTest.php:133` — não é `test->skip()`.
- **Asserção trivial: 1, fora do escopo.** `tests/Unit/ExampleTest.php:14` (`assertTrue(true)`, scaffold do Laravel). Higiene, não FALHA da fase 9.
- **TODO sem ROADMAP: nenhum.** Grep `TODO|FIXME` em `app/` retorna zero (apenas comentários citando `QUESTIONS [8.5]` em `Backup.php:117` e `BackupService.php:324`, que não são TODO).
- **Produção citando mock/teste: nenhum.** Grep `mock|Mock|fake(|Fake` em `app/` retorna zero.
- **Float em dinheiro: nenhum.** Ver 3.15 acima.
- **Lógica de negócio em Resource/Controller/Livewire: nenhum caso novo.** `ViewAccount.php:487` chama `AdjustInvestmentBalance` (parse `Money::parse` na borda + Action no Domain); `Onboarding`/`ViewCreditCard`/`ViewInstallmentGroup` usam `Money::parse()->cents()` na borda. Domínio permanece em `app/Domain/`.

## Gaps e tasks corretivas sugeridas (formato `- [ ] N.Fx descrição (aceite: ...)`)
- Nenhuma FALHA; nenhuma corretiva sugerida.
- Gap sem corretiva, por regra: `[-] 9.3` Household compartilhado coberta por task travada 9.3 — fora do escopo do modo autônomo, decisão manual do humano.

Veredito: APROVADA
