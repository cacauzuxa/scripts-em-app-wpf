# Encoding: UTF-8; Windows PowerShell 5.1 reads this file with -Encoding UTF8.
[CmdletBinding()]
param(
    [string]$AppTitle,
    [string]$AppSubtitle = 'Interface pronta para conectar um fluxo existente.',
    [string]$ShellPath
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase

if ([string]::IsNullOrWhiteSpace($ShellPath)) {
    $ShellPath = Join-Path $PSScriptRoot 'AppShell.xaml'
}
if ([string]::IsNullOrWhiteSpace($AppTitle)) {
    $environmentTitle = [Environment]::GetEnvironmentVariable('WPF_APP_TITLE')
    $AppTitle = if ([string]::IsNullOrWhiteSpace($environmentTitle)) { 'Aplicativo WPF' } else { [string]$environmentTitle }
}

function Set-TextIfPresent {
    param(
        [Parameter(Mandatory = $true)] [System.Windows.Window]$Window,
        [Parameter(Mandatory = $true)] [string]$Name,
        [Parameter(Mandatory = $true)] [string]$Text
    )
    $element = $Window.FindName($Name)
    if ($null -ne $element -and $element.PSObject.Properties['Text']) {
        # Set the WPF property after parsing; values can never become XAML markup.
        $element.Text = [string]$Text
    }
}

if (-not (Test-Path -LiteralPath $ShellPath -PathType Leaf)) {
    throw ('AppShell.xaml não encontrado: ' + $ShellPath)
}

$shellFullPath = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $ShellPath).Path)
$parserContext = New-Object Windows.Markup.ParserContext
$parserContext.BaseUri = [Uri]$shellFullPath
$xamlStream = $null
$window = $null
try {
    $xamlStream = [IO.File]::OpenRead($shellFullPath)
    $window = [Windows.Markup.XamlReader]::Load($xamlStream, $parserContext)
    $window.Title = [string]$AppTitle
    Set-TextIfPresent -Window $window -Name 'AppTitleText' -Text $AppTitle
    Set-TextIfPresent -Window $window -Name 'AppSubtitleText' -Text $AppSubtitle

    # Bootstrap visual mínimo: a camada de negócio entra por composição posterior.
    $window.FindName('StatusTitle').Text = 'Pronto'
    $window.FindName('StatusDetail').Text = 'Aguardando início'
    $window.FindName('OverallProgress').Value = 0
    $window.FindName('ProgressText').Text = '0% · Não iniciado'

    $testMode = $env:WPF_APP_BOOTSTRAP_TEST -eq '1'
    if ($testMode) {
        # Isolated smoke tests show the real window briefly, then close synchronously.
        $window.Show()
        $observationPath = [Environment]::GetEnvironmentVariable('WPF_APP_BOOTSTRAP_OBSERVATION_PATH')
        if (-not [string]::IsNullOrWhiteSpace($observationPath)) {
            $observationFullPath = [IO.Path]::GetFullPath($observationPath)
            $scriptRootFullPath = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\') + '\'
            if (-not $observationFullPath.StartsWith($scriptRootFullPath, [StringComparison]::OrdinalIgnoreCase)) {
                throw 'O arquivo de observação do smoke test deve ficar dentro da fixture.'
            }
            $observation = [ordered]@{
                title = [string]$window.Title
                subtitle = [string]$window.FindName('AppSubtitleText').Text
            }
            $observationParent = Split-Path -Parent $observationFullPath
            if ($observationParent -and -not (Test-Path -LiteralPath $observationParent)) {
                New-Item -ItemType Directory -Path $observationParent -Force | Out-Null
            }
            [IO.File]::WriteAllText($observationFullPath, ($observation | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding($false)))
        }
        $window.Close()
    } else {
        [void]$window.ShowDialog()
    }
    exit 0
}
finally {
    if ($null -ne $xamlStream) { $xamlStream.Dispose() }
    if ($null -ne $window) {
        $window.Resources.MergedDictionaries.Clear()
        $window.Icon = $null
    }
}
