# Pré-requisitos e preparação

## Verificar

Verifique apenas dependências usadas pela cadeia: PowerShell 5.1+, Rscript e pacotes, Excel/Outlook COM, Chrome, Node/módulos, VPN, rede, unidade mapeada/UNC, portas, scripts, modelos, bases e permissões. Registre apenas existência de perfil/credencial, sem exibir segredo.

Se testar escrita criando arquivo temporário, declare esse efeito e remova em `finally`.

## Preparar

O preparador deve ser PowerShell nativo e funcionar sem R no PATH.

- Descubra R no PATH, Program Files, Program Files (x86), LocalAppData e R_HOME.
- Se autorizado, instale em escopo de usuário e atualize PATH sem duplicar.
- Use biblioteca R de usuário quando a biblioteca do sistema não for gravável.
- Crie somente diretórios necessários.
- Não execute fluxo operacional nem altere script oficial.
- Separe `CORRIGIDO`, `JÁ ESTAVA PRONTO` e `AINDA PRECISA DE USUÁRIO/TI`.
- Declare efeitos: software instalado, PATH alterado, arquivos oficiais alterados e fluxo operacional executado.

Teste com R ausente, R fora do PATH, dry-run, módulos Node específicos, caminho com acento e rede.
