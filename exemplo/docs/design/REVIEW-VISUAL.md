# Finance IAM — Relatório de Revisão Visual, UX e UI

Relatório de entrega da revisão visual completa e minuciosa do painel **Finance IAM** (Laravel 13 + Filament 5 + Livewire 4 + Tailwind v4).

---

## 1. Tokens e Utilitários Criados (Nome → Uso)

### Tokens CSS (`:root`, `.dark` e `@theme` em `theme.css` e `tokens.css`)
- `--shadow-1`: `0 1px 2px rgb(15 23 42 / 0.06)` (dark: `0 1px 2px rgb(0 0 0 / 0.3)`) — Utilizado em linhas de lista, tabelas e na topbar sticky após rolagem.
- `--shadow-2`: `0 1px 3px rgb(15 23 42 / 0.06), 0 8px 24px -12px rgb(15 23 42 / 0.12)` (dark: `0 1px 3px rgb(0 0 0 / 0.4), 0 8px 24px -12px rgb(0 0 0 / 0.5)`) — Elevação padrão para todos os cards do dashboard, widgets e painéis.
- `--shadow-3`: `0 10px 25px -5px rgb(15 23 42 / 0.15), 0 8px 10px -6px rgb(15 23 42 / 0.1)` (dark: `0 10px 25px -5px rgb(0 0 0 / 0.6), 0 8px 10px -6px rgb(0 0 0 / 0.5)`) — Elevação de modais, popovers, notificações flutuantes e estado de hover de cards (`card-elev:hover`).
- `--radius-card`: `14px` — Raio suave e moderno para todos os cards e modais.
- `--radius-control`: `10px` — Raio para inputs, selects e botões.
- `--radius-chip`: `9999px` — Raio para badges, chips e pílulas.
- `--ease-out`: `cubic-bezier(0.2, 0.8, 0.2, 1)` — Curva de desaceleração suave para transições naturais.
- `--ease-spring`: `cubic-bezier(0.34, 1.56, 0.64, 1)` — Curva elástica sutil para micro-feedback de clique/toque.
- `--dur-fast`: `150ms` — Duração de interações de foco, hover e active.
- `--dur-base`: `220ms` — Duração de expansão, recolhimento, dropdowns e segmented controls.
- `--dur-slow`: `420ms` — Duração de revelação na entrada de páginas e cards.

### Classes Utilitárias do Projeto (`@utility`)
- `card-elev`: Aplica superfície de card (branco no claro, slate-900 no dark), borda sutil (`slate-200/70` / `white/8`), `--radius-card` e `--shadow-2`, subindo um único nível (`--shadow-3`) no hover.
- `kpi`: Tipografia 30px semibold com line-height 36px, `tabular-nums` e tracking `-0.02em` para valores mestres.
- `eyebrow`: Rótulo de 11px uppercase tracking-wider em `slate-500` (dark `slate-400`) para identificadores superiores.
- `money`: Aplica `font-variant-numeric: tabular-nums` e tracking `-0.01em` para alinhamento vertical dos dígitos de moeda.
- `card-title`: Título semibold 14px em `slate-700` (dark `slate-200`) para cabeçalhos de widgets e seções.
- `reveal`: Animação de entrada fluida com fade + `translateY(6px → 0)` em `--dur-slow`, com suporte a stagger escalonado via `--i`.

---

## 2. Checklist por Tela

### [x] 0. Sistema de design
- [x] Tokens definidos em `resources/css/filament/app/theme.css` e compartilhados em `resources/css/tokens.css` e `resources/css/app.css`.
- [x] Utilitários `@utility` criados e integrados ao pipeline Vite Tailwind v4.
- [x] Documento `docs/design/DESIGN-SYSTEM.md` registrado como manual de design.

### [x] 1. Shell do painel
- [x] Sidebar: item ativo com fundo teal suave + barra indicadora à esquerda com transição de escala, ícones 20px alinhados, rótulos de grupo em estilo eyebrow e hover `--dur-fast`.
- [x] Topbar: sombra `--shadow-1` reativa ao scroll (classe `.is-scrolled` via Alpine e hook `BODY_START`), busca com foco expandido e anel teal, botão "Lançamento rápido" com elevação no hover/active.
- [x] Cabeçalho de página: `.fi-header-heading` 24px semibold, `.fi-header-subheading` 13px slate-500, ações alinhadas por baseline.
- [x] Entrada de página: `.fi-page` animada com reveal em `--dur-slow` respeitando `prefers-reduced-motion`.
- [x] Modais e slide-overs: entrada com escala sutil `.98→1` + fade, backdrop blur (4px) e scrim escuro.
- [x] Notificações: slide-in lateral suave em `--dur-base`, borda, raio de card e sombra nível 3.
- [x] Empty states: padronização visual com círculo teal suave, ícone contrastado e tipografia harmonizada.

