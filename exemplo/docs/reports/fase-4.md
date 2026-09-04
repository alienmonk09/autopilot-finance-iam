Review #1


# Review da fase 4 — Parcelamentos

Escopo auditado: tasks 4.1, 4.2a, 4.2b, 4.3, 4.4 (todas `[x]` no ROADMAP; nenhuma `[!]`/`[-]` na fase — nada a desconsiderar). Arquivo de review anterior inexistente (`docs/reports/fase-4.md` não encontrado via busca; verificação via `git log` indisponível nesta sessão read-only por restrição de ferramenta — sem arquivo prévio, adota-se `Review #1`). SPEC lida: 2.8, 2.11, 3 (foco 3.7; secundárias 3.2/3.3/3.4/3.6), 4.2, 4.4, 4.6, 6. QUESTIONS lido (suposições [4.1]–[4.4] respeitadas pelo código). BLOCKED vazio.

## Resultado do check

Executado `scripts/check.sh` pelo reviewer (resultado literal resumido):

- `pint`: passed
- `phpstan`: passed, errors 0
- `pest`: passed — 513 testes, 513 aprovados, 2129 asserções
- `CHECK: PASS`

## Aceite da fase (item → OK/FALHA + evidência)

Aceite da fase 4: "Σ parcelas == total sempre; cada parcela na fatura certa; antecipação move e recalcula; exclusão respeita regra 3.7".

### 1. Σ parcelas == total sempre → OK

- Teste `soma das parcelas é igual ao total com resto na primeira` — `tests/Feature/Installments/CreateInstallmentPlanTest.php:38` — cria 10000/3, espera `[3334, 3333, 3333]`, soma 10000, descrições `i/N`.
- Teste `resto de centavos de outra divisão também fica na primeira parcela` — `tests/Feature/Installments/CreateInstallmentPlanTest.php:63` — 10001/4 → `[2501, 2500, 2500, 2500]`.
- Teste `realoca o restante entre as futuras com resto na primeira e soma == total` — `tests/Feature/Installments/UpdateFutureInstallmentsTest.php:80` — restante 50001 em 2 futuras → `[30000, 25001, 25000]`, grupo 80001, soma confere; faturas recalculadas `[30000, 25001, 25000]`.
- Teste `desconto é rateado nas antecipadas com resto na primeira e reduz o total` — `tests/Feature/Installments/AnticipateInstallmentsTest.php:88` — antecipa [2,3] com desconto 5001 → `[30000, 27499, 27500]`, grupo 84999, fatura atual 84999.
- Teste `antecipação em conta com desconto…` — `tests/Feature/Installments/AccountInstallmentParityTest.php:84` — 10001/4 menos 101 → `[2501, 2500, 2449, 2450]`, soma 9900, grupo 9900.
- Implementação: `Money::allocate` (resto na 1ª) em `app/Domain/Installments/CreateInstallmentPlan.php:91`, `UpdateFutureInstallments.php:85-87`, `AnticipateInstallments.php:112-120`; invariante `total_cents = Σ parcelas` mantido em `AnticipateInstallments.php:151-152`, `UpdateFutureInstallments.php:126-135`, `CancelInstallmentPlan.php:103-105`. Rejeição de float em `CreateInstallmentPlan.php:200-203` e `UpdateFutureInstallments.php:198-200`.

### 2. Cada parcela na fatura certa → OK

- Teste `cada parcela no cartão cai na fatura certa pelo closing_day` — `tests/Feature/Installments/CreateInstallmentPlanTest.php:95` — 3× de 03/09 com closing_day 10 → refs `['2026-09', '2026-10', '2026-11']`, tipo `CreditCardExpense`, totais de fatura `[30000, 30000, 30000]`.
- Teste `parcela após o fechamento cai na fatura do mês seguinte` — `tests/Feature/Installments/CreateInstallmentPlanTest.php:127` — first 15/09 (após fechamento dia 10) → `['2026-10', '2026-11', '2026-12']`.
- Teste `parcela N cai no mês first_date + N-1` — `tests/Feature/Installments/CreateInstallmentPlanTest.php:79` — datas `2026-09-10, 2026-10-10, 2026-11-10`.
- Teste `dia 31 sofre clamp em fevereiro e volta ao dia cheio em março` — `tests/Feature/Installments/CreateInstallmentPlanTest.php:147` — `2026-01-31, 2026-02-28, 2026-03-31`.
- Teste `criar compra no cartão com Parcelar cai nas faturas certas (SPEC 3.2, 3.7)` — `tests/Feature/Filament/InstallmentToggleFormTest.php:172` — via form Filament, refs `['2026-09', '2026-10', '2026-11']`, soma 90000.
- Teste `preview do parcelamento no cartão mostra valores, datas e faturas` — `tests/Feature/Filament/InstallmentToggleFormTest.php:40` — preview `33,34/33,33/33,33` com faturas Set/Out/Nov 2026.
- Implementação: `app/Domain/Installments/CreateInstallmentPlan.php:113-120` (`InvoiceService::resolveForPurchase` por parcela, com avanço para próxima `open` se fechada — regra 3.6); datas mês a mês com clamp em `CreateInstallmentPlan.php:169-185`; preview com o mesmo algoritmo em `app/Domain/Installments/InstallmentPreview.php:33-70`.

