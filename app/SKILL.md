---
name: app
description: Mapear, criar, revisar, reparar e homologar aplicativos WPF portáteis que envolvem fluxos R/Rscript, PowerShell, Excel, Outlook, navegador ou rede, preservando scripts oficiais e exibindo resultados de negócio com segurança. Use para transformar uma automação Windows existente em aplicativo financeiro ou operacional; não use para interfaces web ou para reescrever lógica financeira sem solicitação explícita.
---

# Aplicativos Financeiros WPF

Transforme um fluxo existente em aplicativo WPF sem confundir interface bonita com sucesso operacional.

## Entrada obrigatória

Antes de editar, reúna os campos de [references/intake-form.md](references/intake-form.md). Aproveite informações já fornecidas e investigue caminhos locais acessíveis; pergunte somente os campos essenciais ainda ausentes, em um bloco curto. Repita o entendimento e os efeitos externos antes de começar.

## Dependência obrigatória: Cacau

Toda invocação de `$app`, inclusive Mapear, Criar, Reparar, Revisar e Homologar, exige uso de `$cacau`. No modo Mapear, a Cacau opera somente em leitura; nos modos de mudança, siga a separação de análise, escrita e revisão definida por ela.

1. Resolva `$CODEX_HOME`; se estiver vazio, use `$HOME/.codex` (no Windows, normalmente `C:\Users\<usuário>\.codex`).
2. Procure primeiro `<CODEX_HOME>/skills/cacau/SKILL.md` e valide o frontmatter `name: cacau`.
3. Se não existir, carregue `$skill-installer` e use o helper `scripts/install-skill-from-github.py --url https://github.com/cacauzuxa/cacau-codex-skill/tree/main/cacau`. A instalação não pode sobrescrever destino existente nem usar outra origem.
4. Valide novamente `<CODEX_HOME>/skills/cacau/SKILL.md` e informe que a skill poderá ficar disponível somente na próxima invocação.
5. Se a instalação ou validação falhar, pare fechado: não mapeie, implemente, repare ou homologue fingindo que Cacau foi usado. Se a instalação informar que a skill só ficará disponível na próxima invocação, encerre esta execução e peça ao usuário para invocar `$app` novamente.

Quando Cacau já existir e estiver válido, invoque-o e siga sua separação entre análise e mudança. Preserve esta exigência mesmo em uma correção pequena; `$app` mantém invocação automática permitida.

## Escolha o modo

- **Mapear**: somente leitura. Descubra cadeia transitiva, entradas, saídas, efeitos, dependências, locks e critérios reais. Leia [references/discovery-and-contract.md](references/discovery-and-contract.md).
- **Criar**: construa a camada WPF em torno dos rodadores oficiais. Leia [references/architecture.md](references/architecture.md), [references/design-system.md](references/design-system.md) e [references/status-safety-logs.md](references/status-safety-logs.md).
- **Revisar ou reparar**: preserve escopo e hashes; corrija somente a camada necessária. Leia as referências da criação, [references/complaints-prevention-gate.md](references/complaints-prevention-gate.md) e compare antes/depois.
- **Preparar outro computador**: implemente verificação e preparação separadas. Leia [references/prerequisites-portability.md](references/prerequisites-portability.md).
- **Homologar ou publicar**: leia [references/qa-release-gate.md](references/qa-release-gate.md) e [references/complaints-prevention-gate.md](references/complaints-prevention-gate.md); aplique também `$financial-app-qa` quando disponível.

Nos modos **Criar**, **Revisar/Reparar** e **Homologar/Publicar**, o gate de [complaints-prevention-gate.md](references/complaints-prevention-gate.md) é obrigatório e bloqueia a entrega quando não houver evidência observável.

## Invariantes

1. Mapeie antes de desenhar ou editar.
2. Preserve scripts, modelos e bases oficiais. Congele SHA-256 antes e compare depois.
3. Separe `AppInterface`, worker, parser de resultado e rodadores oficiais.
4. Mantenha o padrão institucional de cores, tipografia, logo, layout e estados descrito em [references/design-system.md](references/design-system.md). Use os ativos aprovados em `assets/`.
5. Não trate `ExitCode=0`, arquivo criado, processo encerrado ou barra em 100% como confirmação de negócio.
6. Modele pelo menos `SUCESSO`, `OK_COM_PENDENCIAS`, `ERRO` e `BLOQUEADO`.
7. Cada clique executa no máximo uma tentativa. Não faça retry automático de ação com efeito externo.
8. Use lock, idempotência e guarda de duplicidade proporcionais ao risco. Lock local não protege outro computador.
9. Se uma ação externa puder ter ocorrido e o resultado for incerto, bloqueie repetição e exija reconciliação.
10. Limpeza deve mover dados para backup recuperável com timestamp, nunca apagar silenciosamente.
11. A tela mostra resultado, exceções acionáveis, duração e próxima ação. Ruído técnico fica recolhido em Auditoria.
12. `Verificar pré-requisitos` e `Preparar pré-requisitos` são ações separadas. O preparador não pode depender do R para instalar ou localizar R.
13. Não exponha credenciais, tokens, conteúdo integral de e-mail ou dados financeiros desnecessários.
14. Não execute pagamento, envio bancário, upload, e-mail, RPA, importação ou limpeza real sem autorização específica.
15. Diferencie tecnicamente pronto, visualmente aprovado e operacionalmente homologado.

## Fluxo de trabalho

1. Complete a entrada e confirme o escopo.
2. Faça inventário sem executar o fluxo e classifique arquivos protegidos, app, entradas, saídas, logs, backups, testes e legados.
3. Defina contrato de resultado, efeitos e regras de repetição antes da interface.
4. Implemente ou repare a menor camada necessária.
5. Valide estaticamente, teste com fixtures e faça QA em janela real.
6. Execute a revisão crítica obrigatória de [references/end-to-end-review.md](references/end-to-end-review.md), que incorpora o gate de reclamações, simulando o passo a passo como usuário do início ao fim.
7. Corrija problemas encontrados e repita a revisão afetada.
8. Compare hashes e registre limitações e homologações pendentes.

## Entrega

Relate arquivos alterados, cadeia preservada, hashes, testes, capturas, experiência do usuário, resultado observado, limitações e ações externas ainda não homologadas. Não invente evidência visual ou operacional.
