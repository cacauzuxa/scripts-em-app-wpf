[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,
    [string]$OutputJson
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
$extensions = @('.r', '.rmd', '.rds', '.ps1', '.psm1', '.bat', '.cmd', '.cs', '.json', '.xml', '.xlsx', '.xlsm', '.xls', '.csv', '.txt', '.md', '.pdf', '.docx', '.db', '.sqlite')
$callPattern = '(?i)\b(source|sys\.source|system2|system|shell|start-process|powershell|pwsh|rscript|cmd(?:\.exe)?|cscript|wscript)\b|\.\s+["'']'
$secretPattern = '(?i)(password|senha|token|secret|credential|api[_-]?key)'

$files = Get-ChildItem -LiteralPath $resolvedRoot -File -Recurse -Force |
    Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } |
    ForEach-Object {
        $currentFile = $_
        $relative = $currentFile.FullName.Substring($resolvedRoot.Length).TrimStart('\')
        $hash = (Get-FileHash -LiteralPath $currentFile.FullName -Algorithm SHA256).Hash
        $calls = @()

        if ($currentFile.Extension.ToLowerInvariant() -in @('.r', '.ps1', '.psm1', '.bat', '.cmd', '.cs')) {
            $lineNumber = 0
            foreach ($line in (Get-Content -LiteralPath $currentFile.FullName -ErrorAction SilentlyContinue)) {
                $lineNumber++
                if ($line -match $callPattern -and $line -notmatch $secretPattern) {
                    $quoted = [regex]::Matches($line, '["'']([^"'']+)["'']') | ForEach-Object { $_.Groups[1].Value }
                    $candidates = foreach ($value in $quoted) {
                        if ($value -match '\.(r|ps1|psm1|bat|cmd|exe)$') {
                            $candidate = if ([IO.Path]::IsPathRooted($value)) { $value } else { Join-Path $currentFile.DirectoryName $value }
                            [ordered]@{ raw = $value; resolved_candidate = [IO.Path]::GetFullPath($candidate); exists = Test-Path -LiteralPath $candidate }
                        }
                    }
                    $calls += [ordered]@{ line = $lineNumber; text = $line.Trim(); target_candidates = @($candidates) }
                }
            }
        }

        [ordered]@{
            path = $relative
            extension = $currentFile.Extension
            size = $currentFile.Length
            modified_at = $currentFile.LastWriteTime.ToString('o')
            sha256 = $hash
            possible_calls = $calls
        }
    }

$result = [ordered]@{
    schema = 'wpf.flow.inventory.v1'
    completeness = 'HEURISTIC_REQUIRES_MANUAL_TRANSITIVE_CONFIRMATION'
    root = $resolvedRoot
    generated_at = (Get-Date).ToString('o')
    effect = if ($OutputJson) { 'READ_AND_WRITE_MANIFEST' } else { 'READ_ONLY' }
    file_count = @($files).Count
    files = @($files)
    limitations = @(
        'Chamadas construídas dinamicamente podem não ser resolvidas.',
        'Caminhos externos ao root aparecem apenas quando são literais detectáveis.',
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
