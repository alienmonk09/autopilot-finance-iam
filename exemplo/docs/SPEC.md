# SPEC — finance-iam (gestão de finanças pessoais, Laravel 13 + SQLite)

> Especificação integral do produto: escopo, modelo de domínio, regras de negócio, stack, UX e critério de aceite final. As tasks estão em `docs/ROADMAP.md`. O protocolo de trabalho do agente está em `AGENTS.md`. Nada fora deste documento é escopo.

## 0. Visão do produto

Um "Mobills/Organizze self-hosted", com a robustez contábil do Firefly III e a UX de apps modernos (Monarch, Copilot, Actual Budget). Público: pessoa física (ou casal) no Brasil que quer controlar contas bancárias, cartões de crédito, gastos recorrentes, compras parceladas, orçamentos, metas e ver relatórios/dashboard confiáveis.

Referências analisadas (funcionalidades a espelhar, sem copiar código):

| Sistema | O que espelhar |
|---|---|
| **Firefly III** (Laravel, open source) | Tipos de conta (ativo/passivo/despesa/receita), transações imutáveis por partidas (origem → destino), regras de automação (rule engine), transações recorrentes, "bills" (contas fixas a pagar), cofrinhos (piggy banks), orçamentos por período, tags, relatórios ricos, importação CSV, API REST |
| **Actual Budget** (open source, local-first) | Envelope budgeting opcional, schedules (agendamentos com previsão de próximas ocorrências), rules de categorização, reconciliação de conta, split transactions, payees, relatórios (net worth, gastos por categoria, receita x despesa) |
| **Mobills / Organizze** (BR) | Cartão de crédito com fatura (dia de fechamento + vencimento + limite + conta pagadora), compras parceladas caindo em faturas sucessivas, despesas fixas, "melhor dia de compra", metas com prazo, alerta de estouro de orçamento, saldo previsto, lembretes de vencimento, categorias/subcategorias com ícone e cor, tags, anexos |
| **Monarch Money** | Detecção e calendário de recorrências, projeção de fluxo de caixa (saldo futuro), regras de categorização persistentes ("X é sempre Y"), patrimônio líquido ao longo do tempo, metas com contas vinculadas, orçamento por buckets (fixo / recorrente não-mensal / flexível) |
| **Maybe Finance** | Dashboard de patrimônio agregando contas, cartões, empréstimos e investimentos; merchant/payee tracking; multi-moeda por conta |

---

## 1. Stack obrigatória

| Camada | Escolha | Observações |
|---|---|---|
| Linguagem | PHP 8.4+ | Usar tipos estritos (`declare(strict_types=1)`), readonly, enums nativos |
| Framework | **Laravel 13** (última versão estável) | `laravel new`, estrutura padrão do 13 |
| Banco | **SQLite** (único banco, arquivo `database/database.sqlite`) | Ativar `PRAGMA journal_mode=WAL`, `foreign_keys=ON`, `busy_timeout=5000` via config. Sem Postgres/MySQL. Todos os testes rodam em SQLite `:memory:` |
| UI | **Filament 5** (painel de usuário, não painel admin) + **Livewire 4** + Tailwind 4 | Usar Filament como framework de aplicação: Resources, Pages, Widgets (Chart.js), Notifications, Actions. Customizar tema, cores e layout para não parecer "admin genérico". Componentes customizados em Livewire quando o Filament não cobrir |
| Auth | Laravel Fortify (ou auth do Filament) + 2FA TOTP opcional | Registro (auto-registro configurável por `FORTIFY_REGISTRATION`, padrão ligado; produção pessoal roda fechado), login, reset de senha, 2FA, sessões |
| Filas / agendamento | Queue `database`, Scheduler do Laravel | Jobs para geração de recorrências, faturas, notificações, importação |
| Testes | **Pest 3+** | Feature tests por módulo, testes de unidade nos serviços de domínio. Cobertura mínima aceitável: todas as regras de negócio da seção 3 |
| Qualidade | Laravel Pint, Larastan nível 6+, Rector (opcional) | CI local via `composer check` |
| Moeda | BRL default, `pt_BR`, timezone `America/Sao_Paulo` | Campo `currency` por conta preparado para multi-moeda futura; **sem conversão cambial no MVP** |
| Valores monetários | **Inteiro em centavos** (`bigInteger amount_cents`) | SQLite não tem DECIMAL real. NUNCA usar float. Value Object `Money` com `brick/money` ou implementação própria |
| Ícones / assets | Heroicons (nativo do Filament) + Vite | Sem CDN em produção |
| Deploy alvo | Container único (Dockerfile + `docker-compose.yml` com volume para o SQLite e `storage/`) | FrankenPHP ou php-fpm+nginx; scheduler e queue worker no mesmo container via supervisord |

