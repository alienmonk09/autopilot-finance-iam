# FrankenPHP (imagem Docker) — resumo da doc oficial (2026-09)

Fonte: frankenphp.dev/docs/docker + /docs/laravel.

- Imagem `dunglas/frankenphp:<versão>-php<php>-<os>` (ex.: `1-php8.4-bookworm`); baseada nas imagens PHP oficiais; Debian recomendado.
- App Laravel é montado/copiado em `/app` (NÃO `/app/public`); o Caddyfile default já serve `public/`.
- Extensões via `RUN install-php-extensions <nomes>` (script incluso na imagem).
- Caddyfile próprio p/ Laravel clássico (sem Octane): bloco `{$SERVER_NAME}` ou porta fixa; `root * /app/public` + `php_server { try_files {path} index.php }` + `file_server`. Globais úteis: `admin off`, `persist_config off`, `auto_https off`.
- Sem Octane nesta task (modo clássico); Octane seria `php artisan octane:install --server=frankenphp` + `octane:frankenphp` — fora de escopo.
- Scheduler em container: `php artisan schedule:work` (roda `schedule:run` a cada minuto, bloqueante) — ideal como programa do supervisord.
