# Gate de prevenção de reclamações

Este gate é obrigatório em **Criar**, **Revisar/Reparar**, **Homologar/Publicar** e na revisão E2E. Cada item precisa de evidência observável em fixture, log, JSON, captura ou teste nomeado. Uma frase genérica como “parece correto” não satisfaz o gate. Sem evidência, o resultado é `BLOQUEADO` ou “homologação pendente”, conforme o item.

## Resultado e contagens

- [ ] O resultado do dia contém `run_id`, data/hora e origem atuais; o painel rejeita log, envelope ou artefato de execução anterior e mostra o motivo.
- [ ] O mesmo `run_id` amarra resultado, log e artefatos. Uma segunda remessa no mesmo dia aparece como execução separada, nunca como soma silenciosa.
- [ ] O resumo informa números de tarefas, solicitações, lançamentos, pagamentos, PIX U, boletos B, retirados e anexos. Cada métrica tem fonte e regra de contagem.
- [ ] A cardinalidade é reconciliada: quando uma tarefa gera N pagamentos, a tela mostra `1 tarefa -> N pagamentos` e explica a diferença; não apresenta contagens incompatíveis como se fossem iguais.
- [ ] Os estados diferenciam, sem inferência visual, `gerado`, `importado`, `enviado`, `pago`, `anexado` e `verificado`.

## Exceções, mensagens e cores

- [ ] Se houver exceções, elas aparecem antes do resumo secundário e trazem tarefa, localizador, valor, favorecido, motivo e próxima ação.
- [ ] Mensagens técnicas ficam somente em `Auditoria` recolhível. O erro visível é curto, útil, informa causa e ação e oferece o log quando necessário.
- [ ] Não há texto duplicado entre cards, resumo, erro e próxima ação; verifique por captura e por uma busca de strings repetidas.
- [ ] As cores são semânticas: sucesso confirmado não fica vermelho, estado sem pendência não fica amarelo e “próximo passo” não permanece amarelo depois do fim.

## Progresso e tempo

- [ ] `0%` é “não iniciado”, nunca “em execução”. O percentual sobe por etapa confirmada, atualiza ao vivo e preserva o último percentual confirmado quando ocorre erro.
- [ ] Tempo decorrido e ETA são atualizados ao vivo; a ETA informa uma base real, como pelo menos três conclusões, quando houver estimativa.
- [ ] Ramos paralelos mostram contadores e etapas independentes. Só ficam verdes depois de `Verify`/verificação final de cada ramo.
- [ ] Cancelar ou interromper grava estado terminal ou interrompido e libera o lock; nunca deixa `INICIADO` bloqueando a próxima execução.

## Ações combinadas, retomada e duplicidade

- [ ] O botão combinado inicia de fato os dois ramos, com perfis, portas e locks isolados; a captura/log prova ambos. Não reabre abas já disponíveis sem necessidade.
- [ ] Reabrir o app retoma somente estado confirmado e permite continuar de uma etapa posterior sem repetir importação, CNAB ou RPA.
- [ ] Uma ação externa incerta bloqueia a repetição até reconciliação. Ações externas ficam separadas da preparação e exigem confirmação consciente.
- [ ] Múltiplas remessas do dia têm identificador, escopo, resultado e artefatos próprios.

## Pré-requisitos e interface

- [ ] Existem ações separadas `Verificar pré-requisitos` e `Preparar pré-requisitos`. Preparar funciona com R ausente do `PATH`, sem executar o fluxo financeiro.
- [ ] A janela abre maximizada no monitor principal, respeita `960x680` e não apresenta clipping, abas cruas, controles ambíguos ou espaço vazio que deveria conter resultado útil.
- [ ] Manual/FAQ explica o uso para leigo; Código/parâmetros atende manutenção sem despejar console técnico na operação.
- [ ] O texto é UTF-8 e não há mojibake visível; logs técnicos preservam a evidência original.
- [ ] O launcher e a UI não exibem console inútil. Há botões para abrir artefatos, logs e o aplicativo subsequente quando essa ação for relevante e segura.

## Limpeza, exclusão e regeneração

- [ ] Limpeza apresenta preview, informa arquivo aberto/bloqueio, cria backup recuperável e registra origem, destino e hash; não apaga silenciosamente.
- [ ] É possível excluir um lançamento problemático e regenerar/reimportar sem ele somente após registrar explicitamente a exclusão, preservando o original e vinculando o novo `run_id`.
- [ ] O gate testa colisão de nomes, restauração e bloqueio por efeito externo confirmado ou incerto.

## Matriz de evidência mínima

| Área | Evidência mínima | Bloqueio |
|---|---|---|
| Resultado | JSON/envelope fresco + log do mesmo `run_id` | Resultado antigo aceito ou origem ausente |
| Métricas | Fixture com cardinalidade diferente e reconciliação visível | Tarefas/pagamentos ou U/B sem explicação |
| Exceções | Captura com todos os seis campos antes do resumo | Exceção escondida ou sem próxima ação |
| Mensagens | Captura de erro + Auditoria com log técnico | Stack/`CategoryInfo` na operação ou erro inútil |
| Progresso | Capturas de pronto, andamento, Verify, sucesso e erro | 0% em execução, progresso falso ou erro em 100% |
| Paralelismo | Dois perfis/portas, contadores separados e Verify | Um ramo mascara o outro ou fica verde antes de Verify |
| Retomada | Fixture reaberta com etapa confirmada | Reimporta CNAB/RPA ou perde o estado |
| Interface | Capturas maximizada e `960x680` | Clipping, console ou aba não utilizável |
| Limpeza | Preview, backup, manifesto/hash e restauração | Arquivo aberto sem aviso ou original perdido |

O relatório final deve apontar cada item como `PASSOU`, `FALHOU` ou `NÃO TESTADO`, com arquivo/captura/log correspondente. `NÃO TESTADO` não pode ser apresentado como homologação.
