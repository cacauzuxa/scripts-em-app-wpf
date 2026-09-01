# Encoding: UTF-8; Windows PowerShell 5.1 reads this file with -Encoding UTF8.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppRoot,
    [switch]$RequireBrandAssets
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $AppRoot -ErrorAction Stop).Path
$issues = New-Object 'System.Collections.Generic.List[object]'

function Add-Issue {
    param([string]$Severity, [string]$Code, [string]$Message, [string]$Path = '')
    [void]$issues.Add([ordered]@{ severity = $Severity; code = $Code; message = $Message; path = $Path })
}

function Find-Executable {
    param([string]$Name, [string[]]$ExtraPaths = @())
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    foreach ($candidate in $ExtraPaths) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return $null
}

function Invoke-RscriptParse {
    param([string]$RscriptPath, [string]$FilePath)
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $RscriptPath
    $safeFilePath = $FilePath.Replace('"', '\"')
    $startInfo.Arguments = '-e "invisible(parse(file=commandArgs(TRUE)[1], keep.source=FALSE))" "' + $safeFilePath + '"'
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) { return -1 }
        [void]$process.StandardOutput.ReadToEnd()
        [void]$process.StandardError.ReadToEnd()
        $process.WaitForExit()
        return $process.ExitCode
    } finally {
        $process.Dispose()
    }
}

function Get-NonCommentText {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $withoutLineComments = [regex]::Replace($Text, '(?m)^\s*(?:#|//).*$\r?\n?', '')
    return [regex]::Replace($withoutLineComments, '(?s)<!--.*?-->', '')
}

function Test-PlaceholderValue {
    param([string]$Value)
    return [String]::IsNullOrWhiteSpace($Value) -or $Value -match '^(?:__|<|\$\{|\[REDACTED\]|\$\w+\b)'
}

function Test-JsonObjectForSecret {
    param([object]$Value, [ref]$Found)
    if ($null -eq $Value) { return }
    if ($Value -is [PSCustomObject]) {
        foreach ($property in @($Value.PSObject.Properties)) {
            if ($property.Name -match '(?i)^(?:client[_-]?secret|clientsecret|client\s+secret|password|senha|token|secret|credential|api[_-]?key)$' -and -not (Test-PlaceholderValue ([string]$property.Value))) {
                [void]($Found.Value = $true)
            }
            [void](Test-JsonObjectForSecret -Value $property.Value -Found $Found)
        }
    } elseif ($Value -is [Array]) {
        foreach ($item in $Value) {
            [void](Test-JsonObjectForSecret -Value $item -Found $Found)
        }
    }
}

$psFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.ps1' -File -Recurse -ErrorAction Stop)
$rFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.r' -File -Recurse -ErrorAction Stop)
$csFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.cs' -File -Recurse -ErrorAction Stop)
$xamlFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.xaml' -File -Recurse -ErrorAction Stop)
$jsonFiles = @(Get-ChildItem -LiteralPath $root -Filter '*.json' -File -Recurse -ErrorAction Stop)
$shellEntrypoints = @($xamlFiles | Where-Object { $_.BaseName -eq 'AppShell' })

$entrypointFiles = @(
    $psFiles | Where-Object {
        $nameLooksLikeEntryPoint = $_.BaseName -match '(?i)^(app|appinterface|main|start|run|launcher)(?:[-_.].*)?$'
        $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        $hasWpfStartup = (Get-NonCommentText $content) -match '(?i)(XamlReader|ShowDialog\s*\(|\.Show\s*\(|Application\.Current|PresentationFramework|AppShell\.xaml)'
        $nameLooksLikeEntryPoint -or $hasWpfStartup
    }
)
if ($entrypointFiles.Count -eq 0 -and $shellEntrypoints.Count -eq 0) {
    Add-Issue 'ERROR' 'MISSING_UI_ENTRYPOINT' 'Nenhum entrypoint WPF reconhecível foi encontrado; arquivos auxiliares .ps1 não contam como interface.' $root
}

$psParseStatus = 'CHECKED'
foreach ($file in $psFiles) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
    foreach ($parseError in @($parseErrors)) {
        Add-Issue 'ERROR' 'POWERSHELL_PARSE' $parseError.Message $file.FullName
    }
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $nonCommentContent = Get-NonCommentText $content
    if ($nonCommentContent -match '(?i)C:\\Users\\[^\\]+|\\Downloads\\|\\\.codex\\') {
        Add-Issue 'WARNING' 'NON_PORTABLE_PATH' 'Possível caminho local fixo em código executável; confirme a portabilidade.' $file.FullName
    }
    if ($nonCommentContent -match '(?i)AllowDuplicate|retry\s*=\s*true|tentativas?\s*=\s*[2-9]') {
        Add-Issue 'WARNING' 'DUPLICATE_OR_RETRY' 'Possível repetição automática ou bypass de duplicidade; revise semanticamente.' $file.FullName
    }
}

