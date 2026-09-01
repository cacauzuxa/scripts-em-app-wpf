[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,
    [string]$OutputJson,
    [switch]$IncludeAbsolutePaths
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')
$extensions = @('.r', '.ps1', '.psm1', '.bat', '.cmd', '.cs', '.json', '.xml', '.xaml', '.xlsx', '.xlsm', '.xls', '.csv', '.txt', '.md', '.pdf', '.docx', '.db', '.sqlite')
$callPattern = '(?i)\b(source|sys\.source|system2|system|shell|start-process|powershell|pwsh|rscript|cmd(?:\.exe)?|cscript|wscript)\b|\.\s+["'']'
$secretPattern = '(?i)(password|senha|token|secret|credential|api[_-]?key)'
$readErrors = [System.Collections.Generic.List[object]]::new()

function Get-DisplayPath {
    param([string]$AbsolutePath)
    if ($IncludeAbsolutePaths) { return $AbsolutePath }
    if ($AbsolutePath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $AbsolutePath.Substring($resolvedRoot.Length).TrimStart('\')
    }
    return '[external]\' + [IO.Path]::GetFileName($AbsolutePath)
}

$files = Get-ChildItem -LiteralPath $resolvedRoot -File -Recurse -Force |
    Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } |
    ForEach-Object {
        $currentFile = $_
        $relative = $currentFile.FullName.Substring($resolvedRoot.Length).TrimStart('\')
        $calls = @()
        $hash = $null
        try {
            $hash = (Get-FileHash -LiteralPath $currentFile.FullName -Algorithm SHA256).Hash
        } catch {
            $readErrors.Add([ordered]@{ path = $relative; operation = 'HASH'; error = $_.Exception.Message })
        }

        if ($currentFile.Extension.ToLowerInvariant() -in @('.r', '.ps1', '.psm1', '.bat', '.cmd', '.cs')) {
            try {
                $lines = @(Get-Content -LiteralPath $currentFile.FullName -ErrorAction Stop)
            } catch {
                $lines = @()
                $readErrors.Add([ordered]@{ path = $relative; operation = 'READ'; error = $_.Exception.Message })
            }
            for ($index = 0; $index -lt $lines.Count; $index++) {
                $line = $lines[$index]
                if ($line -notmatch $callPattern) { continue }
                $containsSecretMarker = $line -match $secretPattern
                $candidates = @()
                if (-not $containsSecretMarker) {
                    foreach ($match in [regex]::Matches($line, '["'']([^"'']+)["'']')) {
                        $value = $match.Groups[1].Value
                        if ($value -notmatch '\.(r|ps1|psm1|bat|cmd|exe)$') { continue }
                        try {
                            $candidate = if ([IO.Path]::IsPathRooted($value)) { $value } else { Join-Path $currentFile.DirectoryName $value }
                            $resolvedCandidate = [IO.Path]::GetFullPath($candidate)
                            $candidates += [ordered]@{
                                raw = $value
                                target = Get-DisplayPath $resolvedCandidate
                                exists = Test-Path -LiteralPath $resolvedCandidate
                            }
                        } catch {
                            $candidates += [ordered]@{ raw = $value; target = $null; exists = $false; resolution_error = $_.Exception.Message }
                        }
                    }
                }
                $calls += [ordered]@{
                    line = $index + 1
                    text = if ($containsSecretMarker) { '[REDACTED: linha contém marcador de segredo]' } else { $line.Trim() }
                    target_candidates = @($candidates)
                }
            }
        }

        [ordered]@{
            path = $relative
            extension = $currentFile.Extension
            size = $currentFile.Length
            modified_at = $currentFile.LastWriteTime.ToString('o')
            sha256 = $hash
            possible_calls = @($calls)
        }
    }

$result = [ordered]@{
    schema = 'wpf.flow.inventory.v2'
    completeness = if ($readErrors.Count -gt 0) { 'INCOMPLETE_READ_ERRORS' } else { 'HEURISTIC_REQUIRES_MANUAL_TRANSITIVE_CONFIRMATION' }
    root = if ($IncludeAbsolutePaths) { $resolvedRoot } else { '.' }
    absolute_paths_included = [bool]$IncludeAbsolutePaths
    generated_at = (Get-Date).ToString('o')
    effect = if ($OutputJson) { 'READ_AND_WRITE_MANIFEST' } else { 'READ_ONLY' }
    file_count = @($files).Count
    files = @($files)
    read_errors = @($readErrors)
    limitations = @(
        'Chamadas construídas dinamicamente podem não ser resolvidas.',
        'Caminhos externos são redigidos por padrão; use -IncludeAbsolutePaths somente em manifesto local controlado.',
        'Este manifesto não substitui a confirmação manual da cadeia transitiva.'
    )
}

$json = $result | ConvertTo-Json -Depth 8
if ($OutputJson) {
    $parent = Split-Path -Parent $OutputJson
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($OutputJson, $json, [System.Text.UTF8Encoding]::new($false))
}
$json
