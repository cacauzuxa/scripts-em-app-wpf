# Formulário de entrada

Use este formulário quando a invocação não trouxer contexto suficiente. Preencha automaticamente o que puder confirmar nos arquivos e pergunte somente o restante em uma única mensagem.

```text
NOME DO APLICATIVO:

PASTA DE DESTINO:
Exemplo: C:\Fluxos\Nome-do-fluxo

SCRIPTS E ARQUIVOS RELACIONADOS:
- Caminho:
- Função no processo:
- É oficial/protegido ou pode ser alterado?

COMO O PROCESSO FUNCIONA HOJE:
1.
2.
3.

FUNÇÕES QUE O APLICATIVO PRECISA TER:
-

ENTRADAS:
-

SAÍDAS E RESULTADOS ESPERADOS:
-

AÇÕES EXTERNAS OU DE RISCO:
Exemplos: serviço externo, e-mail, upload, importação, RPA, limpeza.

AUTORIZAÇÃO ATUAL:
- Ação autorizada:
- Ambiente autorizado (QA/homologação/produção):
- Quem autorizou:
- Válida somente para esta execução ou também para implementação/testes futuros?
- Ações que continuam proibidas:

COMO SABER QUE DEU CERTO:
-

COMO TRATAR PENDÊNCIA, ERRO E REPETIÇÃO:
-

PARÂMETROS QUE O USUÁRIO PODERÁ ALTERAR:
-

OBSERVAÇÕES:
-
```

## Regras de uso

- Não obrigue o usuário a repetir informações já presentes na conversa ou verificáveis nos caminhos.
- Se os scripts relacionados estiverem em uma pasta acessível, mapeie chamadas internas e apresente a cadeia encontrada para confirmação.
- Se houver mais de um caminho possível com efeitos diferentes, pause para confirmar antes de editar.
- O nome, pasta e funções desejadas não substituem o mapeamento técnico.
- Antes de implementar, apresente um resumo curto: o que será envolvido pelo app, o que permanecerá protegido, o que será adicionado e quais ações externas continuarão bloqueadas durante QA.
- Se a pasta informada já contém os scripts, crie a camada em `Aplicativo/` dentro dela e mantenha o launcher amigável na raiz somente quando solicitado. Não misture infraestrutura do app com entradas, saídas e scripts oficiais.
