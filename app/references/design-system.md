# Design técnico-editorial WPF

Este padrão é o ponto de partida dos aplicativos criados pela skill, salvo identidade oficial diferente fornecida pelo usuário.

## Identidade

- Janela maximizada; `MinWidth=960`, `MinHeight=680`.
- Fundo geral `#F3F4F7`; texto `#102A43`.
- Corpo `Segoe UI`; títulos `Georgia`.
- Cabeçalho em gradiente `#0E2D58` -> `#153F78` -> `#1D4D8D`, com ciano para dados e âmbar somente para próxima ação.
- Ícone abstrato em cartão claro 78x78 com raio 18.
- Eyebrow `APP INTERFACE`, título claro e subtítulo azul-claro.
- Status geral no canto superior direito com título, detalhe e progresso.

Copie `assets/icone.png`, `assets/icone.ico` e `assets/app-template/BrandTheme.xaml` para `Aplicativo/Assets`; copie `assets/app-template/AppShell.xaml` para `Aplicativo/AppShell.xaml`. Use o shell como base da janela ou replique explicitamente suas ligações de tema, ícone e logo. Consulte `assets/ASSET_PROVENANCE.md`. Só substitua os ativos quando o responsável fornecer outra identidade oficial para o fluxo.

## Ligação obrigatória dos ativos

- Mescle `Assets/BrandTheme.xaml` nos recursos da janela.
- Defina `Icon="Assets/icone.ico"` no `Window` e use o mesmo ICO ao compilar o launcher.
- Exiba `Assets/icone.png` no cabeçalho; carregue com `BitmapCacheOption.OnLoad` quando a interface PowerShell construir a imagem em código.
- Resolva caminhos a partir de `$PSScriptRoot` ou do diretório do aplicativo, nunca da pasta da skill.
- Verifique em janela real se PNG, ICO, gradiente, fontes e cores semânticas aparecem; presença dos arquivos não é evidência de uso.

## Cores semânticas

| Estado | Fundo | Destaque |
|---|---|---|
| Pronto/atual | azul-claro | azul institucional |
| Sucesso confirmado | `#E8F3ED` | `#28734A` |
| Atenção | `#FFF8DE` | `#6B4E00` |
| Erro/bloqueio crítico | `#FDEBE7` | `#9A3E34` |

Não use vermelho para `0 pendências` ou estado não executado. Não use verde antes da verificação final.

## Layout

- Cabeçalho e navegação no topo.
- Coluna esquerda próxima de 330 px para ações, parâmetros, pré-requisitos e recuperação.
- Área principal para resultado, etapas, próxima ação, métricas e exceções.
- Rolagem independente quando necessário.
- Rodapé com portabilidade, tentativa única e estado atual.

Abas usuais: `Operação`, `Acompanhar tarefas` quando útil, `Manual e FAQ`, `Código e parâmetros`.

Hierarquia: resultado; exceções acionáveis; próxima ação segura; métricas; etapas/progresso; Auditoria recolhível. Evite console técnico aberto, cartões duplicados, contradições e espaço vazio que poderia mostrar informação útil.

## Progresso

- `0%` significa não iniciado.
- Use etapas confirmadas, não apenas relógio.
- Erro conserva último percentual confirmado e não vira 100%.
- ETA usa mediana de ao menos três conclusões e informa a fonte.
- Ramos paralelos mostram contadores independentes.
- Diferencie `anexado` de `verificado`.