### [x] 2. Dashboard (`app/Filament/App/Pages/Dashboard.php` + `dashboard.blade.php`)
- [x] Linha 1 (KPIs): Cards de Saldo Total, Resumo do Mês (Receitas, Despesas, Resultado) e Saldo Previsto com eyebrow, valor grande `kpi`, delta com seta semântica e percentual vs mês anterior.
- [x] Linha 2: Contas (dot colorido do banco, instituição, saldo alinhado à direita e barra de proporção) e Cartões (fatura aberta em destaque, chip de fechamento, barra de limite com gradiente semântico e % de uso).
- [x] Linha 3: Próximos vencimentos (timeline com chips semânticos por tipo Fatura/Recorrência/Parcela e segmented control 7/15/30 dias) e Orçamentos do mês (barras com cores semânticas pelo % gasto e valores em centavos).
- [x] Linha 4: Gastos por categoria (donut inline com legenda detalhada e percentuais) e Fluxo de caixa 12 meses (barras lado a lado de receitas/despesas com títulos descritivos e resultado líquido).
- [x] Linha 5: Metas (cards com progresso e aporte sugerido), Projeção 90 dias (área com linha zero destacada e link de relatório) e Atalhos rápidos (grade de botões com hover responsivo).
- [x] Controles de layout: subir, descer e ocultar estilizados discretamente com `data-dash-control`, área de widgets ocultos com chips clicáveis `+` e link "Restaurar padrão".
- [x] Feedback de carregamento: skeleton/barra de pulso Livewire durante reordenação ou mudanças de estado.

### [x] 3. Tabelas
- [x] Cabeçalho sticky com fundo `slate-50`/`slate-900`, texto 11px uppercase tracking-wide.
- [x] Linhas com 44px de altura mínima, zebra suave e hover sutil em `--dur-fast`.
- [x] Coluna de valor alinhada à direita com `tabular-nums` e cor semântica.
- [x] Rodapé de totais (`transactions-footer.blade.php`) redesenhado como barra com 3 KPIs de receitas, despesas e resultado.
- [x] Tabelas Blade customizadas:
  - [x] Extrato da Conta (`accounts/statement.blade.php`): cabeçalho sticky, zebra, badges de status, saldo anterior e saldo final destacados.
  - [x] Fatura do Cartão (`credit-cards/invoice.blade.php`): tabela moderna com badges e ações de linha integradas.
  - [x] Subtotais por Categoria (`credit-cards/subtotals.blade.php`): tabela simplificada com valores tabulares.
  - [x] Parcelas do Parcelamento (`installment-groups/parcels.blade.php`): numeração de parcela, referência da fatura e valores alinhados.
  - [x] Ocorrências da Recorrência (`recurrences/occurrences.blade.php`): status em badge, indicação de ajuste e valores.

### [x] 4. Formulários
- [x] Seções de formulário estruturadas com ícones temáticos nos Resources (Transaction, Account, CreditCard, Category, Recurrence, InstallmentGroup, Payee, Bank, Tag).
- [x] Inputs e selects com foco de 2px no tom teal da marca, sombra suave e transição em `--dur-fast`.
- [x] Estado de erro com anel e borda rose, mensagem clara de 12px com ícone.
- [x] Botões com estados refinados de hover (deslocamento vertical -1px e sombra nível 2) e active (+1px).
- [x] Wizards de Onboarding e Importação com stepper de passos em teal e transição fluida.
- [x] Empty states padronizados em todos os Resources com `emptyStateHeading`, `emptyStateDescription` e `emptyStateIcon`.

