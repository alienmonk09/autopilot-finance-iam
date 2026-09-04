# Tarefa

Revisão visual/UX/UI completa e minuciosa do painel **Finance IAM** (Laravel 13 + Filament 5 + Livewire 4 + Tailwind v4), para sair com visual profissional em TODAS as telas: sistema de design coerente (tokens de cor, tipografia, espaçamento, elevação), motion (fade, slide, transições, stagger, hover, feedback de toque), sombras/elevação com hierarquia, tabelas e cards muito melhores, dashboard com apresentação de produto, formulários e estados vazios cuidados, dark mode com a mesma qualidade do claro, responsivo de 375px a 1440px, `prefers-reduced-motion` respeitado.

O app funciona e está 100% testado (1029 testes). Você NÃO muda comportamento, dados, rotas ou regras de negócio. Você muda como ele **parece, se move e se sente**. Cada tela deve ficar visivelmente melhor que antes, sem quebrar nenhum teste.

Rode o app localmente para ver o HTML gerado quando precisar (`php artisan serve` + `curl`), mas o aceite é a suíte + build + o checklist deste documento.

# Contexto técnico (leia antes de tocar em qualquer arquivo)

- **Tema do painel** é compilado pelo Vite: `resources/css/filament/app/theme.css` importa o `theme.css` do Filament e faz `@source` de `app/Filament/App/**`, `resources/views/filament/app/**` e `resources/views/livewire/**`. Logo: **qualquer classe Tailwind v4 escrita nessas Blades/PHP entra no CSS** depois de `npm run build`. Classes usadas fora dessas pastas NÃO existem no CSS (não invente pastas novas de views; se precisar, adicione o `@source` no theme.css).
- O painel está registrado com `->viteTheme('resources/css/filament/app/theme.css')` em `app/Providers/Filament/AppPanelProvider.php`. Cores atuais: primary Teal, gray Slate, danger Rose, success Emerald, warning Amber, info Sky. Dark mode ligado (`ThemeMode::System`).
- **Filament 5 usa Tailwind v4** (`@theme`, `@utility`, `@custom-variant`; sem `tailwind.config.js`). Hooks de estilo do Filament são as classes `fi-*` (`.fi-ta-row`, `.fi-ta-header-cell`, `.fi-section`, `.fi-wi-stats-overview-stat`, `.fi-sidebar`, `.fi-topbar`, `.fi-btn`, `.fi-input`, `.fi-modal`…). Descubra o nome real com `grep -r "fi-<algo>" vendor/filament/*/resources/css` ANTES de escrever CSS para ele; nunca chute nome de classe.
- **Alpine.js já vem no Filament** (`x-data`, `x-show`, `x-transition`, `x-intersect` não vem — use IntersectionObserver em `@keyframes` puros ou `x-init`). Livewire 4 faz morph do DOM: elementos animados dentro de loops precisam de `wire:key`; animação de entrada deve rodar em `@keyframes` CSS (não depender de JS que o morph descarta).
- **Ícones**: Heroicons via `@svg('heroicon-o-…')` / `<x-filament::icon icon="heroicon-o-…">` (já instalados). Nunca emoji como ícone.
- **Fontes**: sem CDN em runtime (SPEC seção 1, testado). Inter Variable já vem autohospedada no Filament; Instrument Sans já é baixada no BUILD via `bunny()` em `vite.config.js` (permitido: fontes só entram no build). Pode adicionar no máximo UMA família nova pelo mesmo mecanismo `bunny()` (ex.: uma mono para valores) — e usar `font-variant-numeric: tabular-nums` em todo número monetário.
- **Dinheiro** é sempre formatado por `Money::format()` (centavos, `R$ 1.234,56`). Nunca formate na Blade por conta própria, nunca mude sinal/cor sem base no dado (`type`, `status`).
- Notas de biblioteca já escritas pelo time: `docs/notes/filament5.md`, `docs/notes/livewire4.md`. Leia antes de usar API do Filament que não conhece de cor.
- Build: `npm run build` (Vite 8). Gate: `scripts/check.sh` (pint + larastan + pest; última linha `CHECK: PASS`). Total de `public/build` precisa ficar **abaixo de 1 MB** (testado): o tema já tem ~630 KB, sobra ~300 KB. Cuidado com `@keyframes` e utilitários em excesso — Tailwind só emite o que é usado, então o custo real é CSS manual.