Pacotes permitidos (além dos acima): `spatie/laravel-medialibrary` (anexos), `spatie/laravel-activitylog` (auditoria), `league/csv` (import/export), parser OFX próprio (SGML simples; o pacote `asgrim/ofxparser` está abandonado e não instala em PHP 8.4+), `barryvdh/laravel-dompdf` (PDF de relatórios), `laravel/sanctum` (API). Qualquer outro pacote: justificar no relatório.

---

## 2. Modelo de domínio (schema)

Todas as tabelas têm `id` (ulid ou bigint autoincrement — escolha uma e mantenha), `created_at`, `updated_at`. Tabelas de dados do usuário têm `user_id` indexado (ou `household_id`, ver 2.13). Soft deletes onde indicado. Nomes em inglês no código, labels em português na UI.

### 2.1 `banks` (instituições financeiras)
- `name`, `slug`, `code` (código COMPE/ISPB, opcional), `logo_path` (opcional), `primary_color` (hex)
- Seed inicial com os ~40 bancos/fintechs mais usados no Brasil (Nubank, Itaú, Bradesco, Banco do Brasil, Caixa, Santander, Inter, C6, BTG, XP, PicPay, Mercado Pago, Sicoob, Sicredi, Banrisul, Neon, Next, Original, Safra, PagBank, Stone, Will, Digio, etc.) + entrada genérica "Carteira/Dinheiro" e "Outro"
- Usuário pode criar bancos próprios (registro com `user_id` nulo = global, preenchido = privado)

### 2.2 `accounts` (contas)
- `user_id`, `bank_id` (nullable), `name`, `type` enum: `checking` (corrente), `savings` (poupança), `wallet` (dinheiro físico), `investment`, `prepaid` (vale/benefício), `other`
- `currency` (default BRL), `initial_balance_cents`, `initial_balance_date`
- `color`, `icon`, `include_in_net_worth` bool, `include_in_dashboard` bool, `is_archived`, `sort_order`, `notes`
- Saldo NUNCA é armazenado como campo editável: é **calculado** = saldo inicial + soma de transações `cleared`/`reconciled` até a data. Pode existir cache (`cached_balance_cents`, `cached_balance_at`) invalidado por observer — se implementar cache, testar invalidação.
- Soft delete só se não houver transações; com transações → arquivar.

### 2.3 `credit_cards` (cartões de crédito)
- `user_id`, `bank_id`, `name`, `brand` enum (`visa`, `mastercard`, `elo`, `amex`, `hipercard`, `other`), `last_four` (opcional)
- `limit_cents`, `closing_day` (1–31), `due_day` (1–31), `payment_account_id` (conta que paga a fatura, nullable)
- `color`, `icon`, `is_archived`, `notes`
- Regras de fechamento: se `closing_day` > dias do mês, usar último dia do mês. O vencimento é sempre no mês seguinte ao fechamento se `due_day <= closing_day`, senão no mesmo mês (configurável por flag `due_in_next_month` bool, default calculado).
- Cartão adicional/dependente: fora do MVP.

