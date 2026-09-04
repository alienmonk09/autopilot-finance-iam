# ARCHITECTURE — finance-iam

Decisões arquiteturais implementadas na fase 0 e contratos que as fases 1–9 devem respeitar. A SPEC (`docs/SPEC.md`) é a única fonte de escopo; este documento registra o *como*.

## 1. Visão geral

Laravel 13 + SQLite + Filament 5 + Livewire 4 em **container único** (`Dockerfile`, `docker-compose.yml`).
FrankenPHP serve o app; queue e scheduler rodam no mesmo container via supervisord
(`docker/supervisord.conf`: `queue:work database` + `schedule:work`).
Fila `database` (`QUEUE_CONNECTION=database` no `.env.example`; `config/queue.php:16`).
Scheduler (`schedule:work`, não cron externo) executa os 4 comandos diários
(`bootstrap/app.php:18-21`): `invoices:close` (fechamento de faturas, 3.6),
`recurrences:generate` (ocorrências, 3.8), `budgets:alert` (alerta 1× por
faixa, 3.12) e `notifications:send` (SPEC 4.13).
UI = painel Filament em `/app` (`app/Providers/Filament/AppPanelProvider.php`), não admin genérico:
tema próprio, dark mode, telas customizadas em Livewire só quando o Filament não cobrir (SPEC 1, 4).
Auth: Fortify headless + telas Blade próprias (registro, login, reset, 2FA TOTP);
o painel usa login nativo do Filament (`->login()`, guard `web`, mesmo model `User`
com `canAccessPanel` liberando o painel `app`) — mesma conta nos dois.
Deploy: `docker compose up` sobe tudo; SQLite em `./database` e uploads/cache em
`./storage` via bind mounts (dados sobrevivem a rebuilds); `public/build` é gerado
no build e nunca montado por volume. Painel usa `->theme(asset(...))` vanilla
(`public/css/filament/app/theme.css`, zero build) e a fonte Inter autohospedada do
dist do Filament — sem CDN em produção (SPEC 1). `DemoSeeder`
(`database/seeders/DemoSeeder.php`) popula 12 meses de dados realistas para
`demo@example.com` / `demo1234` (Conta Corrente Itaú, Poupança Caixa,
Carteira, cartão Nubank com faturas via domínio, recorrência Internet Claro,
parcelamento 10× de sofá): idempotente via `firstOrCreate` (user_id + nome) +
early-return quando o demo já tem transações; roda com
`php artisan db:seed --class=DemoSeeder`. O wizard `Onboarding`
(`app/Filament/App/Pages/Onboarding.php`, `/app/onboarding`, com
`App\Domain\Onboarding\OnboardingService`) guia usuários novos em 3 passos
(conta → cartão opcional → importar/lançar/dashboard).

## 2. PHP 8.4+

Mínimo `^8.4` em `composer.json:9`; `Dockerfile:22` (`dunglas/frankenphp:1-php8.4-bookworm`);
CI fixa `php-version: '8.4'` (`.github/workflows/ci.yml:19`).
Todo código novo usa `declare(strict_types=1)`, classes `readonly` onde imutável
(ex.: `app/Domain/Shared/Money.php:15`) e enums nativos para estados
(`type`, `status`, `frequency`, `period` — SPEC 2.2–2.16).
Nada de sintaxe que exija PHP > 8.4 sem atualizar os três lugares acima.

## 3. Dinheiro em centavos

Todo valor monetário é `bigInteger ..._cents`, **sempre positivo + sinal via `type`**,
nunca `float`/`decimal` (SPEC 1, 3.15).
Value Object único: `App\Domain\Shared\Money` (`app/Domain/Shared/Money.php`):
`parse()` aceita `"1.234,56"`, `"1234,56"`, `"1234.56"`, `"1234"`, `"R$ 1.234,56"`
com sinal opcional; `format()` devolve `"R$ 1.234,56"` (NumberFormatter `pt_BR` com
NBSP normalizado para espaço simples); `allocate($n)` divide em N partes cuja soma
é exata, com o resto do arredondamento na **primeira** parcela
(ex.: 100,00 / 3 = 33,34 + 33,33 + 33,33 — base do parcelamento, SPEC 2.11/3.7).
`toFloat()` existe só para exibição/cálculo externo — nunca persistir.
Formulários fazem parse na borda e convertem para centavos antes de chamar o Domain.

## 4. Transfer single-row

Transferência é **uma única linha** `transfer` com `account_id` (origem) +
`transfer_account_id` (destino) — nunca duas linhas espelhadas (SPEC 2.8/3.9).
Saldo: origem subtrai, destino soma. Relatórios de despesa/receita **ignoram**
transferências; elas aparecem no extrato das duas contas com sinais opostos.
Contrato para fases 2–7: queries de categoria/relatório filtram `type != transfer`;
`TransferService` valida origem ≠ destino e roda em `DB::transaction`.

## 5. Invoice lazy