# Direção de design (decidida; não reabra)

**Tom**: fintech séria e calma — "extrato de banco bem desenhado", não landing page. Refinado, denso onde é tabela, respirando onde é card. Nada de glassmorphism, gradientes roxos, neon, ou hero. Um único acento (teal) com semântica fixa: **entrada = emerald, saída = rose, transferência = sky, pendente = amber, conciliado = teal**; nunca use cor sozinha para dizer isso — sempre ícone ou texto junto.

**Tokens** (defina em `@theme`/`:root` no theme.css e use SEMPRE via classe/var; zero hex solto em Blade, exceto os que os testes exigem — ver Regras):

- Superfícies claras: fundo `slate-50`, card `white`, borda `slate-200/70`; escuras: fundo `slate-950`, card `slate-900`, borda `white/8`.
- Elevação em 3 níveis: `--shadow-1` (linha/lista: `0 1px 2px rgb(15 23 42/.06)`), `--shadow-2` (card: `0 1px 3px … , 0 8px 24px -12px …`), `--shadow-3` (modal/popover/FAB). Hover de card sobe UM nível, nunca dois. No dark, sombra quase some e a hierarquia vem de borda e fundo.
- Raio: `--radius-card: 14px`, `--radius-control: 10px`, chips `9999px`.
- Motion: `--ease-out: cubic-bezier(.2,.8,.2,1)`, `--ease-spring: cubic-bezier(.34,1.56,.64,1)` (só em micro-feedback), durações `--dur-fast: 150ms` (hover, foco), `--dur-base: 220ms` (mostrar/ocultar, dropdown), `--dur-slow: 420ms` (entrada de página/cards). Stagger de cards: `animation-delay: calc(var(--i) * 45ms)` com `--i` setado inline por `$loop->index`, máximo 8 itens escalonados. **Tudo dentro de `@media (prefers-reduced-motion: no-preference)`**; com reduced-motion, estado final imediato.
- Tipografia: UI em Inter Variable (já no Filament) com `cv11, ss01`; números com `tabular-nums`; escala: KPI 30/36px semibold com `letter-spacing:-0.02em`, título de card 14px semibold `slate-700`, rótulo/eyebrow 11px uppercase `tracking-wide slate-500`, corpo 14px, meta 12px. Nada abaixo de 12px.

# O que fazer, tela por tela (ordem obrigatória; marque o checklist no report)

## 0. Sistema de design (primeiro, antes de qualquer tela)

1. Leia, nesta ordem, e SÓ isto do skill de design (caminhos absolutos; não explore o resto):
   - `~/.claude/skills/ui-ux-pro-max/references/pro-rules.md` (regras de polish e checklist de entrega)
   - `~/.claude/skills/ui-ux-pro-max/references/quick-reference.md` (119 regras de UX; foque em Accessibility, Touch, Animation, Forms, Charts)
   - `~/.claude/skills/ui-ux-pro-max/data/stacks/laravel.csv` (regras específicas da stack)
   - `~/.claude/plugins/cache/claude-plugins-official/frontend-design/unknown/skills/frontend-design/SKILL.md` (só as seções de motion, spatial composition e detalhes; IGNORE o apelo a fontes exóticas, maximalismo e "unforgettable" — a direção acima já está fechada)
