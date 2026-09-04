Review #1


# Review da fase 7 — Dashboard, Relatórios, Notificações

Aceite da fase (ROADMAP): "todos os 13 relatórios com testes de agregação em cenários controlados; widgets do dashboard com dados corretos; exportação CSV/PDF; notificações disparam pelo scheduler". Tasks `[!]`/`[-]` na fase: nenhuma (7.1a–7.5 todas `[x]`).

## Resultado do check

Saída literal de `scripts/check.sh` (rodado pelo reviewer):

```
{"tool":"pint","result":"passed"}{"tool":"phpstan","result":"passed","errors":0}
{"tool":"pest","result":"passed","tests":822,"passed":822,"assertions":3580,"duration_ms":17084}
CHECK: PASS
```

## Aceite da fase (item → OK/FALHA + evidência)

1. **Todos os 13 relatórios com testes de agregação em cenários controlados → OK**
   - Implementação: `app/Domain/Reports/ReportQuery.php` — relatórios 1–2 (`expensesByCategory:97`, `incomeByCategory:112`, núcleo `byCategory:952`), 3 (`monthlyIncomeVsExpense:126`), 4 (`cashFlow:180`), 5 (`netWorthByMonth:248`), 6 (`expensesByCard:348`), 7 (`expensesByPayee:407`), 8 (`expensesByTag:458`), 9 (`budgetedVsActual:507`), 10 (`yearOverYear:642`), 11 (`fixedVsVariable:718`), 12 (`balanceProjection:789`), 13 (`categoryTrend:854`). Agregação no SQL com nº fixo de queries (sem N+1), dinheiro em centavos int, sem `auth()` no Domain.
   - Testes (datasets fixos de factories, valores PT-BR em centavos):
     - Rel. 1–5: `tests/Feature/Reports/ReportQueryTest.php:51` (despesas c/ drill-down e splits), `:101` (receitas ignoram transferência/pagamento), `:118` (mensal c/ resultado), `:149` e `:171` (fluxo diário/mensal c/ saldo acumulado), `:182` (patrimônio ativos−passivos), `:204` (budget_basis competence), `:230` (nº de queries fixo, sem N+1).
     - Rel. 6–10: `tests/Feature/Reports/ReportQuerySixToTenTest.php:74` (cartão c/ pending e zero-fill), `:104` (payee, splits contam uma vez), `:138` (top 20), `:151` (tag dupla), `:187` (orçado×realizado c/ subcategorias/splits/global), `:276` (ano a ano 12 meses c/ zeros), `:307` (competence), `:345` (sem N+1).
     - Rel. 11–13: `tests/Feature/Reports/ReportQueryElevenToThirteenTest.php:78` (fixas×variáveis, splits herdam flag), `:149` (competence), `:167` (projeção 90 dias c/ pendentes + recorrências não materializadas), `:215` (materializada não duplica), `:254` (rel. 12 sempre coluna `date` caixa), `:272` (tendência 3 meses, média `intdiv`, ordem desc), `:306` (competence), `:332` (sem N+1).