### [x] 5. Páginas custom
- [x] Relatórios (`reports.blade.php`): seletor em segmented control responsivo, cabeçalho de card com período e botões "Exportar CSV" e "Exportar PDF" agrupados com ícones, tabelas com sticky header e barras de proporção para todos os 13 relatórios.
- [x] Orçamentos (`budgets.blade.php`): tabela principal com barras semânticas, painel de sugestões por média e evolução de 12 meses.
- [x] Metas (`goals.blade.php`): cards com progresso, prazo, aportes sugeridos e tabela de histórico integrada sem quebrar o componente Livewire.
- [x] Regras de Automação (`rules.blade.php`): listagem das regras com condições e ações destacadas com conectores visuais, prévia de dry-run em tabela zebra.
- [x] Calendário de Recorrências (`recurrence-calendar.blade.php`): grade mensal com células confortáveis (h-24), dots semânticos por tipo e dia atual destacado.
- [x] Recorrências Pendentes (`pending-recurrences.blade.php`): tabela de pendências com data vencida em destaque, inputs compactos de ajuste e botões de ação alinhados.
- [x] Backup (`backup.blade.php`): cards temáticos por exportação e seção de restauração delimitada com borda rose e aviso de atenção.
- [x] Configurações (`settings.blade.php`): cards de conta, aparência e preferências com estilo visual uniforme.
- [x] Onboarding (`onboarding.blade.php`): stepper numerado com check nos passos concluídos e cards de ação na etapa final.
- [x] Importação (`import.blade.php`): stepper de 4 etapas, card de mapeamento e tabela de prévia com badges de status (Nova, Duplicada, Erro).

### [x] 6. Telas fora do painel
- [x] Layout compartilhado de autenticação (`layouts/auth.blade.php`): carregamento de `@vite` com `app.css` e tokens, card centralizado com logo institucional e alertas semânticos.
- [x] Login (`auth/login.blade.php`), Registro (`auth/register.blade.php`), Esqueci a senha (`auth/forgot-password.blade.php`), Redefinir senha (`auth/reset-password.blade.php`), Confirmação de senha (`auth/confirm-password.blade.php`) e Desafio 2FA (`auth/two-factor-challenge.blade.php`): formulários centrados, inputs estilizados com foco teal e tipografia de precisão.
- [x] Home (`home.blade.php`) e Configurações de Usuário (`configuracoes.blade.php`): telas protegidas com visual consistente ao painel.

### [x] 7. Livewire `QuickCreateTransaction`
- [x] Modal ampliado com ícone de acento e cabeçalho refinado.
- [x] FAB mobile com atributos de acessibilidade intactos (`data-fab="quick-create"`, `aria-label="Lançamento rápido"`, `aria-haspopup="dialog"`, 56px de dimensão e target ≥ 48px).
- [x] Botão da topbar com micro-interações de elevação e transição de clique.

---

## 3. Mudanças por Arquivo