### 2.4 `invoices` (faturas de cartão)
- `credit_card_id`, `reference_month` (YYYY-MM), `closing_date`, `due_date`, `status` enum: `open`, `closed`, `paid`, `partially_paid`, `overdue`
- `total_cents` (calculado = soma das transações vinculadas), `paid_cents`, `paid_at`
- Unique (`credit_card_id`, `reference_month`).
- Fatura é criada lazy: ao inserir a primeira transação que cai naquele período, ou pelo job diário de fechamento.

### 2.5 `categories` (categorias)
- `user_id` (nullable = padrão do sistema, copiadas para o usuário no cadastro), `parent_id` (nullable — máx. 2 níveis: categoria → subcategoria), `name`, `type` enum: `income`, `expense`, `both`
- `icon`, `color`, `is_archived`, `sort_order`
- Seed padrão em português: Alimentação (Supermercado, Restaurante, Delivery, Padaria), Moradia (Aluguel, Condomínio, Energia, Água, Internet, Gás), Transporte (Combustível, Uber/99, Transporte público, Estacionamento, Manutenção), Saúde (Plano, Farmácia, Consultas), Educação, Lazer (Streaming, Viagem, Bares), Compras (Roupas, Eletrônicos), Pessoal (Cabelo/Estética, Academia), Pets, Impostos e Taxas, Assinaturas, Presentes/Doações, Dívidas/Empréstimos, Investimentos (aportes), Outros. Receitas: Salário, Freelance/PJ, Rendimentos, Reembolso, Venda, Presente, Outros.
- Categorias especiais imutáveis: "Transferência", "Pagamento de fatura", "Ajuste de saldo" (marcadas `is_system`).

### 2.6 `tags`
- `user_id`, `name`, `color`. Pivot `taggables` polimórfico (transações).

### 2.7 `payees` (favorecidos / estabelecimentos)
- `user_id`, `name`, `default_category_id` (nullable), `notes`. Deduplicar por nome normalizado (lower, sem acento, trim). Criado automaticamente ao digitar um payee novo em transação.

### 2.8 `transactions` (o coração do sistema)
- `user_id`, `type` enum: `income`, `expense`, `transfer`, `credit_card_expense`, `credit_card_payment`, `adjustment`
- `account_id` (nullable — nulo quando `credit_card_expense`), `credit_card_id` (nullable — preenchido só em `credit_card_expense`), `invoice_id` (nullable)
- `transfer_account_id` (destino; obrigatório em `transfer`) — **modelagem de transferência**: uma única linha `transfer` com `account_id` (origem) e `transfer_account_id` (destino). Saldo da origem subtrai, do destino soma. Não criar duas linhas espelhadas (evita dessincronização). Relatórios de despesa/receita IGNORAM transferências.
- `amount_cents` (positivo para todos os tipos, exceto `credit_card_expense` que admite negativo = estorno/crédito do emissor na fatura; o sinal vem do `type` para os demais), `currency`
- `date` (data do lançamento/caixa), `competence_date` (data de competência, default = `date`) — permite lançar em setembro despesa que "pertence" a agosto
- `description`, `notes`, `payee_id` (nullable), `category_id` (nullable — obrigatório para income/expense/credit_card_expense, exceto se houver splits)
- `status` enum: `pending` (agendado/não efetivado — não afeta saldo atual, afeta saldo previsto), `cleared` (efetivado), `reconciled` (conciliado com extrato — bloqueado para edição de valor/data sem "desconciliar")
- `recurrence_id` (nullable — origem em uma regra recorrente), `recurrence_occurrence_date`
- `installment_group_id` (nullable), `installment_number`, `installment_total` (ex.: 3/12)
- `is_ignored_in_reports` bool (ex.: reembolsos que não são "renda real")
- `external_id` (hash de importação para deduplicar), `import_batch_id`
- Soft deletes. Índices: (`user_id`,`date`), (`account_id`,`date`), (`credit_card_id`,`invoice_id`), (`category_id`), (`installment_group_id`), (`recurrence_id`,`recurrence_occurrence_date`), (`external_id`).

