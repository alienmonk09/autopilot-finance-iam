# barryvdh/laravel-dompdf 3 — resumo (doc oficial consultada em 2026-09-03)

- `composer require barryvdh/laravel-dompdf` (traz `dompdf/dompdf`); funciona sem publicar config.
- `Pdf::loadHTML($html)->setPaper('a4')->output()` devolve o PDF binário (começa com `%PDF`); `->download('a.pdf')` baixa direto.
- Template: `<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>`; CSS inline com `font-family: DejaVu Sans, sans-serif` (fonte embarcada que cobre acentos PT-BR).
- Sem remoto por padrão (`isRemoteEnabled: false`): nada de CDN, imagens externas ou fontes web no HTML do PDF.
- Fonte: https://github.com/barryvdh/laravel-dompdf
