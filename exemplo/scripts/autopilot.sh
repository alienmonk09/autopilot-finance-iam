#!/usr/bin/env bash
# Loop autônomo: cada iteração é um processo opencode novo (contexto limpo) executando /next.
# Para sozinho quando o roadmap acaba e todas as fases têm review. Tasks travadas são destravadas
# uma vez (/unblock) e, se travarem de novo, ficam [!] e o loop segue.
# Rode com: caffeinate -dis scripts/autopilot.sh  (-dis: não deixa o sistema dormir na tomada; -i só cobre ociosidade)
#
# Env opcionais: TASK_TIMEOUT (s, default 2700), VARIANT (default medium), MAX_ITER (default 400), PUSH (1 = git push após cada iteração, default 1),
#   FREE_MODEL / PAID_MODEL / MODEL_MODE=auto|free|paid (ver pick_model), PROBE_TIMEOUT (s, default 40)
set -uo pipefail
cd "$(dirname "$0")/.."

TASK_TIMEOUT=${TASK_TIMEOUT:-2700}
VARIANT=${VARIANT:-medium}
MAX_ITER=${MAX_ITER:-400}
LOG=logs/autopilot.log
mkdir -p logs docs/reports
touch docs/BLOCKED.md docs/PROGRESS.md docs/HINTS.md logs/unblocked.txt

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"; }

# Push best-effort ao fim de cada iteração (sem rede não trava o loop). PUSH=0 desliga.
push_repo() {
  [ "${PUSH:-1}" = "0" ] && return 0
  git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1 || return 0
  git push -q 2>>"$LOG" || log "push falhou (segue; tenta na próxima iteração)"
}

# Argumentos do comando vão por stdin (`-- 3.2` crasha o yargs; stdin aberto trava o opencode).
run_oc() { # run_oc <command> [args...]
  local cmd=$1; shift
  printf '%s' "$*" | perl scripts/pgtimeout.pl "$TASK_TIMEOUT" \
    opencode run --agent coordinator --command "$cmd" --auto --variant "$VARIANT" \
    >> "$LOG" 2>&1
}

