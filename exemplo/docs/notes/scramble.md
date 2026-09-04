# Scramble (OpenAPI) — resumo da doc oficial (v0.13.x, 2026)

- Compatível com Laravel 13 (`illuminate/contracts: ^10|^11|^12|^13`) e PHP
  ^8.1 (cobre o 8.4 do projeto). Instalação: `composer require dedoc/scramble`.
- Gera OpenAPI 3.1.0 a partir do código (sem PHPDoc obrigatório): infere
  parâmetros de Form Requests, query validation (`$request->validate`) e
  Resources.
- Rotas default: `/docs/api` (UI) + `/docs/api.json` (spec), visíveis só em
  `local` salvo gate `viewApiDocs`.
- Customização (neste projeto, em `AppServiceProvider::configureApiDocs`):
  `Scramble::configure()->expose(ui: '/api/docs', document: '/api/docs/openapi.json')`.
  Por default documenta rotas com prefixo `api` (as nossas `api/v1/*` entram).
- Esconder rota: atributo `#[ExcludeRouteFromDocs]` no método do controller.
- Gate: `Gate::define('viewApiDocs', ...)` libera a UI/spec fora do `local`.