2. Pode consultar o buscador do skill para dúvidas pontuais (2–5 termos, um domínio): `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<consulta>" --domain ux|typography|color|chart|icons` ou `--stack laravel`. NÃO use `--design-system --persist` (a direção já foi decidida; o gerador sugere Google Fonts e glassmorphism, ambos proibidos aqui).
3. Escreva os tokens no topo de `resources/css/filament/app/theme.css` e as classes utilitárias do projeto logo abaixo (`@utility card-elev`, `@utility kpi`, `@utility eyebrow`, `@utility money`, `@utility reveal` com o stagger, etc.). Mantenha INTACTO tudo que já existe no arquivo (FAB, foco visível, gestos; ver Regras).
4. Registre o sistema em `docs/design/DESIGN-SYSTEM.md`: tokens, semântica de cor, escala tipográfica, níveis de elevação, vocabulário de motion, como usar cada `@utility`. Curto e prático (uma página), é o manual pra quem mexer depois.

## 1. Shell do painel (sidebar, topbar, página, modais)

- Sidebar: item ativo com fundo teal suave + barra de 3px à esquerda animada (`transform: scaleY`), ícones 20px alinhados, grupos com eyebrow, hover `--dur-fast`. Colapsada no desktop mantém tooltip nativo do Filament.
- Topbar: sombra `--shadow-1` que só aparece após rolar (classe via Alpine `x-data="{s:false}" @scroll.window="s = scrollY > 8"`), busca com foco animado (anel teal + leve alargamento), botão "Lançamento rápido" com hover que sobe 1px e sombra nível 2, `:active` que desce.
- Cabeçalho de página: título 24px semibold + subtítulo 13px `slate-500` (Filament `->subheading()`/`getSubheading()` onde fizer sentido), ações à direita alinhadas por baseline.
- Entrada de página: `.fi-page` faz fade + `translateY(6px→0)` em `--dur-slow`; seções/cards internos com stagger.
- Modais/slide-overs: entrada com scale `.98→1` + fade; backdrop com blur leve (4px) e `slate-950/40`.
- Notificações do Filament: slide-in da direita, sombra nível 3, ícone colorido pela semântica.
- Empty states padronizados: ícone em círculo teal-50, título 15px, descrição 13px, CTA primário. Use `->emptyStateHeading/Description/Icon/Actions()` nas tabelas e o mesmo padrão visual nas páginas custom.

## 2. Dashboard (`app/Filament/App/Pages/Dashboard.php` + `resources/views/filament/app/pages/dashboard.blade.php`) — a tela mais importante

Apresentação profissional, "abre e entende a vida financeira em 3 segundos". Mantenha TODA a lógica (ordem/visibilidade por usuário, `moveWidgetUp/Down`, `toggleWidget`, `resetLayout`, o atributo `data-dash-control` em cada controle) e os mesmos dados do `DashboardData`. Refaça a apresentação:

- **Linha 1 (KPIs)**: grid 4 colunas (1 no mobile, 2 no tablet) com cards de KPI: eyebrow, valor grande `tabular-nums`, delta com seta ↑/↓ e cor semântica + texto ("vs mês anterior"), sparkline inline SVG dos últimos 6 meses quando o dado existir (`fluxo de caixa 12 meses` já traz série; reaproveite), micro-ícone do KPI em círculo suave no canto. Saldo total, Receitas do mês, Despesas do mês, Saldo previsto.
- **Linha 2**: Contas (lista com dot colorido do banco, nome, instituição, saldo alinhado à direita, barra fina proporcional ao saldo total; hover realça) | Cartões (card por cartão: nome, fatura aberta em destaque, fechamento em X dias como chip, barra de uso do limite com gradiente semântico teal→amber→rose e rótulo de %).
- **Linha 3**: Próximos vencimentos (timeline vertical com datas, chip por tipo Fatura/Recorrência/Parcela, valor à direita; os filtros 7/15/30 dias viram segmented control com transição de indicador) | Orçamentos do mês (barras horizontais por categoria, cor semântica pelo % gasto, valor gasto/limite `tabular-nums`).
- **Linha 4**: Gastos por categoria (donut SVG inline com legenda ao lado, percentuais, hover realça fatia; sem lib) | Fluxo de caixa 12 meses (barras entrada/saída lado a lado em SVG inline, eixo com meses abreviados, tooltip nativo `<title>`, linha do resultado).
- **Linha 5**: Metas (card por meta com anel de progresso SVG e prazo) | Atalhos rápidos (grid de botões com ícone) | Projeção 90 dias (área SVG suave com linha zero destacada).
- Controles subir/descer/ocultar: viram um menu de três pontinhos por card (Filament dropdown) ou ícones discretos que só aparecem no hover do card (sempre visíveis no touch), mantendo `data-dash-control` e os mesmos `wire:click`. "Widgets ocultos": chips clicáveis com ícone `+`, e "Restaurar padrão" como link secundário.
- Cada card usa `card-elev`, cabeçalho com título + ação, `reveal` com stagger na entrada. Skeleton (`animate-pulse` com blocos cinza) enquanto `wire:loading` em mudanças de layout.