Fatura (`invoices`, SPEC 2.4) **não é pré-criada**: nasce ao inserir a primeira
transação do período ou via job diário de fechamento.
Unique (`credit_card_id`, `reference_month YYYY-MM`).
`status`: `open` → `closed` (job diário quando `closing_date < hoje`) →
`paid` / `partially_paid` / `overdue` (`closed` com `due_date < hoje` e não paga).
`total_cents` é calculado (soma das transações vinculadas), nunca editado à mão.
Alocação compra→fatura (SPEC 3.2): `dia(compra) <= closing_day` cai na fatura do mês,
senão na do mês seguinte (flag `purchases_on_closing_day_go_next`, default true);
`closing_day` maior que os dias do mês usa o último dia; fatura fechada não recebe
lançamentos novos (override manual "forçar nesta fatura" permitido, com aviso).
Pagamento (SPEC 3.5) cria `credit_card_payment` (conta origem + cartão + fatura);
parcial gera linha sintética "Saldo anterior da fatura" na próxima; excedente gera
crédito; pagamento **não** é despesa em relatório (a despesa foi a compra).

## 6. Competência vs caixa

Toda transação tem `date` (caixa, DATE puro sem hora — SPEC 3.14) e
`competence_date` (default = `date`, SPEC 2.8).
Orçamentos somam `expense` + `credit_card_expense` por **uma** das duas bases,
conforme `user_settings.budget_basis` (`date` | `competence`, default `date` —
`database/migrations/2026_09_03_041228_create_user_settings_table.php:21`).
Contrato: `BudgetCalculator` (fase 6) e relatórios (fase 7) sempre leem a base
configurada; nunca hardcoded. Usuário com `first_day_of_month` ≠ 1 (mês salarial)
é tratado na camada de período, não mudando o significado das colunas.

## 7. Multi-tenancy por user_id

Toda tabela de dados do usuário tem `user_id` indexado + três camadas (SPEC 2.17):
global scope `CurrentUserScope` (`app/Models/Concerns/CurrentUserScope.php`) filtra
`user_id = Auth::id()`; trait `BelongsToUser`
(`app/Models/Concerns/BelongsToUser.php`) aplica o scope, preenche `user_id` no
`creating` e expõe `user()`; `UserOwnedPolicy`
(`app/Policies/UserOwnedPolicy.php`) nega por padrão (`owns()` fail-closed) e é
ligada via `#[UsePolicy]` nativo do Laravel 13, sem `AuthServiceProvider`.
Sem usuário autenticado (console, migrations, seeds, fila) o scope não filtra —
esses contextos não podem quebrar. **Household compartilhado NÃO foi
implementado**: era a task 9.3 (SPEC 2.17), marcada `[-]` no ROADMAP como fora
do escopo do modo autônomo. O scope central continua sendo `user_id`; trocar
para `household_id` segue como trabalho futuro e manual.

## 8. Lógica de negócio em app/Domain/

Estrutura existente: `app/Domain/{Accounts,Cards,Transactions,Recurrences,
Installments,Budgets,Goals,Rules,Imports,Reports,Users,Exports,Onboarding,
Shared}/`.
Regra: Actions/Services no Domain; Resources/Controllers/Livewire só orquestram
(validar input → chamar Action → renderizar). Toda operação multi-tabela usa
`DB::transaction`. Todo job agendado é **idempotente** com teste de dupla execução
(recorrências: unique `recurrence_id` + `recurrence_occurrence_date`; importação:
`external_id` hash data+valor+descrição; fechamento de fatura: transição de estado
condicional; alertas de orçamento: 1× por faixa por período; DemoSeeder:
`firstOrCreate` + early-return). Exceções de domínio herdam de `DomainException`
(`app/Domain/Shared/DomainException.php:14`), uma subclasse final por contexto
(ex.: `AccountException`). Regras da SPEC seção 3 exigem teste Pest **antes** da
implementação (TDD); sem `skip`, sem TODO sem entrada no ROADMAP.

## 9. SQLite, timezone, locale, moeda

SQLite é o **único** banco: `DB_CONNECTION=sqlite` (`.env.example:24`), pragmas
`foreign_keys=true`, `busy_timeout=5000`, `journal_mode=WAL` via
`config/database.php:40-42` (chave ausente = não aplica, inclusive `:memory:`)
reforçados em `AppServiceProvider::enforceSqlitePragmas`
(`app/Providers/AppServiceProvider.php:47-49`). Testes rodam em `:memory:`.
Sem feature exclusiva de Postgres/MySQL. Timezone `America/Sao_Paulo`,
locale e fallback `pt_BR`, faker `pt_BR` (`config/app.php:68-85`);
`user_settings` repete os defaults por usuário (`currency BRL`, `budget_basis date`).
Campo `currency` existe por conta para multi-moeda futura, mas **sem conversão
cambial no MVP** (SPEC 1): agregações assumem BRL.

## 10. Mapa de contextos e convenções