### 3. Antecipação move e recalcula → OK

- Teste `antecipa parcelas do cartão para a fatura aberta atual mantendo valores` — `tests/Feature/Installments/AnticipateInstallmentsTest.php:63` — [2,3] → invoice da fatura atual, valores mantidos, totais `[90000, 0, 0]`.
- Teste `desconto é rateado…` — `tests/Feature/Installments/AnticipateInstallmentsTest.php:88` (citado acima).
- Teste `parcelamento em conta antecipa alterando a data para hoje` — `tests/Feature/Installments/AnticipateInstallmentsTest.php:105` — datas `['2026-09-10', '2026-10-10', '2026-09-03', '2026-09-03']`.
- Teste `sem fatura aberta resolve uma nova fatura via InvoiceService para hoje` — `tests/Feature/Installments/AnticipateInstallmentsTest.php:125` — destino `2026-09` `open`, total 60000.
- Teste `rejeita parcela cleared ou em fatura fechada` — `tests/Feature/Installments/AnticipateInstallmentsTest.php:172`.
- Teste `ação antecipar move parcelas para a fatura atual com desconto opcional` — `tests/Feature/Filament/InstallmentGroupResourceTest.php:93` — via UI com desconto `50,01` → `[30000, 27499, 27500]`, soma 84999.
- Teste `ação antecipar na tela move parcelas em conta para hoje` — `tests/Feature/Installments/AccountInstallmentParityTest.php:105`.
- Implementação: `app/Domain/Installments/AnticipateInstallments.php:44-159` (valida pendentes + fatura `open`, rateio do desconto, move invoice_id no cartão / data=hoje em conta, recalcula totais das faturas tocadas e do grupo).

### 4. Exclusão respeita regra 3.7 → OK

- Teste `default preserva parcela em fatura fechada e atualiza contagem e total` — `tests/Feature/Installments/CancelInstallmentPlanTest.php:52` — fecha fatura da 3ª, cancela: resta só nº 3 (30000), grupo count 1/total 30000, faturas `[0, 0, 30000]`.
- Teste `default preserva parcelas cleared e reconciled mesmo em fatura aberta` — `tests/Feature/Installments/CancelInstallmentPlanTest.php:82` — restam [1,2], total 60000.
- Teste `sem restantes o grupo é apagado` — `tests/Feature/Installments/CancelInstallmentPlanTest.php:101` — transações 0, grupo nulo, faturas zeradas.
- Teste `deleteAll apaga tudo incluindo cleared e fatura fechada mais o grupo` — `tests/Feature/Installments/CancelInstallmentPlanTest.php:118`.
- Teste `parcelamento em conta apaga as pendentes e o grupo` — `tests/Feature/Installments/CancelInstallmentPlanTest.php:138`.
- Teste `grupo de outro usuário lança exceção e nada é apagado` — `tests/Feature/Installments/CancelInstallmentPlanTest.php:155`.
- Testes de UI: `ação encerrar remove só pendentes em fatura aberta` — `tests/Feature/Filament/InstallmentGroupResourceTest.php:134`; `ação encerrar com excluir tudo…` — `tests/Feature/Filament/InstallmentGroupResourceTest.php:148`.
- Implementação: `app/Domain/Installments/CancelInstallmentPlan.php:35-106` (default = force delete só `pending` em fatura `open`/sem fatura; `deleteAll=true` = tudo + grupo; recalcula faturas; sem restantes apaga o grupo).

Itens complementares do aceite implícito (SPEC 2.11/4.6/4.2/4.4):

- Schema + origem cartão/conta → OK: `tests/Feature/Installments/InstallmentGroupSchemaTest.php:71-111` (colunas 2.11, FKs `CASCADE` em user / `SET NULL` demais, índice `installment_group_id`); migrações `database/migrations/2026_09_03_070001_create_installment_groups_table.php:20-36` e `2026_09_03_070002_add_installment_group_fk_to_transactions_table.php:16-18`.
- Resource com progresso/restante/próximo vencimento/origem + detalhe + 3 ações → OK: `tests/Feature/Filament/InstallmentGroupResourceTest.php:61-91`, implementação `app/Filament/App/Resources/InstallmentGroupResource.php:67-132` e `app/Filament/App/Resources/Pages/ViewInstallmentGroup.php:127-351` (só orquestram o domínio).
- Toggle "Parcelar" (Despesa/Cartão) com preview, criação via domínio, bloqueio de edição direta de valor/origem → OK: `tests/Feature/Filament/InstallmentToggleFormTest.php:91-266` (10 testes), `app/Filament/App/Resources/TransactionResource.php:484-560`.
- Parcelamento em conta (débito/boleto) com paridade → OK: `tests/Feature/Installments/AccountInstallmentParityTest.php` (6 testes) + `tests/Feature/Installments/CreateInstallmentPlanTest.php:163`.

