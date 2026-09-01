[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppRoot
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $AppRoot).Path
$issues = [System.Collections.Generic.List[object]]::new()

function Add-Issue {
    param([string]$Severity, [string]$Code, [string]$Message, [string]$Path = '')
    $issues.Add([ordered]@{ severity = $Severity; code = $Code; message = $Message; path = $Path })
}

$required = @(
    'AppInterface.ps1',
    'config.json',
    'Assets\icone.png',
    'Assets\icone.ico',
    'Infraestrutura\Executar-Acao.ps1',
    'Infraestrutura\Verificar-PreRequisitos.ps1',
    'Infraestrutura\Preparar-PreRequisitos.ps1'
)
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) {
        Add-Issue 'ERROR' 'MISSING_REQUIRED' "Arquivo obrigatório ausente: $relative" $relative
    }
}

$psFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.ps1' -File -Recurse -ErrorAction SilentlyContinue)
foreach ($file in $psFiles) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
    foreach ($parseError in @($parseErrors)) {
        Add-Issue 'ERROR' 'POWERSHELL_PARSE' $parseError.Message $file.FullName
    }

    $content = Get-Content -LiteralPath $file.FullName -Raw
    if ($content -match '(?i)C:\\Users\\[^\\]+') {
        Add-Issue 'ERROR' 'HARDCODED_USER' 'Caminho de usuário fixo encontrado.' $file.FullName
    }
    if ($content -match '(?i)\\\.codex\\|\\Downloads\\') {
        Add-Issue 'ERROR' 'NON_PORTABLE_PATH' 'Caminho local não portátil encontrado.' $file.FullName
    }
    if ($content -match '(?i)AllowDuplicate|retry\s*=\s*true|tentativas?\s*=\s*[2-9]') {
        Add-Issue 'ERROR' 'DUPLICATE_OR_RETRY' 'Possível bypass de duplicidade ou repetição automática.' $file.FullName
    }
}

$configPath = Join-Path $root 'config.json'
if (Test-Path -LiteralPath $configPath) {
    try {
        $configText = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
        [void]($configText | ConvertFrom-Json)
        if ($configText -match '(?i)"(password|senha|token|secret|api[_-]?key)"\s*:\s*"[^"\s]+"') {
            Add-Issue 'ERROR' 'SECRET_IN_CONFIG' 'Possível segredo em texto comum no config.json.' $configPath
        }
    } catch {
        Add-Issue 'ERROR' 'INVALID_CONFIG_JSON' $_.Exception.Message $configPath
    }
}