2. **Páginas Filament dos 13 relatórios com filtros e drill-down + widgets do dashboard com dados corretos → OK**
   - Rel. 1–7: `app/Filament/App/Pages/Reports.php:305` (`painelDespesas` c/ `agruparPorTopo:669`), `:329`, `:355`, `:375`, `:395`, `:414`, `:447`; drill-down via `urlTransacoesCategoria:205`, `urlTransacoesPayee:210`, `urlTransacoesCartao:215`, `urlTransacoesTag:220`. Testes: `tests/Feature/Filament/ReportsPagesTest.php:84` (totais + drill-down subcategoria + link), `:105` (filtros alteram números), `:120`, `:134`, `:154`, `:169`, `:189`, `:212`, `:247` (período inválido vira mensagem amigável).
   - Rel. 8–13: `Reports.php:473` (`painelTags`), `:499`, `:529`, `:593`, `:615`, `:634`. Testes: `tests/Feature/Filament/ReportsPagesExtendedTest.php:63` (tags + link), `:97` (orçado×gasto×diferença), `:115` (12 linhas), `:129` (fixas×variáveis), `:144` (90 linhas dia a dia), `:154` (tendência c/ média), `:188` (entradas inválidas amigáveis).
   - Dashboard (SPEC 4.1): `app/Domain/Dashboard/DashboardData.php` (`totalBalance:69`, `monthSummary:100`, `forecastEndOfMonth:129`, `accountBalances:163`, `cardSummaries:201`, `upcoming:270`, `budgets:367`, `expensesByCategory:423`, `cashFlow12:439`, `goals:454`, `balanceProjection90:500`); layout em `app/Domain/Dashboard/DashboardLayout.php:48` (ordem/visibilidade em `user_settings.dashboard_widgets`); Page só orquestra em `app/Filament/App/Pages/Dashboard.php:132-219`. Testes: `tests/Feature/Dashboard/DashboardDataTest.php:53` (saldo+variação), `:67` (ignora conta fora do dashboard/outro usuário), `:85` (resumo+mês anterior), `:105` (previsto inclui pendentes, regra 3.1), `:119`, `:129` (fatura aberta, dias p/ fechar, limite), `:149` (vencimentos fatura+recorrência+parcela ordenados), `:183`, `:200` (reusa ReportQuery), `:218` (metas), `:237`; `tests/Feature/Filament/DashboardPageTest.php:56` (saldo/contas c/ `Money::fromCents` exato), `:70` (cartões+atalhos), `:88` (ocultar persiste), `:102` (reordenar persiste), `:124` (reset), `:131` (isolamento por usuário).
   - Ressalva não-bloqueante (sem FALHA, ver Gaps): as tasks 7.2a/7.2b citam "gráficos (Chart.js via widgets)" e a SPEC 4.9 fala em "gráficos"/"donut"; o implementado usa barras CSS puras + tabelas (`resources/views/filament/app/pages/reports.blade.php`, sem dependência Chart.js no código — grep por `Chart` retorna só nome de ícone). Os dados estão corretos e há visual por relatório, então o aceite ("dados corretos") é atendido; fica como melhoria opcional.
3. **Exportação CSV/PDF → OK**
   - Implementação: `app/Domain/Reports/ReportExport.php:44` (`build` 1–13), `:67` (`toCsv` league/csv, `;`, BOM UTF-8), `:89` (`toPdf` dompdf), `:99` (filename determinístico PT-BR); Page em `Reports.php:235` (`exportarCsv`) e `:261` (`exportarPdf`), só orquestrando o Domain.
   - Testes: `tests/Feature/Reports/ReportExportTest.php:53` (BOM, `;`, cabeçalho PT-BR, valor formatado), `:81` (isolamento por usuário), `:99` (os 13 geram cabeçalho + linha c/ dataset mínimo), `:195` (rel. 11 c/ Total, rel. 10 c/ 12 meses), `:208` (nomes determinísticos), `:228` (PDF começa com `%PDF`, título+cabeçalho), `:254` (relatório inválido → `ReportException`), `:261` (Livewire baixa CSV e PDF c/ filtros atuais).
4. **Notificações disparam pelo scheduler → OK**
   - Implementação: `app/Domain/Notifications/CheckNotifications.php:54` (`run`, idempotente via dedupe type+data em `notifications`, `DB::transaction`), `app/Jobs/SendNotificationsJob.php:30` (fila database, delega ao Domain), `app/Console/Commands/SendNotificationsCommand.php:16` (`notifications:send`), agendamento em `bootstrap/app.php:16-21` (`notifications:send` diário junto a `invoices:close`, `recurrences:generate`, `budgets:alert`).
   - Testes: `tests/Feature/Notifications/CheckNotificationsTest.php:72` (fecha na janela), `:87` (fora da janela não), `:94` (fechada não re-avisa fechamento), `:102` (vencimento), `:113` (overdue), `:124` (paga nunca), `:131` (due→overdue sem duplicar), `:149` (pendente vencida só), `:186` (meta uma vez), `:207` (incompleta/concluída fora), `:228` (2× sem duplicar), `:237` (preferência por usuário), `:246` (`via` = database+mail, PT-BR, `R$ 1.500,00`), `:328` (job+command idempotentes), `:349` (`schedule:list` contém `notifications:send` diário `0 0 * * *`); preferências e sino em `tests/Feature/Settings/NotificationPreferencesTest.php:27` (`hasDatabaseNotifications`), `:31` e `:39` (edição de `notify_bills_days_before`, `notify_invoice_closing_days_before`, `notify_budget_threshold`, `budget_basis`, `theme`).

## Regras da seção 3 tocadas (regra → OK/FALHA + teste)

