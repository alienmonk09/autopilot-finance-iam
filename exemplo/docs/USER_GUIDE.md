# Guia do usuário — finance-iam

Tudo abaixo existe de verdade no painel (`/app`). Valores em R$; o app guarda
tudo em centavos inteiros. Telas em português, com dark mode (claro/escuro/sistema
em `/app/settings`) e mobile funcional (botão flutuante **+** para lançar em
poucos toques).

## Primeiros passos

1. Suba o app (`docker compose up --build -d`, acesse `http://localhost:8000`).
2. Para explorar com dados prontos: `docker compose exec app php artisan
   db:seed --class=DemoSeeder` e entre em `/app/login` com
   `demo@example.com` / `demo1234`. Vêm 12 meses de lançamentos (Salário de
   R$ 8.500,00, Aluguel de R$ 1.800,00, iFood, Uber, Conta de Luz,
   Supermercado, Netflix de R$ 59,90, reserva mensal de R$ 500,00 para a
   poupança), cartão Nubank com faturas, recorrência da Internet Claro
   (R$ 129,90) e um parcelamento de 10× de um sofá de R$ 3.499,00.
3. Conta nova? O wizard **Começar agora** (`/app/onboarding`) aparece sozinho:
   passo 1, crie a primeira conta (ex.: Conta Corrente Itaú, saldo inicial de
   R$ 2.500,00); passo 2, crie o primeiro cartão (opcional, pode pular);
   passo 3, escolha entre importar um extrato, fazer o primeiro lançamento ou
   ir ao dashboard. Dá para pular tudo e voltar depois pelo menu.

## Lançar despesa, receita e transferência

- Atalho global: botão **+** na topbar (ou FAB no mobile) abre o lançamento
  rápido de qualquer tela.
- Tela cheia: **Transações** (`/app/transactions`) → Novo, abas **Despesa**,
  **Receita**, **Transferência**, **Cartão**. Ex.: Despesa de R$ 45,90 no iFood
  (categoria Delivery), conta Conta Corrente Itaú, data de hoje.
- **Transferência** é uma linha só com origem + destino: ex. R$ 500,00 da
  corrente para a poupança. Não conta como despesa nem receita; aparece no
  extrato das duas contas.
- **Status**: `pendente` (agendado — entra só no saldo previsto), `pago`
  (efetivado — entra no saldo atual), `conciliado` (conferido com o extrato —
  precisa "desconciliar" para editar valor/data).
- **Dividir (split)**: uma compra de R$ 350,00 no mercado pode virar R$ 250,00
  em Supermercado + R$ 100,00 em Limpeza; a soma tem que bater com o total.
- **Anexo**: dá para subir o comprovante (foto/PDF) no lançamento.
- O campo **favorecido** autocompleta e sugere a categoria usada da última vez
  (iFood → Delivery). Dá para gerenciar e juntar duplicados em **Favorecidos**
  (`/app/payees`).
- Filtros da listagem: período (hoje, semana, mês, mês anterior, ano,
  personalizado), conta, cartão, categoria, etiqueta, favorecido, tipo, status,
  faixa de valor e texto — com totais (receita, despesa, resultado) no rodapé.
  Ações em massa: categorizar, etiquetar, marcar como pago, excluir, mover de
  conta. Navegação por mês (‹ Setembro ›) como nos apps BR.

## Compra no cartão, faturas e pagamento

- Aba **Cartão** no lançamento (`/app/transactions/create`): ex. R$ 1.200,00
  em Eletrônicos nas Casas Bahia. A tela mostra um preview: "cai na fatura de
  Out/2026, vence 05/11".
- **Cartões** (`/app/credit-cards`): cada cartão mostra limite, usado,
  disponível, comprometido em parcelas futuras, fatura atual e o melhor dia de
  compra (o dia após o fechamento). Abrindo o cartão (`/app/credit-cards/{id}`)
  você navega por fatura (‹ Set/2026 ›), vê os lançamentos, o subtotal por
  categoria e os parcelamentos ativos.
