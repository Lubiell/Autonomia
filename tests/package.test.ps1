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
    $Code = Run-Package (Join-Path $Tmp 'ok') @('analise-dados')
    Check 'sucesso sai com 0' ($Code -eq 0)

    # Copia do repositorio: lixo fora do zip, SKILL.md com BOM, name diferente da pasta
    $Repo = Join-Path $Tmp 'repo'
    New-Item -ItemType Directory -Force $Repo | Out-Null
    Copy-Item -Recurse (Join-Path $Root '.claude') $Repo
    Copy-Item $Packager $Repo
    $Copy = Join-Path $Repo 'package.ps1'
    $Sk = Join-Path $Repo '.claude\skills\analise-dados'
    New-Item -ItemType Directory -Force (Join-Path $Sk '__pycache__'), (Join-Path $Sk 'sub') | Out-Null
    foreach ($F in '__pycache__\a.pyc', 'x.pyc', '.DS_Store', 'sub\.DS_Store', 'sub\ok.md') { Set-Content -LiteralPath (Join-Path $Sk $F) 'x' }
    $SkillMd = Join-Path $Sk 'SKILL.md'
    $Text = [IO.File]::ReadAllText($SkillMd)
    [IO.File]::WriteAllText($SkillMd, $Text, (New-Object Text.UTF8Encoding $true))

    $Out = Join-Path $Tmp 'lixo'
    $env:OUT = $Out
    try { & $Copy 'analise-dados' *>&1 | Out-Null } finally { Remove-Item Env:OUT }
    $Zip = Join-Path $Out 'analise-dados.zip'
    if (Test-Path $Zip) {
        $E = Get-Entries $Zip
        Check 'lixo fora do zip' (@($E | Where-Object { $_ -match 'pycache|\.pyc$|DS_Store' }).Count -eq 0)
        Check 'arquivo comum em subpasta entra' ($E -contains 'analise-dados/sub/ok.md')
    } else { Check 'SKILL.md com BOM aceito' $false }

    [IO.File]::WriteAllText($SkillMd, ($Text -replace '(?m)^name: analise-dados', 'name: outro-nome'))
    $Out = Join-Path $Tmp 'errado'
    $env:OUT = $Out
    try { $Msg = & $Copy 'analise-dados' *>&1 | Out-String; $Code = $LASTEXITCODE } finally { Remove-Item Env:OUT }
    Check 'name diferente da pasta da erro' ($Code -ne 0 -and $Msg -match "declara name 'outro-nome'")
    Check 'name errado nao cria zip' (-not (Test-Path (Join-Path $Out 'analise-dados.zip')))
}
finally {
    Remove-Item -Recurse -Force $Tmp
}

Write-Host "passou: $script:Pass  falhou: $script:Fail"
if ($script:Fail -gt 0) { exit 1 }