# Modelo dos agentes: prefere o FREE; se o probe do free falhar (rate limit), usa o PAID. Reavalia a cada
# iteração e volta ao free sozinho. MODEL_MODE=free|paid trava num deles. A troca reescreve o `model:`
# dos 3 agentes em .opencode/agents/ e commita (cada iteração é um processo novo e lê os arquivos).
FREE_MODEL=${FREE_MODEL:-opencode/muse-spark-1.3-contributor-free}
PAID_MODEL=${PAID_MODEL:-opencode-go/muse-spark-1.3-contributor}
MODEL_MODE=${MODEL_MODE:-auto}
PROBE_TIMEOUT=${PROBE_TIMEOUT:-40}
current_model() { grep -hm1 '^model:' .opencode/agents/coordinator.md | sed 's/^model: *//'; }
free_ok() {
  perl scripts/pgtimeout.pl "$PROBE_TIMEOUT" opencode run --model "$FREE_MODEL" "Responda apenas: OK" </dev/null 2>&1 | grep -qw OK
}
pick_model() {
  local want cur
  case "$MODEL_MODE" in
    free) want=$FREE_MODEL ;;
    paid) want=$PAID_MODEL ;;
    *) if free_ok; then want=$FREE_MODEL; else want=$PAID_MODEL; fi ;;
  esac
  cur=$(current_model)
  [ "$want" = "$cur" ] && return 0
  perl -pi -e "s#^model: .*#model: $want#" .opencode/agents/*.md
  git add .opencode/agents && git commit -qm "chore: agentes em $want (autopilot)" || true
  log "modelo: $cur → $want"
}

# Só após timeout (rc 142): mata composer/artisan/pest cujo cwd é ESTE repo. Nunca processos alheios.
kill_orphans() {
  local root p
  root=$(pwd -P)
  for p in $(pgrep -f 'artisan|vendor/bin/(pest|phpstan|pint)|composer' 2>/dev/null); do
    lsof -a -p "$p" -d cwd -Fn 2>/dev/null | grep -q "^n$root" && kill -TERM "$p" 2>/dev/null
  done
  true
}

# Sobras em docs/ são trabalho legítimo (reports, notes, progress) — salva SÓ se nada fora de docs/
# estiver sujo (senão estaríamos commitando um [x] cuja implementação vai ser revertida abaixo).
cleanup_tree() {
  local dirty_all dirty_outside
  dirty_all=$(git status --porcelain)
  [ -z "$dirty_all" ] && return 0
  dirty_outside=$(printf '%s\n' "$dirty_all" | grep -vE '^.. docs/' || true)
  if [ -z "$dirty_outside" ]; then
    git add -A docs && git commit -qm "chore: autopilot salvou sobras em docs/" || true
    return 0
  fi
  log "árvore suja após a iteração (processo morreu no meio?) — revertendo"
  git checkout -- . && git clean -fdq
}

# Task travada → /unblock uma única vez por família (3.2 e suas subtasks 3.2a/3.2b contam juntas).
try_unblock() {
  local id base n
  while read -r id; do
    [ -z "$id" ] && continue
    grep -qx "$id" logs/unblocked.txt && continue
    base=$(printf '%s' "$id" | sed -E 's/[a-z]+$//')
    n=$(grep -cE "^## ${base//./\\.}[a-z]*( |$)" docs/BLOCKED.md || true)
    echo "$id" >> logs/unblocked.txt
    if [ "${n:-0}" -le 1 ]; then
      log "destravando $id (1º travamento da família $base)"
      run_oc unblock "$id"; [ $? -eq 142 ] && kill_orphans
      cleanup_tree
    else
      log "$id: 2º travamento da família $base — fica [!] para humano"
    fi
  done < <(grep -E '^- \[!\] ' docs/ROADMAP.md | awk '{print $3}')
}

# Fases com alguma [x] que ainda devem review: sem report, ou REPROVADA com corretivas feitas e só 1 review
# (mesma regra do phase-gate; sem isso a última fase do roadmap nunca ganharia o 2º review).
missing_reviews() {
  local n
  for n in 0 1 2 3 4 5 6 7 8 9; do
    grep -qE "^- \[x\] $n\." docs/ROADMAP.md || continue
    [ "$(scripts/phase-gate.sh $((n + 1)))" = "NEEDS_REVIEW $n" ] && echo "$n"
  done
  true
}

fails=0; same=0; last_task=""; last_gate=""; i=0
while :; do
  i=$((i + 1))
  if [ "$i" -gt "$MAX_ITER" ]; then log "MAX_ITER=$MAX_ITER atingido"; break; fi

  try_unblock

  next=$(scripts/next-task.sh)
  if [ "$next" = "NONE" ]; then
    pend=$(missing_reviews)
    if [ -z "$pend" ]; then
      log "roadmap concluído e todas as fases revisadas — $(scripts/status.sh | head -1)"
      break
    fi
    for n in $pend; do
      log "review pendente da fase $n"
      run_oc review "$n"; [ $? -eq 142 ] && kill_orphans
      cleanup_tree
    done
    continue   # o review pode ter criado corretivas N.Fx
  fi
  task=${next%% *}

  # Gate preso: o review automático não produziu um relatório que o phase-gate reconheça.
  gate=$(scripts/phase-gate.sh)
  if [ "$gate" = "$last_gate" ] && [ "${gate%% *}" = "NEEDS_REVIEW" ]; then
    n=${gate#* }; f="docs/reports/fase-$n.md"
    log "gate preso em '$gate' — forçando veredito REPROVADA na fase $n"
    [ -s "$f" ] || echo "(review automático não produziu relatório)" > "$f"
    scripts/mark-review.sh "$n" REPROVADA && git add -A docs && git commit -qm "chore: fase $n review forçado (autopilot)" || true
    last_gate=""; continue
  fi
  last_gate=$gate

  # Sem progresso na mesma task por 4 iterações (o review de fase consome 1 legitimamente).
  if [ "$task" = "$last_task" ]; then same=$((same + 1)); else same=0; fi
  if [ "$same" -ge 3 ]; then
    log "$task repetiu 4 iterações sem progresso — marcando travada"
    scripts/mark-blocked.sh "$task" "autopilot: sem progresso em 4 iterações" && git add -A && git commit -qm "chore: $task travada (autopilot)" || true
    same=0; last_task=""; continue
  fi
  last_task=$task

  pick_model
  log "iteração $i — task $task [$(current_model)] ($(scripts/status.sh | head -1))"
  if run_oc next; then
    fails=0
  else
    rc=$?
    fails=$((fails + 1))
    last_task=""; same=0   # falha de processo (429, crash) não conta como "iteração sem progresso"
    log "opencode saiu com rc=$rc (falhas seguidas: $fails)"
    [ "$rc" -eq 142 ] && kill_orphans
    cleanup_tree
    sleep $((60 * fails))
    if [ "$fails" -ge 6 ]; then
      log "6 falhas seguidas (provider fora? rate limit?) — pausa de 30 min"
      sleep 1800; fails=0
    fi
    continue
  fi
  cleanup_tree
  push_repo
done

push_repo
log "fim. status:"
scripts/status.sh | tee -a "$LOG"
blocked=$(grep -E '^- \[!\] ' docs/ROADMAP.md || true)
[ -n "$blocked" ] && log "tasks travadas que precisam de humano:" && echo "$blocked" | tee -a "$LOG"
exit 0