- **Pagar fatura**: botão na página da fatura — total ou parcial, escolhendo a
  conta de origem e a data. Parcial deixa o restante como "Saldo anterior da
  fatura" na próxima; se pagar a mais, vira crédito. Pagar fatura não é
  despesa nos relatórios (a despesa foi a compra).
- Fatura fechada não recebe lançamentos novos (compra atrasada vai para a
  próxima, com aviso); dá para forçar "nesta fatura" quando precisar, e
  reabrir uma fatura paga.
- **Estorno/crédito na fatura**: para registrar um reembolso do emissor, lance uma compra no cartão com valor negativo (ex.: `-271,42` ou `R$ -271,42`). Ele reduz o total da fatura e o gasto da categoria nos relatórios, aparece na fatura com `+ R$ 271,42` em verde e rótulo “Estorno no cartão”, e não afeta o saldo da conta. Importar fatura com linha negativa também cria o estorno automaticamente.

## Parcelamentos

- No lançamento, toggle **Parcelar**: ex. sofá de R$ 3.499,00 em 10× — a 1ª
  parcela absorve a diferença de centavos e cada parcela cai na fatura do seu
  mês. Funciona no cartão e no débito/boleto (conta).
- **Parcelamentos** (`/app/installment-groups`): progresso (3/12), restante,
  próximo vencimento; detalhe com todas as parcelas e ações de **antecipar**
  (com desconto opcional), **editar futuras** e **encerrar**. Excluir remove só
  as parcelas pendentes, salvo confirmação de "excluir tudo".

## Recorrências e pendentes

- No lançamento, toggle **Repetir** ou direto em **Recorrências**
  (`/app/recurrences`): ex. Conta de Luz todo dia 12 (valor varia),
  Aluguel dia 10, Salário dia 5. Frequências: diária, semanal, quinzenal,
  mensal, bimestral, trimestral, semestral, anual.
- **Confirmação**: se a recorrência não confirma sozinha, a ocorrência nasce
  pendente e aparece em **Pendentes de confirmação**
  (`/app/pending-recurrences`) — confirme com o valor real (ex. luz veio
  R$ 189,37 em vez de R$ 180,00), pule ou adie. O **Calendário**
  (`/app/recurrence-calendar`) mostra tudo no mês.
- Editar uma regra oferece: só esta ocorrência, esta e futuras, ou todas
  (lançamentos já efetivados nunca mudam; ocorrência editada à mão não é
  sobrescrita). Pausar remove só as pendentes futuras.

## Orçamentos e metas

- **Orçamentos** (`/app/budgets`): por categoria no mês — orçado, gasto,
  restante, barra de progresso. Ex.: Delivery R$ 400,00; gastou R$ 320,00 =
  80% (alerta). Dá para copiar o mês anterior ou sugerir pela média dos
  últimos 3 meses; gráfico orçado × gasto em 12 meses. Sobra/estouro pode
  carregar para o mês seguinte (rollover). O gasto segue a base configurada
  (data do lançamento ou competência) em `/app/settings`.
- **Metas** (`/app/goals`): ex. Reserva de emergência R$ 10.000,00 até
  dezembro — cards com progresso, aporte sugerido/mês e aporte rápido (que
  pode gerar a transferência para a conta vinculada). Conta tipo
  **investimento** (`/app/accounts`): aportes/resgates como transferências e
  atualização manual do saldo (sem cotação online).

## Relatórios e exports

- **Relatórios** (`/app/reports`): 13 no total — despesas/receitas por
  categoria, receita × despesa por mês, fluxo de caixa, evolução do patrimônio,
  gastos por cartão/fatura, por favorecido (top 20), por etiqueta, orçado ×
  realizado, comparativo ano a ano, fixas × variáveis, projeção de saldo 90
  dias e tendência por categoria. Todos com filtro de período, gráficos,
  drill-down (categoria → subcategoria → lançamentos) e exportação **CSV** e
  **PDF**.
