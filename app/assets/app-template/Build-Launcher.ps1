# Encoding: UTF-8; Windows PowerShell 5.1 reads this file with -Encoding UTF8.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [Parameter(Mandatory = $true)]
    [string]$IconPath,
    [Parameter(Mandatory = $true)]
    [string]$AppScript,
    [Parameter(Mandatory = $true)]
    [string]$AppTitle,
    [Parameter(Mandatory = $true)]
    [string]$MutexName
)

$ErrorActionPreference = 'Stop'

function Resolve-ExistingFile {
    param([string]$Path, [string]$Description)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw ($Description + ' não encontrado: ' + $Path)
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

$source = Resolve-ExistingFile -Path $SourcePath -Description 'Código C#'
$icon = Resolve-ExistingFile -Path $IconPath -Description 'Ícone ICO'
$output = [IO.Path]::GetFullPath($OutputPath)
$outputParent = Split-Path -Parent $output
if ($outputParent -and -not (Test-Path -LiteralPath $outputParent)) {
    New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
}

$templateText = [IO.File]::ReadAllText($source, [Text.Encoding]::UTF8)
function ConvertTo-CSharpLiteral {
    param([string]$Value)
    $escaped = $Value.Replace('\', '\\').Replace('"', '\"')
    $escaped = $escaped.Replace(([char]13).ToString(), '\r').Replace(([char]10).ToString(), '\n')
    return $escaped
}
$sourceText = $templateText.Replace('__APP_SCRIPT__', (ConvertTo-CSharpLiteral $AppScript))
$sourceText = $sourceText.Replace('__APP_TITLE__', (ConvertTo-CSharpLiteral $AppTitle))
$sourceText = $sourceText.Replace('__MUTEX_NAME__', (ConvertTo-CSharpLiteral $MutexName))
if ($sourceText -match '__APP_SCRIPT__|__APP_TITLE__|__MUTEX_NAME__') {
    throw 'A fonte temporária ainda contém placeholders do launcher.'
}
$temporarySource = Join-Path ([IO.Path]::GetTempPath()) ('wpf-launcher-' + [Guid]::NewGuid().ToString('N') + '.cs')
$sourceEncoding = New-Object System.Text.UTF8Encoding($true)

try {
    [IO.File]::WriteAllText($temporarySource, $sourceText, $sourceEncoding)

    $compiler = $null
    $command = Get-Command csc.exe -ErrorAction SilentlyContinue
    if ($command) {
        $compiler = $command.Source
    }
    if (-not $compiler) {
        $frameworkRoot = Join-Path $env:WINDIR 'Microsoft.NET\Framework'
        $compilerCandidates = @(Get-ChildItem -LiteralPath $frameworkRoot -Filter 'csc.exe' -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | Select-Object -ExpandProperty FullName)
        if ($compilerCandidates.Count -gt 0) {
            $compiler = $compilerCandidates[0]
        }
    }
    if (-not $compiler) {
        throw 'csc.exe não foi encontrado. Instale o .NET Framework 4.x Developer Tools ou informe csc.exe no PATH.'
    }

    $arguments = @(
        '/nologo',
        '/target:winexe',
        '/optimize+',
        '/reference:System.dll',
        '/reference:System.Windows.Forms.dll',
        ('/win32icon:' + $icon),
        ('/out:' + $output),
        $temporarySource
    )

    & $compiler @arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw ('Falha ao compilar o launcher (código ' + $exitCode + ').')
    }

    [ordered]@{
        status = 'COMPILED'
        compiler = $compiler
        template = $source
        icon = $icon
        output = $output
        app_script = $AppScript
        app_title = $AppTitle
        mutex_name = $MutexName
    } | ConvertTo-Json -Depth 3
} finally {
    if (Test-Path -LiteralPath $temporarySource) {
        [IO.File]::Delete($temporarySource)
    }
}
