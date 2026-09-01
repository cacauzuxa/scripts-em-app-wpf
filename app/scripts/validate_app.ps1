[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppRoot,
    [switch]$RequireBrandAssets
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $AppRoot).Path
$issues = [System.Collections.Generic.List[object]]::new()

function Add-Issue {
    param([string]$Severity, [string]$Code, [string]$Message, [string]$Path = '')
    $issues.Add([ordered]@{ severity = $Severity; code = $Code; message = $Message; path = $Path })
}

$psFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.ps1' -File -Recurse -ErrorAction Stop)
$xamlFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.xaml' -File -Recurse -ErrorAction Stop)
$jsonFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.json' -File -Recurse -ErrorAction Stop)

if ($psFiles.Count -eq 0 -and $xamlFiles.Count -eq 0) {
    Add-Issue 'ERROR' 'MISSING_UI_ENTRYPOINT' 'Nenhum arquivo PowerShell ou XAML foi encontrado para a interface.' $root
}

foreach ($file in $psFiles) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
    foreach ($parseError in @($parseErrors)) {
        Add-Issue 'ERROR' 'POWERSHELL_PARSE' $parseError.Message $file.FullName
    }
    $content = Get-Content -LiteralPath $file.FullName -Raw
    if ($content -match '(?i)C:\\Users\\[^\\]+|\\Downloads\\|\\\.codex\\') {
        Add-Issue 'WARNING' 'NON_PORTABLE_PATH' 'Possível caminho local fixo; confirme se está apenas em comentário ou fixture.' $file.FullName
    }
    if ($content -match '(?i)AllowDuplicate|retry\s*=\s*true|tentativas?\s*=\s*[2-9]') {
        Add-Issue 'WARNING' 'DUPLICATE_OR_RETRY' 'Possível repetição automática ou bypass de duplicidade; revise semanticamente.' $file.FullName
    }
}

foreach ($file in $xamlFiles) {
    try {
        [xml](Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8) | Out-Null
    } catch {
        Add-Issue 'ERROR' 'INVALID_XAML_XML' $_.Exception.Message $file.FullName
    }
}

foreach ($file in $jsonFiles) {
    try {
        $jsonText = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        [void]($jsonText | ConvertFrom-Json)
        if ($jsonText -match '(?i)"(password|senha|token|secret|api[_-]?key)"\s*:\s*"(?!__|<|\$\{)[^"\s]+"') {
            Add-Issue 'ERROR' 'SECRET_IN_JSON' 'Possível segredo em texto comum no JSON.' $file.FullName
        }
    } catch {
        Add-Issue 'ERROR' 'INVALID_JSON' $_.Exception.Message $file.FullName
    }
}

if ($RequireBrandAssets) {
    foreach ($relative in @('Assets\icone.png', 'Assets\icone.ico', 'Assets\BrandTheme.xaml')) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) {
            Add-Issue 'ERROR' 'MISSING_BRAND_ASSET' "Ativo visual obrigatório ausente: $relative" $relative
        }
    }
    $uiText = (($psFiles + $xamlFiles) | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
    foreach ($check in @(
        @{ pattern = 'BrandTheme\.xaml|HeaderGradient'; code = 'THEME_NOT_CONNECTED'; message = 'Tema institucional não está ligado à interface.' },
        @{ pattern = 'icone\.ico'; code = 'ICON_NOT_CONNECTED'; message = 'ICO não está ligado à janela ou ao launcher.' },
        @{ pattern = 'icone\.png'; code = 'LOGO_NOT_CONNECTED'; message = 'PNG não está ligado ao cabeçalho.' }
    )) {
        if ($uiText -notmatch $check.pattern) {
            Add-Issue 'ERROR' $check.code $check.message $root
        }
    }
}

$errors = @($issues | Where-Object severity -eq 'ERROR').Count
$warnings = @($issues | Where-Object severity -eq 'WARNING').Count
$result = [ordered]@{
    schema = 'wpf.app.static-validation.v2'
    validation_scope = 'DETERMINISTIC_PARSE_STRUCTURE_AND_TARGETED_HEURISTICS'
    app_root = $root
    generated_at = (Get-Date).ToString('o')
    brand_profile_required = [bool]$RequireBrandAssets
    status = if ($errors -gt 0) { 'STATIC_ERROR' } elseif ($warnings -gt 0) { 'STATIC_WARNING' } else { 'STATIC_OK' }
    release_gate_passed = $false
    errors = $errors
    warnings = $warnings
    issues = @($issues)
    unverified_release_gates = @(
        'Comportamento e resultado de negócio',
        'Locks, idempotência e efeitos externos',
        'QA em janela WPF real',
        'Homologação operacional'
    )
}
$result | ConvertTo-Json -Depth 6
if ($errors -gt 0) { exit 1 }
