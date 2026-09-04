Review #1


# Review da fase 3 — Cartões de crédito e faturas

Escopo auditado: tasks 3.1 a 3.5 do `docs/ROADMAP.md` contra o aceite da fase e as regras da seção 3 do SPEC tocadas pela fase (3.2, 3.3, 3.4, 3.5, 3.6, 3.14, 3.15 + SPEC 2.3/2.4/2.8/4.4 como seções da fase). Tasks `[!]`/`[-]` na fase: nenhuma.

## Resultado do check

Saída literal de `scripts/check.sh` (rodado pelo reviewer em 2026-09-03):

```
{"tool":"pint","result":"passed"}{"tool":"phpstan","result":"passed","errors":0}
{"tool":"pest","result":"passed","tests":449,"passed":449,"assertions":1798,"duration_ms":9124}
CHECK: PASS
```

## Aceite da fase (item → OK/FALHA + evidência)

1. **Testes de alocação em fatura com meses de 28/29/30/31 dias e closing_day 1, 15, 28, 31 → OK.** `tests/Unit/Domain/Cards/InvoiceAllocatorTest.php:54-87` — dataset com fev/2026 (28d), fev/2024 (29d), abr/2026 (30d), jan/2026 (31d) × `closing_day` 1/15/28/31, incluindo clamp (`C=31` em fev→28/29, em abr→30). Bordas dia-do-fechamento × flag `purchases_on_closing_day_go_next` em `InvoiceAllocatorTest.php:89-113`. Implementação: `app/Domain/Cards/InvoiceAllocator.php:36-86`.
2. **Pagamento total/parcial/excedente → OK.** Total: `tests/Feature/Cards/PayInvoiceTest.php:56-85` (status `paid`, `total_cents` intacto, lançamento `credit_card_payment` com categoria de sistema). Parcial: `PayInvoiceTest.php:87-118` (`partially_paid` + linha sintética "Saldo anterior da fatura" na próxima fatura, `total_cents=4000`). Segunda parcial sem duplicar + quitação apagando a linha: `PayInvoiceTest.php:120-156`. Excedente virando crédito (`paid_cents`) na próxima fatura: `PayInvoiceTest.php:158-179`. Implementação: `app/Domain/Cards/PayInvoice.php:50-187`.
3. **Limite disponível correto → OK.** `tests/Feature/Cards/CreditCardLimitServiceTest.php:40-63` (desconta `open`+`closed`+`partially_paid`+`overdue` como `total−pago`, ignora `paid`: usado 48000, disponível 952000), isolamento por cartão em `:65-80`, crédito de excedente em `:82-91`, e liberação do limite após pagamento integral em `PayInvoiceTest.php:235-245`. Implementação: `app/Domain/Cards/CreditCardLimitService.php:32-80`.
4. **Job de fechamento idempotente → OK.** `tests/Feature/Cards/CloseInvoicesTest.php:118-132` (2ª execução: `closed=0 overdue=0`, sem novas faturas), duplo `invoices:close` via artisan em `:134-153`, agendamento diário (`0 0 * * *`) em `:155-163`. Scheduler registrado em `bootstrap/app.php:16-18`; comando em `app/Console/Commands/CloseInvoicesCommand.php:16-27`; serviço em `app/Domain/Cards/CloseInvoices.php:43-84`.

Itens de escopo 3.4/3.5 (UI) verificados com teste: cards com limite/uso/melhor dia (`tests/Feature/Filament/CreditCardResourceTest.php:62-78`), navegação mensal de fatura (`:139-165`), pagar total/parcial pela UI (`:167-211`), reabrir (`:236-250`), forçar lançamento em fatura fechada + aviso de desvio (`:268-314`), aba Cartão com preview "Cai na fatura de Set/2026, vence 05/10" / "Out/2026, vence 05/11" (`tests/Feature/Filament/CardPurchaseFormTest.php:35-65` e `:196-209`, domínio em `tests/Unit/Domain/Cards/InvoicePreviewTest.php:26-48`), schema/migrations 3.1 (`tests/Feature/Cards/CreditCardInvoiceSchemaTest.php:71-155`).

## Regras da seção 3 tocadas (regra → OK/FALHA + teste)

