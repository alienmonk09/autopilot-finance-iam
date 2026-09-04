# spatie/laravel-activitylog v5 (Laravel 13 + PHP 8.4)

Instalado como `spatie/laravel-activitylog: ^5.1` (2026-09-03). Requer PHP ^8.4,
`illuminate/* ^12.0||^13.0`. ATENÇÃO: namespaces mudaram da v4 para a v5.

- Instalação: `composer require spatie/laravel-activitylog` + publicar migration
  `vendor:publish --provider="Spatie\Activitylog\ActivitylogServiceProvider" --tag="activitylog-migrations"`
  (cria `activity_log`: `log_name`, `description`, `nullableMorphs subject/causer`,
  `event` nullable, `attribute_changes` json, `properties` json). IDs bigint: compatível
  com `subject_id/causer_id` integer default. Config opcional (`--tag="activitylog-config"`):
  `enabled` (env `ACTIVITYLOG_ENABLED`), `default_log_name='default'`.
- Model (v5!): trait `Spatie\Activitylog\Models\Concerns\LogsActivity`
  (NÃO mais `Spatie\Activitylog\Traits\LogsActivity`) + opções
  `Spatie\Activitylog\Support\LogOptions` (NÃO mais `Spatie\Activitylog\LogOptions`):
  `LogOptions::defaults()->logFillable()->logOnlyDirty()->dontLogEmptyChanges()`
  (`dontSubmitEmptyLogs()` da v4 RENOMEADO para `dontLogEmptyChanges()`).
- Eventos default: `created/updated/deleted` (+ `restored` automático com SoftDeletes).
  Customizar via `protected static $recordEvents` ou `$doNotRecordEvents`.
- Leitura (v5!): `$activity->attribute_changes` (Collection; NÃO `->changes`),
  scopes `Activity::forSubject($m)->causedBy($user)->forEvent('updated')`,
  enum `Spatie\Activitylog\Enums\ActivityEvent::Created`.
- Causer: resolvido do auth default automaticamente; trait de leitura no causer:
  `Spatie\Activitylog\Models\Concerns\CausesActivity` (`activitiesAsCauser`).
- Desligar por instância: `$model->disableLogging()` / `->enableLogging()`.
