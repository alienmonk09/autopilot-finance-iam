# Filament 5 — notas da task 1.5 (docs oficiais, 2026-09-03)

- `DeleteAction` tem hooks `before()`/`after()`; `before()` injeta `$record`, `$action` etc. por nome de parâmetro.
- `$action->halt()` dentro de `before()`/`action()` aborta a ação (lança `Filament\Support\Exceptions\Halt`); `->success()`/`->failure()` marcam o status.
- Notificação manual: `Filament\Notifications\Notification::make()->danger()->title()->body()->send()` (status via `Concerns\HasStatus`, título `HasTitle`, corpo `HasBody`).
- `successNotificationTitle()` no `DeleteAction`/`Action` customiza a notificação de sucesso; `failureNotificationTitle()`/`failureNotification()` existem em `Actions\Concerns\CanNotify`.
- Filtro liga/desliga com default ligado: `Filter::make('x')->toggle()->default()->query(fn (Builder $q) => ...)` (`default(mixed $state = true)` em `Filters\Concerns\HasDefaultState`).
- Ícones via enum `Filament\Support\Icons\Heroicon` (ex.: `OutlinedArchiveBox`, `OutlinedArchiveBoxXMark`).
- Em testes: `Filament::setCurrentPanel('app')` no `beforeEach`; ações de tabela via `Livewire::test(ListX::class)->callTableAction('nome', $record)`; visibilidade via `assertCanSeeTableRecords()` / `assertCanNotSeeTableRecords()`; `removeTableFilters()` limpa inclusive defaults; notificações via `assertNotified('Título')`.

## Bulk actions (task 2.3c, verificado no vendor Filament 5)
- `bulkActions()` está deprecated: usar `->toolbarActions([...])` na tabela (`HasBulkActions` delega para toolbar).
- `Filament\Actions\BulkAction::make('nome')` (já vem com `->bulk()` + `->accessSelectedRecords()`); form via `->form([...])` (modal), confirmação via `->requiresConfirmation()`, `->deselectRecordsAfterCompletion()`.
- Closure `->action()` injeta por nome/tipo: `Collection|EloquentCollection|LazyCollection $records` (= `getIndividuallyAuthorizedSelectedRecords()`), `array $data` (form), `BulkAction $action`.
- Autorização por registro: `->authorizeIndividualRecords('update'|'delete')` (filtra via Gate+policy por registro); `->authorize()` sem registro é para a ação inteira (não passar classe).
- Em testes: `->callTableBulkAction('nome', [$records], ['campo' => $valor])`, `->assertTableBulkActionExists('nome')`, `->assertHasNoTableBulkActionErrors()`.

## ViewRecord + extrato (task 2.5, docs 5.x viewing-records + infolists/custom-entries)
- Página: `class ViewX extends Filament\Resources\Pages\ViewRecord` (`$resource`), registro `'view' => Pages\ViewX::route('/{record}')`
  (antes de `'edit' => ... '/{record}/edit'`); `mount(int|string $record)` resolve + autoriza (403 via policy `view()`; com
  global scope por usuário, registro alheio nem resolve → 404); `hydrate()` re-autoriza a cada update Livewire.
- `infolist(Schema)` pode ser definido NA PÁGINA (não só no Resource); sem componentes no infolist, cai no form desabilitado.
- `ViewEntry::make('x')->view('blade.view')` (`Filament\Infolists\Components\ViewEntry`; `view()`/`viewData()` vêm de
  `Support\Components\ViewComponent`): na Blade, `$this` é o componente Livewire (a página) — dá para chamar métodos
  públicos (`$this->statement()`); `$record` também disponível.
- `Section::make()` aceita `Closure` no heading (avaliado por render — serve para rótulo com mês dinâmico).
- `#[Url(as: 'mes')] public ?int $mes` funciona em ViewRecord igual ao ListRecords (mesmo padrão de navegação mensal).
- Conteúdo sem tabela: visibilidade em teste via `assertSee`/`assertDontSee` (NÃO `assertCanNotSeeTableRecords`, que é só tabela).