## 3. Tabelas (todos os `ListX` em `app/Filament/App/Resources/*/Pages` + `resources/views/filament/app/{accounts/statement,credit-cards/invoice,installment-groups/parcels,recurrences/occurrences}.blade.php`)

Configure no PHP do Resource (colunas) e no CSS (`.fi-ta-*`):

- Cabeçalho sticky com fundo `slate-50`/`slate-900`, texto 11px uppercase tracking-wide; linhas 44px de altura mínima; zebra suave; hover `slate-50`/`white/4` em `--dur-fast`; linha clicável com `cursor-pointer`.
- Coluna de valor sempre `->alignEnd()` + `tabular-nums` + cor semântica por tipo (`->color(fn)`), com sinal e ícone pequeno (seta) — Transações, Faturas, Parcelas, Extrato.
- Badges com semântica (status pendente/confirmado/conciliado, tipo, categoria com cor da categoria como dot) via `->badge()->color()`/`->icon()`; datas `d/m` com dia da semana em `->description()` onde ajudar; payee/categoria com `->description()` secundária em vez de coluna extra.
- Agrupamento por data (`->groups()` / `->defaultGroup('date')`) na lista de Transações, com sumário de entradas/saídas/resultado por grupo (`->summarize()`), e o rodapé de totais existente (`transactions-footer.blade.php`) redesenhado como barra fixa inferior com 3 KPIs.
- Filtros: layout `->filtersLayout(FiltersLayout::AboveContentCollapsible)` onde tem mais de 2 filtros; chips de filtro ativo visíveis; busca com ícone.
- Mobile: mantenha a tabela empilhada existente (`md:fi-visible` já usada; teste cobre) e melhore a leitura: título da linha em negrito, valor grande à direita, meta em 12px.
- Ações de linha: ícones com tooltip, agrupadas em `ActionGroup` quando > 2; ação destrutiva sempre com confirmação (já existe) e cor danger.
- Tabelas custom em Blade (extrato, fatura, parcelas, ocorrências): mesmo vocabulário (classes do sistema), cabeçalho sticky, zebra, totais destacados.

## 4. Formulários (todos os `Create*/Edit*` + `Settings`, `Rules`, `Import`, `Budgets`, `Goals`, `Onboarding`)

- Seções (`Section::make()->description()->icon()`) agrupando campos por assunto, 2 colunas no desktop, 1 no mobile; campo de valor com prefixo `R$` e `tabular-nums`; selects com ícone/cor; toggles com descrição.
- Foco: anel teal 2px + sombra suave em `--dur-fast`; erro: borda rose + mensagem abaixo do campo com ícone; helper text em 12px.
- Botões: primário teal com hover que escurece e sobe 1px, `:active` desce; secundário outline; destrutivo rose. Estado `wire:loading` com spinner (Filament já tem — garanta que aparece).
- Wizards (Import, Onboarding): stepper com passo atual em teal, concluídos com check, transição de passo com fade+slide horizontal; cards de opção (ex.: "importar / lançar / dashboard") com hover e seleção clara.

## 5. Páginas custom (`Reports`, `Budgets`, `Goals`, `Rules`, `Import`, `Backup`, `RecurrenceCalendar`, `PendingRecurrences`, `Settings`, `Onboarding`)