### 2.9 `transaction_splits` (divisão de uma transação em várias categorias)
- `transaction_id`, `category_id`, `amount_cents`, `description`. Soma dos splits DEVE ser igual ao `amount_cents` da transação (validação de domínio + constraint testada).

### 2.10 `recurrences` (regras de transação recorrente / despesas fixas)
- `user_id`, `name`, tudo que uma transação tem como template (`type`, `account_id`, `credit_card_id`, `transfer_account_id`, `amount_cents`, `category_id`, `payee_id`, `description`, tags)
- `frequency` enum: `daily`, `weekly`, `biweekly`, `monthly`, `bimonthly`, `quarterly`, `semiannual`, `yearly`, `custom` (+ `interval` e `unit` para custom)
- `start_date`, `end_type` enum: `never`, `on_date`, `after_occurrences`; `end_date`, `max_occurrences`
- `day_of_month` (para mensal; se 29–31 e o mês não tem, usa último dia), `weekday` (semanal)
- `auto_confirm` bool: se true, a ocorrência já nasce `cleared` na data; se false, nasce `pending` e o usuário confirma (com possibilidade de ajustar valor — conta de luz varia)
- `generate_ahead_months` (default 3): quantos meses adiante manter ocorrências materializadas
- `is_active`, `last_generated_date`, `next_occurrence_date`
- Ocorrências geradas viram linhas em `transactions` com `recurrence_id` + `recurrence_occurrence_date` (unique) — idempotência do job.
- Editar a regra oferece: "só esta ocorrência", "esta e futuras", "todas" (todas = regenera pendentes não editadas manualmente; ocorrências `cleared` nunca são alteradas retroativamente). Ocorrência editada manualmente ganha `is_detached` (campo na transaction) e não é sobrescrita.

### 2.11 `installment_groups` (parcelamentos)
- `user_id`, `description`, `total_cents`, `installments_count`, `first_date`, `credit_card_id` (nullable), `account_id` (nullable — parcelamento em débito/boleto também existe), `category_id`, `payee_id`
- Ao criar: gera N transações (`installment_number` 1..N), valores arredondados em centavos com a diferença de arredondamento na primeira parcela (ex.: 100,00 / 3 = 33,34 + 33,33 + 33,33). Cada parcela cai na fatura correta segundo o dia de fechamento.
- Ações: editar valor/descrição de todas as parcelas futuras; **antecipar parcelas** (move parcelas escolhidas para a fatura atual, opcionalmente com desconto informado); excluir o parcelamento inteiro ou apenas parcelas futuras; ver progresso (pagas/total, restante).

### 2.12 `budgets` (orçamentos)
- `user_id`, `category_id` (nullable = orçamento global do mês), `period` enum: `monthly`, `yearly`, `custom`; `amount_cents`, `start_date`, `end_date` (nullable), `rollover` bool (sobra/estouro carrega para o mês seguinte, estilo envelope), `alert_threshold_pct` (default 80), `is_active`
- Gasto do período = soma de `expense` + `credit_card_expense` (por **competência** ou por **data**, configuração global do usuário) na categoria e subcategorias, excluindo `is_ignored_in_reports`.
- Tabela auxiliar `budget_periods` materializada por mês com `budgeted_cents`, `spent_cents`, `carried_over_cents` (recalculada por job/observer) para histórico e gráficos rápidos.

### 2.13 `goals` (metas / objetivos / cofrinhos)
- `user_id`, `name`, `target_cents`, `target_date` (nullable), `account_id` (conta vinculada onde o dinheiro fica, nullable), `initial_cents`, `icon`, `color`, `status` (`active`, `completed`, `archived`)
- `goal_contributions`: `goal_id`, `transaction_id` (nullable), `amount_cents`, `date`, `notes`. Aporte pode criar automaticamente uma transferência para a conta vinculada.
- Calcular: progresso %, aporte mensal necessário para bater a data, projeção de data de conclusão no ritmo atual.

