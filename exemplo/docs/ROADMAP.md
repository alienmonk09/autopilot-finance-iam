# ROADMAP — fonte da verdade do progresso

Cada checkbox é uma task. `- [ ]` = pendente, `- [x]` = concluída (marcar SÓ via `scripts/mark-done.sh` após `scripts/check.sh` verde). As fases são sequenciais: a fase N+1 só começa depois do review da fase N em `docs/reports/fase-N.md`. Referências "seção X.Y" apontam para `docs/SPEC.md`.

Regras gerais de cada task: (a) migrations + models + factories + enums; (b) lógica de negócio em `app/Domain/<Contexto>/` (Actions/Services), nunca em Resource/Controller/Livewire; (c) testes Pest RED → GREEN; (d) UI Filament; (e) `scripts/check.sh` verde; (f) commit `feat(fase-N.M): ...` feito pelo coordenador.

## Fase 0 — Fundação (aceite: app sobe, login funciona, `composer check` verde, CI configurada)
- [x] 0.1 Skeleton Laravel 13 (PHP 8.4+) mesclado neste repo já populado. Receita fechada, executar literalmente: `rm -rf /tmp/skel && composer create-project --no-interaction --prefer-dist laravel/laravel /tmp/skel && rsync -a --exclude .git --exclude README.md --exclude AGENTS.md --exclude CLAUDE.md --exclude .gitignore /tmp/skel/ ./ && cat /tmp/skel/.gitignore >> .gitignore && rm -rf /tmp/skel`. O skeleton traz um `AGENTS.md` próprio (Laravel Boost): ele NÃO pode substituir o `AGENTS.md` deste repo. Depois: em `composer.json` trocar `"php": "^8.3"` por `"^8.4"`; configurar SQLite (WAL, foreign_keys, busy_timeout) em `config/database.php` + `AppServiceProvider`. Aceite: `php artisan about` funciona, `AGENTS.md` continua começando com `# finance-iam — protocolo`, `.gitignore` contém `/logs/`
- [x] 0.2 Instalar com `composer require --no-interaction` (versões atuais, consultar doc oficial antes): Filament 5, Livewire 4, Tailwind 4 (via Vite), Pest, Pint, Larastan; scripts `composer check` (pint --test + larastan + pest), `composer test`, `composer lint`. Aceite: `scripts/check.sh` termina em `CHECK: PASS`
- [x] 0.3 Auth (registro, login, reset, 2FA TOTP), `user_settings` com defaults, locale pt_BR, timezone
- [x] 0.4 Value Object `Money` (parse "1.234,56"/"1234.56", formatação BRL, soma/subtração/alocação proporcional para parcelas) + testes
- [x] 0.5 Estrutura `app/Domain/{Accounts,Cards,Transactions,Recurrences,Installments,Budgets,Goals,Rules,Imports,Reports}`; global scope por `user_id`; policies
- [x] 0.6 Tema Filament: cores, logo, fontes, layout do painel, dark mode, ícones; painel em `/app`
- [x] 0.7 Dockerfile (imagem PHP 8.4+, FrankenPHP ou php-fpm+nginx) + docker-compose (app + volume sqlite + storage), supervisord (scheduler + queue), `.env.example`; acrescentar seção "Rodando o app" ao README.md existente (não substituir o arquivo)
- [x] 0.8 GitHub Actions: `composer check` em push/PR
- [x] 0.9 `docs/ARCHITECTURE.md` (decisões: centavos, transfer single-row, invoice lazy, competência, PHP 8.4+)

## Fase 1 — Bancos, Contas, Categorias, Tags, Payees (aceite: CRUD completo; saldo calculado correto em testes com todos os tipos de transação simulados por factory)
- [x] 1.1 Migrations/models/factories: banks, accounts, categories, tags, payees
- [x] 1.2 Seeders: bancos BR (com cores), categorias padrão (clonadas para o usuário no registro via evento)
- [x] 1.3 `AccountBalanceService` (saldo em data, saldo previsto) + testes cobrindo regra 3.1
- [x] 1.4 Filament Resources: Accounts (cards + tabela), Categories (árvore/drag order), Tags, Payees (merge), Banks (custom do usuário)
- [x] 1.5 Arquivamento/bloqueio de exclusão (regra 3.13)