- Reports (489 linhas de Blade): cada relatório em card com título, período em chip, gráfico SVG inline quando houver série, tabela com o vocabulário da seção 3, botões de exportar CSV/PDF com ícone agrupados à direita. Seletor de relatório vira tabs/segmented control com indicador animado.
- Budgets: barras por categoria com o mesmo componente do dashboard; "copiar do mês anterior" e "sugerir médias" como ações secundárias com ícone.
- Goals: cards com anel de progresso; concluída ganha check e opacidade.
- Rules: builder de condições/ações como cards empilhados com conector visual; preview de dry-run em tabela zebra.
- RecurrenceCalendar: grade mensal com células 44px+, dot por tipo, hoje destacado, navegação de mês com setas e transição.
- PendingRecurrences: lista com ações confirmar/pular alinhadas, chip de atraso.
- Backup/Settings: cards por assunto, ações perigosas (restore) em card com borda rose e confirmação.

## 6. Telas fora do painel (`resources/views/auth/*.blade.php`, `resources/views/layouts/auth.blade.php`, `home.blade.php`, `welcome.blade.php`, `configuracoes.blade.php`)

Mesmo sistema (essas usam `resources/css/app.css` via `@vite`: adicione lá os mesmos tokens ou importe um `resources/css/tokens.css` compartilhado pelos dois entries). Login/registro/2FA/reset: card centrado com logo, campos com o mesmo foco, botão primário, links secundários, fade de entrada. Nada de "página em branco com formulário nu".

## 7. Livewire `QuickCreateTransaction` (`app/Livewire`, `resources/views/livewire/quick-create-transaction.blade.php`)

Modal/slide-over com entrada animada, campos em ordem valor → tipo (segmented entrada/saída/transferência com cor semântica) → conta → categoria → descrição → data; teclado numérico no mobile (`inputmode="decimal"`); botão salvar com loading; toast de sucesso. Mantenha o FAB (`data-fab="quick-create"`) e o `aria-label="Lançamento rápido"`/`aria-haspopup="dialog"` exatamente como estão.

# Arquivos

- PODE ler: tudo em `app/Filament/`, `app/Livewire/`, `app/Providers/Filament/AppPanelProvider.php`, `resources/`, `vite.config.js`, `docs/notes/filament5.md`, `docs/notes/livewire4.md`, `docs/SPEC.md` (seção 4 UX), `tests/Feature/Filament/AccessibilityMobileTest.php`, `tests/Feature/Performance/LighthouseBudgetTest.php`, `vendor/filament/*/resources/css/**` (só para descobrir classes `fi-*`), `app/Domain/Dashboard/*.php` (só para saber o formato dos dados). Não liste diretórios fora disso; não leia `app/Domain/**` além do Dashboard, nem `app/Models`, nem migrations.
- PODE editar/criar: `resources/css/filament/app/theme.css`, `resources/css/app.css`, `resources/css/tokens.css` (novo, opcional), `resources/views/filament/app/**`, `resources/views/livewire/**`, `resources/views/auth/**`, `resources/views/layouts/**`, `resources/views/{home,welcome,configuracoes}.blade.php`, `app/Filament/App/**` (SÓ configuração de apresentação: colunas, badges, cores, ícones, seções, descrições, agrupamentos, empty states, subheadings, render hooks — nunca queries, actions de negócio, validação, autorização), `app/Livewire/QuickCreateTransaction.php` (idem: só apresentação), `app/Providers/Filament/AppPanelProvider.php` (cores, fontes, render hooks, `->sidebarWidth()` etc.), `vite.config.js` (só para adicionar UMA fonte via `bunny()`), `docs/design/DESIGN-SYSTEM.md` e `docs/design/REVIEW-VISUAL.md` (novos).
- NÃO TOCAR: `tests/**`, `app/Domain/**`, `app/Models/**`, `app/Http/**`, `routes/**`, `database/**`, `scripts/**`, `docs/**` (exceto `docs/design/`), `Dockerfile`, `docker-compose.yml`, `composer.json`, `package.json` (nenhum pacote novo, npm ou composer), `.opencode/**`, `AGENTS.md`, `README.md`, `CHANGELOG.md`, `resources/views/reports/export-pdf.blade.php` (PDF fica como está).

