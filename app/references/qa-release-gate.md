# QA e publicação

## Gate técnico

- Inventário, efeitos e manifesto SHA-256 concluídos.
- Parse PowerShell e R.
- Configuração e contrato JSON válidos.
- Fixtures de sucesso, atenção, erro e bloqueio.
- Resultado antigo rejeitado; métricas coerentes.
- Lock, concorrência, tentativa única e duplicidade testados.
- Limpeza recuperável, encoding e pré-requisitos testados.
- Progresso testado em 0%, intermediário, 100%, pendência e erro.

`scripts/validate_app.ps1` cobre somente estrutura e padrões estáticos. Mesmo quando retorna `STATIC_OK`, mantém `release_gate_passed=false`; conclua manualmente todos os gates desta referência e `$financial-app-qa` antes de liberar.

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
