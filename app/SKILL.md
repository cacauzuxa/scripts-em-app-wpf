---
name: app
description: Mapear, criar, revisar, reparar e homologar aplicativos WPF portáteis para automações Windows com R/Rscript, PowerShell, Excel, Outlook, navegador ou rede. Use quando uma automação operacional existente precisar de interface WPF sem alterar silenciosamente a regra de negócio; não use para interfaces web.
---

# Scripts em APP WPF

Transforme uma automação Windows existente em aplicativo WPF sem confundir interface bonita com sucesso operacional.

## Escopo e entrada

Antes de editar, aproveite o contexto já fornecido e investigue caminhos acessíveis. Use [references/intake-form.md](references/intake-form.md) apenas para os campos essenciais ainda ausentes; não faça o usuário repetir informações. Confirme efeitos externos antes de qualquer ação que possa enviar, pagar, importar, excluir ou publicar.

Se o usuário invocar `$cacau` explicitamente, siga a orquestração dessa skill. Caso contrário, trabalhe diretamente: `$app` não instala, exige nem finge ter usado outra skill.

## Escolha o modo

- **Mapear**: somente leitura. Leia [references/discovery-and-contract.md](references/discovery-and-contract.md).
- **Criar**: leia [references/architecture.md](references/architecture.md), [references/design-system.md](references/design-system.md) e [references/status-safety-logs.md](references/status-safety-logs.md).
- **Revisar ou reparar**: leia somente as referências ligadas à superfície afetada e aplique [references/core-quality-gate.md](references/core-quality-gate.md).
- **Preparar outro computador**: leia [references/prerequisites-portability.md](references/prerequisites-portability.md).
- **Homologar ou publicar**: leia [references/qa-release-gate.md](references/qa-release-gate.md), [references/core-quality-gate.md](references/core-quality-gate.md) e [references/end-to-end-review.md](references/end-to-end-review.md). Aplique `$financial-app-qa` quando disponível.

Carregue [references/finance-operations-gate.md](references/finance-operations-gate.md) somente quando o fluxo realmente envolver remessas, pagamentos, CNAB, PIX, boletos, importações, anexos ou efeitos financeiros equivalentes.

## Invariantes

1. Mapeie a cadeia afetada antes de desenhar ou editar.
2. Preserve scripts, modelos e bases oficiais; compare SHA-256 quando houver arquivos protegidos.
3. Separe interface, worker, parser de resultado e rodadores oficiais na proporção necessária ao fluxo.
4. Use o tema e os ativos de [references/design-system.md](references/design-system.md), salvo identidade oficial diferente fornecida pelo usuário.
5. Não trate `ExitCode=0`, arquivo criado, processo encerrado ou barra em 100% como confirmação de negócio.
6. Modele `SUCESSO`, `OK_COM_PENDENCIAS`, `ERRO` e `BLOQUEADO` quando o fluxo tiver resultado operacional.
7. Cada clique executa no máximo uma tentativa de ação com efeito externo; não faça retry automático.
8. Use lock, idempotência e guarda de duplicidade proporcionais ao risco. Lock local não protege outro computador.
9. Se uma ação externa puder ter ocorrido e o resultado for incerto, bloqueie repetição até reconciliação.
10. Limpeza deve ser recuperável e explícita; nunca apague silenciosamente.
11. Mostre resultado, exceções acionáveis, duração e próxima ação; deixe ruído técnico recolhido em Auditoria.
12. Não exponha credenciais, tokens, conteúdo integral de e-mail ou dados desnecessários.
13. Não execute pagamento, envio, upload, e-mail, RPA, importação, limpeza ou publicação real sem autorização específica.
14. Diferencie tecnicamente pronto, visualmente aprovado e operacionalmente homologado.

## Fluxo de trabalho

1. Confirme escopo e efeitos.
2. Faça inventário sem executar o fluxo; use `scripts/inventory_flow.ps1` quando ajudar.
3. Defina contrato de resultado e regras de repetição antes da interface.
4. Implemente ou repare a menor camada necessária.
5. Rode verificações determinísticas com `scripts/validate_app.ps1`, testes afetados e QA real proporcional ao risco.
6. Em criação ampla, reparo visual relevante ou homologação, aplique a revisão de [references/end-to-end-review.md](references/end-to-end-review.md). Em mudança pequena, revise somente o caminho afetado.
7. Corrija falhas e repita apenas as verificações afetadas.
8. Registre evidências, limitações e homologações pendentes.

## Entrega

Relate arquivos alterados, cadeia preservada, testes, capturas quando feitas, resultado observado, limitações e efeitos externos ainda não homologados. Não invente evidência visual ou operacional.
