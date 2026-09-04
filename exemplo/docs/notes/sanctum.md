# Sanctum (tokens pessoais) — resumo da doc oficial (Laravel 13.x, 2026)

- Instalação: `php artisan install:api` (adiciona `laravel/sanctum` ao composer,
  publica `config/sanctum.php` + migration `personal_access_tokens`, cria
  `routes/api.php` e registra `api:` em `bootstrap/app.php`).
- User usa o trait `Laravel\Sanctum\HasApiTokens`; emitir com
  `$user->createToken($name, $abilities = ['*'], $expiresAt = null)` →
  `->plainTextToken` (hash SHA-256 no banco; exibir uma única vez).
- Proteger rotas: `->middleware('auth:sanctum')` (tenta cookie/SPA primeiro,
  depois `Authorization: Bearer`).
- Revogar: `$user->tokens()->delete()` (todos), `->where('id', $id)->delete()`
  (um), `$request->user()->currentAccessToken()->delete()` (o atual).
- Expiração: `config/sanctum.php` → `'expiration'` (minutos; default null =
  nunca expira); limpeza com `sanctum:prune-expired`.
- Testes: `Sanctum::actingAs($user, ['*'])`, ou token real via
  `createToken()->plainTextToken` + header `Authorization: Bearer ...`
  (este projeto usa token real nos testes de API: exercita o stack todo).
- Abilities: `tokenCan()` / middleware `abilities:` / `ability:` (aliases a
  registrar em `bootstrap/app.php`; fora de escopo da task 8.6).