### 2.14 `rules` (motor de regras / auto-categorização)
- `user_id`, `name`, `is_active`, `priority`, `stop_processing` bool
- `rule_conditions`: `field` (`description`, `payee`, `amount`, `account`, `credit_card`, `type`), `operator` (`contains`, `starts_with`, `ends_with`, `equals`, `regex`, `gt`, `lt`, `between`), `value`, `match_all` (AND/OR no nível da regra)
- `rule_actions`: `action` (`set_category`, `set_payee`, `add_tag`, `set_description`, `set_ignored`, `set_notes`), `value`
- Disparo: ao criar/importar transação (automático) + botão "aplicar regras" retroativo com preview (dry-run listando o que mudaria) antes de confirmar.

### 2.15 `import_batches` + `import_rows`
- Batch: `user_id`, `source` (`csv`, `ofx`), `target_account_id`/`target_credit_card_id`, `target_reference_month` (`AAAA-MM` opcional para cartão), `file_path`, `mapping` json, `status`, `rows_total`, `rows_imported`, `rows_skipped`, `rows_duplicated`
- Row: dados brutos, `parsed` json, `status` (`pending`, `imported`, `duplicate`, `ignored`, `error`), `transaction_id`
- Fluxo de staging: upload → detectar delimitador/encoding (UTF-8 e Latin-1) → mapear colunas (salvar mapping por banco para reuso; presets Nubank, Itaú, Inter, XP) → preview com dedupe (hash de data+valor+descrição normalizada → `external_id`) → aplicar regras → confirmar.
- Suporte a parcelas: campo canônico opcional `installment` (`n de N` ou `n/N`) gera sufixo ` (n/N)` na descrição (refletido no hash dedupe) e preenche `installment_number`/`installment_total` da transação.
- Pagamento de fatura em cartão: linha com valor negativo e descrição de pagamento vira `ignored` com motivo explicativo, nunca vira compra.

### 2.16 `notifications` (Laravel padrão) + `user_settings`
- `user_settings`: `user_id`, `currency`, `locale`, `timezone`, `first_day_of_month` (para quem fecha o mês no dia do salário, ex.: dia 5), `budget_basis` (`date` | `competence`), `dashboard_widgets` json (ordem/visibilidade), `notify_bills_days_before` (default 3), `notify_invoice_closing_days_before` (default 2), `notify_budget_threshold` bool, `theme` (`light`, `dark`, `system`)

### 2.17 Multiusuário
- MVP: cada usuário vê apenas seus dados (`user_id` em tudo + global scope). Preparar para "household" compartilhado (fase 9, opcional): tabela `households` + `household_user` e trocar o scope de `user_id` para `household_id`. **Não implementar household antes da fase 9.**

### 2.18 Auditoria
- `activity_log` (spatie) em transactions, accounts, credit_cards, recurrences, installment_groups, budgets, goals, rules: quem, quando, diff antes/depois.

---

## 3. Regras de negócio críticas (todas precisam de teste)