$appPath = Join-Path $root 'AppInterface.ps1'
if (Test-Path -LiteralPath $appPath) {
    $app = Get-Content -LiteralPath $appPath -Raw
    foreach ($check in @(
        @{ pattern = 'MinWidth\s*=\s*["'']?960'; code = 'MIN_WIDTH'; message = 'MinWidth=960 não identificado.' },
        @{ pattern = 'MinHeight\s*=\s*["'']?680'; code = 'MIN_HEIGHT'; message = 'MinHeight=680 não identificado.' },
        @{ pattern = '#0E2D58|#153F78|#1D4D8D'; code = 'BRAND_COLORS'; message = 'Gradiente institucional não identificado.' },
        @{ pattern = 'Georgia'; code = 'TITLE_FONT'; message = 'Fonte Georgia para títulos não identificada.' },
        @{ pattern = 'Segoe UI'; code = 'BODY_FONT'; message = 'Fonte Segoe UI não identificada.' },
        @{ pattern = 'Auditoria'; code = 'AUDIT_AREA'; message = 'Área de Auditoria não identificada.' },
        @{ pattern = 'Manual'; code = 'MANUAL_TAB'; message = 'Manual/FAQ não identificado.' },
        @{ pattern = 'Pre.?Requis'; code = 'PREREQUISITES_UI'; message = 'Controles de pré-requisitos não identificados.' },
        @{ pattern = '(?i)run[_-]?id|id.?execu|execu[cç][aã]o.*data|resultado.*fresc|fresco.*resultado'; code = 'FRESH_RESULT_GUARD'; message = 'Guarda estática de resultado fresco/run_id não identificada.' },
        @{ pattern = '(?i)tarefa|solicita[cç][aã]o|lan[cç]amento|pagamento|PIX\s*U|boleto\s*B|retirad|anexo'; code = 'BUSINESS_COUNTS'; message = 'Contagens de negócio (tarefas, lançamentos, pagamentos, U/B, retirados ou anexos) não identificadas.' },
        @{ pattern = '(?i)1\s*(tarefa|solicita[cç][aã]o).*\bN\b|cardinal|quantidade.*pagamento|pagamento.*tarefa'; code = 'CARDINALITY_EXPLANATION'; message = 'Explicação estática de cardinalidade tarefa -> N pagamentos não identificada.' },
        @{ pattern = '(?i)exce[cç][aã]o|pend[eê]ncia'; code = 'EXCEPTIONS_FIRST'; message = 'Bloco de exceções/pendências não identificado.' },
        @{ pattern = '(?i)localizador|favorecid|motivo|pr[oó]xima.?a[cç][aã]o'; code = 'ACTIONABLE_EXCEPTION_FIELDS'; message = 'Campos acionáveis de exceção (localizador, favorecido, motivo ou próxima ação) não identificados.' },
        @{ pattern = '(?i)Auditoria|stderr|stack|log.*t[eé]cn'; code = 'TECHNICAL_AUDIT'; message = 'Separação de Auditoria/log técnico não identificada.' },
        @{ pattern = '(?i)causa|a[cç][aã]o.*log|abrir.*log|Mensagem'; code = 'USEFUL_ERROR'; message = 'Erro visível com causa, ação ou acesso ao log não identificado.' },
        @{ pattern = '(?i)duplic|dedup|sem.*texto.*repet|repeti[cç][aã]o'; code = 'DUPLICATE_TEXT_GUARD'; message = 'Guarda estática contra texto/reexecução duplicada não identificada.' },
        @{ pattern = '(?i)E8F3ED|28734A|FDEBE7|9A3E34|sem.*pend[eê]ncia|Status.*Foreground'; code = 'SEMANTIC_COLORS'; message = 'Cores semânticas para sucesso, atenção e erro não identificadas.' },
        @{ pattern = '(?i)DispatcherTimer|timer|ao.?vivo|live|atualiz'; code = 'LIVE_PROGRESS'; message = 'Atualização ao vivo de progresso/estado não identificada.' },
        @{ pattern = '(?i)ETA|estimativa|tempo.*decorr|elapsed|mediana'; code = 'LIVE_TIMING'; message = 'Tempo decorrido/ETA não identificado.' },
        @{ pattern = '(?i)paralel|ramo|contador.*independ|perfil|porta'; code = 'PARALLEL_ISOLATION'; message = 'Isolamento e contadores independentes de ramos paralelos não identificados.' },
        @{ pattern = '(?i)Verify|Verificar.*final|verifica[cç][aã]o.*final'; code = 'VERIFY_GATE'; message = 'Gate de Verify/verificação final não identificado.' },
        @{ pattern = '(?i)retom|reabert|resume|idempot|etapa.*confirm'; code = 'RESUME_GUARD'; message = 'Retomada/reabertura por etapa confirmada não identificada.' },
        @{ pattern = '(?i)remessa.*(dia|data)|run[_-]?id|m[uú]ltipl'; code = 'MULTIPLE_RUNS'; message = 'Identificação de múltiplas remessas/execuções não identificada.' },
        @{ pattern = '(?i)Cancelar|Interromper|INICIADO|lock|mutex'; code = 'CANCEL_UNLOCK'; message = 'Cancelamento/interrupção com liberação de lock não identificada.' },
        @{ pattern = '(?i)pre.?requis|Verificar|Preparar'; code = 'PREREQUISITE_ACTIONS'; message = 'Ações separadas de verificar/preparar pré-requisitos não identificadas.' },
        @{ pattern = '(?i)monitor.*principal|PrimaryScreen|WindowState.*Maximized|WindowStartupLocation'; code = 'WINDOW_BEHAVIOR'; message = 'Abertura maximizada no monitor principal não identificada.' },
        @{ pattern = '(?i)clipping|ClipToBounds|ActualWidth|ScrollViewer|redimension'; code = 'RESPONSIVE_LAYOUT'; message = 'Proteção estática contra clipping/redimensionamento não identificada.' },
        @{ pattern = '(?i)C[oó]digo|par[aâ]metro'; code = 'MAINTENANCE_TAB'; message = 'Área de Código/parâmetros para manutenção não identificada.' },
        @{ pattern = '(?i)UTF-?8|mojibake|encoding'; code = 'UTF8_ENCODING'; message = 'Proteção/checagem de encoding UTF-8 não identificada.' },
        @{ pattern = '(?i)backup|manifesto|SHA-?256|arquivo.*aberto|bloqueio'; code = 'CLEANUP_EVIDENCE'; message = 'Evidência de limpeza com backup, bloqueio ou hash não identificada.' },
        @{ pattern = '(?i)extern|confirma[cç][aã]o.*usu[aá]rio|efeito'; code = 'EXTERNAL_ACTIONS'; message = 'Separação/confirmação de ações externas não identificada.' },
        @{ pattern = '(?i)exclu|regener|reimport|preserv.*original|lan[cç]amento.*problem'; code = 'REGENERATE_AUDIT'; message = 'Exclusão/regeneração/reimportação auditável não identificada.' },
        @{ pattern = '(?i)artefato|abrir.*app|subsequente'; code = 'ARTIFACT_ACTIONS'; message = 'Ações para abrir artefato/log/aplicativo subsequente não identificadas.' },
        @{ pattern = '(?i)gerado|importado|enviado|pago|anexado|verificado'; code = 'BUSINESS_STATES'; message = 'Estados de negócio gerado/importado/enviado/pago/anexado/verificado não identificados.' }
    )) {
        if ($app -notmatch $check.pattern) {
            Add-Issue 'WARNING' $check.code $check.message $appPath
        }
    }
}

$errors = @($issues | Where-Object severity -eq 'ERROR').Count
$warnings = @($issues | Where-Object severity -eq 'WARNING').Count
$result = [ordered]@{
    schema = 'wpf.app.static-validation.v1'
    validation_scope = 'STATIC_STRUCTURE_AND_PATTERNS_ONLY'
    app_root = $root
    generated_at = (Get-Date).ToString('o')
    status = if ($errors -gt 0) { 'STATIC_ERROR' } elseif ($warnings -gt 0) { 'STATIC_WARNING' } else { 'STATIC_OK' }
    release_gate_passed = $false
    errors = $errors
    warnings = $warnings
    issues = @($issues)
    unverified_release_gates = @(
        'Gate de prevenção de reclamações e revisão E2E',
        'Cadeia transitiva confirmada manualmente',
        'Hashes protegidos comparados antes/depois',
        'Scripts R analisados/testados',
        'Contrato de resultado e fixtures de negócio',
        'Locks, idempotência e limpeza recuperável',
        'Autorização e efeitos externos',
        'QA em janela WPF real',
        'Homologação operacional'
    )
}
$result | ConvertTo-Json -Depth 6
if ($errors -gt 0) { exit 1 }