## Fase 2 — Transações (aceite: lançar despesa/receita/transferência/ajuste com status, split, anexo, tags; filtros e totais corretos; auditoria gravada)
- [x] 2.1 Migrations transactions, transaction_splits, taggables, media (anexos), activity_log
- [x] 2.2 `CreateTransaction`, `UpdateTransaction`, `DeleteTransaction`, `TransferService`, `SplitValidator` + testes (regras 3.9, 3.10, 3.15)
- [x] 2.3a Resource Filament de transações: tabela básica + form de criação/edição com abas por tipo (Despesa · Receita · Transferência) e navegação por mês (‹ Set/2026 ›)
- [x] 2.3b Filtros da seção 4.2 (período com presets, conta, categoria, tag, payee, tipo, status, faixa de valor, texto), totais do filtro no rodapé, agrupamento opcional por dia
- [x] 2.3c Ações em massa (categorizar, adicionar tag, marcar cleared, excluir, mover de conta) + testes
- [x] 2.4 Autocomplete payee → sugere categoria padrão do payee (última usada)
- [x] 2.5 Extrato por conta com saldo acumulado linha a linha
- [x] 2.6 Reconciliação (regra 3.11) com UI (informar saldo do extrato, marcar, ajustar)
- [x] 2.7 Modal "lançamento rápido" global (botão + na topbar e FAB mobile)

## Fase 3 — Cartões de crédito e faturas (aceite: testes de alocação em fatura com meses de 28/29/30/31 dias e closing_day 1, 15, 28, 31; pagamento total/parcial/excedente; limite disponível correto; job de fechamento idempotente)
- [x] 3.1 Migrations credit_cards, invoices; transação tipo `credit_card_expense` e `credit_card_payment`
- [x] 3.2a `InvoiceAllocator` (regras 3.2 e 3.3: data da compra → fatura; fechamento/vencimento) com testes cobrindo meses de 28/29/30/31 dias e closing_day 1, 15, 28, 31
- [x] 3.2b `InvoiceService` (criação lazy, totais, close, reopen, forçar lançamento em fatura fechada) + testes
- [x] 3.2c `CreditCardLimitService` (regra 3.4) + `PayInvoice` (regra 3.5: total, parcial, excedente, saldo anterior sintético) + testes
- [x] 3.3 Job/Command `invoices:close` diário no scheduler (3.6) + testes
- [x] 3.4 Resource Filament de cartões (cards com limite/uso/melhor dia) e página de fatura com navegação mensal, lançamentos, subtotal por categoria, pagar, reabrir, forçar lançamento em fatura fechada
- [x] 3.5 Compras no cartão no form unificado de transações (aba Cartão) com preview "cai na fatura de Out/2026, vence 10/11"

## Fase 4 — Parcelamentos (aceite: Σ parcelas == total sempre; cada parcela na fatura certa; antecipação move e recalcula; exclusão respeita regra 3.7)
- [x] 4.1 Migration installment_groups; campos em transactions
- [x] 4.2a `CreateInstallmentPlan` (alocação de centavos com resto na 1ª parcela, datas, fatura de cada parcela) + testes da regra 3.7
- [x] 4.2b `AnticipateInstallments`, `UpdateFutureInstallments`, `CancelInstallmentPlan` + testes
- [x] 4.3 Toggle "Parcelar" no form de transação com preview das parcelas; Resource de parcelamentos com progresso e ações
- [x] 4.4 Parcelamento em conta (débito/boleto) além de cartão

## Fase 5 — Recorrências / despesas fixas (aceite: job idempotente; dia 31 e fevereiro tratados; editar "esta/futuras/todas"; confirmação de pendentes com valor ajustado; pausa remove só futuras pendentes)
- [x] 5.1 Migration recurrences; campos em transactions (`recurrence_id`, `recurrence_occurrence_date`, `is_detached`)
- [x] 5.2 `RecurrenceScheduler` (cálculo de próximas datas para todas as frequências) + `GenerateRecurrenceOccurrences` job + command `recurrences:generate` no scheduler diário + testes (regra 3.8)
- [x] 5.3 Edição em cascata (esta/futuras/todas) + testes
- [x] 5.4 Toggle "Repetir" no form de transação; Resource de recorrências; calendário mensal; página "Pendentes de confirmação"
- [x] 5.5 Saldo previsto passa a considerar ocorrências não materializadas (3.1) + teste