$rParseStatus = if ($rFiles.Count -gt 0) { 'NOT_CHECKED' } else { 'NOT_APPLICABLE' }
if ($rFiles.Count -gt 0) {
    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    $rExtra = New-Object 'System.Collections.Generic.List[string]'
    if ($env:R_HOME) { [void]$rExtra.Add((Join-Path $env:R_HOME 'bin\Rscript.exe')) }
    $rCandidates = @()
    if ($env:ProgramFiles) {
        $rCandidates += Get-ChildItem -LiteralPath (Join-Path $env:ProgramFiles 'R') -Filter 'Rscript.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    }
    if ($programFilesX86) {
        $rCandidates += Get-ChildItem -LiteralPath (Join-Path $programFilesX86 'R') -Filter 'Rscript.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    }
    $rscript = Find-Executable -Name 'Rscript.exe' -ExtraPaths @($rExtra + $rCandidates)
    if ($rscript) {
        $rParseStatus = 'CHECKED'
        foreach ($file in $rFiles) {
            $rExitCode = Invoke-RscriptParse -RscriptPath $rscript -FilePath $file.FullName
            if ($rExitCode -ne 0) {
                Add-Issue 'ERROR' 'R_PARSE' 'O arquivo R não pôde ser analisado pelo Rscript.' $file.FullName
            }
        }
    } else {
        Add-Issue 'WARNING' 'RSCRIPT_NOT_AVAILABLE' 'Rscript não está disponível; parsing de R marcado como NOT_CHECKED.' $root
    }
}

$csharpStatus = 'NOT_PRESENT'
if ($csFiles.Count -gt 0) {
    $frameworkRoot = Join-Path $env:WINDIR 'Microsoft.NET\Framework'
    $cscCandidates = @(Get-ChildItem -LiteralPath $frameworkRoot -Filter 'csc.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -ExpandProperty FullName)
    $csc = Find-Executable -Name 'csc.exe' -ExtraPaths @($cscCandidates)
    if (-not $csc) {
        $csharpStatus = 'NOT_CHECKED'
        Add-Issue 'WARNING' 'CSHARP_COMPILER_NOT_AVAILABLE' 'csc.exe não está disponível; compilação C# marcada como NOT_CHECKED.' $root
    } else {
        $csharpStatus = 'CHECKED'
        $validationTemp = Join-Path ([IO.Path]::GetTempPath()) ('wpf-app-validation-' + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $validationTemp -Force | Out-Null
        try {
            $compileArgs = @('/nologo', '/target:winexe', ('/out:' + (Join-Path $validationTemp 'validation.exe')), '/reference:System.dll', '/reference:System.Windows.Forms.dll')
            $iconCandidate = Join-Path $root 'Assets\icone.ico'
            if (Test-Path -LiteralPath $iconCandidate -PathType Leaf) {
                $compileArgs += '/win32icon:' + (Resolve-Path -LiteralPath $iconCandidate).Path
            }
            $compileArgs += @($csFiles | ForEach-Object { $_.FullName })
            $compileOutput = @(& $csc @compileArgs 2>&1)
            if ($LASTEXITCODE -ne 0) {
                $safeOutput = ($compileOutput | Out-String).Trim()
                if ($safeOutput.Length -gt 400) { $safeOutput = $safeOutput.Substring(0, 400) }
                Add-Issue 'ERROR' 'CSHARP_COMPILE' ('Falha ao compilar o C# do aplicativo. ' + $safeOutput) $root
            }
        } finally {
            if (Test-Path -LiteralPath $validationTemp) {
                Remove-Item -LiteralPath $validationTemp -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

$parsedXaml = New-Object 'System.Collections.Generic.List[object]'
foreach ($file in $xamlFiles) {
    try {
        $xml = [xml](Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8)
        [void]$parsedXaml.Add($xml)
    } catch {
        Add-Issue 'ERROR' 'INVALID_XAML_XML' ('XAML inválido: ' + $_.Exception.Message) $file.FullName
    }
}

foreach ($file in $jsonFiles) {
    try {
        $jsonText = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        $jsonObject = $jsonText | ConvertFrom-Json
        $containsSecret = $false
        Test-JsonObjectForSecret -Value $jsonObject -Found ([ref]$containsSecret)
        if ($containsSecret) {
            Add-Issue 'ERROR' 'SECRET_IN_JSON' 'Possível segredo em texto comum no JSON; valor omitido.' $file.FullName
        }
    } catch {
        Add-Issue 'ERROR' 'INVALID_JSON' $_.Exception.Message $file.FullName
    }
}

$sourceFiles = @($psFiles + $rFiles + $csFiles)
foreach ($file in $sourceFiles) {
    $safeScan = Get-NonCommentText (Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8)
    $secretValuePattern = '(?i)(?:["'']?)(?:client[_-]?secret|clientsecret|client\s+secret|password|senha|token|secret|credential|api[_-]?key)(?:["'']?)\s*(?:=|:)\s*["'']?(?!__|<|\$\{|\[REDACTED\])[^"''\s;,)]{2,}'
    if ($safeScan -match $secretValuePattern) {
        Add-Issue 'ERROR' 'SECRET_IN_SOURCE' 'Possível segredo em código-fonte; valor omitido.' $file.FullName
    }
}

if ($RequireBrandAssets) {
    foreach ($relative in @('Assets\icone.png', 'Assets\icone.ico', 'Assets\BrandTheme.xaml')) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) {
            Add-Issue 'ERROR' 'MISSING_BRAND_ASSET' ('Ativo visual obrigatório ausente: ' + $relative) $relative
        }
    }
    $themeLinked = $false
    $iconLinked = $false
    $logoLinked = $false
    foreach ($xml in $parsedXaml.ToArray()) {
        foreach ($node in $xml.SelectNodes('//*')) {
            $sourceAttribute = $node.Attributes['Source']
            if ($sourceAttribute) {
                $source = $sourceAttribute.Value.Replace('/', '\').TrimStart('\')
                if ($source -match '(?i)(^|\\)Assets\\BrandTheme\.xaml$') { $themeLinked = $true }
                if ($source -match '(?i)(^|\\)Assets\\icone\.png$') { $logoLinked = $true }
            }
            $iconAttribute = $node.Attributes['Icon']
            if ($iconAttribute -and $iconAttribute.Value.Replace('/', '\').TrimStart('\') -match '(?i)(^|\\)Assets\\icone\.ico$') {
                $iconLinked = $true
            }
        }
    }
    if (-not $themeLinked) {
        Add-Issue 'ERROR' 'THEME_NOT_CONNECTED' 'Tema institucional não está ligado em um ResourceDictionary XAML real.' $root
    }
    if (-not $iconLinked) {
        Add-Issue 'ERROR' 'ICON_NOT_CONNECTED' 'ICO não está ligado ao atributo Icon de uma janela XAML real.' $root
    }
    if (-not $logoLinked) {
        Add-Issue 'ERROR' 'LOGO_NOT_CONNECTED' 'PNG não está ligado ao Source de um elemento XAML real.' $root
    }
}

$errors = @($issues | Where-Object { $_.severity -eq 'ERROR' }).Count
$warnings = @($issues | Where-Object { $_.severity -eq 'WARNING' }).Count
$xamlStatus = if ($xamlFiles.Count -gt 0) { 'CHECKED' } else { 'NOT_PRESENT' }
$validationStatus = if ($errors -gt 0) { 'STATIC_ERROR' } elseif ($warnings -gt 0) { 'STATIC_WARNING' } else { 'STATIC_OK' }
$entrypointStatus = if ($entrypointFiles.Count -gt 0 -or $shellEntrypoints.Count -gt 0) { 'FOUND' } else { 'MISSING' }
$result = [ordered]@{
    schema = 'wpf.app.static-validation.v2'
    validation_scope = 'DETERMINISTIC_PARSE_STRUCTURE_AND_TARGETED_HEURISTICS'
    app_root = $root
    generated_at = (Get-Date).ToString('o')
    brand_profile_required = [bool]$RequireBrandAssets
    entrypoint_status = $entrypointStatus
    entrypoints = @($entrypointFiles + $shellEntrypoints | ForEach-Object { $_.FullName })
    checks = [ordered]@{
        powershell = $psParseStatus
        r = $rParseStatus
        csharp = $csharpStatus
        xaml = $xamlStatus
    }
    status = $validationStatus
    release_gate_passed = $false
    errors = $errors
    warnings = $warnings
    issues = $issues.ToArray()
    unverified_release_gates = @(
        'Comportamento e resultado de negócio',
        'Locks, idempotência e efeitos externos',
        'QA em janela WPF real',
        'Homologação operacional'
    )
}
$result | ConvertTo-Json -Depth 8
if ($errors -gt 0) { exit 1 }
