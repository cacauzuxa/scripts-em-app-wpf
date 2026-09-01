# Revisão de ponta a ponta

Faça esta revisão depois de criação ampla, reparo visual relevante ou antes de homologar. Atue como uma pessoa que nunca viu os scripts. Use fixtures ou dry-run para evitar efeitos externos.

1. Abra pelo launcher oficial e confirme nome, objetivo, logo e estado inicial.
2. Percorra somente as ações reais do fluxo, na ordem operacional.
3. Observe progresso, duração, resultado, exceções e próxima ação durante a execução.
4. Simule os estados aplicáveis: sucesso, pendência, erro, bloqueio e interrupção.
5. Reabra o app e verifique resultado antigo, lock e repetição quando esses riscos existirem.
6. Consulte ajuda, parâmetros, artefatos e Auditoria como operador e mantenedor.
7. Repita com teclado, janela maximizada e tamanho mínimo `960x680`.
8. Aplique [core-quality-gate.md](core-quality-gate.md).
9. Se houver operação financeira, aplique também [finance-operations-gate.md](finance-operations-gate.md).

Registre `PASSOU`, `FALHOU`, `NÃO TESTADO` ou `NÃO APLICÁVEL`, com evidência curta. Não repita a implementação durante a revisão e não transforme inspeção estática em QA visual ou homologação operacional.
