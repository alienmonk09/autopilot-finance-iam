# Livewire 4 — resumo (doc oficial consultada em 2026-09-03)

- Requisitos: Laravel 10+, PHP 8.1+.
- Instalação: `composer require livewire/livewire` (auto-discovery, zero-config).
- Layout full-page: `php artisan livewire:layout` → `resources/views/layouts/app.blade.php` com `@livewireStyles` / `@livewireScripts`
  (injeção de assets é automática mesmo sem as diretivas).
- Config opcional: `php artisan livewire:config` → `config/livewire.php`.
- Alpine.js já vem embutido no JS do Livewire.
- Pegadinha Nginx: rotas `/livewire-{hash}/...` precisam chegar ao Laravel (`try_files ... /index.php?$query_string`); com `route:cache` rodar `route:clear`.
- Nesta task 0.2: SÓ `composer require`, sem gerar layout (layouts entram nas tasks de UI).
- Fonte: https://livewire.laravel.com/docs/installation
