# Gate condicional para operações financeiras

Carregue este arquivo somente quando o fluxo envolver pagamentos, remessas, CNAB, PIX, boletos, importações, anexos ou efeitos financeiros equivalentes.

- Identifique cada execução por `run_id`, horário, origem e escopo; não some remessas silenciosamente.
- Explique cardinalidades diferentes, como uma tarefa que gera vários pagamentos.
- Diferencie estados como gerado, importado, enviado, pago, anexado e verificado somente quando existirem no processo.
- Mostre exceções com identificador, valor quando necessário, motivo e próxima ação segura.
- Uma ação externa confirmada ou incerta bloqueia repetição até reconciliação.
- Ramos paralelos precisam de perfis, portas, locks, contadores e verificação final independentes.
- Retomada não pode repetir importação, CNAB, RPA, pagamento, envio ou anexo já confirmado.
- Testes usam fixtures isoladas; não execute efeito financeiro real para homologar interface.

Registre apenas os critérios aplicáveis em uma matriz `critério -> evidência`. Marque os demais como `NÃO APLICÁVEL`, não como falha.
