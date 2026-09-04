# Filament 5 — resumo (doc oficial consultada em 2026-09-03)

- Requisitos: PHP 8.2+, Laravel 11.28+, Tailwind CSS 4.1+.
- Instalação panel builder: `composer require filament/filament:"^5.0"` + `php artisan filament:install --panels`
  (cria `app/Providers/Filament/AdminPanelProvider.php`; registrar em `bootstrap/providers.php` se ausente).
- No PowerShell usar `"~5.0"` em vez de `"^5.0"`.
- Criar usuário: `php artisan make:filament-user`; painel default em `/admin`.
- Publicar config: `php artisan vendor:publish --tag=filament-config` → `config/filament.php`.
- Nesta task 0.2: SÓ `composer require`, sem `filament:install --panels` (scaffold do painel é da task 0.6).
- Fonte: https://filamentphp.com/docs/5.x/introduction/installation

## Painel custom (task 0.6, verificado no vendor + docs 5.x)

- Novo painel: `php artisan make:filament-panel app` → `app/Providers/Filament/AppPanelProvider.php`
  (`PanelProvider::panel(Panel $panel)`), registrar em `bootstrap/providers.php`, `->id('app')->path('app')`.
- Template canônico do provider (ver `PanelProviderClassGenerator` no vendor): `->login()`,
  `->colors([...])`, `->discoverPages()/->pages([Dashboard::class])`, `->middleware([... EncryptCookies,
  AddQueuedCookiesToResponse, StartSession, AuthenticateSession, ShareErrorsFromSession,
  PreventRequestForgery (Laravel 12+, senão VerifyCsrfToken), SubstituteBindings,
  DisableBladeIconComponents, DispatchServingFilamentEvent])`, `->authMiddleware([Authenticate::class])`.
- Auth: `User` implementa `Filament\Models\Contracts\FilamentUser::canAccessPanel(Panel $panel): bool`;
  sem isso, em produção qualquer autenticado entra. `->login()` usa o guard `web` (mesmos usuários do Fortify).
- Cores: `->colors(['primary' => Color::Teal, ...])` (`Filament\Support\Colors\Color`; aceita hex/RGB e gera a
  paleta 50–950). Paleta default genérica = primary Amber: trocar é o que mais tira cara de "admin genérico".
- FONTES SEM CDN: NÃO chamar `->font('X')` sem provider (cai no `BunnyFontProvider` = `fonts.bunny.net`!).
  Sem `->font()`, o painel usa `Inter Variable` autohospedada no dist do Filament via `LocalFontProvider`
  (zero requisição externa). Para família custom autohospedada: `->font('Nome', url: asset(...),
  provider: LocalFontProvider::class)`.
- TEMA: `->viteTheme('resources/css/...')` exige manifest do Vite (500 sem `npm run build`, quebra Pest/CI).
  Para CSS sem build: `->theme(asset('css/filament/app/theme.css'))` com CSS vanilla commitado em `public/`.
  Stub oficial do tema Tailwind (`stubs/ThemeCss.stub`): `@import '.../vendor/filament/filament/resources/css/theme.css'`
  + `@source` de `app/Filament/**` e `resources/views/filament/**` — só migrar para `viteTheme` quando houver
  build garantido (Docker/CI com `npm run build`).
- Páginas custom: `class X extends Filament\Pages\Page` com `protected static ?string $navigationLabel`,
  `protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedY` (`Filament\Support\Icons\Heroicon`),
  `$navigationGroup`, `$navigationSort`, `$title`, e `protected string $view = 'filament.app.pages.x'`
  (instância, não estática). View usa `<x-filament-panels::page>` + `<x-filament::empty-state heading=""
  description="" icon="heroicon-o-..." />` ou `<x-filament::section heading="" description="" icon="">`.
  Classes Tailwind arbitrárias nas views SÓ funcionam com tema Vite compilado (docs de styling).
- Dark mode: `->darkMode()` ligado por padrão; `->defaultThemeMode(ThemeMode::System)` (`Filament\Enums\ThemeMode`);
  `->themeSwitcher(false)` esconde o toggle; `->darkMode(isForced: true)` força escuro.
- Logo: `->brandName()`, `->brandLogo(fn () => view(...))` (HTML/SVG inline), `->darkModeBrandLogo(...)`,
  `->brandLogoHeight('2rem')`, `->favicon(asset(...))`. SVG com `style` inline independe do build do tema.
- `User::canAccessPanel` restrito por `$panel->getId()` quando houver mais de um painel.

## Campos reativos + testes de form (task 2.4, docs 5.x forms/overview + forms/select)

- Campo reage a cada troca com `->live()` (`->reactive()` é alias, mesmo trait `HasStateBindingModifiers`).
- `->afterStateUpdated(fn (Set $set, Get $get, mixed $livewire, $state) => ...)` (`Filament\Schemas\Components\Utilities\Set/Get`;
  `$old`/`$oldRaw` e `$operation` também injetáveis; props da página via `data_get($livewire, 'prop')`).
- `$set('outro', $valor)` só muda estado do frontend (hook do outro campo NÃO roda, salvo `shouldCallUpdatedHooks: true`).
- Em teste: `Livewire::test(Page::class)->set('data.campo', $id)` dispara o hook; `->assertFormSet(['campo' => $id])`
  confere o estado (`vendor/filament/forms/src/Testing/TestsForms.php`).

## Ação global topbar + FAB (task 2.7, docs 5.x components/action + advanced/render-hooks)

- Componente Livewire (`HasActions, HasSchemas` + `InteractsWithActions, InteractsWithSchemas,
  RestrictsFileUploadsToSchemaComponents`) com método `nomeAction(): Action`; na view `{{ $this->nomeAction }}`
  + `<x-filament-actions::modals />`; segundo gatilho via `wire:click="mountAction('nome')"`.
- Registro global no painel: `->renderHook(PanelsRenderHook::TOPBAR_END, fn (): string =>
  Blade::render("@livewire('componente')"))` (`Filament\View\PanelsRenderHook`).
- `Action::make()->authorize('create', Model::class)` resolve a policy `create(User)`; `halt()` lança exceção
  (código após ele não executa); notificação com botão usa `Notification::make()->actions([Action::make()->url(...)])`.
- Reuso de form de Resource em Action: extrair `formComponents(): array` (fonte única); `form()` embrulha com
  `$schema->components(...)`; Action usa `->schema(fn (): array => Resource::formComponents())`; Tabs com
  `livewireProperty('tipo')` lê/escreve prop pública do host (página ou componente).
- Em teste: `->callAction('nome', data: [...])`; após SUCESSO a action desmonta e `assertHasNoActionErrors()`
  quebra (`getMountedActionSchemaName()` null em componente sem schema próprio) — assertar DB + `assertNotified()`
  em vez disso; `assertHasActionErrors([...])`/`assertActionMounted()` valem quando o modal continua aberto.