1. **Saldo de conta** = `initial_balance_cents` + Σ(income) − Σ(expense) − Σ(transfer onde é origem) + Σ(transfer onde é destino) − Σ(credit_card_payment onde é origem) ± adjustment, considerando apenas `cleared`/`reconciled` com `date <= hoje`. **Saldo previsto** em data D = mesma fórmula incluindo `pending` com `date <= D` + ocorrências recorrentes ainda não materializadas até D + faturas em aberto com vencimento <= D (pela conta pagadora).
2. **Alocação de compra no cartão em fatura**: compra na data X com `closing_day` C → se `dia(X) <= C` (ou `< C` se a config do cartão for "fecha no dia C, compras do dia já vão para a próxima" — expor a flag `purchases_on_closing_day_go_next` default true, comportamento Nubank), cai na fatura que fecha em C do mês de X; senão na fatura do mês seguinte. Testar com meses de 28/29/30/31 dias e cartão com `closing_day` 31.
3. **Vencimento** da fatura: `due_day` no mês seguinte ao fechamento quando `due_day <= closing_day`; senão mesmo mês. Se cair em fim de semana, NÃO ajustar automaticamente (manter simples; exibir aviso na UI).
4. **Limite disponível** do cartão = `limit_cents` − Σ(faturas `open`/`closed`/`partially_paid` não pagas: `total_cents − paid_cents`) − Σ(parcelas futuras ainda não faturadas). Exibir "comprometido em parcelas futuras" separadamente.
5. **Pagamento de fatura**: cria transação `credit_card_payment` com `account_id` (origem), `credit_card_id`, `invoice_id`, `amount_cents`. Pagamento parcial → status `partially_paid` e o restante fica como "saldo anterior" na próxima fatura (linha de transação `credit_card_expense` sintética com categoria de sistema "Saldo anterior da fatura", flag `is_system`). Pagamento maior que o total → gera crédito (linha negativa na próxima fatura). Pagamento de fatura NÃO é despesa no relatório de categorias (a despesa já foi contada na compra).
6. **Fechamento de fatura** (job diário): toda fatura `open` cuja `closing_date < hoje` vira `closed`; `closed` com `due_date < hoje` e não paga vira `overdue`. Fechada não recebe novas transações (nova compra com data dentro dela após fechada vai para a próxima — com aviso na UI; permitir override manual "forçar nesta fatura" para lançamentos atrasados).
7. **Parcelamento**: soma das parcelas == total, sempre; arredondamento na 1ª parcela; parcela N cai na fatura de (mês da parcela 1 + N−1); excluir grupo remove só parcelas `pending`/não faturadas em fatura fechada, a menos que o usuário confirme "excluir tudo".
8. **Recorrência**: job diário gera ocorrências até `hoje + generate_ahead_months`; idempotente (unique `recurrence_id`+`recurrence_occurrence_date`); ocorrência `is_detached` nunca é regenerada; dia 31 em mês de 30 dias → dia 30; fevereiro idem; `end_type` respeitado; pausar regra não apaga ocorrências passadas, remove apenas `pending` futuras.
9. **Transferência** não aparece em despesa nem receita; aparece no extrato das duas contas com sinais opostos.
10. **Split**: Σ splits == amount; transação com splits tem `category_id` nulo e relatórios usam os splits.
11. **Reconciliação**: usuário informa saldo do extrato em data D → sistema mostra diferença vs saldo calculado → marca transações `cleared` como `reconciled` → se sobrar diferença, oferece criar `adjustment` com categoria "Ajuste de saldo". Transação `reconciled` só é editável após "desconciliar" explicitamente.
12. **Orçamento**: `spent` respeita `budget_basis`; inclui subcategorias; rollover carrega `budgeted − spent` (positivo ou negativo) para o mês seguinte quando ativo; alerta dispara uma única vez por período ao cruzar `alert_threshold_pct` e outra ao cruzar 100%.
13. **Exclusão de conta/cartão** com transações → bloqueada; oferecer arquivar. Excluir categoria com transações → obrigar realocar para outra categoria.
14. **Datas e timezone**: tudo em `America/Sao_Paulo`; `date` é DATE puro (sem hora) para evitar bug de fuso.
15. **Dinheiro**: nunca float. Input aceita "1.234,56" e "1234.56"; armazena centavos; exibe `R$ 1.234,56`.
16. **Estorno no cartão**: `credit_card_expense` com `amount_cents` negativo representa estorno/crédito do emissor na fatura; reduz `total_cents` da fatura e o limite usado (`total_cents − paid_cents`), reduz o gasto da categoria nos relatórios e no orçamento, tem efeito zero no saldo de conta, não aceita `splits` e na importação de fatura linha com valor negativo vira estorno.

---

## 4. UX / telas (Filament 5)

