# Testes do install.ps1 em pastas temporarias (nunca toca ~\.claude).
# Uso: pwsh -NoProfile -File tests/install.test.ps1   (ou powershell -ExecutionPolicy Bypass -File ...)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Installer = Join-Path $Root 'install.ps1'
$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("orq-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $Tmp | Out-Null
$Utf8 = New-Object Text.UTF8Encoding $false
$script:Pass = 0
$script:Fail = 0

function Check($Name, $Cond) {
    if ($Cond) { $script:Pass++ } else { $script:Fail++; Write-Host "FALHOU: $Name" }
}
function Run-Install($Dest) {
    $env:CLAUDE_HOME = $Dest
    try { & $Installer *>&1 | Out-String } finally { Remove-Item Env:CLAUDE_HOME }
}
function Read-Json($Path) { [IO.File]::ReadAllText($Path, $Utf8) | ConvertFrom-Json }

try {
    # Instalacao nova
    $H = Join-Path $Tmp 'novo'
    Run-Install $H | Out-Null
    $S = Read-Json (Join-Path $H 'settings.json')
    $Cmd = @($S.hooks.PreToolUse)[0].hooks[0].command
    $Fwd = $H -replace '\\', '/'
    Check 'novo: hook aponta para a instalacao' ($Cmd -eq ('bash "' + $Fwd + '/hooks/guard.sh"'))
    Check 'novo: sem CLAUDE_PROJECT_DIR' (-not ($Cmd -like '*CLAUDE_PROJECT_DIR*'))
    Check 'novo: sandbox ligado' ($S.sandbox.enabled -eq $true)
    Check 'novo: ask inclui retry fora do sandbox' (@($S.permissions.ask) -contains 'Bash(dangerouslyDisableSandbox:true)')
    Check 'novo: deny copiado' (@($S.permissions.deny).Count -gt 0)
    Check 'novo: guard.sh copiado' (Test-Path (Join-Path $H 'hooks\guard.sh'))
    Check 'novo: skill copiada' (Test-Path (Join-Path $H 'skills\discover-resources\decisoes.md'))

    # Mescla com settings do usuario
    $H = Join-Path $Tmp 'existente'
    New-Item -ItemType Directory -Force $H | Out-Null
    $UserJson = '{"model":"x","permissions":{"allow":["Bash(ls:*)"],"ask":["Bash(git push:*)"]},"sandbox":{"enabled":false},"hooks":{"PreToolUse":[{"matcher":"Edit","hooks":[{"type":"command","command":"echo meu"}]}]}}'
    [IO.File]::WriteAllText((Join-Path $H 'settings.json'), $UserJson, $Utf8)
    Run-Install $H | Out-Null
    $SPath = Join-Path $H 'settings.json'
    $S = Read-Json $SPath
    Check 'existente: mantem model' ($S.model -eq 'x')
    Check 'existente: mantem allow' ((@($S.permissions.allow) -join ',') -eq 'Bash(ls:*)')
    Check 'existente: mantem sandbox do usuario' ($S.sandbox.enabled -eq $false)
    $Cmds = @(@($S.hooks.PreToolUse) | ForEach-Object { $_.hooks[0].command })
    Check 'existente: mantem hook do usuario' ($Cmds[0] -eq 'echo meu')
    Check 'existente: acrescenta o guard' ($Cmds.Count -eq 2 -and $Cmds[1] -like '*/hooks/guard.sh"')
    $Ask = @($S.permissions.ask)
    Check 'existente: ask sem duplicata' ($Ask.Count -eq @($Ask | Select-Object -Unique).Count)
    Check 'existente: backup do settings' (@(Get-ChildItem $H -Directory -Filter 'backup-orquestrador-*').Count -ge 1)
    $Raw = [IO.File]::ReadAllBytes($SPath)
    Check 'existente: UTF-8 sem BOM' (-not ($Raw.Length -ge 3 -and $Raw[0] -eq 0xEF -and $Raw[1] -eq 0xBB -and $Raw[2] -eq 0xBF))

    # Reexecucao nao muda nada
    $Before = [IO.File]::ReadAllText($SPath, $Utf8)
    $Out = Run-Install $H
    Check 'reexecucao: settings ja atualizado' ($Out -match 'settings\.json \(j.{1,2} atualizado\)')
    Check 'reexecucao: arquivo igual' ([IO.File]::ReadAllText($SPath, $Utf8) -eq $Before)
}
finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}

Write-Host "passou: $script:Pass  falhou: $script:Fail"
if ($script:Fail -gt 0) { exit 1 }
