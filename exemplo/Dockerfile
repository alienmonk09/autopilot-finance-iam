# finance-iam — container único (FrankenPHP + supervisord + SQLite).
#
# Estágio 1 compila os assets frontend (Vite/Tailwind); o estágio final
# serve o app, a fila (queue:work) e o agendador (schedule:work) via
# supervisord, tudo no mesmo container, conforme a SPEC seção 1.

# ------------------------------------------------------------------ vendor
# Só pra dar ao estágio frontend o CSS-fonte do Filament (o tema do painel,
# resources/css/filament/app/theme.css, importa vendor/filament/**/resources/css).
FROM composer:2 AS vendor

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-scripts --no-autoloader --ignore-platform-reqs

# ---------------------------------------------------------------- frontend
FROM node:20-alpine AS frontend

WORKDIR /build

COPY package.json ./
RUN npm install --ignore-scripts

COPY vite.config.js ./
COPY resources ./resources
COPY public ./public
COPY --from=vendor /app/vendor/filament ./vendor/filament

RUN npm run build

# ------------------------------------------------------------------- app
FROM dunglas/frankenphp:1-php8.4-bookworm AS app

WORKDIR /app

# Extensões que o app exige (pdo_sqlite/sqlite3 = banco; intl = NumberFormatter
# pt_BR do Money; dom/xml = Filament/Blade; zip, bcmath, pcntl, gd/exif =
# vendor; opcache = produção) + supervisord (web + queue + scheduler).
RUN install-php-extensions \
        bcmath \
        curl \
        dom \
        exif \
        fileinfo \
        gd \
        intl \
        mbstring \
        opcache \
        pcntl \
        pdo_sqlite \
        sqlite3 \
        zip \
    && apt-get update \
    && apt-get install -y --no-install-recommends supervisor \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1

COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-scripts --no-autoloader

COPY . .

# Assets compilados no estágio frontend: o tema do painel (->viteTheme) e as
# telas Blade (@vite) leem public/build/manifest.json — gerado aqui, nunca
# montado por volume.
COPY --from=frontend /build/public/build ./public/build

RUN mkdir -p storage/app storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && composer install --no-dev --prefer-dist --optimize-autoloader \
    && cp .env.example .env \
    && touch database/database.sqlite \
    && php artisan migrate --force \
    && php artisan filament:assets \
    && rm -f .env database/database.sqlite database/database.sqlite-journal database/database.sqlite-wal \
    && chown -R www-data:www-data storage bootstrap/cache database \
    && chmod -R ug+rwX storage bootstrap/cache database

COPY docker/Caddyfile /etc/caddy/Caddyfile
COPY docker/supervisord.conf /etc/supervisor/conf.d/app.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/app.conf"]