Layout com sidebar: Dashboard · Transações · Contas · Cartões · Recorrências · Parcelamentos · Orçamentos · Metas · Relatórios · Importar · Regras · Categorias · Configurações. Dark mode. Responsivo (mobile funcional: lançar transação em ≤ 3 toques do dashboard via botão flutuante "+").

Regras gerais de tabela e cabeçalho (rodada de UX de 2026-09-06): **nenhuma tela rola na horizontal** em 390, 1150 ou 1440 px. Tabela tem no máximo 5 colunas; informação secundária vai na segunda linha da coluna a que pertence; status é ícone com tooltip; ações de linha ficam num menu; no celular cada linha é um cartão de até 3 linhas (título, valor, meta), nunca uma pilha de blocos rotulados. Cabeçalho de página tem uma ação primária e as demais em cinza; navegação de mês em botões de ícone.

### 4.1 Dashboard
Widgets reordenáveis (config do usuário):
- Saldo total (contas ativas, `include_in_dashboard`) + variação vs mês anterior
- Receitas / Despesas / Resultado do mês + comparação com mês anterior
- Saldo previsto para o fim do mês (regra 3.1)
- Contas: lista com saldo por conta e ícone/cor do banco
- Cartões: fatura atual (aberta) de cada cartão, valor, fecha em X dias, limite disponível, barra de uso
- Próximos vencimentos (7/15/30 dias): faturas + recorrências pendentes + parcelas
- Orçamentos do mês: barras por categoria com % e alerta
- Gastos por categoria (donut) do mês
- Fluxo de caixa 12 meses (barras receita x despesa + linha saldo)
- Metas: progresso
- Atalhos rápidos: + Despesa, + Receita, + Transferência, + Compra no cartão

### 4.2 Transações
- Tabela unificada com filtros: período (presets: hoje, semana, mês, mês anterior, ano, custom), conta, cartão, categoria, tag, payee, tipo, status, valor (faixa), texto; ordenação; totais do filtro no rodapé (receita, despesa, resultado); agrupamento opcional por dia
- Ações em massa: categorizar, adicionar tag, marcar cleared, excluir, mover de conta
- Form de criação/edição com abas por tipo (Despesa · Receita · Transferência · Cartão) — campos condicionais, na ordem valor (campo grande, foco inicial, teclado decimal) → data → descrição → conta/cartão → categoria → favorecido → status; competência, etiquetas, divisão, observações e anexos ficam numa seção "Mais detalhes" recolhida, e Parcelar/Repetir em seções recolhidas até o toggle ligar; o modal "Lançamento rápido" usa o mesmo form e cabe numa tela de 900 px sem rolar; toggle "Repetir" (abre config de recorrência) e "Parcelar" (número de parcelas, preview das datas/faturas); autocomplete de payee com sugestão de categoria; upload de anexo (comprovante); split
- Detalhe: histórico de auditoria, anexos, parcelas irmãs, ocorrências irmãs
- Navegação por mês (‹ Setembro 2026 ›) padrão dos apps BR

### 4.3 Contas
- Cards por conta (logo/cor do banco, saldo, saldo previsto); extrato por conta com saldo acumulado linha a linha; ação "Reconciliar"; ação "Ajustar saldo"; arquivar

### 4.4 Cartões
- Card por cartão: limite, usado, disponível, comprometido em parcelas, fatura atual, "melhor dia de compra" (dia após fechamento)
- Página do cartão: navegação por fatura (‹ Set/2026 ›), status, lista de lançamentos da fatura, subtotal por categoria, botão "Pagar fatura" (total/parcial, escolher conta, data), botão "Reabrir fatura" (admin da própria conta), lista de parcelamentos ativos no cartão

### 4.5 Recorrências
- Lista com próxima ocorrência, frequência, valor, conta/cartão, status; calendário mensal das ocorrências; ações pausar/retomar/encerrar; página de "Pendentes de confirmação" (ocorrências `pending` vencidas — confirmar com valor ajustado, pular, ou adiar)

