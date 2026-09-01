# Status, segurança e logs

## Estados

- `SUCESSO`: critérios obrigatórios confirmados.
- `OK_COM_PENDENCIAS`: terminou, mas há itens que exigem decisão ou ficaram fora.
- `ERRO`: falhou e não há confirmação suficiente para avançar.
- `BLOQUEADO`: não deve começar ou repetir até resolver pré-condição ou reconciliar efeito externo.

Cada exceção traz item, origem, motivo simples e próxima ação.

## Segurança

- Um clique, uma tentativa; sem retry automático.
- Desabilite ações incompatíveis enquanto executa.
- Registre `run_id`, data, ação, parâmetros não secretos, hash de entrada e artefatos.
- Não reutilize resultado antigo.
- Bloqueie duplicidade pela chave de negócio apropriada.
- Em resultado externo incerto, reconcilie antes de repetir.
- Limpeza cria backup recuperável e respeita confirmações externas.

Para `Limpar` ou `Recomeçar`, exija:

- escopo e exclusões explícitos;
- preview antes da mutação;
- confirmação do usuário;
- backup com timestamp e tratamento de colisão;
- manifesto com origem, destino, tamanho e SHA-256;
- instrução e teste de restauração;
- bloqueio quando houver efeito externo confirmado ou incerto.

## Logs e encoding

- Log operacional: etapas, contagens, resultado, pendências, motivo e próxima ação.
- Log técnico: stdout/stderr integral, comandos sanitizados, stack e caminhos.
- Interface mostra marcos operacionais; técnico fica em `Auditoria` recolhível.
- Mensagem amigável remove `CategoryInfo` e `FullyQualifiedErrorId`, preservando original no arquivo.
- Novos JSON/logs usam UTF-8. Repare OEM850/Windows-1252 somente quando sinais de mojibake diminuírem sem introduzir `�`.