# Regras

- NÃO use git para NADA (nem status, nem diff, nem stash). O coordenador commita.
- Nenhum pacote novo; nenhuma URL externa em runtime (nada de `googleapis`, `unpkg`, `cdn.` no CSS/HTML — há teste que falha). Fontes só via `bunny()` no build.
- Teste é contrato: **não edite testes**. Estes trechos são exigidos por teste e devem continuar existindo exatamente assim (pode mover de lugar, não pode sumir): em `theme.css` → `:focus-visible`, `:active`, `#0f766e`, `48px`, `safe-area-inset-bottom`, `overscroll-behavior`, `-webkit-overflow-scrolling: touch`, `[data-dash-control]`; no HTML do dashboard → `data-fab="quick-create"`, `aria-label="Lançamento rápido"`, `aria-haspopup="dialog"`, `data-dash-control`, `lang="pt-BR"`, `name="viewport"`, `name="description"`, texto `Pular para o conteúdo`, classe `fi-main-content`, avatar `data:image/svg+xml`. Se alguma mudança visual exigir mexer em teste, PARE, deixe a tela como está e reporte em "desvios".
- Contraste AA (4,5:1 texto, 3:1 UI) nos dois temas; foco visível em tudo; alvos de toque ≥ 44px; nada de cor sozinha como único sinal; `prefers-reduced-motion` em toda animação; nenhuma animação de `width/height/top/left` (só `transform`/`opacity`); nada de `!important` salvo para vencer utilitário do Filament e com comentário do porquê.
- Não invente dados: se um gráfico precisar de série que o `DashboardData` não fornece, renderize sem o gráfico e anote em "gaps". Não altere `app/Domain`.
- Livewire: todo elemento em loop com `wire:key`; nenhum `x-data` que perca estado no morph sem `wire:ignore` consciente.
- Formatação: `vendor/bin/pint --dirty` antes de terminar (PHP). Blade: 4 espaços, atributos em ordem `wire:* x-* class` .
- Texto em português do Brasil, como o app. Nunca troque rótulos que já existem (os testes buscam alguns).
- Trabalhe em passes: (0 sistema) → (1 shell) → (2 dashboard) → (3 tabelas) → (4 forms) → (5 páginas) → (6 auth) → (7 quick-create). Ao fim de CADA passe rode `npm run build && scripts/check.sh | tail -3`. Se der `CHECK: FAIL`, conserte antes de seguir; se o build passar de 1 MB, reduza CSS manual antes de seguir. Não avance com gate vermelho.

# Aceite (executável)

```bash
npm run build                                  # sem erro; theme-*.css gerado
du -sk public/build | awk '{print $1" KB (< 1024)"}'
scripts/check.sh | tail -1                     # → CHECK: PASS  (1029 testes, 0 falhas)
grep -cE 'googleapis|unpkg|cdn\.' public/build/assets/*.css   # → 0 em todos
grep -c 'prefers-reduced-motion' resources/css/filament/app/theme.css   # → ≥ 1
```

Mais o checklist marcado no report (abaixo), com TODAS as telas da seção "O que fazer" cobertas.

# Report final obrigatório (`docs/design/REVIEW-VISUAL.md`)

1. Tokens e utilitários criados (nome → uso).
2. Checklist por tela (0–7 e cada Resource/Page nomeado), com `[x]` feito / `[ ]` não feito e o motivo.
3. Mudanças por arquivo (uma linha cada).
4. Desvios da spec (o que você fez diferente e por quê) e testes que bloquearam algo.
5. Gaps conhecidos: o que ficou por fazer, dados que faltaram para gráficos, pontos que precisam de olho humano no browser (liste as telas e o que checar).
6. Saída literal dos comandos de aceite.