## Regras da seção 3 tocadas (regra → OK/FALHA + teste)

- **3.7 Parcelamento (soma == total; arredondamento na 1ª; parcela N no mês 1+N−1; exclusão só pendentes/fatura aberta salvo confirmação)** → OK. Coberta por `CreateInstallmentPlanTest.php` (10 testes), `AnticipateInstallmentsTest.php` (6 testes), `UpdateFutureInstallmentsTest.php` (5 testes), `CancelInstallmentPlanTest.php` (6 testes).
- **3.2/3.3 Alocação em fatura e vencimento** → OK (reuso do `InvoiceAllocator`/`InvoiceService` da fase 3). Evidência: `CreateInstallmentPlanTest.php:95-145` (fatura certa + pós-fechamento), `InstallmentToggleFormTest.php:40-76` (preview com `reference_month` via `InstallmentPreview.php:53-56`), `InstallmentToggleFormTest.php:172-198` (refs via form). Vencimento em si permanece testado na fase 3; a fase 4 não o altera.
- **3.4 Limite disponível (descontar parcelas futuras não faturadas; exibir comprometido separado)** → OK. `CreditCardLimitService::futureInstallments()` implementado de verdade em `app/Domain/Cards/CreditCardLimitService.php:77-102` (pendentes `credit_card_expense` em fatura `open`, escopo por dono do cartão). Testes: `tests/Feature/Cards/CreditCardFutureInstallmentsTest.php:41-168` (4 testes: soma 90000; fechada/paga/parcial/vencida não contam; cleared/excluída sai; isolamento por cartão/usuário + conta ignorada) e `AccountInstallmentParityTest.php:60-82` (conta não afeta limite).
- **3.6 Fechamento de fatura (fechada não recebe novas; respeito a status)** → OK (respeito, sem reimplementar o job da fase 3). Evidência: `CancelInstallmentPlanTest.php:52-80` (fatura fechada preservada + totais recalculados), `AnticipateInstallmentsTest.php:172-184` (fatura fechada bloqueia antecipação), `CreateInstallmentPlan.php:113-120` (fatura fechada empurra para a próxima `open` via `resolveForPurchase`).
- **3.14 Datas (DATE puro) e 3.15 Dinheiro (nunca float)** → OK. `firstDate()` normaliza para `Y-m-d` sem hora (`CreateInstallmentPlan.php:238-250`, `InstallmentPreview.php:98-106`); `totalCents()`/`remaining()`/`discount()` rejeitam float (`CreateInstallmentPlan.php:200-223`, `UpdateFutureInstallments.php:197-212`, `AnticipateInstallments.php:205-212`); UI converte via `Money::parse` (`ViewInstallmentGroup.php:157`, `TransactionResource.php:523-560`).

## Sinais de contorno encontrados

Nenhum. Varredura em `app/Domain/Installments/`, `tests/Feature/Installments/`, `tests/Feature/Filament/Installment*`, `tests/Feature/Cards/CreditCardFutureInstallmentsTest.php` e `app/Filament/App/Resources/` (Installment* + TransactionResource + CreditCardResource):

- Sem `skip`/`markTestSkipped`/asserção trivial (`assertTrue(true)`, `expect(true)`) nos testes da fase.
- Sem `TODO`/`FIXME` sem entrada no ROADMAP no código da fase.
- Sem `mock`/`Mock` em código de produção da fase; ocorrências de "float"/"nunca float" são guards que **rejeitam** float (`is_float` → `InstallmentException`) e comentários — conformidade com a regra 3.15, não violação.
- Sem lógica de negócio em Resource/Page/Livewire: `InstallmentGroupResource` contém só projeções de leitura (`paidCount`, `progressText`, `remainingCents`, `nextDueLabel`, `originLabel`); `ViewInstallmentGroup` só orquestra `AnticipateInstallments`/`UpdateFutureInstallments`/`CancelInstallmentPlan`; `TransactionResource::toInstallmentPayload`/`installmentPreview` são tradução de form + preview via `InstallmentPreview` (domínio); a criação delega ao `CreateInstallmentPlan`.
- `DB::transaction` presente nas três mutações multi-tabela (`CreateInstallmentPlan.php:57`, `AnticipateInstallments.php:46`, `UpdateFutureInstallments.php:44`, `CancelInstallmentPlan.php:37`).
- Fixtures realistas em português (Notebook Dell, Geladeira Brastemp, Móveis planejados, Nubank Roxinho, NuConta), centavos inteiros.
- Observação (não é contorno): `TransactionResource::installmentPreview()` e projeções do `InstallmentGroupResource` duplicam formatação de apresentação — aceitável como camada de UI, sem regra de domínio duplicada (alocação/datas vivem no domínio).

## Gaps e tasks corretivas sugeridas

Nenhum gap encontrado. Todos os itens do aceite e todas as regras tocadas estão OK com teste + implementação. Nenhuma task corretiva `4.Fx` a criar. Tasks `[!]`/`[-]` na fase: nenhuma.

Veredito: APROVADA
