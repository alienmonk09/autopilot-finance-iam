# Fortify — resumo (doc oficial consultada em 2026-09-03)

Versão instalada: `laravel/fortify ^1.39` (traz `pragmarx/google2fa` — nenhum pacote extra
de TOTP necessário). Fonte: https://laravel.com/docs/13.x/fortify

- Headless: registra rotas + controllers; as telas Blade são nossas. Ativação:
  `composer require laravel/fortify` + `php artisan fortify:install` (publica
  `config/fortify.php`, `app/Actions/Fortify/*`, `FortifyServiceProvider`,
  migration de 2FA e tabela `passkeys`).
- Telas registradas via `Fortify::*View(...)` no `boot()` do `FortifyServiceProvider`
  (`loginView`, `registerView`, `requestPasswordResetLinkView`, `resetPasswordView`,
  `twoFactorChallengeView`, `confirmPasswordView`). Provider registrado em
  `bootstrap/providers.php`.
- Features ativas (scaffold default, mantidas): `registration`, `resetPasswords`,
  `updateProfileInformation`, `updatePasswords`,
  `twoFactorAuthentication(['confirm' => true, 'confirmPassword' => true])`, `passkeys`.
- Rotas principais: `POST /login`, `POST /logout`, `POST /register`,
  `POST /forgot-password` (link), `POST /reset-password` (redefine; GET
  `/reset-password/{token}` exibe a tela), `GET|POST /two-factor-challenge`
  (nome `two-factor.login`, campos `code` ou `recovery_code`),
  `POST /user/two-factor-authentication` (ativa), `POST
  /user/confirmed-two-factor-authentication` (`code`), `DELETE
  /user/two-factor-authentication` (desativa), `POST
  /user/two-factor-recovery-codes` (regenera).
- `User` usa `Laravel\Fortify\TwoFactorAuthenticatable` (métodos
  `twoFactorQrCodeSvg()`, `recoveryCodes()`, `hasEnabledTwoFactorAuthentication()`).
- Gestão de 2FA exige senha confirmada recentemente (`password.confirm`, sessão
  `auth.password_confirmed_at`). Em testes: `->withSession(['auth.password_confirmed_at'
  => time()])`.
- TOTP válido em testes: `app(PragmaRX\Google2FA\Google2FA::class)->getCurrentOtp(decrypt($user->two_factor_secret))`.
- `home` pós-login: `config/fortify.php` `'home' => '/home'`.
- Rate limiters `login` (5/min por e-mail+IP) e `two-factor` já vêm no provider gerado.

## Por que Fortify e não o auth do Filament

O auth do Filament 5 exige um Panel (`filament:install --panels`, rota `/admin`) —
scaffold proibido nesta task (é a task 0.6). Fortify é headless e funciona sem painel.