### 4.6 Parcelamentos
- Lista com progresso (3/12), restante, próximo vencimento, cartão; detalhe com todas as parcelas; ações: antecipar, editar futuras, encerrar

### 4.7 Orçamentos
- Visão do mês: por categoria — orçado, gasto, restante, barra, rollover acumulado; copiar orçamento do mês anterior; sugerir orçamento pela média dos últimos 3 meses; gráfico de evolução orçado x gasto 12 meses

### 4.8 Metas
- Cards com progresso, prazo, aporte sugerido/mês; aporte rápido; histórico

### 4.9 Relatórios (todos com filtro de período, exportação CSV/PDF e gráficos)
1. Despesas por categoria (donut + tabela drill-down até subcategoria e transações)
2. Receitas por categoria
3. Receita x Despesa por mês (12/24 meses) com resultado
4. Fluxo de caixa diário/mensal com saldo acumulado
5. Evolução do patrimônio (net worth) mensal: ativos (contas) − passivos (faturas em aberto + parcelas futuras)
6. Gastos por cartão e por fatura (comparativo entre meses)
7. Gastos por payee (top 20)
8. Gastos por tag
9. Orçado x Realizado por categoria (período)
10. Comparativo ano a ano (mesmo mês, anos diferentes)
11. Despesas fixas x variáveis (fixas = originadas de recorrência ou categoria marcada como fixa)
12. Projeção de saldo 90 dias (dia a dia, considerando pendentes, recorrências, parcelas e faturas)
13. Tendência por categoria (média móvel 3 meses)

### 4.10 Importação / Exportação
- Wizard CSV/OFX (2.15): seleção de fatura-alvo para cartão (faturas existentes ou próximos meses calculados, desabilitando pagas), mapeamento de colunas incluindo parcela opcional e prévia com motivo de linhas ignoradas. Exportação completa em CSV por entidade e backup do arquivo SQLite (download `.sqlite` + JSON de todas as entidades do usuário). Restauração de backup JSON.

### 4.11 Regras
- CRUD com builder de condições/ações; testar regra contra transações existentes (preview) e aplicar retroativamente

### 4.12 Configurações
- Perfil, senha, 2FA, preferências (2.16), gerenciar categorias/tags/payees (merge de payees duplicados), exclusão de conta (LGPD: apaga tudo)

### 4.13 Notificações
- Sino no topo (database notifications) + e-mail opcional: fatura fecha em N dias, fatura vence em N dias, fatura vencida, recorrência pendente de confirmação, orçamento em 80%/100%, meta concluída, importação finalizada

---

## 5. API REST (fase 8)
- Sanctum tokens pessoais; prefixo `/api/v1`; JSON:API-like simples
- Endpoints: accounts, credit-cards, invoices, categories, tags, payees, transactions (com filtros da 4.2), recurrences, installments, budgets, goals, reports/summary, reports/by-category, reports/cash-flow
- Rate limit, paginação, validação com Form Requests, resources com `amount` em centavos + `amount_formatted`
- Documentação OpenAPI gerada (scramble ou similar)

---


## 6. Critério de aceite final (Definition of Done do projeto)

- [ ] `composer check` verde (pint, larastan ≥ nível 6, pest) com ≥ 250 testes cobrindo todas as regras da seção 3
- [ ] `docker compose up` sobe a aplicação, scheduler e queue; `DemoSeeder` popula 12 meses de dados realistas; login com usuário demo funciona
- [ ] Todas as telas da seção 4 implementadas e navegáveis, em português, com dark mode e mobile funcional
- [ ] Todos os 13 relatórios entregues com exportação
- [ ] Importação CSV/OFX funcional com dedupe comprovado por teste de reimportação
- [ ] API v1 documentada e testada
- [ ] `docs/` completo: README, ARCHITECTURE, ROADMAP (todas as fases marcadas), CHANGELOG, USER_GUIDE, QUESTIONS, reports/fase-0..9

