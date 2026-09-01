# Descoberta e contrato

## Inventário mínimo

- Launcher, rodador principal e cadeia transitiva de `source()`, dot-source, `system2`, `Start-Process`, `Rscript`, BAT e executáveis.
- Entradas, saídas, logs, históricos, temporários, backups, modelos e bases.
- Dependências de R, PowerShell, Excel COM, Outlook COM, Chrome, Node, VPN, unidade mapeada e UNC.
- Perfis, portas e arquivos de credencial, registrando somente existência, nunca conteúdo.
- Efeitos externos: serviços corporativos, e-mail, upload, importação, pagamento, baixa e limpeza.
- Critérios reais de sucesso, atenção, erro, bloqueio, duplicidade e retomada.

Classifique cada ação pelo efeito real: leitura pura; leitura com teste temporário; preparação local; mutação interna recuperável; efeito externo. Um botão chamado `Verificar` pode criar e remover arquivo para testar escrita, portanto declare a exceção.

## Evidência protegida

Gere manifesto SHA-256 antes de editar. Inclua scripts oficiais, modelos, planilhas com macro, parsers homologados e bases de referência. Compare depois da entrega.

## Contrato de resultado

Prefira JSON UTF-8 novo e fresco. `wpf.app.result.v1` é o contrato comum da camada de aplicativo, não o nome do processo; detalhes específicos ficam em `action`, `metrics` e `artifacts`:

```json
{
  "schema": "wpf.app.result.v1",
  "action": "processar",
  "run_id": "20260901_143000",
  "started_at": "2026-09-01T14:30:00-03:00",
  "finished_at": "2026-09-01T14:34:22-03:00",
  "exit_code": 0,
  "business_status": "OK_COM_PENDENCIAS",
  "result_classification_confirmed": true,
  "title": "Processamento concluído com atenção",
  "message": "12 pagamentos gerados; 1 item retirado.",
  "progress": 100,
  "last_confirmed_stage": "RESULTADO_VALIDADO",
  "metrics": {},
  "exceptions": [{"item":"9814568","reason":"Guia vencida","next_action":"Solicitar nova guia"}],
  "artifacts": [],
  "log_path": "C:/caminho/log.txt"
}
```

- Valide schema, tipos, `run_id`, horários e data de modificação.
- Datas usam ISO 8601 com timezone explícito; intervalos de negócio devem declarar se início e fim são inclusivos.
- Pendência de negócio prevalece sobre código técnico zero.
- Erro preserva a última etapa confirmada.
- Métricas devem ser coerentes entre tarefas, solicitações, lançamentos, pagamentos, anexos, sucessos e exceções.
- Explique cardinalidades diferentes, como uma tarefa com dois pagamentos.
- Nunca use resultado de outro dia apenas porque é o arquivo mais recente.
- `result_classification_confirmed=true` confirma que o resultado foi classificado com evidência suficiente; não significa sucesso. O sucesso é definido exclusivamente por `business_status`.
- Ações como `limpar`, `abrir_logs`, `importar` e `enviar` devem ter contratos e critérios próprios, mesmo quando usam o envelope comum.
