# Scripts em APP WPF

Skill pública para transformar automações Windows existentes em aplicativos WPF portáteis, preservando a regra de negócio e tornando o fluxo observável.

O nome público é **Scripts em APP WPF**. O identificador técnico da skill é `app`.

`$app` funciona de forma independente. Se o usuário também invocar `$cacau`, a implementação pode ser delegada conforme as regras dela; a skill não instala dependências nem abre agentes sem esse pedido explícito.

## O que a skill orienta

- mapear o inventário transitivo antes de editar: chamadas, entradas, saídas, modelos, históricos, dependências e efeitos;
- manter scripts oficiais, modelos e bases protegidos, registrando hashes SHA-256 quando aplicável;
- separar interface WPF, worker, parser de resultado e rodadores oficiais;
- trabalhar com resultado estruturado `wpf.app.result.v1` e inventário seguro `wpf.flow.inventory.v2`;
- iniciar a janela com tema, ícone e logo já conectados pelo `AppShell.xaml`;
- diferenciar `SUCESSO`, `OK_COM_PENDENCIAS`, `ERRO` e `BLOQUEADO`;
- fazer uma tentativa por clique, com lock, idempotência, reconciliação e bloqueio de repetição quando o efeito externo for incerto;
- verificar e preparar pré-requisitos em ações separadas;
- fazer QA em janela real, com teclado, redimensionamento, foco, textos, estados e artefatos observáveis.

A skill não reescreve automaticamente a regra de negócio, não promete velocidade ou economia e não autoriza pagamento, envio, upload, importação, RPA, e-mail ou limpeza real. Essas ações dependem de autorização específica e evidência suficiente.

## Instalação

No Codex, instale a pasta da skill com:

```text
$skill-installer Instale a skill pública Scripts em APP WPF: https://github.com/cacauzuxa/scripts-em-app-wpf/tree/main/app
```

Depois, invoque-a pelo identificador técnico:

```text
$app Mapeie este fluxo Windows e proponha a menor camada WPF necessária, sem executar ações externas.
```

## Estrutura

```text
app/                      # skill distribuível; identificador técnico app
  SKILL.md
  agents/openai.yaml
  references/              # contratos, arquitetura, segurança, portabilidade e QA
  scripts/                 # inventário e validação estática
  assets/                  # shell, tema WPF, PNG e ICO fornecidos pelo autor
docs/                      # landing page, sitemap, robots e infográfico
scripts/build_infographic.py
```

## Limites e evidência

`ExitCode=0`, arquivo criado, processo encerrado ou barra em 100% não confirmam, sozinhos, o resultado de negócio. O painel deve mostrar a classificação do resultado, contagens, exceções, próxima ação e trilha de auditoria. Quando a cadeia transitiva, a autorização ou a confirmação externa não puder ser observada, a entrega permanece pendente ou `BLOQUEADO`.

## Licença

MIT. Consulte [LICENSE](LICENSE). Consulte também [CHANGELOG](CHANGELOG.md) para a versão pública atual.
