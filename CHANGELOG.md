# Changelog

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
