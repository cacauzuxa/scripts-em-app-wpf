# Gate essencial de qualidade

Use este gate em criação ampla, revisão, reparo relevante e homologação. Para uma mudança pequena, aplique somente os itens afetados. Registre `PASSOU`, `FALHOU` ou `NÃO TESTADO`; ausência de evidência nunca vira homologação.

| Critério | Evidência suficiente | Bloqueio |
|---|---|---|
| Resultado fresco | resultado e log ligados à execução atual | artefato antigo aceito como atual |
| Estados | fixture ou teste para sucesso, atenção, erro e bloqueio aplicáveis | cor ou mensagem contradiz o estado |
| Erro acionável | causa curta, próxima ação e acesso ao log técnico | stack técnico exposto sem orientação |
| Repetição | uma tentativa por clique e guarda proporcional ao efeito | retry automático ou duplicidade possível |
| Interrupção | estado terminal/interrompido e lock liberado | execução fica presa como iniciada |
| Interface | captura real no tamanho mínimo e maximizada | clipping, controle ambíguo ou conteúdo inacessível |
| Acessibilidade básica | teclado, foco visível, ordem lógica e nomes compreensíveis | ação essencial depende somente de mouse ou cor |
| Portabilidade | caminhos relativos/configuráveis e pré-requisitos claros | usuário, Downloads ou `.codex` fixos no app |
| Segurança | diff/config/log sem segredo ou dado desnecessário | credencial ou conteúdo sensível exposto |
| Recuperação | preview e backup quando houver limpeza | exclusão silenciosa ou irrecuperável |

Não exija recursos inexistentes no fluxo. Paralelismo, ETA, retomada, limpeza, múltiplas execuções e instalação de pré-requisitos só entram no gate quando fazem parte do contrato real.
