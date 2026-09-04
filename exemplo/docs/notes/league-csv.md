# league/csv 9 — resumo (doc oficial consultada em 2026-09-03)

- `Writer::createFromString('')` cria CSV em memória; `insertOne(array)` / `insertAll(iterable)` gravam.
- `setDelimiter(';')` troca o delimitador; `setOutputBOM(Bom::Utf8)` prefixa o BOM UTF-8 (`\xEF\xBB\xBF`).
- `toString()` / `getContent()` devolvem o CSV como string.
- `fputcsv` põe aspas em campos com espaço/delimitador/quebra de linha (ex.: `"Saldo acumulado"`) — válido para Excel BR com `;`.
- Round-trip: `Reader::createFromString($s)->setDelimiter(';')->fetchOne(0)` relê a linha.
- Fonte: https://csv.thephpleague.com/9.0/writer/
