# QA e publicação

## Gate técnico

- Inventário, efeitos e manifesto SHA-256 concluídos quando houver arquivos/efeitos sob escopo.
- Parse PowerShell; parse de R somente quando houver R no fluxo e Rscript disponível. Caso R seja usado e Rscript não esteja disponível, registre `NOT_CHECKED`.
- Configuração e contrato JSON válidos quando utilizados.
- Fixtures de sucesso, atenção, erro e bloqueio aplicáveis ao contrato.
- Resultado antigo rejeitado e métricas coerentes quando o fluxo produzir resultado persistente.
- Lock, concorrência, tentativa única e duplicidade testados quando houver risco de execução concorrente ou efeito externo.
- Limpeza recuperável, encoding e pré-requisitos testados quando essas capacidades existirem.
- Progresso testado em 0%, intermediário, 100%, pendência e erro quando houver etapas observáveis.

`scripts/validate_app.ps1` cobre somente estrutura e padrões estáticos. Mesmo quando retorna `STATIC_OK`, mantém `release_gate_passed=false`; conclua manualmente os gates aplicáveis desta referência antes de liberar. Use `$financial-app-qa` somente quando o fluxo for financeiro e a skill estiver disponível.

## Janela real

- Abra pelo launcher oficial e confirme uma janela sem console indesejado.
- Teste maximizada e 960x680.
- Inspecione pronto, execução, sucesso, atenção, erro e bloqueio.
- Navegue por Operação, Manual/FAQ e Código/parâmetros.
- Valide rolagem, foco, teclado, redimensionamento, textos e sobreposição.
- Clique somente em ações seguras ou fixtures isoladas.
- Capture evidências nomeadas por estado e resolução.

## Liberação

Compare hashes antes/depois e diferencie scripts preservados, camada alterada e artefatos de QA. Não chame fixture de homologação operacional. A primeira execução real de banco, e-mail, RPA, importação ou agendamento exige observação e confirmação de negócio.
