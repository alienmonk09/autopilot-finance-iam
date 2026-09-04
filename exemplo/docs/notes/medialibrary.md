# spatie/laravel-medialibrary v11 (Laravel 13 + PHP 8.4)

Instalada como `spatie/laravel-medialibrary: ^11.23` (2026-09-03). Requer PHP ^8.4,
`illuminate/* ^12.0|^13.0`. Sem config publicada (usa defaults); disco default `public`.

- Instalação: `composer require spatie/laravel-medialibrary` + publicar migration
  `vendor:publish --provider="Spatie\MediaLibrary\MediaLibraryServiceProvider" --tag="medialibrary-migrations"`
  (cria `media` com `morphs('model')`, coleção, disco, `order_column`). Config opcional
  (`--tag="medialibrary-config"`): `disk_name` default `public`, `media_model`,
  `queue_conversions_by_default=true`.
- Model: `implements HasMedia` (`Spatie\MediaLibrary\HasMedia`) + trait
  `InteractsWithMedia` (`Spatie\MediaLibrary\InteractsWithMedia`).
- Uso: `$model->addMedia($path)->toMediaCollection('attachments')`,
  `$model->addMediaFromRequest('file')->toMediaCollection('attachments')`,
  `$model->getMedia('attachments')`, `$media->getUrl()`. Conversões via
  `registerMediaConversions()` (não usado no MVP — anexos são comprovantes brutos).
- Testes: `Storage::fake('public')` troca o disco default; `addMedia()` com arquivo
  temporário real funciona em SQLite `:memory:` sem fila (sem conversões registradas,
  nada é enfileirado).
- Requisitos do servidor (só p/ thumbnails): GD (imagens), Imagick+Ghostscript (PDF),
  ffmpeg (vídeo). MVP não gera conversão, então nada disso é obrigatório.