- **3.2 Alocação compra→fatura → OK.** `InvoiceAllocatorTest.php:34-52` (antes/depois do fechamento, flag do dia do fechamento) + dataset 28/29/30/31 dias (`:54-113`); lazy-create via `InvoiceService::forPurchase` em `tests/Feature/Cards/InvoiceServiceTest.php:33-78`. Código: `InvoiceAllocator.php:36-86`, `InvoiceService.php:43-50`.
- **3.3 Vencimento → OK.** Mesmo-mês vs mês-seguinte vs `due_in_next_month` em `InvoiceAllocatorTest.php:115-130`; clamp de `due_day` 31 em mês curto em `:132-139` — este caso (`2026-02-28`, um sábado) prova também o "NÃO ajustar fim de semana". Código: `InvoiceAllocator.php:71-79`.
- **3.4 Limite disponível → OK.** `CreditCardLimitServiceTest.php:30-91` (ver item 3 do aceite). `futureInstallments()=0` até a fase 4 é suposição registrada em `docs/QUESTIONS.md [3.2c]`, com campo já exposto à UI (`CreditCardLimit`) — não é lacuna do aceite. Código: `CreditCardLimitService.php:32-80`.
- **3.5 Pagamento de fatura → OK.** `PayInvoiceTest.php:56-265` (total, parcial, parcial-dupla, quitação, excedente, rejeições, conta de outro usuário, pagamento fora de despesa via `TransactionTotals` em `:207-223`, categorias de sistema sem duplicar em `:225-233`, desvio pulando fatura fechada em `:247-265`). Excedente como `paid_cents` (e não "linha negativa", impossível com `amount_cents` positivo) é suposição registrada em `docs/QUESTIONS.md [3.2c]`. Código: `PayInvoice.php:50-187`.
- **3.6 Fechamento / fatura fechada / override → OK.** Job: `CloseInvoicesTest.php:49-132` (fecha `open`, vence `closed`, `paid`/`partially_paid` nunca vencem, `open` duplamente vencida → `overdue` direto, idempotência). Desvio para próxima aberta + `force=true`: `InvoiceServiceTest.php:135-202`; UI com aviso e forçado: `CreditCardResourceTest.php:268-314`; form unificado: `CardPurchaseFormTest.php:84-107`. Código: `CloseInvoices.php:43-84`, `InvoiceService.php:58-190`.
- **3.14 Datas/timezone (DATE puro, America/Sao_Paulo) → OK.** `InvoiceAllocatorTest.php:179-187` (hora 00:00:00, tz `America/Sao_Paulo`, `CarbonImmutable`); `normalizeDate` rejeita overflow/`DD/MM/YYYY` (`:168-177`). Código: `InvoiceAllocator.php:101-133`.
- **3.15 Dinheiro (nunca float) → OK.** `PayInvoiceTest.php:181-192` rejeita `0`, negativo e `1.5` (float); UI converte via `Money::parse`/`MoneyInputRule` (`ViewCreditCard.php:498-510`, `CreditCardResource.php:160-173`); sem `(float)`/`floatval` em `app/Domain/Cards` (grep vazio).

## Sinais de contorno encontrados

Nenhum. Verificação sistemática:

- **Teste `skip`**: nenhum em `tests/` (grep por `skip(`/`markTestSkipped` vazio; 449 testes, 449 passando, 0 pulados).
- **Asserção trivial**: os 46 `toBeTrue()` nos testes da fase são predicados reais (relações `->is()`, `Gate::allows/denies`, `Schema::hasTable`, `exists()`, `is_ignored_in_reports`) — nenhum `expect(true)`.
- **Produção citando mock/teste**: grep em `app/` por `mock|Mock|fake(` vazio.
- **Float em dinheiro**: grep em `app/Domain/Cards` por conversões float vazio; fronteira `PayInvoice::pay` exige `is_int` (`PayInvoice.php:57-59`).
- **Lógica de negócio em Resource/Controller/Livewire**: Resources/Pages só orquestram o domínio (`CreditCardLimitService`, `InvoiceService`, `PayInvoice`, `Create/Update/DeleteTransaction`, `InvoicePreview`); `TransactionResource::cardInvoicePreview` e `notifyIfDiverted` delegam a `InvoicePreview` (`TransactionResource.php:409-473`); criação/edição vinculam fatura **dentro** de `CreateTransaction`/`UpdateTransaction` (`CreateTransaction.php:143-177`, `UpdateTransaction.php:122-253`). Observações sem peso de FALHA: `ViewCreditCard::subtotalsByCategory` (`ViewCreditCard.php:216-247`) faz agregação presentacional por categoria (nenhuma regra da seção 3 a governa; totais persistem via `recalculateTotals`) e `CreditCardResource::bestPurchaseDay` (`CreditCardResource.php:96-99`) é derivação de 1 linha da SPEC 4.4, coberta por teste (`CreditCardResourceTest.php:62-78`).
- **`TODO` sem entrada no ROADMAP**: grep em `app/` por `TODO|FIXME|XXX|HACK` vazio.
- **Suposições**: todas registradas em `docs/QUESTIONS.md` ([3.1], [3.2a], [3.2b], [3.2c]×3, [3.3], [3.5]) — nenhuma decisão silenciosa.

## Gaps e tasks corretivas sugeridas (formato `- [ ] N.Fx descrição (aceite: ...)`)

Nenhum gap — todos os itens do aceite têm teste e implementação correspondentes, `scripts/check.sh` verde, sem tasks `[!]`/`[-]` na fase. Sem tasks corretivas.

Veredito: APROVADA
