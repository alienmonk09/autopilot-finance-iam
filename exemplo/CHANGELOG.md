# Changelog — finance-iam

Gestão de finanças pessoais (contas, cartões, faturas, parcelamentos, recorrências, orçamentos, metas, relatórios) em **Laravel 13 + SQLite + Filament 5**.

Formato inspirado em [Keep a Changelog](https://keepachangelog.com/), simplificado: uma seção por fase do `docs/ROADMAP.md`, sem datas inventadas (a cronologia está nos reviews em `docs/reports/fase-N.md` e no histórico do repositório). Este arquivo completa a lista de `docs/` exigida pela SPEC 6 (README, ARCHITECTURE, ROADMAP, CHANGELOG, USER_GUIDE, QUESTIONS, reports/fase-0..9).

## [Fase 0] — Fundação

- Skeleton Laravel 13 mesclado no repo com PHP mínimo `^8.4` em `composer.json`, Dockerfile e CI; `php artisan about` verde.
- SQLite como único banco (WAL, `foreign_keys=ON`, `busy_timeout=5000`) em `config/database.php` + `AppServiceProvider`; testes em `:memory:`.
- Filament 5 + Livewire 4 + Tailwind 4 (via Vite); painel em `/app` com tema próprio e dark mode; `composer check` (Pint + Larastan + Pest) e GitHub Actions.
- Auth com Fortify (registro, login, reset de senha, 2FA TOTP) + `user_settings` com defaults, locale `pt_BR`, timezone `America/Sao_Paulo`.
- Value Object `Money` (parse de "1.234,56"/"1234.56", formatação BRL, soma sem float, `allocate` com o resto na 1ª parcela) com testes.
- Estrutura `app/Domain/*`, global scope por `user_id` + policies, container único (FrankenPHP + supervisord com scheduler e queue), `docs/ARCHITECTURE.md` e resumos de documentação oficial em `docs/notes/`.

## [Fase 1] — Bancos, Contas, Categorias, Tags, Payees

- Migrations, models e factories de `banks`, `accounts`, `categories`, `tags`, `payees` (+ `taggables`).
- Seeders: ~42 bancos/fintechs BR com cores (+ "Carteira/Dinheiro" e "Outro") e categorias padrão em português clonadas para o usuário no registro via evento.
- `AccountBalanceService` com saldo em data e saldo previsto cobrindo a regra 3.1 (todos os tipos de transação, só `cleared`/`reconciled` no saldo atual).
- Resources Filament: contas (cards + tabela), categorias (árvore com ordenação), tags, payees com merge de duplicados, bancos do usuário.
- Arquivamento e bloqueio de exclusão (regra 3.13): conta com lançamentos arquiva em vez de excluir; categoria em uso exige realocação.

## [Fase 2] — Transações

- Migrations de `transactions`, `transaction_splits`, `taggables`, anexos (medialibrary) e `activity_log` (auditoria).
- `CreateTransaction`/`UpdateTransaction`/`DeleteTransaction`, `TransferService` (transferência em linha única origem + destino, regra 3.9) e `SplitValidator` (Σ splits == total, regra 3.10); valores sempre em centavos inteiros (regra 3.15).
- Resource de transações com abas por tipo (Despesa · Receita · Transferência · Ajuste), navegação por mês e modal de "lançamento rápido" global (botão + na topbar, FAB no mobile).
- Filtros da seção 4.2 (período com presets, conta, categoria via splits, tag, payee, tipo, status, faixa de valor, texto) com totais no rodapé e agrupamento opcional por dia; ações em massa.
- Autocomplete de payee com sugestão de categoria; extrato por conta com saldo acumulado linha a linha; reconciliação com ajuste de saldo (regra 3.11); auditoria gravada em criar/atualizar/excluir.

## [Fase 3] — Cartões de crédito e faturas

- Migrations de `credit_cards` e `invoices`; tipos `credit_card_expense` e `credit_card_payment`.
- `InvoiceAllocator` (regras 3.2 e 3.3: compra → fatura, fechamento e vencimento) com testes em meses de 28/29/30/31 dias e `closing_day` 1, 15, 28 e 31; faturas criadas lazy.
- `InvoiceService` (totais calculados, fechamento, reabertura, forçar lançamento em fatura fechada com aviso).
- `CreditCardLimitService` (limite disponível, regra 3.4, com comprometido em parcelas futuras separado) e `PayInvoice` (pagamento total/parcial/excedente; parcial gera "Saldo anterior da fatura" na próxima; pagamento não conta como despesa — regra 3.5).
- Job/comando `invoices:close` diário no scheduler (regra 3.6), idempotente.
- UI: cards de cartão (limite, usado, disponível, melhor dia de compra), página de fatura com navegação mensal e pagamento, aba Cartão no form de transação com preview de fatura/vencimento.

## [Fase 4] — Parcelamentos

- Migration de `installment_groups` e campos de parcela (`installment_group_id`, número/total) nas transações.
- `CreateInstallmentPlan`: Σ parcelas == total sempre, com o resto do arredondamento na 1ª parcela (ex.: 100,00 / 3 = 33,34 + 33,33 + 33,33); parcela N no mês da 1ª + N−1, com clamp de dia 31.
- Cada parcela do cartão alocada na fatura correta pelo `closing_day`; fatura fechada empurra a parcela para a próxima aberta.
- `AnticipateInstallments` (move para a fatura atual, com desconto rateado opcional), `UpdateFutureInstallments` (editar futuras) e `CancelInstallmentPlan` (remove só pendentes em fatura aberta, salvo "excluir tudo" — regra 3.7).
- Toggle "Parcelar" no form de transação com preview; Resource de parcelamentos com progresso, restante e próximo vencimento; parcelamento em conta (débito/boleto) além do cartão.

## [Fase 5] — Recorrências / despesas fixas

- Migration de `recurrences` e campos `recurrence_id`, `recurrence_occurrence_date` e `is_detached` nas transações.
- `RecurrenceScheduler` (todas as frequências) + job/comando `recurrences:generate` diário, idempotente por unique `recurrence_id` + data de ocorrência.
- Dia 31 em mês curto cai no último dia (fevereiro incluso); `end_type` respeitado; pausar remove só as pendentes futuras.
- Edição em cascata "só esta / esta e futuras / todas" (lançamentos efetivados nunca mudam; ocorrência editada à mão vira `detached` e não é sobrescrita).
- Toggle "Repetir" no form; Resource de recorrências com calendário mensal e página de pendentes de confirmação (confirmar com valor ajustado, pular, adiar); saldo previsto passa a somar ocorrências ainda não materializadas (regra 3.1).

## [Fase 6] — Orçamentos e Metas

- Migrations de `budgets`, `budget_periods`, `goals` e `goal_contributions`.
- `BudgetCalculator`: gasto por data ou por competência (`budget_basis`), incluindo subcategorias e splits, excluindo ignorados (regra 3.12).
- `BudgetRolloverService` (sobra/estouro carrega para o mês seguinte quando ativo) e `BudgetAlertJob` (alerta uma única vez por faixa: threshold e 100%).
- UI de orçamento mensal (barras por categoria, copiar mês anterior, sugerir pela média dos últimos 3 meses, evolução orçado × gasto em 12 meses).
- `GoalProjectionService` (progresso %, aporte mensal necessário, projeção de conclusão) e aporte rápido que gera transferência opcional para a conta vinculada.

## [Fase 7] — Dashboard, Relatórios, Notificações

- `ReportQuery` com os 13 relatórios da seção 4.9 (despesas/receitas por categoria, receita × despesa mensal, fluxo de caixa, patrimônio, cartão/fatura, payee, tag, orçado × realizado, ano a ano, fixas × variáveis, projeção de saldo 90 dias, tendência por categoria), com SQL agregado sem N+1.
- Páginas Filament dos relatórios 1–7 e 8–13, com filtros de período, gráficos e drill-down (categoria → subcategoria → lançamentos).
- Exportação CSV (`;`, BOM UTF-8) e PDF genérica para todos os relatórios.
- Dashboard com widgets reordenáveis (config em `user_settings`): saldo total, receitas/despesas do mês, saldo previsto, contas, cartões, próximos vencimentos, orçamentos, donut por categoria, fluxo de caixa 12 meses, metas e projeção de 90 dias integrada.
- Notificações (fatura fechando/vencendo/vencida, recorrência pendente, orçamento em 80%/100%, meta concluída, importação finalizada) via jobs no scheduler, em database + e-mail.

## [Fase 8] — Importação, Exportação, Regras, API

- Migrations de `import_batches`/`import_rows` e `rules`/`rule_conditions`/`rule_actions`.
- `CsvParser` (autodetect de delimitador/encoding) + `ImportMapper` (mapeamento salvo por banco, presets Nubank/Itaú/Inter) + `Deduplicator` por `external_id` (hash de data+valor+descrição); reimportação não duplica.
- Parser OFX próprio (SGML simples, sem pacote externo abandonado) com fixtures e testes.
- Wizard de importação (upload → mapeamento → preview com dedupe → confirmar) com regras aplicadas na confirmação.
- `RuleEngine` (condições, ações, prioridade, `stop_processing`) com hook em criação/importação, mais aplicação retroativa com dry-run (preview antes de confirmar) e builder de condições/ações na UI.
- Exportação CSV por entidade, backup JSON + download do SQLite e restore com round-trip; API v1 Sanctum (`/api/v1`, valores em centavos + `amount_formatted`, filtros, paginação, OpenAPI gerada).

## [Fase 9] — Polimento e extras

- Performance: índices revisados, cache de saldos com invalidação testada por observer, eager loading e `EXPLAIN QUERY PLAN` nos agregados dos relatórios.
- Acessibilidade e mobile: skip-link, FAB de lançamento rápido, tabelas responsivas/empilhadas, gestos básicos, formulários e rótulos em português.
- Household compartilhado (SPEC 2.17, task 9.3) marcado como `[-]`: fora do escopo do modo autônomo; o isolamento permanece por `user_id` (troca para `household_id` fica como trabalho futuro manual).
- Investimentos básicos: conta do tipo `investment` com aportes/resgates e ajuste manual de saldo (sem cotação online).
- Flag `is_fixed` em categorias para o relatório de despesas fixas × variáveis (granularidade por split).
- Onboarding: wizard inicial (primeira conta → primeiro cartão → importar/lançar) + `DemoSeeder` idempotente com 12 meses de dados realistas (`db:seed --class=DemoSeeder`, login demo).
- Docs finais: README, ARCHITECTURE e guia do usuário (`docs/USER_GUIDE.md`); Lighthouse mobile ≥ 90 nas telas principais (dashboard, transações, fatura do cartão, relatórios) com budgets acompanhados (task 9.F1).

## [Pós-roadmap] — Correções

- Estorno/crédito em fatura de cartão (#1): `credit_card_expense` passa a admitir `amount_cents` negativo, reduzindo `total_cents` da fatura e o limite usado, reduzindo o gasto da categoria nos relatórios e orçamentos, com efeito zero no saldo de conta, sem `splits`; importação de fatura com linha negativa vira estorno (`refund` no preview); UI mostra `+ R$` em verde e rótulo “Estorno no cartão”; API v1 aceita `amount_cents` negativo só para `credit_card_expense`.
- **Importação de fatura de cartão (#2)**:
  - Fatura-alvo explícita para lote de cartão (`target_reference_month` em `import_batches`), permitindo direcionar todas as linhas importadas para a fatura escolhida independente da data da compra.
  - Reconhecimento de coluna de parcelas (`installment` com formatos `n de N` e `n/N`) adicionando o sufixo ` (n/N)` na descrição (refletido no hash de deduplicação) e preenchendo `installment_number` e `installment_total` nas transações criadas.
  - Preset nativo da XP (`Data;Estabelecimento;Portador;Valor;Parcela`) reconhecendo colunas e parcelamento automaticamente.
  - Linhas de pagamento de fatura em importação de cartão (valores negativos com descrição de pagamento) passam a ser marcadas como `ignored` com motivo explicativo, evitando compras negativas espúrias.
  - Seleção de fatura de destino no wizard (etapa 1) com listagem das faturas existentes e próximos 3 meses calculados (desabilitando faturas já pagas), suporte a coluna de parcela na etapa 2 e exibição de parcelas e motivos de linhas ignoradas na prévia (etapa 3).