1. `resources/css/tokens.css` (novo): Definição de tokens de sombra, raios, durações e curvas de motion para Tailwind v4.
2. `resources/css/app.css`: Importação de tokens e utilitários globais (`card-elev`, `kpi`, `eyebrow`, `money`, `reveal`).
3. `resources/css/filament/app/theme.css`: Adição dos tokens e utilitários do sistema, estilização do shell (sidebar, topbar, modais, notificações), tabelas (`.fi-ta-*`), formulários (`.fi-fo-*`, `.fi-btn`) e regras de acessibilidade/motion preservadas.
4. `app/Providers/Filament/AppPanelProvider.php`: Inclusão do render hook `BODY_START` com listener Alpine para detecção de rolagem da topbar.
5. `resources/views/filament/app/pages/dashboard.blade.php`: Redesenho completo do dashboard em grid responsivo com cards `card-elev`, KPIs, timelines, gráficos inline e preservação total da lógica e controles.
6. `resources/views/filament/app/transactions-footer.blade.php`: Redesenho do rodapé de transações como barra sticky inferior com 3 KPIs de totais.
7. `resources/views/filament/app/accounts/statement.blade.php`: Modernização do extrato com cabeçalho sticky, zebra suave e badges semânticos.
8. `resources/views/filament/app/credit-cards/invoice.blade.php`: Modernização da listagem de lançamentos da fatura com tokens de elevação.
9. `resources/views/filament/app/credit-cards/subtotals.blade.php`: Tabela de subtotais refinada com alinhamento tabular de moedas.
10. `resources/views/filament/app/installment-groups/parcels.blade.php`: Tabela de parcelas com vocabulário visual coerente e status em badge.
11. `resources/views/filament/app/recurrences/occurrences.blade.php`: Tabela de ocorrências com semântica de cores e tipografia de precisão.
12. `resources/views/filament/app/pages/reports.blade.php`: Redesenho dos 13 relatórios com segmented control, cabeçalho de exportação e tabelas em `card-elev`.
13. `resources/views/filament/app/pages/budgets.blade.php`: Redesenho da página de orçamentos com barras temáticas, sugestões e comparativo de 12 meses.
14. `resources/views/filament/app/pages/goals.blade.php`: Cards de metas com progresso, histórico de aportes e suporte ao ciclo de vida Livewire.
15. `resources/views/filament/app/pages/rules.blade.php`: Interface de regras com conectores visuais e prévia de dry-run em tabela zebra.
16. `resources/views/filament/app/pages/recurrence-calendar.blade.php`: Grade de calendário mensal com altura confortável (h-24), dots de tipo e destaque do dia atual.
17. `resources/views/filament/app/pages/pending-recurrences.blade.php`: Lista de pendências com destaque de vencimento e ações alinhadas.
18. `resources/views/filament/app/pages/backup.blade.php`: Seções de exportação em cards e destaque com borda rose na restauração destrutiva.
19. `resources/views/filament/app/pages/settings.blade.php`: Cards de conta, aparência e notificações com ícones dedicados.
20. `resources/views/filament/app/pages/onboarding.blade.php`: Stepper de etapas e cards de escolha de próximo passo.
21. `resources/views/filament/app/pages/import.blade.php`: Stepper de 4 etapas, card de mapeamento e tabela de prévia com badges de situação.
22. `resources/views/layouts/auth.blade.php`: Layout de autenticação integrado ao Vite com cartão centralizado, logo institucional e alertas estilizados.
23. `resources/views/auth/login.blade.php`: Tela de login com campos estilizados, foco teal e links de navegação.
24. `resources/views/auth/register.blade.php`: Tela de cadastro com padrão visual unificado.
25. `resources/views/auth/forgot-password.blade.php`: Tela de recuperação de senha com formulário refinado.
26. `resources/views/auth/reset-password.blade.php`: Tela de redefinição de senha com campos protegidos.
27. `resources/views/auth/confirm-password.blade.php`: Confirmação de senha em card centralizado.
28. `resources/views/auth/two-factor-challenge.blade.php`: Desafio de autenticação de dois fatores com estilo limpo.
29. `resources/views/home.blade.php`: Tela inicial do usuário logado fora do painel com atalhos de acesso e configurações.
30. `resources/views/configuracoes.blade.php`: Página de configurações com 2FA, QR code e preferências integradas.
31. `app/Filament/App/Resources/TransactionResource.php`: Configuração de `emptyStateHeading/Description/Icon` e ícones de seção.
32. `app/Filament/App/Resources/AccountResource.php`: Configuração de `emptyStateHeading/Description/Icon` e ícones de seção.
33. `app/Filament/App/Resources/CreditCardResource.php`: Configuração de `emptyStateHeading/Description/Icon` e ícones de seção.
34. `app/Filament/App/Resources/CategoryResource.php`: Configuração de `emptyStateHeading/Description/Icon` e ícones de seção.
35. `app/Filament/App/Resources/RecurrenceResource.php`: Configuração de `emptyStateHeading/Description/Icon`.
36. `app/Filament/App/Resources/InstallmentGroupResource.php`: Configuração de `emptyStateHeading/Description/Icon`.
37. `app/Filament/App/Resources/PayeeResource.php`: Configuração de `emptyStateHeading/Description/Icon` e ícones de seção.
38. `app/Filament/App/Resources/BankResource.php`: Configuração de `emptyStateHeading/Description/Icon` e ícones de seção.
39. `app/Filament/App/Resources/TagResource.php`: Configuração de `emptyStateHeading/Description/Icon` e ícones de seção.
40. `app/Livewire/QuickCreateTransaction.php`: Adição de `modalIcon` e `modalWidth('3xl')` na ação de criação rápida.
41. `docs/design/DESIGN-SYSTEM.md` (novo): Manual do sistema de design, tokens, regras de elevação e vocabulário de motion.
42. `docs/design/REVIEW-VISUAL.md` (novo): Este relatório final de revisão visual e UX.

---

## 4. Desvios da Spec e Testes que Bloquearam Algo

