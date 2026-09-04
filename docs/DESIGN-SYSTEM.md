# Finance IAM — Design System

Guia de referência do sistema visual do Finance IAM (Laravel 13 + Filament 5 + Livewire 4 + Tailwind v4).
Direção: **Fintech séria e calma** — extrato de banco refinado, denso nas tabelas, respirando nos cards.

---

## 1. Tokens de Superfície & Cores

### Superfícies
| Superfície | Claro (Light) | Escuro (Dark) |
|---|---|---|
| Fundo (`body`) | `slate-50` (`#f8fafc`) | `slate-950` (`#020617`) |
| Cards / Painéis | `white` (`#ffffff`) | `slate-900` (`#0f172a`) |
| Bordas | `slate-200/70` (`rgba(226, 232, 240, 0.7)`) | `white/8` (`rgba(255, 255, 255, 0.08)`) |

### Semântica de Cores (Fixa)
Acentos semânticos são **fixos** e nunca transmitem informação por cor isolada (sempre acompanhados de texto ou ícone):
- **Entrada**: Emerald (`#10b981` / `text-emerald-600` / `dark:text-emerald-400`, `+` ou seta para cima `↑`)
- **Saída**: Rose (`#f43f5e` / `text-rose-600` / `dark:text-rose-400`, `−` ou seta para baixo `↓`)
- **Transferência**: Sky (`#0284c7` / `text-sky-600` / `dark:text-sky-400`, ícone `⇄`)
- **Pendente**: Amber (`#d97706` / `text-amber-600` / `dark:text-amber-400`, relógio/alerta)
- **Conciliado / Primário da Marca**: Teal (`#0f766e` / `text-teal-700` / `dark:text-teal-400`, checkmark)

---

## 2. Elevação & Sombras

| Nível | Token | Claro | Escuro | Uso |
|---|---|---|---|---|
| **Nível 1** | `--shadow-1` | `0 1px 2px rgb(15 23 42 / 0.06)` | `0 1px 2px rgb(0 0 0 / 0.3)` | Linhas de lista, tabelas, topbar ao rolar |
| **Nível 2** | `--shadow-2` | `0 1px 3px rgb(15 23 42 / .06), 0 8px 24px -12px rgb(15 23 42 / .12)` | `0 1px 3px rgb(0 0 0 / .4), 0 8px 24px -12px rgb(0 0 0 / .5)` | Cards do dashboard, painéis de widgets |
| **Nível 3** | `--shadow-3` | `0 10px 25px -5px rgb(15 23 42 / .15), 0 8px 10px -6px rgb(15 23 42 / .1)` | `0 10px 25px -5px rgb(0 0 0 / .6), 0 8px 10px -6px rgb(0 0 0 / .5)` | Modais, popovers, FAB mobile, hover de cards |

*Regra de elevação*: O hover em card sobe **exatamente um nível** (`--shadow-2` → `--shadow-3`). No dark mode, a hierarquia é prioritariamente dada por contraste de borda (`white/8` → `white/16`) e fundo.

---

## 3. Raios de Borda (Radius)

- **Cards**: `--radius-card: 14px` (`rounded-[14px]`)
- **Controles & Inputs**: `--radius-control: 10px` (`rounded-[10px]`)
- **Chips & Badges**: `--radius-chip: 9999px` (`rounded-full`)

---

## 4. Tipografia & Escala Numérica

- **Fonte de Interface**: `Inter Variable` autohospedada pelo Filament, com `font-feature-settings: 'cv11', 'ss01'`.
- **Fonte Secundária / Externa**: `Instrument Sans` baixada no build via Vite (`bunny()`).
- **Valores Monetários & Dados**: sempre com `font-variant-numeric: tabular-nums` (via utilitário `money` ou `tabular-nums`) para alinhamento uniforme de dígitos.
- **Escala**:
  - **KPI**: 30px / 36px line-height (`1.875rem / 2.25rem`), semibold, `letter-spacing: -0.02em`.
  - **Título de Card / Seção**: 14px (`0.875rem`), semibold, `slate-700` (dark `slate-200`).
  - **Eyebrow / Rótulo de Cabeçalho**: 11px (`0.6875rem`), uppercase, semibold, `tracking-wide`, `slate-500` (dark `slate-400`).
  - **Corpo**: 14px (`0.875rem`), regular/medium.
  - **Meta / Secundário**: 12px (`0.75rem`), regular. *Nenhum texto deve ficar abaixo de 12px*.

---

## 5. Vocabulário de Motion

Todas as animações são estritamente condicionadas a `@media (prefers-reduced-motion: no-preference)`. Com `prefers-reduced-motion: reduce`, todas as transições assumem estado final imediato (`transform: none`, `opacity: 1`, `animation: none`).

- **Durações**:
  - `--dur-fast: 150ms`: micro-interações de foco, hover e active.
  - `--dur-base: 220ms`: expansão, dropdowns, segmented controls.
  - `--dur-slow: 420ms`: revelação e entrada de página/cards.
- **Curvas de Transição**:
  - `--ease-out: cubic-bezier(0.2, 0.8, 0.2, 1)`: desaceleração padrão suave.
  - `--ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1)`: micro-feedback elástico sutil (somente press/active).
- **Stagger**:
  - Utilizado em sequências de cards e listas: `animation-delay: calc(var(--i, 0) * 45ms)`, onde `--i` é o índice do loop (máximo 8 itens escalonados).

---

## 6. Utilitários CSS (`@utility`)

Classes reutilizáveis compiladas em `theme.css` e `app.css`:

1. `card-elev`: Aplica fundo branco/slate-900, raio de 14px, borda sutil, sombra nível 2 e transição suave para sombra nível 3 no hover.
2. `kpi`: Tipografia 30px semibold com `tabular-nums` e tracking `-0.02em`.
3. `eyebrow`: Rótulo de 11px uppercase tracking-wide para identificadores superiores de cards e seções.
4. `money`: Força `tabular-nums` e tracking `-0.01em` para alinhamento tabular perfeito de moedas formatadas pelo `Money::format()`.
5. `card-title`: Título semibold 14px com cores contrastadas em claro e escuro.
6. `reveal`: Animação de entrada suave com fade + `translateY(6px → 0)` em `--dur-slow`, respeitando `--i` para escalonamento (stagger).
