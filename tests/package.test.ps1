# Testes do package.ps1 em pasta temporaria.
# Uso: pwsh -NoProfile -File tests/package.test.ps1   (ou powershell -ExecutionPolicy Bypass -File ...)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$Root = Split-Path $PSScriptRoot -Parent
$Packager = Join-Path $Root 'package.ps1'
$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("pkg-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $Tmp | Out-Null
$script:Pass = 0
$script:Fail = 0

function Check($Name, $Cond) {
    if ($Cond) { $script:Pass++ } else { $script:Fail++; Write-Host "FALHOU: $Name" }
}
function Run-Package($Out, $SkillArgs) {
    $env:OUT = $Out
    try { & $Packager @SkillArgs *>&1 | Out-String | Out-Null; return $LASTEXITCODE } finally { Remove-Item Env:OUT }
}
function Get-Entries($Zip) {
    $A = [IO.Compression.ZipFile]::OpenRead($Zip)
    try { @($A.Entries | ForEach-Object { $_.FullName }) } finally { $A.Dispose() }
}

try {
    $Out = Join-Path $Tmp 'todas'
    Run-Package $Out @() | Out-Null
    $Skills = @(Get-ChildItem (Join-Path $Root '.claude\skills') -Directory | ForEach-Object { $_.Name })
    foreach ($S in $Skills) {
        $Zip = Join-Path $Out "$S.zip"
        if (-not (Test-Path $Zip)) { Check "${S}: zip criado" $false; continue }
        $E = Get-Entries $Zip
        Check "${S}: tem $S/SKILL.md" ($E -contains "$S/SKILL.md")
        Check "${S}: tudo dentro de $S/" (@($E | Where-Object { -not $_.StartsWith("$S/") }).Count -eq 0)
        Check "${S}: sem barra invertida" (@($E | Where-Object { $_.Contains('\') }).Count -eq 0)
    }
    Check 'frontend-design com LICENSE.txt' ((Get-Entries (Join-Path $Out 'frontend-design.zip')) -contains 'frontend-design/LICENSE.txt')
    Check 'webapp-testing com scripts' ((Get-Entries (Join-Path $Out 'webapp-testing.zip')) -contains 'webapp-testing/scripts/with_server.py')

    $Out = Join-Path $Tmp 'uma'
    Run-Package $Out @('analise-dados') | Out-Null
    Check 'argumento limita a uma skill' (@(Get-ChildItem $Out).Count -eq 1 -and (Test-Path (Join-Path $Out 'analise-dados.zip')))

    $Code = Run-Package (Join-Path $Tmp 'x') @('nao-existe')
    Check 'skill inexistente da erro' ($Code -ne 0)
}
finally {
    Remove-Item -Recurse -Force $Tmp
}

Write-Host "passou: $script:Pass  falhou: $script:Fail"
if ($script:Fail -gt 0) { exit 1 }
