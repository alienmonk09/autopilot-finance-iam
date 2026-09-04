# Laravel 13 — resumo (doc oficial consultada em 2026-09-03)

- Instalação: `laravel new example-app` (via `laravel/installer`) ou `composer create-project laravel/laravel`; requer PHP 8.4+ neste projeto (skeleton traz `^8.4`), Node/npm ou Bun para assets.
- Este repo já é Laravel 13.30.1 (verificado via `composer show laravel/framework`).
- Banco default: SQLite (`database/database.sqlite`, migrado no create-project); `.env` usa `DB_CONNECTION=sqlite`.
- Dev: `composer run dev` sobe server + queue + vite; `npm install && npm run build` para assets.
- Pegadinhas: servir sempre da raiz do webroot; `php artisan about` valida boot; não commitar `.env` / `*.sqlite`.
- Fonte: https://laravel.com/docs/13.x/installation
