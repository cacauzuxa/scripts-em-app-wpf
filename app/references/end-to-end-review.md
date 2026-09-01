# Revisão crítica de ponta a ponta

Esta revisão é obrigatória depois da implementação e antes de declarar o aplicativo pronto. Atue como uma pessoa que nunca viu os scripts e precisa concluir o trabalho diário com segurança.

Antes de começar, invoque `$cacau` conforme a entrada de dependência da skill e aplique integralmente [complaints-prevention-gate.md](complaints-prevention-gate.md). Registre `PASSOU`, `FALHOU` ou `NÃO TESTADO` por cenário; não transforme cenário não executado em homologação.

## Simulação do usuário

1. Abra o aplicativo pelo launcher oficial.
2. Confirme que nome, logo, subtítulo e objetivo deixam claro qual processo será realizado.
3. Use `Verificar pré-requisitos` e, em fixture isolada, `Preparar pré-requisitos`.
4. Preencha ou altere parâmetros como um usuário comum.
5. Percorra cada ação na ordem operacional usando dry-run, preview ou fixtures.
6. Observe progresso, tempo decorrido, estimativa, contagens e mensagens durante a execução.
7. Valide sucesso, atenção, erro e bloqueio.
8. Confirme se a próxima ação sugerida é realmente segura e lógica.
9. Simule interrupção, reabertura do aplicativo, resultado antigo, lock ativo e tentativa de repetição.
10. Consulte Manual/FAQ, Código/parâmetros, histórico, artefatos e Auditoria.
11. Repita em janela maximizada e em 960x680, usando mouse e teclado.
12. Para qualquer ação `Limpar`, confira preview dos itens, exclusões, confirmação, backup, manifesto, colisões de nome e restauração em fixture isolada.

## Cenários reais do gate

Execute em fixtures isoladas e sem efeitos financeiros externos:

1. **Resultado fresco e remessas do dia**: deixe um log/envelope de ontem e uma remessa anterior do mesmo dia; inicie uma nova remessa e confirme que somente o `run_id` atual aparece, com as duas remessas identificadas separadamente.
2. **Cardinalidade financeira**: use uma tarefa com dois pagamentos, solicitações que viram lançamentos, PIX U, boletos B, retirados e anexos; confirme números coerentes e a explicação `1 tarefa -> N pagamentos`.
3. **Exceção prioritária**: force uma falha com tarefa, localizador, valor, favorecido, motivo e próxima ação; confirme que a exceção aparece antes do resumo e que a mensagem técnica fica em Auditoria.
4. **Mensagem e cor**: simule erro curto com causa, ação e link de log; simule sucesso sem pendências e encerramento; confirme ausência de duplicação, vermelho em sucesso e amarelo de próximo passo após o fim.
5. **Progresso vivo**: abra em pronto, execute um andamento intermediário e falhe após uma etapa confirmada; confirme que 0% não significa execução, que o percentual não volta/avança falsamente, e que tempo decorrido e ETA atualizam.
6. **Paralelismo e botão combinado**: execute os dois ramos em perfis/portas isolados; confirme contadores independentes, que ambos iniciaram sem reabrir abas e que somente o Verify final torna cada ramo verde.
7. **Interrupção e retomada**: cancele no meio, reabra e continue a partir da etapa confirmada; confirme lock liberado, ausência de `INICIADO` preso e ausência de repetição de importação, CNAB ou RPA.
8. **Pré-requisitos sem R no PATH**: remova R do `PATH`, rode Verificar e depois Preparar em fixture; confirme que Preparar não depende de R e não inicia o fluxo operacional.
9. **Interface e linguagem**: inspecione monitor principal maximizado e `960x680`; confirme ausência de clipping, abas cruas, console inútil, mojibake e espaço vazio sem propósito; leia FAQ como leigo e Código/parâmetros como mantenedor.
10. **Limpeza e recuperação**: mantenha um arquivo aberto, um bloqueio e um lançamento problemático; confirme aviso, preview, backup, hash, preservação do original e regeneração/reimportação somente com registro explícito.
11. **Estados e artefatos**: simule gerado, importado, enviado, pago, anexado e verificado; confirme que cada estado é distinto e que os botões seguros abrem artefato, log ou app subsequente quando aplicável.

## Perguntas críticas

- Um usuário leigo sabe onde começar e o que acontecerá ao clicar?
- A tela distingue tarefas, lançamentos, pagamentos, anexos, sucessos e exceções?
- Os estados `gerado`, `importado`, `enviado`, `pago`, `anexado` e `verificado` são distintos e apoiados por evidência?
- Diferenças de cardinalidade são explicadas, como uma tarefa com dois pagamentos?
- O que não foi processado aparece primeiro, com item, motivo e próxima ação?
- Existe mensagem contraditória, duplicada, técnica demais ou sem utilidade?
- Alguma cor indica erro quando tudo deu certo, ou sucesso antes da confirmação?
- A barra avança por evidência real e atualiza durante a ação?
- O aplicativo retoma o estado correto ao fechar e abrir?
- Há risco de repetir importação, remessa, e-mail, anexo, pagamento ou limpeza?
- O fluxo está fluido ou exige abrir logs e planilhas para entender uma decisão básica?
- O manual permite que outra pessoa opere e que um mantenedor localize o código certo?
- Existe botão visível que não funciona, função ausente ou espaço que deveria exibir informação útil?
- A limpeza mostra exatamente o que será movido, o que será preservado e como restaurar?
- Uma remessa antiga, uma segunda remessa no mesmo dia ou um resultado com 1 tarefa e N pagamentos pode ser identificado sem ambiguidade?
- Cancelar libera o lock e a reabertura evita repetir importação, CNAB e RPA?
- O botão combinado iniciou os dois ramos em perfis/portas isolados e cada ramo passou por Verify?
- Preparar pré-requisitos funciona sem R no `PATH` e permanece separado de Verificar?
- O usuário encontra ações seguras para abrir artefatos, logs e o app subsequente?

## Evidência

- Capture pronto, execução, sucesso, atenção, erro e bloqueio.
- Registre resolução e estado de negócio em cada captura.
- Relacione cada problema com arquivo/controle e correção proposta.
- Para cada item do gate, registre `PASSOU`, `FALHOU` ou `NÃO TESTADO` e a evidência correspondente.
- Corrija achados de segurança, contradição e bloqueio antes de publicar.
- Não use captura de fixture como prova de homologação externa.

## Resultado da revisão

Entregue três blocos:

1. **Funcionou bem**: passos claros e evidência observada.
2. **Foi corrigido**: problema, impacto e validação após correção.
3. **Ainda exige homologação real**: ações externas não executadas e como confirmá-las.
