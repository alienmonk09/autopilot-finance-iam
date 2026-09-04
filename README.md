# Autopilot finance-iam

Um app de finanças pessoais (Laravel 13 + SQLite + Filament 5) construído em **um dia** por um modelo de IA gratuito, sem humano no loop, a partir de um prompt. Depois, uma segunda rodada com outro modelo deixou o visual apresentável.

Este repositório é o **guia de reprodução**: o que foi feito, na ordem, com os arquivos reais para você copiar. Foi escrito para quem nunca montou um fluxo desses, inclusive quem está no primeiro período e ainda está aprendendo terminal e git.

- **A história completa, com números e o que deu errado:** https://alienmonk09.github.io/autopilot-finance-iam/ (página autocontida; também em `index.html`)
- **Diagrama interativo da arquitetura do app:** `arquitetura.html`
- **Os arquivos reais do projeto** (protocolo, agentes, scripts, spec, roadmap, reviews, log inteiro): pasta `exemplo/`

---

## 0. Como ler este guia

Você não precisa reproduzir tudo para aproveitar. Escolha uma trilha:

| Trilha | O que fazer | Tempo | Precisa de |
|---|---|---|---|
| **Só entender** | Ler a [página da história](https://alienmonk09.github.io/autopilot-finance-iam/) e as seções 1, 6 e 7 deste README | 30 min | Nada. Nem terminal. |
| **Ver por dentro** | A trilha anterior + abrir `exemplo/AGENTS.md`, `exemplo/docs/ROADMAP.md` e um review em `exemplo/docs/reports/` e comparar com o que a história conta | 1 h | Saber ler markdown |
| **Experimentar pequeno** | Seções 2 a 4, mas com um projeto de brinquedo de 5 a 8 tasks (veja "Comece pequeno" na seção 4) | uma tarde | Terminal, git, uma conta no GitHub |
| **Reproduzir** | Tudo, com um app de verdade | um fim de semana | O acima + a stack do seu app |

Se você nunca usou terminal nem git, faça a trilha "só entender" agora e volte depois. Para aprender git, o livro oficial é gratuito e tem tradução: https://git-scm.com/book/pt-br/v2 (os capítulos 1 e 2 bastam para este guia).

### Glossário: as palavras que aparecem o tempo todo

Leia uma vez. Quando esbarrar numa delas mais adiante, volte aqui.

| Palavra | O que significa neste guia |
|---|---|
| **Modelo (de IA)** | O programa que gera texto e código a partir de um pedido. ChatGPT, Claude e Gemini são modelos. Uns são fortes e caros, outros fracos e gratuitos. |
| **Prompt** | O texto que você manda ao modelo. Aqui, "prompt" quase sempre é um documento de várias páginas, não uma frase. |
| **Token** | A unidade em que o modelo conta texto, mais ou menos meia palavra. Custo e limite de uso são medidos em tokens. |
| **Rate limit** | Cota de uso. Quando estoura, o modelo para de responder por algumas horas. Nos modelos gratuitos isso acontece muito. |
| **Agente** | Um modelo com permissão para agir: ler arquivos, editar, rodar comandos. No opencode, um agente é um arquivo markdown que diz qual modelo usar e o que ele pode ou não fazer. |
| **Spec** | Especificação. O documento que diz *o que* construir: regras, telas, o que é "pronto". |
| **Roadmap** | A lista de tarefas, em ordem, com uma caixinha (`[ ]`) na frente de cada uma. |
| **Task** | Uma tarefa do roadmap. Pequena o bastante para um modelo fraco fazer em menos de 45 minutos. |
| **Fase** | Um grupo de tasks que juntas entregam algo verificável (ex.: "Fase 2: transações"). |
| **Protocolo** | As regras do jogo para os agentes, escritas em `AGENTS.md`: o que fazer em cada situação, em passos numerados. |
| **Gate** | Um script que responde "passou" ou "não passou". É o único juiz de que uma task está pronta. Ninguém, nem o modelo nem você, marca uma task como feita sem o gate verde. |
| **Lint, análise estática, testes** | As três coisas que o gate roda. Lint: formatação do código. Análise estática: procura erros sem executar. Testes: executa o código e confere o resultado. |
| **Loop / iteração** | O loop é o programa que repete "pegar a próxima task, executar, verificar, salvar". Cada volta é uma iteração. |
| **Commit / push** | Commit: salvar um ponto no histórico do git. Push: mandar esse histórico para o GitHub. Aqui o commit é a rede de segurança: se algo dá errado, volta-se ao último commit. |
| **Árvore suja** | Arquivos modificados que ainda não viraram commit. |
| **Timeout** | Limite de tempo. Se uma iteração passa de 45 minutos, é morta e revertida. |
| **Review** | Auditoria de uma fase inteira contra a spec, feita por um agente que só lê. Termina em APROVADA ou REPROVADA. |
| **Stack** | O conjunto de tecnologias do app. Aqui: PHP com Laravel (framework web), SQLite (banco de dados em um arquivo) e Filament (painel administrativo pronto). Você pode trocar tudo isso. |
| **Docker** | Ferramenta para rodar o app numa caixa isolada, com tudo instalado. Só aparece no fim, para ver o app funcionando. |
| **CDN** | Servidor externo de onde páginas web costumam baixar CSS e JavaScript. O prompt proibiu, para o app funcionar sem internet. |

---

## 1. A ideia em um parágrafo

Um modelo barato não é confiável para **decidir**. Ele esquece, inventa e, se puder, marca a tarefa como feita sem ter feito. Então a ideia é tirar toda decisão dele e colocar em arquivos e scripts:

- uma **spec** que diz o que construir;
- um **roadmap** com tasks em checkbox e critério de aceite;
- um **protocolo** (`AGENTS.md`) com passos numerados para cada situação;
- **três agentes** com permissões mecânicas: quem implementa não usa git, quem revisa não edita;
- um **gate** (`scripts/check.sh`) que é o único aceite;
- um **loop de fora** (`scripts/autopilot.sh`) que roda um processo novo por task, com timeout e reversão.

O modelo só executa. O git guarda o estado. Um humano olha de 40 em 40 minutos.

Números do caso real:

| | |
|---|---|
| Tasks | 69 (67 do roadmap + 2 corretivas), 10 fases |
| Tempo | 22 horas de relógio, das quais ~9 paradas por rate limit e por notebook dormindo |
| Reviews de fase | 10, sendo 9 aprovados de primeira |
| Testes ao final | 1.029 (Pest), Larastan e Pint verdes |
| Custo em tokens | zero no modelo gratuito; 3 iterações no pago, centavos |
| Bugs no loop | 4, todos nos scripts, nenhum no protocolo |
| Bug de produto que passou por 10 reviews | 1 (painel sem CSS; ninguém abre browser) |

---

## 2. O que você precisa

- **Um Mac ou Linux** com terminal. No Windows, use o WSL2 (um Linux dentro do Windows). No Mac, deixe na tomada: notebook na bateria dorme e derruba a conexão (aconteceu 3 vezes).
- **Git** e uma conta no GitHub. O loop faz push a cada task; se a máquina morrer, o trabalho está lá.
- **[opencode](https://opencode.ai)** ≥ 1.18, a ferramenta que roda os agentes no terminal: `curl -fsSL https://opencode.ai/install | bash`. Depois `opencode auth login` e escolha o provider `opencode` (tem modelos gratuitos; o usado aqui foi `opencode/muse-spark-1.3-contributor-free`).
- **Opcional, para não parar no rate limit:** o mesmo modelo pago no OpenCode Go (`opencode auth login --provider opencode-go`; US$0,10 por milhão de tokens de entrada). O loop alterna sozinho.
- **Um modelo forte para escrever a spec** (aqui foi o Claude). É a única parte onde vale gastar com o modelo caro. O plano gratuito de qualquer chat serve para começar.
- **A stack do seu app.** Aqui: PHP 8.4, Composer, Node 20, e Docker para rodar no fim. O esqueleto não sabe nada de Laravel; o que muda de stack para stack é só o `check.sh`.

---

## 3. O processo em seis passos

```
prompt ──► SPEC.md + ROADMAP.md ──► AGENTS.md + agentes + scripts ──► 3 iterações vigiadas ──► loop solto ──► app rodando
 (você)     (modelo forte + você)        (copiar daqui e adaptar)         (opencode run)       (autopilot.sh)   (docker compose)
```

Em português: você escreve o pedido; um modelo forte transforma em spec e roadmap; você copia daqui o protocolo, os agentes e os scripts; roda três tasks olhando; solta o loop; no fim, roda o app e olha.

Cada passo abaixo diz o que fazer, o que copiar deste repositório e o que adaptar.

---

## 4. Passo a passo

### Comece pequeno

Antes de um app de 67 tasks, faça um de 5 a 8. Ideias que cabem numa tarde: uma lista de tarefas em linha de comando, um conversor de unidades, um contador de palavras com relatório. O roadmap pode ser assim:

```markdown
## Fase 0 — Fundação (aceite: `scripts/check.sh` imprime CHECK: PASS num projeto vazio)
- [ ] 0.1 Criar projeto, instalar ferramenta de testes, um teste que sempre passa
- [ ] 0.2 `scripts/check.sh` roda lint e testes e termina com CHECK: PASS ou CHECK: FAIL

## Fase 1 — Funcionalidade (aceite: os três comandos funcionam com testes)
- [ ] 1.1 Comando `add <texto>` grava uma tarefa em tasks.json + teste
- [ ] 1.2 Comando `list` imprime as tarefas numeradas + teste
- [ ] 1.3 Comando `done <n>` marca a tarefa n como feita + teste
```

Todo o resto do guia vale igual para esse projeto. Você vai ver o loop inteiro funcionar em uma hora e entender cada peça antes de escalar.

### Passo 1 — Instale e teste o opencode

```bash
curl -fsSL https://opencode.ai/install | bash
opencode auth login          # provider: opencode
opencode models | grep free  # veja os modelos gratuitos disponíveis
opencode run --model opencode/muse-spark-1.3-contributor-free "Responda apenas: OK"
```

Se a última linha imprimir `OK`, está pronto. Se demorar ou falhar, o modelo está em rate limit: espere ou use o pago.

### Passo 2 — Escreva o prompt

O prompt não é "faça um app de finanças". É um documento. O usado aqui está em [`docs/prompt-original.md`](docs/prompt-original.md) (38 KB) e tem:

- **Domínio** completo: contas, cartões, faturas, parcelamentos, recorrências, orçamentos, metas, relatórios, importação, API.
- **Regras de negócio numeradas** (3.1, 3.2...), porque os reviews vão citá-las. Exemplo: "dinheiro em centavos, nunca float"; "transferência é uma linha só".
- **Telas** e o que cada uma mostra.
- **Definição de pronto**: testes, Docker, seed de demonstração (dados falsos para o app não abrir vazio), docs.
- **Restrições**: sem CDN, sem pacote pago, SQLite.

Gaste tempo aqui. Tudo que ficar ambíguo vira uma "suposição" que o modelo vai registrar e seguir sozinho, sem perguntar (foram 138 no caso real; todas em `exemplo/docs/QUESTIONS.md`).

### Passo 3 — Gere a SPEC e o ROADMAP com o modelo forte

Peça ao Claude (ou equivalente) para transformar o prompt em dois arquivos:

- **`docs/SPEC.md`**: o contrato. Escopo, regras numeradas, UX, critérios de aceite final. Veja o real em [`exemplo/docs/SPEC.md`](exemplo/docs/SPEC.md).
- **`docs/ROADMAP.md`**: tasks em checkbox, agrupadas em fases, **cada fase com o aceite no título** e **cada task com um critério que um script consegue verificar**. Veja [`exemplo/docs/ROADMAP.md`](exemplo/docs/ROADMAP.md). Formato de uma linha:

```markdown
## Fase 2 — Transações (aceite: CRUD completo com split, transferência single-row, filtros; testes verdes)
- [ ] 2.1 Migration transactions + model + factory + scope por user_id
- [ ] 2.2a `Money` value object (centavos, parse "1.234,56", format "R$ 1.234,56") + testes
```

Regras que funcionaram:

- Task cabe em **um processo de 45 minutos** de um modelo barato. Se não cabe, quebre em `2.2a`, `2.2b`.
- **Fase 0 é fundação**: skeleton (projeto vazio do framework), auth, painel, `check.sh` verde vazio. Só depois vem domínio.
- Marcadores: `[ ]` pendente, `[x]` feita, `[!]` travada, `[-]` substituída por subtasks. Os scripts dependem disso.

**Revise você.** É a única revisão humana obrigatória do processo. O loop inteiro vai obedecer a esses dois arquivos.

### Passo 4 — Monte o projeto

Crie a pasta do projeto, inicie o git e copie deste repositório (troque `<este-repo>` pelo caminho onde você clonou este guia):

```bash
mkdir meu-app && cd meu-app && git init
cp -r <este-repo>/exemplo/AGENTS.md .
cp -r <este-repo>/exemplo/.opencode .
cp -r <este-repo>/exemplo/scripts .
mkdir -p docs/reports logs
cp <este-repo>/exemplo/docs/{HINTS,PROGRESS,BLOCKED,QUESTIONS}.md docs/   # e esvazie o conteúdo, deixando só o cabeçalho
# coloque a sua SPEC.md e ROADMAP.md em docs/
```

O que cada coisa é:

| Arquivo | O que faz | Adaptar? |
|---|---|---|
| `AGENTS.md` | O protocolo: ciclo de uma task em passos numerados, delegação, o que fazer na falha, no travamento e na troca de fase. Nenhum passo espera humano. | Só o nome do projeto e a stack citada. A estrutura serve para qualquer app. |
| `.opencode/agents/coordinator.md` | Lê a próxima task, delega, roda o gate, commita, marca `[x]`. **Não escreve código.** | Modelo (`model:`) se usar outro. |
| `.opencode/agents/implementer.md` | Escreve código. **Sem git, sem marcar checkbox** (bloqueado por permissão, não por pedido). | Modelo. |
| `.opencode/agents/reviewer.md` | Audita uma fase inteira contra a SPEC e escreve `docs/reports/fase-N.md` com veredito. **Não edita.** | Modelo. |
| `.opencode/commands/next.md` | O comando `/next`: injeta via shell a próxima task, o gate, as travadas, os aprendizados recentes e as dicas. O modelo não precisa descobrir onde está. | Não. |
| `.opencode/commands/{phase,review,unblock,status}.md` | Fechar uma fase, (re)rodar review, quebrar task travada em subtasks, status. | Não. |
| `scripts/check.sh` | **O único aceite.** Lint + análise estática + testes. Última linha `CHECK: PASS` ou `CHECK: FAIL`. | **Sim: é aqui que entra a sua stack.** Troque `composer check` pelo equivalente (`npm test && npm run lint`, `pytest && ruff`...). Mantenha a última linha. |
| `scripts/next-task.sh` | Próxima `[ ]` do roadmap, ou `NONE`. | Não. |
| `scripts/phase-gate.sh` | Decide se a fase anterior precisa de review antes de seguir. | Não. |
| `scripts/mark-done.sh`, `mark-blocked.sh`, `mark-review.sh`, `note.sh` | Mexem no roadmap e nos docs de forma determinística (o modelo chama scripts, não edita markdown na mão). | Não. |
| `scripts/autopilot.sh` | O loop de fora (seção 5). | Variáveis de ambiente, se quiser. |
| `scripts/pgtimeout.pl` | Timeout que mata o grupo de processo inteiro (senão sobram testes órfãos rodando). | Não. |
| `docs/HINTS.md` | Dica para o loop sem parar: o que estiver aqui entra em toda iteração. Apague quando não precisar. | Vazio no início. |
| `docs/PROGRESS.md` | Aprendizados entre iterações (só acrescenta, nunca apaga; as últimas 40 linhas entram em cada `/next`). | Vazio no início. |
| `docs/BLOCKED.md`, `docs/QUESTIONS.md` | Tasks travadas para humano; suposições tomadas. | Vazios no início. |

Duas pegadinhas do opencode que custaram horas:

- **Permissões: a última regra que casa vence.** O `"*"` (vale para tudo) vai no topo do bloco, as exceções embaixo. Veja `exemplo/.opencode/agents/implementer.md`.
- **Argumentos de comando vão por stdin** (a entrada padrão do processo, o que você "digitaria"). `-- 3.2` derruba o parser e stdin aberto trava o processo. Os scripts já fazem certo.

### Passo 5 — Rode três iterações olhando

```bash
opencode run --agent coordinator --command next --auto --variant high
```

Isso executa **um** ciclo: próxima task → implementer → `check.sh` → commit → `[x]`. Rode três vezes lendo a saída. Você está checando:

1. O implementer não tentou usar git (se tentou, a permissão bloqueou?).
2. O `check.sh` rodou e a última linha foi `CHECK: PASS`.
3. O commit tem só a task e o `[x]` foi marcado pelo script, não na mão.
4. `docs/PROGRESS.md` ganhou uma linha útil.

Na fase 0, o skeleton do framework costuma trazer o próprio `AGENTS.md` e `.gitignore`. Se o modelo sobrescrever o seu, restaure do git (`git checkout -- AGENTS.md`) e coloque uma dica em `docs/HINTS.md`.

`--variant high` é o nível de raciocínio do modelo. Com `low`, o modelo ignorou instrução pontual; com `high`, obedeceu. Custa mais tempo por task, mas menos retrabalho.

### Passo 6 — Solte o loop

```bash
caffeinate -dis scripts/autopilot.sh      # Mac: -dis segura o sistema acordado (só na tomada). Linux: só scripts/autopilot.sh
tail -f logs/autopilot.log                # em outro terminal, acompanha o log ao vivo
scripts/status.sh                         # placar a qualquer hora
```

O `autopilot.sh` faz, por iteração:

1. Testa se o modelo gratuito responde ("OK" em 40 s). Se não, troca os agentes para o pago e volta sozinho quando liberar.
2. Se há task `[!]`, tenta `/unblock` uma vez por família (quebra em subtasks). Se travar de novo, deixa `[!]` para humano e segue.
3. Se não há task pendente e alguma fase está sem review (ou reprovada com corretivas prontas), roda `/review`.
4. Roda `/next` num processo novo, com timeout de 45 minutos.
5. Se o processo morreu: árvore suja fora de `docs/` é revertida (o `[x]` nunca fica sem o código). Sobras só em `docs/` viram commit.
6. Falha de processo (rate limit, rede) **não conta** como "tentativa da task". Mesma task 4 vezes sem progresso vira `[!]`. 6 falhas de processo seguidas: pausa de 30 minutos.
7. `git push` ao fim de cada iteração, sem travar se a rede cair.

Para sozinho quando o roadmap acaba e todas as fases têm review aprovado. Na troca de fase, o reviewer audita a fase inteira; se reprovar, cria tasks corretivas `N.F1`, `N.F2`, executa e re-revisa **uma vez**.

**Como monitorar de leve** (a cada 40 minutos, só leitura):

```bash
scripts/status.sh | head -1                      # X/67 tasks (travadas: N)
grep -E '^\[20' logs/autopilot.log | tail -5     # últimas iterações
cat docs/BLOCKED.md                              # travadas esperando você
git log --oneline -3
pgrep -fl 'opencode run'                         # tem processo rodando?
```

Intervir só se: task `[!]` nova, review reprovada, mesma task há mais de 60 minutos, ou processo ausente com roadmap incompleto. E, nesses casos, quase sempre o bug é no loop, não no modelo.

**Quando algo dá errado:**

| Sintoma | Causa | O que fazer |
|---|---|---|
| `opencode saiu com rc=1` várias vezes | Rate limit do modelo gratuito | Nada. O loop alterna para o pago (se configurado) ou pausa 30 min. Sem pago: espere; a cota é por conta e libera em horas. |
| `árvore suja após a iteração — revertendo` | Processo morreu no meio (rede, sleep) | Nada. A task será refeita. Deixe o notebook na tomada. |
| Task marcada `[!]` | 4 iterações sem progresso | Leia `docs/BLOCKED.md`. Ou a task era grande demais (quebre no roadmap e volte para `[ ]`), ou a spec era ambígua (esclareça em `docs/HINTS.md`). |
| Review `REPROVADA` | O reviewer achou gap contra a SPEC | Nada. O loop cria as corretivas. Leia o relatório em `docs/reports/fase-N.md` para entender. |
| Loop parou com `fim. status` mas ainda falta algo | Bug no loop | Foi o caso aqui uma vez (a re-review da última fase não rodava). Está corrigido nos scripts deste repositório. |

### Passo 7 — Rode o app e olhe

```bash
cp .env.example .env
docker compose up --build -d
docker compose exec app php artisan db:seed --class=DemoSeeder   # usuário demo com 12 meses de dados
```

E abra no browser. **Este é o passo que o processo não faz sozinho.** No caso real, o painel estava sem CSS desde a fase 0: o agente tinha registrado um "tema" de 3 KB que substituía o CSS inteiro do Filament, e as telas usavam classes Tailwind que ninguém compilava. Dez reviews aprovaram, porque o gate e o reviewer só leem código e testes. Foram dois commits à mão para consertar.

Lição para o seu `check.sh`: coloque algo que **veja a tela**. No mínimo, um teste de que o CSS das views foi compilado; melhor, um screenshot automatizado na troca de fase.

### Passo 8 — Segunda rodada: o visual com outro modelo

Funcional não é bonito. Em vez de reabrir o loop, a estética virou **uma task delegada a um modelo diferente** (gemini-3.8-flash, via [omp](https://github.com/can1357/oh-my-pi) e [acpx](https://github.com/openclaw/acpx); serve qualquer agente que leia arquivos e rode shell).

O que fez dar certo foi a spec, não o modelo. Está em [`docs/spec-revisao-visual.md`](docs/spec-revisao-visual.md) e tem:

1. **Direção de design decidida de antemão** ("fintech séria e calma, um acento, semântica de cor fixa: entrada emerald, saída rose..."). O modelo não escolhe estética.
2. **Contexto técnico** que ele não descobriria sozinho: como o CSS é compilado, onde as classes entram, o que os testes exigem que continue existindo.
3. **Roteiro tela por tela em oito passes**, com gate verde obrigatório no fim de cada um.
4. **Listas fechadas** de arquivos que pode ler, pode editar e não pode tocar.
5. **Regras**: sem git, sem pacote novo, sem CDN, testes são contrato (não edita teste; se um teste bloquear, para e reporta).
6. **Aceite executável** e **report obrigatório** (checklist por tela, desvios, gaps).

Resultado: 32 minutos, 39 arquivos, 1.029 testes verdes. Depois, revisão humana em três larguras de tela e dark mode: seis ajustes pequenos e um bug de build. O report do modelo está em [`docs/REVIEW-VISUAL.md`](docs/REVIEW-VISUAL.md) e o manual do design system que ele escreveu em [`docs/DESIGN-SYSTEM.md`](docs/DESIGN-SYSTEM.md).

Para rodar com o omp: crie um preset no acpx apontando para `omp acp --model google-antigravity/gemini-3.8-flash --thinking high --tools read,glob,grep,edit,write,bash` e dispare com `acpx --approve-all --timeout 5400 <preset> exec -f docs/spec-revisao-visual.md`. Com outro agente, cole a spec como prompt. Sempre com a árvore limpa antes (o commit é a rede de segurança).

---

## 5. Quanto custa e quanto demora

| Item | Caso real |
|---|---|
| Spec + roadmap com modelo forte | uma conversa longa; o custo de um chat |
| 69 tasks + 11 reviews no modelo gratuito | 103 processos, ~13 horas úteis, R$ 0 |
| 3 iterações no modelo pago (rate limit) | centavos |
| Rodada visual (gemini-3.8-flash) | 32 minutos, ~1,2 M tokens de entrada (cache), ~150 k de saída |
| Horas perdidas com rate limit e notebook dormindo | ~9 |
| Horas de atenção humana | ~2 (spec, três iterações vigiadas, checks de 40 min, correções finais) |

---

## 6. O que deu errado e como está corrigido

Todos os bugs foram nos **scripts do loop**. O modelo seguiu o protocolo em 69 tasks: nunca marcou checkbox sem gate verde, nunca fez duas tasks num ciclo, registrou suposição em vez de perguntar.

1. **Primeiro review contado como segundo.** `mark-review.sh` contava o cabeçalho que o coordinator escreve. Corrigido: só conta review commitado.
2. **Rate limit travando task.** O guard de "4 iterações sem progresso" contava falha de rede como tentativa. Corrigido: falha de processo zera o contador.
3. **Re-review da última fase nunca rodava.** A regra "reprovada + corretivas prontas → segundo review" só existia no gate de troca de fase; na última fase não há próxima. Corrigido em `missing_reviews`.
4. **opencode pendurado sob rate limit** em vez de falhar. Cada tentativa queimava o timeout inteiro. Mitigado com o probe de 40 s antes de cada iteração e a alternância para o pago.

E fora do loop: **notebook na bateria dorme mesmo com `caffeinate`**. Custou três reversões de task. Tomada.

A lição que vale para qualquer projeto, com ou sem IA: **o que não é verificado por máquina não está verificado.** Dez reviews aprovaram um painel sem CSS porque nenhum deles abria o browser.

---

## 7. Perguntas frequentes

**Isso é "programar com IA"? Eu ainda preciso aprender a programar?** Precisa, e mais do que antes. Quem escreveu a spec, desenhou o protocolo, achou os quatro bugs no loop e consertou o painel sem CSS foi um humano lendo código. O modelo barato fez a parte repetitiva. Sem saber ler o que ele produz, você não tem como julgar se está certo.

**Serve para outra stack?** Sim. O protocolo, os agentes, os comandos e o loop não sabem nada de Laravel. Troque o `check.sh` e a SPEC.

**Precisa do modelo pago?** Não. Sem ele o loop pausa quando o gratuito atinge a cota e retoma sozinho. Demora mais.

**Posso usar outro modelo gratuito?** Sim, troque `model:` nos três agentes (ou `FREE_MODEL` no autopilot). A cota dos modelos gratuitos do provider `opencode` é por conta, não por modelo: quando um cai, os outros caem junto.

**Posso rodar no Windows?** O loop é bash + perl; use WSL2.

**E se eu quiser mudar a spec no meio?** Edite `docs/SPEC.md`/`ROADMAP.md` e commite. A próxima iteração lê o novo estado. Para uma dica pontual sem mudar a spec, `docs/HINTS.md`.

**O modelo pode apagar meu trabalho?** O implementer não tem git. O loop reverte árvore suja, mas nunca toca em commit. Tudo que passou no gate está no git e no push.

**Quanto de supervisão de verdade?** Três iterações olhando no começo, um check de leitura a cada 40 minutos, e o browser no fim. O resto é opcional.

**Posso copiar isso para um trabalho da faculdade?** Pode, a licença é MIT. Cite a fonte e, principalmente, entenda o que está copiando: o professor vai perguntar.

---

## 8. Mapa deste repositório

```
index.html                     A história ilustrada (autocontida; GitHub Pages)
arquitetura.html               Diagrama interativo do app final (Archify)
LICENSE                        MIT
docs/
  prompt-original.md           O prompt que virou SPEC e ROADMAP
  spec-revisao-visual.md       Spec de dispatch da rodada visual (modelo de spec fechada)
  REVIEW-VISUAL.md             Report do gemini-3.8-flash
  DESIGN-SYSTEM.md             Manual do design system que ele escreveu
  finance-iam.architecture.json  Spec do diagrama (Archify)
exemplo/                       Os arquivos reais do finance-iam
  AGENTS.md                    O protocolo
  .opencode/agents/            coordinator, implementer, reviewer
  .opencode/commands/          /next, /phase, /review, /unblock, /status
  scripts/                     autopilot.sh, check.sh, next-task.sh, phase-gate.sh, mark-*.sh, note.sh, status.sh, pgtimeout.pl
  docs/SPEC.md, ROADMAP.md     O contrato e as 69 tasks marcadas
  docs/QUESTIONS.md            138 suposições registradas
  docs/PROGRESS.md             Aprendizados entre iterações
  docs/reports/                Os 11 reviews (fase 9: #1 reprovado, #2 aprovado)
  docs/notes/                  Notas de biblioteca que os agentes escreveram
  docs/design/                 Spec, report e manual da rodada visual
  logs/autopilot.log           O log inteiro do dia, com os erros
  README.md, CHANGELOG.md, Dockerfile, docker-compose.yml
```

O código do app em si (`app/`, `tests/`, `resources/`) não está aqui; o objetivo deste repositório é o processo. Os arquivos em `exemplo/` são cópias fiéis, só com caminhos e e-mails pessoais trocados.
