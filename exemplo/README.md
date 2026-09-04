# finance-iam

Gestão de finanças pessoais (contas, cartões, faturas, parcelamentos, recorrências, orçamentos, metas, relatórios) em **Laravel 13 + SQLite + Filament 5**. Construído por agentes via [opencode](https://opencode.ai) seguindo um roadmap com gate mecânico.

## Documentos

| Arquivo | Papel |
|---|---|
| `docs/SPEC.md` | Escopo completo: domínio, regras de negócio, UX, aceite final |
| `docs/ROADMAP.md` | Tasks em checkbox — fonte da verdade do progresso |
| `docs/ARCHITECTURE.md` | Decisões arquiteturais e mapa dos contextos de domínio |
| `docs/USER_GUIDE.md` | Guia do usuário: primeiros passos e dia a dia no painel |
| `AGENTS.md` | Protocolo dos agentes (ciclo de task, delegação, fim de fase) |
| `docs/QUESTIONS.md` | Ambiguidades e suposições |
| `docs/BLOCKED.md` | Task travada (loop para até um humano resolver) |
| `docs/reports/fase-N.md` | Review de cada fase |

## Modo autônomo (o normal)

Pré-requisitos: PHP 8.4+, Composer, Node 20+, opencode ≥ 1.18 logado no provider `opencode`.

```bash
cd finance-iam
caffeinate -dis scripts/autopilot.sh        # roda até o roadmap acabar; log em logs/autopilot.log (-dis: não deixa o Mac dormir na tomada)
tail -f logs/autopilot.log                   # acompanhar
scripts/status.sh                            # progresso a qualquer momento
```

Cada iteração é um processo `opencode run` novo (contexto limpo) executando `/next`. O loop:
- executa uma task, valida com `scripts/check.sh`, commita e marca `[x]`;
- na troca de fase roda o review (`docs/reports/fase-N.md`); se reprovar, cria tasks corretivas `N.Fx`, executa, re-revisa uma vez e segue;
- task que falha 3 vezes vira `[!]`; o loop chama `/unblock`, que a quebra em subtasks `N.Ma, N.Mb...` e continua; se a família travar de novo, fica `[!]` e o loop pula;
- 6 falhas de processo seguidas (provider fora, rate limit) → pausa de 30 min e retoma.

No fim, `logs/autopilot.log` lista as tasks `[!]` que sobraram para humano, e `docs/QUESTIONS.md` as suposições tomadas.

Para dar uma dica ao loop sem parar: escreva em `docs/HINTS.md` (injetado em toda iteração enquanto tiver conteúdo; apague quando não precisar mais). Aprendizados entre iterações ficam em `docs/PROGRESS.md` (append-only, as últimas 40 linhas entram em cada `/next`).

Variáveis: `TASK_TIMEOUT` (s por iteração, default 2700), `VARIANT` (reasoning do muse: minimal/low/medium/high/xhigh, default medium), `MAX_ITER` (default 400), `PUSH` (git push após cada iteração, default 1; `PUSH=0` desliga).

Modelo: a cada iteração o loop testa o `FREE_MODEL` (default `opencode/muse-spark-1.3-contributor-free`); se responder, usa ele; se estiver em rate limit, usa o `PAID_MODEL` (default `opencode-go/muse-spark-1.3-contributor`, precisa de `opencode auth login --provider opencode-go`) e volta ao free sozinho quando liberar. `MODEL_MODE=free|paid` trava num deles. A troca reescreve `model:` em `.opencode/agents/*.md` e commita.

## Modo manual

```bash
opencode            # Tab até o agente "coordinator"
/next               # UM ciclo de task
/phase              # ciclos até fechar a fase atual
/unblock 3.2        # quebra uma task [!] em subtasks
/review 2           # (re)roda o review de uma fase
/status
```

## Gate mecânico

`scripts/check.sh` é o único aceite (pint + larastan + pest via `composer check`). O coordenador roda ele mesmo depois de cada task; o implementer não marca checkbox nem usa git (bloqueado por permission). Marcadores no ROADMAP: `[ ]` pendente, `[x]` feita, `[!]` travada, `[-]` substituída por subtasks.

## Rodando o app

Container único (FrankenPHP em `:8000` + fila + scheduler via supervisord, SQLite em `database/database.sqlite`). Pré-requisito: Docker com plugin compose.

```bash
cp .env.example .env          # só na primeira vez (APP_KEY é gerada no boot se vazia)
docker compose up --build -d  # sobe app + queue:work + schedule:work
docker compose logs -f app    # acompanhar
docker compose down           # parar (os dados em database/ e storage/ permanecem)
```

Acesse `http://localhost:8000` (painel em `/app`). As migrations rodam sozinhas no boot e o build já compila os assets (`npm run build` dentro do Dockerfile).

Para explorar com dados prontos, popule o usuário demo (12 meses de lançamentos realistas em português — salário, aluguel, iFood, Uber, conta de luz, recorrência e parcelamento):

```bash
docker compose exec app php artisan db:seed --class=DemoSeeder
```

Depois entre em `/app/login` com `demo@example.com` / `demo1234`. O seed é idempotente: rodar de novo não duplica nada (contas, cartão e payees via `firstOrCreate`; se o demo já tem transações, os lançamentos são pulados). Usuários novos também passam pelo wizard "Começar agora" (`/app/onboarding`): criar a primeira conta → criar o primeiro cartão (opcional) → importar, lançar ou ir ao dashboard.

Prefere criar o seu próprio usuário? Via tinker no container:

```bash
docker compose exec app php artisan tinker
```

```php
\App\Models\User::create(['name' => 'Seu Nome', 'email' => 'voce@example.com', 'password' => 'troque-esta-senha']);
```

Depois entre com esse e-mail/senha em `/app/login` (o mesmo usuário vale para as telas Fortify fora do painel).
