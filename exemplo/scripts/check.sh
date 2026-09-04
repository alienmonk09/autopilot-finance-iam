#!/usr/bin/env bash
# Único critério de aceite. Última linha sempre "CHECK: PASS" ou "CHECK: FAIL".
# Saída completa em logs/check.log; na tela só as últimas 120 linhas (contexto pequeno pro modelo).
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p logs
fail() { echo "CHECK: FAIL ($1)"; exit 1; }
[ -f composer.json ] || fail "composer.json ausente — fase 0 ainda não criou o app"
if composer run-script --list 2>/dev/null | grep -qE '^\s*check\b'; then
  composer check > logs/check.log 2>&1; rc=$?
  tail -n 120 logs/check.log
  [ "$rc" -eq 0 ] || fail "composer check rc=$rc — saída completa em logs/check.log"
else
  echo "WARN: script composer 'check' ainda não existe (aceitável só até a task 0.2)"
  php artisan about > logs/check.log 2>&1 || fail "php artisan about"
fi
echo "CHECK: PASS"