## Fase 6 — Orçamentos e Metas (aceite: spent correto por data e por competência com subcategorias; rollover; alertas disparam uma vez por faixa; metas calculam aporte/projeção)
- [x] 6.1 Migrations budgets, budget_periods, goals, goal_contributions
- [x] 6.2 `BudgetCalculator`, `BudgetRolloverService`, `BudgetAlertJob` + testes (3.12)
- [x] 6.3 UI de orçamento mensal (barras, copiar mês anterior, sugerir pela média)
- [x] 6.4 `GoalProjectionService` + UI de metas com aporte rápido (gera transferência opcional)

## Fase 7 — Dashboard, Relatórios, Notificações (aceite: todos os 13 relatórios com testes de agregação em cenários controlados; widgets do dashboard com dados corretos; exportação CSV/PDF; notificações disparam pelo scheduler)
- [x] 7.1a `ReportQuery` dos relatórios 1 a 5 da seção 4.9 (SQL agregado, sem N+1) + testes com dataset fixo de factories
- [x] 7.1b `ReportQuery` dos relatórios 6 a 10 + testes
- [x] 7.1c `ReportQuery` dos relatórios 11 a 13 (fixas x variáveis, projeção 90 dias, tendência) + testes
- [x] 7.2a Páginas Filament dos relatórios 1 a 7 com gráficos (Chart.js via widgets), filtros de período e drill-down
- [x] 7.2b Páginas Filament dos relatórios 8 a 13
- [x] 7.2c Exportação CSV e PDF genérica para todos os relatórios + testes
- [x] 7.3 Dashboard com widgets reordenáveis (config em user_settings) — 4.1
- [x] 7.4 Notificações (4.13): jobs no scheduler, database + mail, preferências do usuário
- [x] 7.5 Projeção de saldo 90 dias (relatório 12) integrada ao dashboard

## Fase 8 — Importação, Exportação, Regras, API (aceite: importar CSV Nubank/Itaú/Inter de exemplo e OFX sem duplicar em reimportação; regras aplicadas na importação e retroativamente com preview; backup/restore round-trip; API com testes de autenticação e filtros)
- [x] 8.1 Migrations import_batches/import_rows, rules/rule_conditions/rule_actions
- [x] 8.2a `CsvParser` (delimitador/encoding autodetect), `ImportMapper` (salvar mapping por banco), `Deduplicator` (external_id hash) + fixtures CSV anonimizadas de 3 bancos BR + testes
- [x] 8.2b `OfxParser` próprio (SGML simples, sem pacote externo) + fixture OFX + testes
- [x] 8.3 Wizard de importação (staging → mapping → preview → confirmar)
- [x] 8.4a `RuleEngine` (avaliação de condições, execução de ações, prioridade, stop) + hook em criação/importação + testes
- [x] 8.4b Aplicar regras retroativamente com dry-run (preview) + UI builder de condições/ações
- [x] 8.5 Exportação CSV por entidade; backup JSON + download do SQLite; restore JSON
- [x] 8.6 API v1 (seção 5) + OpenAPI + testes

## Fase 9 — Polimento e extras (aceite: Lighthouse mobile ≥ 90 nas telas principais; suíte completa verde; docs atualizados)
- [x] 9.1 Performance: índices revisados, cache de saldos com invalidação testada, eager loading, `EXPLAIN QUERY PLAN` nos relatórios
- [x] 9.2 Acessibilidade e mobile (FAB, gestos básicos, tabelas responsivas)
- [-] 9.3 Household compartilhado (2.17) — fora do escopo do modo autônomo; reativar manualmente se desejado
- [x] 9.4 Investimentos básicos: conta tipo `investment` com aportes/resgates e atualização manual de saldo (sem cotação online)
- [x] 9.5 Categoria "fixa" (flag) para relatório fixo x variável
- [x] 9.6 Onboarding: wizard inicial (criar primeira conta, primeiro cartão, importar ou lançar) + dados de demonstração (`db:seed --class=DemoSeeder`)
- [x] 9.7 Docs finais: README, ARCHITECTURE, guia do usuário curto em `docs/USER_GUIDE.md`
- [x] 9.F1 Rodar Lighthouse mobile nas telas principais (dashboard, transações, fatura do cartão, relatórios) e anexar scores ≥ 90 ou corrigir o que reprovar (aceite: Lighthouse mobile ≥ 90 nas telas principais)
- [x] 9.F2 Criar CHANGELOG.md com o histórico das fases 0–9 (aceite: docs atualizados; SPEC 6 docs/ completo)

