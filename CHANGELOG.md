# Changelog

## [1.2.0] - 2026-09-01

- Launcher C# compatível com o compilador do Windows PowerShell 5.1/.NET Framework, com tratamento amigável de falha de inicialização e código de saída não zero.
- Novo Build-Launcher.ps1 turnkey: recebe AppScript/AppTitle/MutexName, substitui placeholders com escaping seguro em fonte temporária, compila com ICO e limpa a fonte.
- Inventário amplia a cadeia para JS/VBS/manifestos, mantém dependências mesmo com marcadores de segredo e redige valores/caminhos por padrão.
- Validador passa a reconhecer entrypoints reais, compilar C# quando possível, marcar R ausente como NOT_CHECKED, ignorar comentários nas ligações XML e detectar variantes de client_secret sem expor valores.
- AppShell.xaml ganha progresso visível, rolagem independente, tamanho mínimo 960x680, inicialização maximizada e teste real de BaseUri/ativos no Windows PowerShell 5.1.
- Encoding UTF-8 foi explicitado nos PS1 públicos e nos recursos XAML, com regressões para evitar mojibake.
- Gates de R, limpeza, paralelismo, ETA, financeiro e financial-app-qa ficam explicitamente condicionais; launcher na raiz só é usado quando solicitado.

## [1.1.0] - 2026-09-01

- `$app` passa a funcionar de forma independente; `$cacau` é usada somente quando o usuário a invoca explicitamente.
- Novo `AppShell.xaml` com tema, ICO e PNG já conectados.
- Gate universal reduzido e controles financeiros movidos para referência condicional.
- Inventário v2 redige caminhos absolutos por padrão e registra falhas de leitura.
- Validador v2 troca busca extensa de palavras por parsing determinístico e heurísticas identificadas como tal.
- Entrada principal reduzida de 754 para 524 palavras.

## [1.0.0] - 2026-09-01

- Publicação inicial da skill `app`, com nome público Scripts em APP WPF.
- Contratos neutros `wpf.app.result.v1` e `wpf.flow.inventory.v1`.
- Referências públicas para inventário transitivo, arquitetura WPF, segurança, portabilidade e QA em janela real.
- Landing page acessível, infográfico A4 de duas páginas e fonte editável em Python/ReportLab.