- **Backup** (`/app/backup`): exportar qualquer entidade em CSV, baixar backup
  JSON completo, baixar o SQLite e **restaurar** um backup JSON (atenção: a
  restauração substitui todos os seus dados).

## Importação CSV/OFX + regras

- **Importar** (`/app/import`): wizard em 4 passos — upload (CSV de bancos BR
  como Nubank, Itaú, Inter e XP, ou OFX) → mapeamento de colunas (o app detecta
  delimitador e encoding, e salva o mapeamento por banco para reuso) → preview com
  duplicadas marcadas → confirmar. Reimportar o mesmo arquivo não duplica
  (dedupe por data+valor+descrição normalizada).
- **Fatura de cartão de crédito**: ao importar para um cartão, você pode escolher a
  **Fatura de destino** (etapa 1). Por padrão, a opção é *Automática* (aloca cada
  compra na fatura correspondente à sua data); ao escolher uma fatura específica
  (ex.: `2026-06`), **todas** as compras do arquivo caem nela, mesmo que tenham
  datas antigas. Faturas já pagas aparecem desabilitadas e marcadas como `(paga)`.
- **Parcelas**: arquivos com coluna de parcela (como `4 de 5` ou `4/5`, reconhecida
  automaticamente no preset XP ou mapeada na etapa 2) têm o sufixo ` (n/N)` anexado
  à descrição — garantindo que parcelas de mesmo valor tenham hashes distintos — e
  preenchem `installment_number` e `installment_total` no lançamento criado.
- **Linhas de pagamento de fatura**: em extratos de cartão, linhas com valor negativo
  e descrições de pagamento (ex.: "Pagamento recebido", "Pagamento de fatura",
  "Débito automático") são identificadas e marcadas como **Ignoradas** com motivo
  explicativo na prévia, nunca virando compra no cartão. O pagamento da fatura
  deve ser registrado pela tela do cartão ou lançamento manual.
- **Regras** (`/app/rules`): automação tipo "se descrição contém iFood, define
  categoria Delivery e adiciona etiqueta delivery". Builder de condições e
  ações com prioridade; roda sozinha ao criar/importar, e dá para **testar
  contra lançamentos existentes (preview)** antes de aplicar retroativamente.

## Contas, cartões, categorias e configurações

- **Contas** (`/app/accounts`): cards com saldo e saldo previsto; extrato com
  saldo acumulado linha a linha; ações **Reconciliar** (informa o saldo do
  extrato, o app mostra a diferença e oferece criar o ajuste) e **Ajustar
  saldo**; arquivar em vez de excluir quando há lançamentos. **Bancos**
  (`/app/banks`), **Categorias** (`/app/categories`, árvore com subcategorias
  e flag "fixa" para o relatório fixas × variáveis), **Etiquetas**
  (`/app/tags`).
- **Configurações** (`/app/settings`): perfil, senha, 2FA, preferências (moeda,
  dia de fechamento do mês, base do orçamento, widgets do dashboard, dias de
  aviso) e exclusão da conta (apaga tudo).
- O sino no topo mostra as notificações: fatura fechando/vencendo/vencida,
  recorrência aguardando confirmação, orçamento em 80%/100%, meta concluída,
  importação finalizada.

## API

- REST `/api/v1` com tokens Sanctum: `POST /api/v1/tokens` (e-mail + senha →
  token; limite de 10 tentativas/min), depois `Authorization: Bearer <token>`
  em `accounts`, `credit-cards`, `invoices` (+ `POST /invoices/{id}/pay`),
  `categories`, `tags`, `payees`, `transactions` (com os filtros da tela 4.2),
  `recurrences`, `installments`, `budgets`, `goals` (+ contribuições) e
  `reports/summary|by-category|cash-flow`. Valores em centavos
  (`amount_cents`) + `amount_formatted` ("R$ 1.234,56"). Documentação OpenAPI
  gerada automaticamente.
