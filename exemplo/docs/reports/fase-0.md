Review #1

# Review da fase 0 — Fundação

## Resultado do check
Comando `scripts/check.sh` (único aceite, AGENTS.md regra 8). Saída literal:
```
{"tool":"pint","result":"passed"}{"tool":"phpstan","result":"passed","errors":0}
{"tool":"pest","result":"passed","tests":90,"passed":90,"assertions":293,"duration_ms":1078}
CHECK: PASS
```
Complemento: `php artisan about` funciona (Laravel 13.30.1, PHP 8.5.8, Filament v5.7.8, Livewire v4.4.3, Timezone America/Sao_Paulo, Locale pt_BR, Database sqlite, Queue database).

## Aceite da fase (item → OK/FALHA + evidência)
Aceite da fase (ROADMAP.md:7): "app sobe, login funciona, `composer check` verde, CI configurada".

- app sobe → OK. `php artisan about` funciona; `config/database.php:35-45` SQLite default com `foreign_key_constraints` (`config/database.php:40`), `busy_timeout` (`config/database.php:41`), `journal_mode` WAL (`config/database.php:42`) + reforço em `app/Providers/AppServiceProvider.php:47-49`; `Dockerfile` (FrankenPHP `dunglas/frankenphp:1-php8.4-bookworm`, `Dockerfile:22`) + `docker-compose.yml:6-15` (binds `./database`, `./storage`, porta 8000) + `docker/supervisord.conf:21-46` (frankenphp + queue:work + schedule:work); `.env.example:24,32-44` (sqlite, pragmas, queue database); teste `tests/Feature/Deploy/DeployConfigTest.php:56-84` (Dockerfile PHP 8.4+ e extensões, compose persistente, supervisord web+queue+scheduler). Task 0.1: `AGENTS.md:1` continua `# finance-iam — protocolo`, `.gitignore:19` contém `/logs/`, `composer.json:9` `"php": "^8.4"`. Task 0.7: seção "Rodando o app" existe em `README.md:54-77` (arquivo preservado, não substituído).
- login funciona → OK. Registro: `tests/Feature/Auth/RegistrationTest.php:12-37` (cria usuário + settings defaults, redirect `/home`); login válido/inválido/logout/guard: `tests/Feature/Auth/AuthenticationTest.php:12-47`; reset: `tests/Feature/Auth/PasswordResetTest.php:17-44`; 2FA TOTP ativar/confirmar/challenge/recovery/desativar: `tests/Feature/Auth/TwoFactorTest.php:49-129`; painel Filament `/app` usa mesmos usuários Fortify guard `web`: `tests/Feature/Filament/AppPanelTest.php:30-42` + redirect guest `tests/Feature/Filament/AppPanelTest.php:22-28`. Implementação: Fortify headless + `app/Providers/Filament/AppPanelProvider.php:28` (`->login()`), `config/app.php:68-85` (timezone, locale pt_BR, faker pt_BR).
- `composer check` verde → OK. `composer.json:55-59` define `check` = pint --test + phpstan + pest e `lint`/`test`; `scripts/check.sh:1-17` delega a `composer check`; resultado literal acima: pint passed, phpstan errors 0, pest 90/90. Tasks 0.2 e 0.8 cobertas por esse verde.
- CI configurada → OK. `.github/workflows/ci.yml:1-35` (on push+PR, PHP 8.4 em `ci.yml:19`, extensões sqlite/intl/bcmath, `composer install` + `composer check` em `ci.yml:35`). `composer.json:9` + `Dockerfile:22` + `ci.yml:19` alinhados em PHP 8.4 (regra global 11).
- Itens das tasks 0.3–0.9 (detalhamento do aceite) → todos OK: 0.3 auth+settings+locale (testes acima + `tests/Feature/Settings/UserSettingsTest.php:10-55`); 0.4 Money (ver seção 3, regra 15); 0.5 Domain `app/Domain/{Accounts,Cards,Transactions,Recurrences,Installments,Budgets,Goals,Rules,Imports,Reports,Users,Shared}/` + scope `app/Models/Concerns/CurrentUserScope.php:25-33` + trait `BelongsToUser` + `app/Policies/UserOwnedPolicy.php:31-73` (fail-closed em `owns`, `UserOwnedPolicy.php:69-72`), provados por `tests/Feature/Domain/OwnershipTest.php:25-107` e `tests/Unit/Domain/DomainExceptionsTest.php:17-41`; 0.6 tema Filament (`AppPanelProvider.php:29-45`: brand Finance IAM, Teal/Slate, darkMode, theme asset local) provado por `tests/Feature/Filament/AppPanelTest.php:44-85` (identidade, sem CDN, sidebar SPEC 4 com 12 labels e páginas OK); 0.9 `docs/ARCHITECTURE.md:1-153` (centavos, transfer single-row, invoice lazy, competência, PHP 8.4+); 0.1 docs oficiais consultadas: `docs/notes/laravel13.md`, `docs/notes/filament5.md`, `docs/notes/livewire4.md`, `docs/notes/fortify.md`, `docs/notes/frankenphp.md`.

