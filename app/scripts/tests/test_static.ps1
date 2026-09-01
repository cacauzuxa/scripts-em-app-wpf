# Encoding: UTF-8; Windows PowerShell 5.1 reads this file with -Encoding UTF8.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('wpf-app-tests-' + [Guid]::NewGuid().ToString('N'))
$utf8 = New-Object System.Text.UTF8Encoding($false)
$failures = New-Object 'System.Collections.Generic.List[string]'
$loadedWindow = $null
$xamlStream = $null

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { [void]$failures.Add($Message) }
}

function Write-Utf8 {
    param([string]$Path, [string]$Content)
    [IO.File]::WriteAllText($Path, $Content, $utf8)
}

New-Item -ItemType Directory -Path $fixture -Force | Out-Null
try {
    foreach ($bomPath in @(
        (Join-Path $repo 'app\scripts\inventory_flow.ps1'),
        (Join-Path $repo 'app\scripts\validate_app.ps1'),
        (Join-Path $repo 'app\assets\app-template\Build-Launcher.ps1'),
        (Join-Path $repo 'app\scripts\tests\test_static.ps1')
    )) {
        $bomBytes = [IO.File]::ReadAllBytes($bomPath)
        Assert-True ($bomBytes.Length -ge 3 -and $bomBytes[0] -eq 0xEF -and $bomBytes[1] -eq 0xBB -and $bomBytes[2] -eq 0xBF) ('UTF-8 BOM ausente em ' + $bomPath)
    }
    foreach ($encodedPath in @(
        (Join-Path $repo 'app\scripts\inventory_flow.ps1'),
        (Join-Path $repo 'app\scripts\validate_app.ps1'),
        (Join-Path $repo 'app\assets\app-template\Build-Launcher.ps1'),
        (Join-Path $repo 'app\assets\app-template\AppShell.xaml'),
        (Join-Path $repo 'app\assets\app-template\BrandTheme.xaml')
    )) {
        $encodedText = [IO.File]::ReadAllText($encodedPath, [Text.Encoding]::UTF8)
        Assert-True ($encodedText -notmatch '�') ('mojibake encontrado em ' + $encodedPath)
    }
    $appShellText = [IO.File]::ReadAllText((Join-Path $repo 'app\assets\app-template\AppShell.xaml'), [Text.Encoding]::UTF8)
    $brandThemeText = [IO.File]::ReadAllText((Join-Path $repo 'app\assets\app-template\BrandTheme.xaml'), [Text.Encoding]::UTF8)
    Assert-True ($appShellText -match '<\?xml[^>]+encoding="utf-8"') 'AppShell sem declaração UTF-8'
    Assert-True ($brandThemeText -match '<\?xml[^>]+encoding="utf-8"') 'BrandTheme sem declaração UTF-8'

    $assets = Join-Path $fixture 'Assets'
    New-Item -ItemType Directory -Path $assets -Force | Out-Null
    Copy-Item (Join-Path $repo 'app\assets\app-template\AppShell.xaml') (Join-Path $fixture 'AppShell.xaml')
    Copy-Item (Join-Path $repo 'app\assets\app-template\BrandTheme.xaml') (Join-Path $assets 'BrandTheme.xaml')
    Copy-Item (Join-Path $repo 'app\assets\icone.ico') (Join-Path $assets 'icone.ico')
    Copy-Item (Join-Path $repo 'app\assets\icone.png') (Join-Path $assets 'icone.png')
    Copy-Item (Join-Path $repo 'app\assets\app-template\Launcher.cs') (Join-Path $fixture 'Launcher.cs')
    Write-Utf8 (Join-Path $fixture 'AppInterface.ps1') '$xaml = Join-Path $PSScriptRoot ''AppShell.xaml''; [Windows.Markup.XamlReader]::Parse([IO.File]::ReadAllText($xaml))'
    Write-Utf8 (Join-Path $fixture 'workflow.r') 'x <- 1'

    $validate = Join-Path $repo 'app\scripts\validate_app.ps1'
    $valid = & $validate -AppRoot $fixture -RequireBrandAssets | ConvertFrom-Json
    Assert-True ($valid.entrypoint_status -eq 'FOUND') 'entrypoint real não reconhecido'
    Assert-True ($valid.checks.csharp -eq 'CHECKED') 'C# não foi compilado'
    Assert-True ($valid.checks.r -in @('CHECKED', 'NOT_CHECKED')) 'status de parsing R inválido'
    Assert-True ($valid.release_gate_passed -eq $false) 'release gate foi indevidamente liberado'

    Add-Type -AssemblyName PresentationFramework
    $xamlPath = Join-Path $fixture 'AppShell.xaml'
    $parserContext = New-Object Windows.Markup.ParserContext
    $parserContext.BaseUri = [Uri]([IO.Path]::GetFullPath($xamlPath))
    $xamlStream = [IO.File]::OpenRead($xamlPath)
    $loadedWindow = [Windows.Markup.XamlReader]::Load($xamlStream, $parserContext)
    $xamlStream.Close()
    $xamlStream = $null
    Assert-True ($null -ne $loadedWindow.FindName('OverallProgress')) 'ProgressBar não carregou no AppShell real'
    Assert-True ($null -ne $loadedWindow.FindName('BrandLogo').Source) 'logo PNG não carregou via BaseUri'
    Assert-True ($null -ne $loadedWindow.Icon) 'ícone ICO não carregou via BaseUri'
    Assert-True ($loadedWindow.Resources.MergedDictionaries.Count -gt 0) 'tema não carregou via BaseUri'
    $contentGrid = $loadedWindow.Content
    $bodyGrid = $contentGrid.Children[1]
    $scrollCount = @($bodyGrid.Children | Where-Object { $_ -is [Windows.Controls.ScrollViewer] }).Count
    Assert-True ($scrollCount -eq 2) 'rolagem independente não está presente no AppShell'

    $canary = 'DO_NOT_LEAK_' + [Guid]::NewGuid().ToString('N')
    Write-Utf8 (Join-Path $fixture 'config.json') ('{"client_secret":"' + $canary + '"}')
    $secretResult = & $validate -AppRoot $fixture | ConvertFrom-Json
    $secretText = $secretResult | ConvertTo-Json -Depth 8
    Assert-True ($secretText -match 'SECRET_IN_JSON') 'client_secret não foi detectado'
    Assert-True ($secretText -notmatch [regex]::Escape($canary)) 'valor sensível apareceu no resultado'

    $commentXaml = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"><!-- Icon="Assets/icone.ico" --><!-- Source="Assets/icone.png" --><!-- Source="Assets/BrandTheme.xaml" --></Window>'
    Write-Utf8 (Join-Path $fixture 'AppShell.xaml') $commentXaml
    $commentResult = & $validate -AppRoot $fixture -RequireBrandAssets | ConvertFrom-Json
    $commentCodes = @($commentResult.issues | ForEach-Object { $_.code })
    Assert-True ($commentCodes -contains 'THEME_NOT_CONNECTED') 'comentário falso passou como tema'
    Assert-True ($commentCodes -contains 'ICON_NOT_CONNECTED') 'comentário falso passou como ícone'
    Assert-True ($commentCodes -contains 'LOGO_NOT_CONNECTED') 'comentário falso passou como logo'

    $invoke = Join-Path $fixture 'Invoke.ps1'
    $absolute = 'D:/Users/fixture folder/secret-token.ps1'
    $secretValue = 'value with spaces "quoted"'
    Write-Utf8 $invoke ('Start-Process "' + $absolute + '" --client_secret ''' + $secretValue + '''')
    foreach ($name in @('child.js', 'child.mjs', 'child.cjs', 'child.vbs', 'child.psd1')) {
        Write-Utf8 (Join-Path $fixture $name) ''
    }
    $inventory = Join-Path $repo 'app\scripts\inventory_flow.ps1'
    $inventoryResult = & $inventory -Root $fixture | ConvertFrom-Json
    $inventoryText = $inventoryResult | ConvertTo-Json -Depth 10
    Assert-True ($inventoryText -notmatch [regex]::Escape($absolute)) 'caminho absoluto apareceu no inventário'
    Assert-True ($inventoryText -notmatch [regex]::Escape($canary)) 'valor sensível apareceu no inventário'
    Assert-True ($inventoryText -notmatch [regex]::Escape($secretValue)) 'segredo quoted com espaços apareceu no inventário'
    Assert-True ($inventoryText -notmatch 'value with spaces') 'segredo quoted com espaços não foi consumido completamente'
    $invokeRecord = @($inventoryResult.files | Where-Object { $_.path -eq 'Invoke.ps1' })[0]
    Assert-True (@($invokeRecord.possible_calls[0].target_candidates).Count -gt 0) 'dependência foi descartada por marcador de segredo'
    Assert-True (@($inventoryResult.files | Where-Object { $_.path -match 'child\.(js|mjs|cjs|vbs|psd1)$' }).Count -eq 5) 'extensões adicionais não foram inventariadas'

    $built = Join-Path $fixture 'Launcher.exe'
    $build = Join-Path $repo 'app\assets\app-template\Build-Launcher.ps1'
    $buildParameters = @{
        SourcePath = Join-Path $repo 'app\assets\app-template\Launcher.cs'
        OutputPath = $built
        IconPath = Join-Path $repo 'app\assets\icone.ico'
        AppScript = 'Aplicativo\App Interface.ps1'
        AppTitle = 'Teste "turnkey"'
        MutexName = 'ScriptsEmAppWpf.Test'
    }
    $buildResult = & $build @buildParameters | ConvertFrom-Json
    Assert-True ($buildResult.status -eq 'COMPILED' -and (Test-Path -LiteralPath $built -PathType Leaf)) 'launcher não compilou com ICO'
    $builtText = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($built))
    Assert-True ($builtText -notmatch '__APP_SCRIPT__|__APP_TITLE__|__MUTEX_NAME__') 'exe final contém placeholder do launcher'
    Add-Type -AssemblyName System.Drawing
    $embeddedIcon = [Drawing.Icon]::ExtractAssociatedIcon($built)
    Assert-True ($null -ne $embeddedIcon) 'ICO não foi embutido no exe final'
    if ($null -ne $embeddedIcon) { $embeddedIcon.Dispose() }

    $missingSource = Join-Path $fixture 'missing-launcher-source.cs'
    $missingParameters = @{
        SourcePath = $missingSource
        OutputPath = Join-Path $fixture 'missing.exe'
        IconPath = Join-Path $repo 'app\assets\icone.ico'
        AppScript = 'AppInterface.ps1'
        AppTitle = 'Teste'
        MutexName = 'ScriptsEmAppWpf.Missing'
    }
    $missingOutput = @()
    try {
        $missingOutput = @(& $build @missingParameters 2>&1 | Out-String)
    } catch {
        $missingOutput = @($_ | Out-String)
    }
    $missingText = ($missingOutput -join [Environment]::NewLine)
    Assert-True ($missingText.IndexOf('Código C# não encontrado', [StringComparison]::Ordinal) -ge 0) 'erro de source inexistente perdeu o texto amigável'
    Assert-True ($missingText.IndexOf([char]0xC3) -lt 0) 'erro de source inexistente sofreu mojibake'

    Write-Utf8 (Join-Path $fixture 'Launcher.cs') 'class Broken {'
    $brokenResult = & $validate -AppRoot $fixture | ConvertFrom-Json
    Assert-True (@($brokenResult.issues | Where-Object { $_.code -eq 'CSHARP_COMPILE' }).Count -gt 0) 'C# inválido não foi reportado'

    if ($failures.Count -gt 0) {
        $failures | ForEach-Object { Write-Error $_ }
        exit 1
    }
    Write-Output 'PASS test_static.ps1'
    exit 0
} finally {
    if ($null -ne $xamlStream) {
        $xamlStream.Close()
        $xamlStream = $null
    }
    if ($null -ne $loadedWindow) {
        $loadedLogo = $loadedWindow.FindName('BrandLogo')
        if ($null -ne $loadedLogo) { $loadedLogo.Source = $null }
        $loadedWindow.Icon = $null
        $loadedWindow.Resources.MergedDictionaries.Clear()
        $loadedWindow.Close()
        $loadedWindow = $null
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    if (Test-Path -LiteralPath $fixture) {
        [IO.Directory]::Delete($fixture, $true)
    }
}