- **Regra 3.1 (saldo / saldo previsto / projeção) → OK.** É a única regra da seção 3 com comportamento novo nesta fase (projeção 90 dias = relatório 12 + widget do dashboard + `forecastEndOfMonth`). Provas: `tests/Feature/Dashboard/DashboardDataTest.php:105` (previsto fim do mês = atual − pendente, `target_date` fim do mês), `tests/Feature/Reports/ReportQueryElevenToThirteenTest.php:167` (90 dias c/ pendentes + recorrências não materializadas, sem dupla contagem), `:215` (ocorrência materializada sai da projeção e entra pelo mapper), `:254` (coluna `date` caixa mesmo com `budget_basis` competence), `tests/Feature/Filament/DashboardProjectionTest.php:48` (dashboard == relatório 12, 90 dias, final 28000 = 100000+50000−12000−20000−3×30000, mínimo 28000 em 2026-11-15), `:87` (data inválida → `DashboardException`, que estende `InvalidArgumentException` — `DashboardException.php:7-14`).
- **Nenhuma outra regra nova da seção 3 nesta fase — declarado explicitamente.** Os relatórios apenas *reutilizam* convenções já testadas: 3.5/3.9 (transferência e pagamento de fatura fora de receita/despesa — `ReportQueryTest.php:101`, `:118`), 3.10 (splits — `ReportQueryTest.php:51`, `ReportQuerySixToTenTest.php:104`, `:187`, `ReportQueryElevenToThirteenTest.php:78`, `:272`), 3.12 (orçado×realizado com subcategorias — `ReportQuerySixToTenTest.php:187`, que delega à mesma conta do `BudgetCalculator`). Regras 3.2–3.8, 3.11, 3.13–3.15 não têm comportamento novo na fase 7.

## Sinais de contorno encontrados

- **Teste `skip`: nenhum.** O único `skip` no repo é chamada de domínio legítima (`ResolvePendingOccurrenceTest.php:133`, `$this->resolver->skip(...)`, fora da fase 7). Nenhum `test->skip`/`markTestSkipped` nos testes da fase 7.
- **Asserção trivial: nenhuma.** Asserções conferem valores calculados exatos (`Money::fromCents(...)`, contagens, datas, `toHaveCount(90)`, igualdade dashboard==relatório, `%PDF`, BOM), incluindo casos negativos (`assertDontSee`, fora-da-janela, inválidos amigáveis).
- **Código de produção citando mock/teste: nenhum.** Grep por `mock|Mock` em `app/Domain/Reports` retorna só comentários ("nunca float"); sem referências a teste em `ReportQuery.php`, `ReportExport.php`, `DashboardData.php`, `DashboardLayout.php`, `CheckNotifications.php`.
- **Float em dinheiro: nenhum.** Centavos int em todo o Domain (`intdiv` em médias/percentuais: `ReportQuery.php:927`, `DashboardData.php:91`, `:253`, `:398`); formatação só via `Money::fromCents()->format()` (`ReportExport.php:522-525`).
- **Lógica de negócio em Resource/Controller/Livewire: não.** `Reports.php` e `Dashboard.php` só orquestram o Domain (memos por request + agrupamento de apresentação `agruparPorTopo:669`, cuja única query extra é um lookup de nomes de categorias-pai — apresentação pura, documentada no docblock `:30-34`). Agregações e regras moram em `ReportQuery`, `ReportExport`, `DashboardData`, `DashboardLayout`, `CheckNotifications`.
- **`TODO` sem entrada no ROADMAP: nenhum.** Grep por `TODO|FIXME|XXX|HACK` em `app/` retorna vazio.
- **Suposições registradas:** `[7.1a]`, `[7.1b]`, `[7.1c]`, `[7.2c]`, `[7.3]`, `[7.4]` em `docs/QUESTIONS.md` (citadas nos docblocks), todas com comportamento correspondente nos testes.

## Gaps e tasks corretivas sugeridas (formato `- [ ] N.Fx descrição (aceite: ...)`)

Nenhum gap: zero FALHAs, zero tasks `[!]`/`[-]` na fase, `CHECK: PASS` com 822 testes. Nenhuma task corretiva `7.Fx` a criar. Observação opcional (não-bloqueante, sem corretiva): trocar as barras CSS por Chart.js/donut nos relatórios/Fluxo de caixa 12 meses aproximaria o texto das tasks 7.2a/7.2b ("Chart.js via widgets") e da SPEC 4.9 ("donut"); os dados e o aceite estão corretos como estão.

Veredito: APROVADA
