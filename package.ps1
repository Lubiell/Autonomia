# Empacota as skills de .claude\skills\ em zips para enviar ao claude.ai
# (Personalizar > Skills), onde valem no chat, no app de desktop e no Cowork.
# Uso: powershell -ExecutionPolicy Bypass -File .\package.ps1 [skill ...]   (sem argumento, todas)
# Saida: dist\<skill>.zip, com a pasta da skill no topo do zip, como o claude.ai exige.
# Pasta de saida: defina $env:OUT para mudar (padrao: dist\ na raiz do repositorio).
# Arquivo so em ASCII de proposito: o PowerShell 5.1 le .ps1 sem BOM como ANSI.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Src = Join-Path $PSScriptRoot '.claude\skills'
$Out = if ($env:OUT) { $env:OUT } else { Join-Path $PSScriptRoot 'dist' }
New-Item -ItemType Directory -Force $Out | Out-Null
$Out = (Resolve-Path -LiteralPath $Out).ProviderPath

$Names = if ($args.Count -gt 0) { @($args) } else { @(Get-ChildItem -LiteralPath $Src -Directory | ForEach-Object { $_.Name }) }

$Failed = $false
foreach ($Name in $Names) {
    $Dir = Join-Path $Src $Name
    $Skill = Join-Path $Dir 'SKILL.md'
    if (-not (Test-Path -LiteralPath $Skill)) { Write-Host "ERRO: ${Name}: nao existe $Skill"; $Failed = $true; continue }

    # name do primeiro bloco ---
    $Declared = ''; $Fence = 0
    foreach ($Line in [IO.File]::ReadAllLines($Skill)) {
        if ($Line.Trim() -eq '---') { $Fence++; if ($Fence -gt 1) { break }; continue }
        if ($Fence -eq 1 -and $Line -match '^name:\s*(.*?)\s*$') { $Declared = $Matches[1]; break }
    }
    if ($Declared -ne $Name) {
        Write-Host "ERRO: ${Name}: o SKILL.md declara name '$Declared'; o claude.ai recusa nome diferente da pasta"
        $Failed = $true; continue
    }

    $Zip = Join-Path $Out "$Name.zip"
    if (Test-Path -LiteralPath $Zip) { Remove-Item -LiteralPath $Zip }
    $Archive = [IO.Compression.ZipFile]::Open($Zip, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $Base = (Resolve-Path -LiteralPath $Dir).ProviderPath.TrimEnd('\', '/')
        Get-ChildItem -LiteralPath $Dir -Recurse -File -Force |
            Where-Object { $_.FullName -notmatch '[\\/]__pycache__[\\/]' -and $_.Extension -ne '.pyc' -and $_.Name -ne '.DS_Store' } |
            Sort-Object FullName |
            ForEach-Object {
                # Barra normal no nome da entrada: o Compress-Archive do 5.1 grava barra invertida.
                $Rel = $_.FullName.Substring($Base.Length + 1).Replace('\', '/')
                [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive, $_.FullName, "$Name/$Rel")
            }
    } finally { $Archive.Dispose() }
    Write-Host "ok: $Zip"
}

if ($Failed) { exit 1 }
Write-Host 'Envie em claude.ai > Personalizar > Skills > enviar skill, e ative cada uma.'
