# Encoding: UTF-8; Windows PowerShell 5.1 reads this file with -Encoding UTF8.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,
    [string]$OutputJson,
    [switch]$IncludeAbsolutePaths
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path
$rootComparison = $resolvedRoot.TrimEnd('\')
$extensions = @(
    '.r', '.ps1', '.psm1', '.psd1', '.bat', '.cmd', '.cs',
    '.js', '.mjs', '.cjs', '.vbs',
    '.json', '.xml', '.xaml', '.xlsx', '.xlsm', '.xls', '.csv',
    '.txt', '.md', '.pdf', '.docx', '.db', '.sqlite'
)
$scriptExtensions = @('.r', '.ps1', '.psm1', '.psd1', '.bat', '.cmd', '.cs', '.js', '.mjs', '.cjs', '.vbs')
$callPattern = '(?i)\b(source|sys\.source|system2|system)\s*\(|\b(start-process|powershell|pwsh|rscript|cmd(?:\.exe)?|cscript|wscript|shell)\b|\.\s+'
$secretPattern = '(?i)(\b(?:password|senha|token|secret|credential|api[_-]?key|client[_-]?secret|clientsecret)\b\s*(?:=|:)\s*|--(?:password|senha|token|secret|credential|api[_-]?key|client[_-]?secret|clientsecret)\s+)(?:"[^"]*"|''[^'']*''|[^\r\n;,)]+)'
$absolutePathPattern = '(?i)(?<![A-Za-z0-9_])(?:[A-Z]:[\\/]|\\\\)[^"\r\n;,)]+'
$readErrors = New-Object 'System.Collections.Generic.List[object]'

function ConvertTo-SafeText {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return $null }
    $safe = [regex]::Replace($Text, $secretPattern, '$1[REDACTED]')
    if (-not $IncludeAbsolutePaths) {
        $safe = [regex]::Replace($safe, $absolutePathPattern, '[ABSOLUTE_PATH_REDACTED]')
    }
    return $safe
}

function Test-UnderRoot {
    param([string]$AbsolutePath)
    $candidate = [IO.Path]::GetFullPath($AbsolutePath)
    if ($candidate.Equals($rootComparison, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    $prefix = $rootComparison
    if (-not $prefix.EndsWith('\', [StringComparison]::Ordinal)) { $prefix += '\' }
    return $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
}

function Get-DisplayPath {
    param([string]$AbsolutePath)
    $normalized = [IO.Path]::GetFullPath($AbsolutePath)
    if ($IncludeAbsolutePaths) { return (ConvertTo-SafeText $normalized) }
    if (Test-UnderRoot $normalized) {
        $prefix = $rootComparison
        if (-not $prefix.EndsWith('\', [StringComparison]::Ordinal)) { $prefix += '\' }
        if ($normalized.Equals($rootComparison, [StringComparison]::OrdinalIgnoreCase)) { return '.' }
        return $normalized.Substring($prefix.Length).TrimStart('\')
    }
    return '[external]\' + [IO.Path]::GetFileName($normalized)
}

function Get-DisplayValue {
    param([string]$Value)
    if ([String]::IsNullOrWhiteSpace($Value)) { return $Value }
    try {
        if ([IO.Path]::IsPathRooted($Value)) { return (Get-DisplayPath $Value) }
    } catch {
        # Keep the value below sanitized when it is not a valid filesystem path.
    }
    return (ConvertTo-SafeText $Value)
}

$files = @(
    Get-ChildItem -LiteralPath $resolvedRoot -File -Recurse -Force -ErrorAction Stop |
        Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } |
        ForEach-Object {
            $currentFile = $_
            $relative = Get-DisplayPath $currentFile.FullName
            $calls = New-Object 'System.Collections.Generic.List[object]'
            $hash = $null
            try {
                $hash = (Get-FileHash -LiteralPath $currentFile.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            } catch {
                [void]$readErrors.Add([ordered]@{
                        path = $relative
                        operation = 'HASH'
                        error = ConvertTo-SafeText $_.Exception.Message
                    })
            }

            if ($scriptExtensions -contains $currentFile.Extension.ToLowerInvariant()) {
                try {
                    $lines = @(Get-Content -LiteralPath $currentFile.FullName -Encoding UTF8 -ErrorAction Stop)
                } catch {
                    $lines = @()
                    [void]$readErrors.Add([ordered]@{
                            path = $relative
                            operation = 'READ'
                            error = ConvertTo-SafeText $_.Exception.Message
                        })
                }
                for ($index = 0; $index -lt $lines.Count; $index++) {
                    $line = [string]$lines[$index]
                    if ($line -notmatch $callPattern) { continue }
                    $candidates = New-Object 'System.Collections.Generic.List[object]'
                    foreach ($match in [regex]::Matches($line, '["'']([^"'']+)["'']')) {
                        $value = $match.Groups[1].Value
                        if ($value -notmatch '(?i)\.(r|ps1|psm1|psd1|bat|cmd|cs|js|mjs|cjs|vbs|exe)$') { continue }
                        try {
                            if ([IO.Path]::IsPathRooted($value)) {
                                $candidate = $value
                            } else {
                                $candidate = Join-Path $currentFile.DirectoryName $value
                            }
                            $resolvedCandidate = [IO.Path]::GetFullPath($candidate)
                            [void]$candidates.Add([ordered]@{
                                    raw = Get-DisplayValue $value
                                    target = Get-DisplayPath $resolvedCandidate
                                    exists = Test-Path -LiteralPath $resolvedCandidate
                                })
                        } catch {
                            [void]$candidates.Add([ordered]@{
                                    raw = Get-DisplayValue $value
                                    target = $null
                                    exists = $false
                                    resolution_error = ConvertTo-SafeText $_.Exception.Message
                                })
                        }
                    }
                    [void]$calls.Add([ordered]@{
                            line = $index + 1
                            text = ConvertTo-SafeText $line.Trim()
                            target_candidates = $candidates.ToArray()
                        })
                }
            }

            [ordered]@{
                path = $relative
                extension = $currentFile.Extension
                size = $currentFile.Length
                modified_at = $currentFile.LastWriteTime.ToString('o')
                sha256 = $hash
                possible_calls = $calls.ToArray()
            }
        }
)

$result = [ordered]@{
    schema = 'wpf.flow.inventory.v2'
    completeness = if ($readErrors.Count -gt 0) { 'INCOMPLETE_READ_ERRORS' } else { 'HEURISTIC_REQUIRES_MANUAL_TRANSITIVE_CONFIRMATION' }
    root = if ($IncludeAbsolutePaths) { Get-DisplayPath $resolvedRoot } else { '.' }
    absolute_paths_included = [bool]$IncludeAbsolutePaths
    generated_at = (Get-Date).ToString('o')
    effect = if ($OutputJson) { 'READ_AND_WRITE_MANIFEST' } else { 'READ_ONLY' }
    file_count = $files.Count
    files = @($files)
    read_errors = $readErrors.ToArray()
    limitations = @(
        'Chamadas construídas dinamicamente, aliases e resolução por variáveis podem não ser resolvidos.',
        'Candidatos são identificados por extensão e texto; a existência do arquivo não confirma que ele é executado.',
        'Caminhos externos e absolutos são redigidos por padrão; use -IncludeAbsolutePaths somente em manifesto local controlado.',
        'Este manifesto não substitui a confirmação manual da cadeia transitiva, dos comentários e das dependências implícitas.'
    )
}

$json = $result | ConvertTo-Json -Depth 10
if ($OutputJson) {
    $parent = Split-Path -Parent $OutputJson
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputJson), $json, $utf8)
}
$json