| Contexto | Responsabilidade (SPEC) |
|---|---|
| `Accounts` | Contas, saldo calculado + previsto (3.1), extrato, reconciliação (3.11), arquivamento (3.13), cache de saldo (`AccountCachedBalance`: `cached_balance_cents`/`cached_balance_at`, null = stale, invalidação por observer com teste), conta `investment` com atualização manual de saldo (`AdjustInvestmentBalance`, sem cotação online) |
| `Cards` | Cartões, faturas lazy, alocação/vencimento/limite/pagamento/fechamento (3.2–3.6) |
| `Transactions` | CRUD, transfer single-row (3.9), splits (3.10), status pending/cleared/reconciled, anexos, auditoria |
| `Recurrences` | Regras recorrentes, job idempotente, dia 31/fevereiro, esta/futuras/todas, `is_detached` (3.8) |
| `Installments` | Parcelamentos, soma exata com resto na 1ª, antecipação, cancelamento (3.7) |
| `Budgets` | `BudgetCalculator`, rollover, alerta 1× por faixa (3.12) + `budget_periods` materializada |
| `Goals` | Metas, aportes (transferência opcional), projeção de conclusão |
| `Rules` | Motor de regras, prioridade/stop, dry-run retroativo |
| `Imports` | CSV (`CsvParser` com autodetect de delimitador/encoding + `ImportMapper` com mapping salvo por banco) / OFX (parser próprio SGML, sem pacote externo), staging → mapping → preview → confirmar (`/app/import`), dedupe por `external_id`, regras aplicadas na confirmação, reimportação sem duplicar (testada) |
| `Reports` | 13 relatórios (4.9, `/app/reports`), SQL agregado sem N+1 (checados com `EXPLAIN QUERY PLAN` na fase 9), exportação CSV (`;`, BOM UTF-8, Money formatado) e PDF |
| `Users` | Registro, `user_settings`, categorias padrão clonadas via evento (`EnsureDefaultUserSettings`) |
| `Exports` | CSV por entidade (`EntityCsvExporter`), backup JSON versionado + restore com wipe atômico (`BackupService`), download do SQLite — tudo em `/app/backup` |
| `Onboarding` | `OnboardingService` (passo atual/progresso) + wizard `/app/onboarding` |
| `Shared` | `Money`, `DomainException`, convenções transversais |

Convenções: `DomainException` por contexto; testes Pest cobrindo **todas** as regras
da seção 3 (aceite final: `composer check` verde com ≥ 250 testes); fixtures
realistas em português (iFood, Uber, Conta de Luz, Aluguel, Salário) com valores
plausíveis em centavos; qualidade via `composer check` (Pint + Larastan nível 6+ +
Pest) e CI em push/PR (`.github/workflows/ci.yml`).
Testes de unidade do Domain são Pest puro (sem TestCase do Laravel); feature tests
usam SQLite `:memory:` com `actingAs`/login para exercer scope + policy.
Auditoria via `spatie/laravel-activitylog` em transactions, accounts, credit_cards,
recurrences, installment_groups, budgets, goals e rules (SPEC 2.18);
anexos via `spatie/laravel-medialibrary`; CSV via `league/csv`; OFX com parser
próprio (o pacote `asgrim/ofxparser` não instala em PHP 8.4+); PDFs via
`barryvdh/laravel-dompdf`; API v1 via Sanctum (`routes/api.php`, prefixo
`/api/v1`, token em `POST /api/v1/tokens`, throttle, paginação, centavos +
`amount_formatted`, OpenAPI via `dedoc/scramble`). Categorias têm flag
`is_fixed` (fase 9.5): o relatório fixas × variáveis considera fixa a
transação originada de recorrência OU com categoria marcada fixa (granularidade
por split). Qualquer pacote além
desses exige justificativa no report da task.

## 11. Estado final (fases 1–9) — o que este documento já reflete

As fases 1–9 estão implementadas sem mudar as decisões das seções 1–10:
centavos, transfer single-row, invoice lazy, competência/caixa via
`budget_basis`, multi-tenancy por `user_id` (sem household), Domain com
`DB::transaction` e jobs idempotentes. Destaques por fase para quem for ler
o código: fase 1 — saldo calculado/previsto e arquivamento (3.1, 3.13);
fase 2 — transferências, splits, reconciliação (3.9–3.11), modal de
lançamento rápido global (botão + na topbar e FAB mobile); fase 3 —
alocação/vencimento/limite/pagamento/fechamento (3.2–3.6); fase 4 —
parcelamentos com soma exata e antecipação (3.7); fase 5 — recorrências
idempotentes com cascata esta/futuras/todas (3.8); fase 6 — orçamentos com
rollover e alertas 1× por faixa (3.12) + metas com projeção; fase 7 — 13
relatórios sem N+1 com CSV/PDF, dashboard com widgets reordenáveis
(`user_settings.dashboard_widgets`), notificações database + mail; fase 8 —
importação CSV/OFX com dedupe, regras com dry-run, backup/restore, API
Sanctum; fase 9 — índices revisados, cache de saldos, `is_fixed`,
`investment` sem cotação, onboarding + DemoSeeder. Rotas do painel em
`/app/*` (ver `docs/USER_GUIDE.md`); API em `/api/v1/*` (SPEC 5).
