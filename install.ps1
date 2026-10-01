# Instala o orquestrador no nível do usuário (~\.claude), valendo para todos os projetos.
# Uso: powershell -ExecutionPolicy Bypass -File .\install.ps1   (destino: ~\.claude; ou defina $env:CLAUDE_HOME)
$ErrorActionPreference = 'Stop'

$Src = $PSScriptRoot
$Dest = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME '.claude' }
$Dest = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Dest)
$Utf8 = New-Object Text.UTF8Encoding $false
$Backup = Join-Path $Dest ("backup-orquestrador-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))

# Copia src para dst; se dst existir com conteúdo diferente, guarda cópia no backup.
function Install-File($SrcFile, $Rel) {
    $Dst = Join-Path $Dest $Rel
    if ((Test-Path -LiteralPath $Dst) -and ((Get-FileHash -LiteralPath $SrcFile).Hash -ne (Get-FileHash -LiteralPath $Dst).Hash)) {
        $Bak = Join-Path $Backup $Rel
        New-Item -ItemType Directory -Force (Split-Path $Bak) | Out-Null
        Copy-Item -LiteralPath $Dst $Bak
        Write-Host "  backup: $Rel"
    }
    New-Item -ItemType Directory -Force (Split-Path $Dst) | Out-Null
    Copy-Item -LiteralPath $SrcFile $Dst -Force
    Write-Host "  ok: $Rel"
}

Write-Host "Instalando em $Dest"
New-Item -ItemType Directory -Force $Dest | Out-Null

Install-File (Join-Path $Src 'CLAUDE.md') 'CLAUDE.md'
Get-ChildItem (Join-Path $Src '.claude\agents\*.md') | ForEach-Object {
    Install-File $_.FullName (Join-Path 'agents' $_.Name)
}
$SkillsRoot = Join-Path $Src '.claude'
Get-ChildItem -LiteralPath (Join-Path $SkillsRoot 'skills') -Recurse -File | ForEach-Object {
    Install-File $_.FullName $_.FullName.Substring($SkillsRoot.Length + 1)
}

# settings.json: junta deny/ask às regras existentes, sem apagar nada do usuário.
$Settings = Join-Path $Dest 'settings.json'
$SrcSettings = Join-Path $Src '.claude\settings.json'
if (-not (Test-Path -LiteralPath $Settings)) {
    Copy-Item $SrcSettings $Settings
    Write-Host "  ok: settings.json (novo)"
} else {
    # Lê como UTF-8 explícito (o PS 5.1 assume ANSI). No PS 7.5+, -DateKind String evita converter datas.
    $JsonArgs = @{}
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { $JsonArgs.DateKind = 'String' }
    $DstJson = [IO.File]::ReadAllText($Settings, $Utf8) | ConvertFrom-Json @JsonArgs
    $SrcJson = [IO.File]::ReadAllText($SrcSettings, $Utf8) | ConvertFrom-Json @JsonArgs
    if (-not $DstJson.permissions) {
        $DstJson | Add-Member -NotePropertyName permissions -NotePropertyValue ([pscustomobject]@{})
    }
    $Added = 0
    foreach ($Key in 'deny', 'ask') {
        $Cur = @($DstJson.permissions.$Key | Where-Object { $_ })
        $New = @($SrcJson.permissions.$Key | Where-Object { $Cur -cnotcontains $_ })
        $Added += $New.Count
        $DstJson.permissions | Add-Member -NotePropertyName $Key -NotePropertyValue ($Cur + $New) -Force
    }
    if ($Added -eq 0) {
        Write-Host "  ok: settings.json (já atualizado)"
    } else {
        New-Item -ItemType Directory -Force $Backup | Out-Null
        Copy-Item -LiteralPath $Settings (Join-Path $Backup 'settings.json')
        Write-Host "  backup: settings.json"
        # UTF-8 sem BOM: o Windows PowerShell 5.1 grava BOM com -Encoding UTF8, e o JSON pode falhar ao carregar.
        [IO.File]::WriteAllText($Settings, ($DstJson | ConvertTo-Json -Depth 20), $Utf8)
        Write-Host "  ok: settings.json (permissões mescladas)"
    }
}

if (Test-Path -LiteralPath $Backup) { Write-Host "Backup dos arquivos substituídos: $Backup" }
Write-Host "Pronto. Remova o CLAUDE.md da raiz dos projetos que tinham cópia dele, para não carregar as regras em dobro."