## Regras da seção 3 tocadas (regra → OK/FALHA + teste)
A fase 0 só toca as regras transversais 3.14 e 3.15. As regras 3.1–3.13 têm implementação e testes previstos nas fases 1–8 do ROADMAP e não são exigíveis nesta fase (não são FALHA).

- 3.14 Datas e timezone (tudo America/Sao_Paulo, `date` DATE puro) → OK. Código: `config/app.php:68` timezone default `America/Sao_Paulo`, `config/app.php:81-85` locale/fallback/faker `pt_BR`, `.env.example:7-10` mesmos defaults. Teste: `tests/Feature/Settings/UserSettingsTest.php:10-15` (timezone, `date_default_timezone_get`, locale, faker_locale) + defaults por usuário em `tests/Feature/Settings/UserSettingsTest.php:17-34` e `tests/Feature/Auth/RegistrationTest.php:25-36`.
- 3.15 Dinheiro nunca float, centavos, parse "1.234,56"/"1234.56", exibe `R$ 1.234,56` → OK. Código: `app/Domain/Shared/Money.php:15-17` (readonly, int cents, "Nunca float"), `Money.php:28-47` parse, `Money.php:61-76` format BRL, `Money.php:138-153` allocate resto na 1ª parcela (base de 2.11/3.7). Testes: `tests/Unit/Domain/Shared/MoneyTest.php:7-126` (parse todos os formatos em `MoneyTest.php:11-27`, rejeição `MoneyTest.php:29-41`, formato `MoneyTest.php:43-48`, soma sem float `MoneyTest.php:50-55`, allocate exato `MoneyTest.php:82-100`, imutabilidade `MoneyTest.php:106-114`).
- 3.1–3.13 → não tocadas pela fase 0 (sem código nem teste exigido aqui; cobertura virá nas fases 1–8). Sem FALHA.

## Sinais de contorno encontrados
- teste `skip` / `markTestSkipped`: nenhum (grep em `tests/*.php` só achou a palavra "comportamento" em comentário de `tests/Support/OwnedWidgetPolicy.php:10`).
- asserção trivial: nenhuma — 293 assertions em 90 testes, todas com valores concretos (ex.: `MoneyTest.php:14-27`, `OwnershipTest.php:87-95`, `DeployConfigTest.php:40-53`).
- código de produção citando mock/teste: nenhum em `app/`.
- float em dinheiro: uso legítimo e isolado — `Money.php:55-58` `toFloat()` documentado "só para exibição/cálculo externo. Nunca persistir" + `Money.php:93-100` `multiply(int|float)` com `round(..., PHP_ROUND_HALF_UP)`; armazenamento é int centavos (`Money.php:17`), testes provam ausência de float (`MoneyTest.php:50-64`). Não é contorno.
- lógica de negócio em Resource/Controller/Livewire: nenhuma — Filament Pages são placeholders puros (ex.: `app/Filament/App/Pages/Transactions.php:8-21`, só navegação/view); domínio em `app/Domain/`, scope/policy em `app/Models/Concerns/`, `app/Policies/`.
- `TODO`/`FIXME` sem entrada no ROADMAP: nenhum em `app/` ou `tests/` (grep só achou "Nunca float" em comentário de `Money.php:13`).

## Gaps e tasks corretivas sugeridas (formato `- [ ] N.Fx descrição (aceite: ...)`)
Nenhum gap. Tasks `[!]`/`[-]` na fase 0: nenhuma (informado no pedido; confirmado: ROADMAP fase 0 só tem `[x]` 0.1–0.9). Nenhuma FALHA, logo nenhuma corretiva `0.Fx`.

Veredito: APROVADA