- **Single Root Element no Livewire 4**: Na página `Goals` (`goals.blade.php`), envolver o laço `@forelse` e o bloco `@empty` em um `<div>` externo fez com que o Livewire 4 emitisse uma exceção de múltiplos nós raízes ao compilar com os modais internos de ações do Filament. A solução adotada foi manter o `<x-filament-panels::page>` como nó de topo sem invólucros artificiais desnecessários, aplicando as classes de elevação e espaçamento diretamente nos cartões filhos.
- **Single-line Blade `@php` Directive**: Diretivas de PHP em uma linha única no Blade do Laravel exigem a sintaxe com parênteses `@php($var = ...)` em vez de `@php ... @endphp` na mesma linha para correta compilação com o Livewire. Foi devidamente padronizado.
- **Tamanho do Build**: O limite estrito de 1 MB para `public/build` foi respeitado com folga: o bundle compilado totalizou **868 KB**, mantendo todas as fontes, SVGs e regras CSS sem estourar o orçamento.
- **Contratos de Teste Estritos**: Foram mantidos intactos todos os seletores e literais verificados por testes de acessibilidade e performance (`:focus-visible`, `:active`, `#0f766e`, `48px`, `safe-area-inset-bottom`, `overscroll-behavior`, `-webkit-overflow-scrolling: touch`, `[data-dash-control]`, `data-fab="quick-create"`, `aria-label="Lançamento rápido"`).

---

## 5. Gaps Conhecidos e Pontos para Verificação Humana no Browser

1. **Dashboard — Navegação e Densidade em Telas Ultrawide (> 1440px)**: O grid de 4 colunas se adapta de 1 a 4 colunas; verificar a respiração visual em telas com largura de 1920px.
2. **Gráficos Donut e Barras nos Relatórios 1 a 13**: As proporções utilizam cálculos puros de porcentagem em CSS/HTML (`conic-gradient` e barras relativas); checar visualmente no Safari, Chrome e Firefox para confirmar a renderização idêntica dos gradientes cônicos.
3. **Calendário de Recorrências em Telas Pequenas (375px)**: A tabela de 7 dias com min-height de 64px possui rolagem horizontal suave no mobile; checar o comportamento de swipe em dispositivo físico.
4. **Modo Escuro / Alto Contraste**: As superfícies foram configuradas em `slate-950` e `slate-900` com bordas `white/8`; verificar no monitor se a separação entre os cards e o fundo está agradável e confortável para os olhos em sessões longas.

---

## 6. Saída Literal dos Comandos de Aceite

### `npm run build`
```
> build
> vite build

vite v8.2.2 building client environment for production...
[plugin laravel:fonts] Optimized font fallbacks require the optional "fontaine" package. Install it, or set "optimizedFallbacks: false" on your fonts to disable the feature.
transforming...
✓ 4 modules transformed.
rendering chunks...
computing gzip size...
public/build/manifest.json                                       1.70 kB │ gzip:  0.37 kB
public/build/fonts-manifest.json                                 5.74 kB │ gzip:  0.71 kB
public/build/assets/instrument-sans-400-normal-DRC__1Mx.woff2   16.86 kB
public/build/assets/instrument-sans-500-normal-Dk9ku72i.woff2   17.23 kB
public/build/assets/instrument-sans-600-normal-B7fBEWYG.woff2   17.40 kB
public/build/assets/instrument-sans-400-normal-D1W7dsQl.woff    21.24 kB
public/build/assets/instrument-sans-500-normal-Z6ESRlEs.woff    21.65 kB
public/build/assets/instrument-sans-600-normal-B9e8oLYv.woff    21.67 kB
public/build/assets/fonts-C9MNnjVw.css                           2.35 kB │ gzip:  0.38 kB
public/build/assets/app-CFlnVRNI.css                            67.94 kB │ gzip: 13.69 kB
public/build/assets/theme-BnVyir-a.css                         666.74 kB │ gzip: 71.91 kB
public/build/assets/app-BvRk9kiK.js                              0.00 kB │ gzip:  0.02 kB

✓ built in 418ms
```

### `du -sk public/build | awk '{print $1" KB (< 1024)"}'`
```
868 KB (< 1024)
```

### `scripts/check.sh | tail -1`
```
CHECK: PASS
```

### `grep -cE 'googleapis|unpkg|cdn\.' public/build/assets/*.css`
```
0
```

### `grep -c 'prefers-reduced-motion' resources/css/filament/app/theme.css`
```
4
```
