# Arquitetura

```text
Launcher EXE
  -> AppInterface.ps1 (WPF)
    -> Infraestrutura/Executar-Acao.ps1
      -> rodador oficial R/PowerShell
        -> resultado estruturado + log técnico
    -> Infraestrutura/Ler-Resultado.ps1
      -> estado visível + próxima ação segura
```

Estrutura recomendada:

```text
Aplicativo/
|-- AppInterface.ps1
|-- AppShell.xaml
|-- AppInterface.Launcher.cs
|-- App Interface Nome.exe
|-- config.json
|-- Assets/BrandTheme.xaml, icone.png e icone.ico
|-- Infraestrutura/
|-- Dados/execucoes, locks e historico_execucoes.csv
|-- Logs/
|-- Capturas/QA/
|-- Testes/
`-- Documentacao/
```

Quando o usuário disser “na mesma pasta”, interprete por padrão como: raiz do fluxo preservada, componentes internos em `Aplicativo/` e apenas o launcher final na raiz. Confirme antes se ele realmente quiser todos os arquivos lado a lado.

- **Launcher**: C# `[STAThread]`, caminho relativo, PowerShell oculto, nenhuma regra financeira.
- **Interface**: renderiza estado e coleta confirmação; não interpreta log bruto nem implementa negócio.
- **Worker**: cria `run_id`, lock e log; executa uma tentativa; lê resultado fresco; grava envelope final.
- **Rodador oficial**: continua como fonte da lógica operacional.
- **Parser**: converte resultado em estado, métricas, exceções e próxima ação.
- **Configuração**: guarda somente parâmetros variáveis, nunca segredo em texto comum.

## Concorrência e portabilidade

- Mutex limita janela local; lock em pasta compartilhada ou coordenação central limita outros computadores.
- Ramos paralelos precisam de perfis, portas, locks e progresso independentes.
- Atualize WPF por `DispatcherTimer`, runspace ou processo filho; não bloqueie a thread visual.
- Resolva caminhos por `$PSScriptRoot`; evite usuário fixo, `Downloads`, `%TEMP%` e `.codex` como caminhos oficiais.
- Carregue PNG com `BitmapCacheOption.OnLoad`; use ICO na janela e launcher.

## Recursos iniciais da skill

- Copie `assets/app-template/BrandTheme.xaml` e `AppShell.xaml` para iniciar a janela com tema, ícone e logo conectados.
- Ao carregar `AppShell.xaml` por `XamlReader` no PowerShell, defina `ParserContext.BaseUri` para a raiz de `Aplicativo/`; isso resolve `Assets/BrandTheme.xaml`, `icone.ico` e `icone.png` sem depender do diretório atual.
- Adapte `assets/app-template/Launcher.cs`, substituindo `__APP_SCRIPT__`, `__APP_TITLE__` e `__MUTEX_NAME__`.
- Copie os ícones aprovados de `assets/`.
- Esses arquivos são camada de apresentação e inicialização; não copie regras de negócio de outro fluxo.
- Audite a política de execução do launcher. O template usa `RemoteSigned`; só altere para `Bypass` quando houver necessidade comprovada, autorização e registro da justificativa.
