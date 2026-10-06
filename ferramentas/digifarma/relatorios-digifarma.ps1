<#
.SYNOPSIS
Relatórios do Digifarma (banco Firebird). Só lê o banco: nunca altera nada.

.DESCRIPTION
-Mapa: grava um arquivo de texto com as tabelas e colunas do banco (só os nomes e tipos, nenhum dado
de cliente ou de venda). É o primeiro passo para montar os relatórios de vencimento, produtos parados,
curva ABC, margem etc.
Com -ContarLinhas, conta também as linhas de cada tabela (mais lento; só leitura).

.EXAMPLE
.\relatorios-digifarma.ps1 -Banco 'localhost:C:\Digifarma\Dados\Digifarma6.FDB' -Mapa -ContarLinhas
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Banco,
    [string]$Usuario = 'SYSDBA',
    [switch]$Mapa,
    [switch]$ContarLinhas,
    [string]$Isql,
    [string]$PastaSaida
)
$ErrorActionPreference = 'Stop'

$Utf8Bom = New-Object Text.UTF8Encoding $true
$Utf8Estrito = New-Object Text.UTF8Encoding $false, $true
$Ansi = [Text.Encoding]::GetEncoding(1252)
$script:Senha = $null

function Stop-Script([string]$Msg, [int]$Codigo = 1) {
    Write-Host "ERRO: $Msg"
    exit $Codigo
}

# Aspas no estilo da linha de comando do Windows (o caminho do banco pode ter espaços).
function Format-Arg([string]$A) {
    if ($A -notmatch '[\s"]') { return $A }
    return '"' + ($A -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Convert-Bytes([byte[]]$Bytes) {
    try { return $Utf8Estrito.GetString($Bytes) } catch { return $Ansi.GetString($Bytes) }
}

# Roda o isql sem janela; a senha vai por ISC_PASSWORD só para o processo filho, nunca na linha de comando.
function Start-Tool([string]$Exe, [string[]]$Argumentos) {
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    $psi.Arguments = ($Argumentos | ForEach-Object { Format-Arg $_ }) -join ' '
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    if ($script:Senha) { $psi.EnvironmentVariables['ISC_PASSWORD'] = $script:Senha }
    $p = [Diagnostics.Process]::Start($psi)
    $p.StandardInput.Close()
    $out = New-Object IO.MemoryStream
    $err = New-Object IO.MemoryStream
    $t1 = $p.StandardOutput.BaseStream.CopyToAsync($out)
    $t2 = $p.StandardError.BaseStream.CopyToAsync($err)
    $p.WaitForExit()
    $t1.Wait(); $t2.Wait()
    return [pscustomobject]@{ Codigo = $p.ExitCode; Saida = (Convert-Bytes $out.ToArray()); Erro = (Convert-Bytes $err.ToArray()) }
}

# Executa SQL só de leitura pelo isql (-b: para no primeiro erro) e devolve as linhas da saída.
function Invoke-Isql([string]$Sql) {
    $tmp = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllText($tmp, "SET HEADING OFF;`n$Sql`n", $Ansi)
        $r = Start-Tool $script:IsqlExe @('-b', '-q', '-ch', 'NONE', '-user', $Usuario, '-i', $tmp, $Banco)
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
    $msg = (($r.Erro -split "`r?`n") | Where-Object { $_.Trim() -and $_.Trim() -ne 'Rolling back work.' }) -join "`n"
    if ($r.Codigo -ne 0 -or $msg) { Stop-Script "o isql falhou (código $($r.Codigo)): $msg" }
    return $r.Saida -split "`r?`n"
}

# Linhas marcadas com '#<tag>|' viram vetores de campos; o resto da saída do isql é ignorado.
function Get-Rows($Linhas, [string]$Tag, [int]$Campos) {
    $prefixo = "#$Tag|"
    foreach ($l in $Linhas) {
        $l = $l.Trim()
        if (-not $l.StartsWith($prefixo, [StringComparison]::Ordinal)) { continue }
        $r = $l.Substring($prefixo.Length).Split('|')
        if ($r.Count -ne $Campos) { Stop-Script "resposta inesperada do banco (esperava $Campos campos, vieram $($r.Count)): $l" }
        , $r
    }
}

# Identificador SQL: nome comum vai como está; o resto entre aspas.
function Q([string]$Nome) {
    if ($Nome -cmatch '^[A-Z][A-Z0-9_$]*$') { return $Nome }
    return '"' + $Nome.Replace('"', '""') + '"'
}

function Find-Isql {
    if ($Isql) {
        if (-not (Test-Path -LiteralPath $Isql -PathType Leaf)) { Stop-Script "isql não encontrado em '$Isql'." }
        return (Resolve-Path -LiteralPath $Isql).Path
    }
    $cmd = Get-Command 'isql.exe', 'isql-fb' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if (-not $base) { continue }
        foreach ($padrao in @('Firebird\*\isql.exe', 'Firebird\*\bin\isql.exe')) {
            $achado = Get-ChildItem -Path (Join-Path $base $padrao) -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
            if ($achado) { return $achado.FullName }
        }
    }
    Stop-Script "isql do Firebird não encontrado. Informe o caminho com -Isql 'C:\...\isql.exe' (fica na pasta do Firebird instalado no servidor do Digifarma)."
}

# Tipo da coluna como se escreve no SQL (NUMERIC(15,2), VARCHAR(60)...).
function Format-Type([int]$Tipo, [int]$SubTipo, [int]$Escala, [int]$Precisao, [int]$Tamanho) {
    if ($Escala -lt 0 -and @(7, 8, 16, 27) -contains $Tipo) { return "NUMERIC($Precisao,$(-$Escala))" }
    switch ($Tipo) {
        7 { return 'SMALLINT' }
        8 { return 'INTEGER' }
        16 { return 'BIGINT' }
        10 { return 'FLOAT' }
        27 { return 'DOUBLE' }
        12 { return 'DATE' }
        13 { return 'TIME' }
        35 { return 'TIMESTAMP' }
        14 { return "CHAR($Tamanho)" }
        37 { return "VARCHAR($Tamanho)" }
        23 { return 'BOOLEAN' }
        261 { if ($SubTipo -eq 1) { return 'BLOB TEXTO' } else { return 'BLOB' } }
    }
    return "TIPO $Tipo"
}

if (-not $Mapa) { Stop-Script 'escolha o que gerar: por enquanto só -Mapa.' 2 }

$script:IsqlExe = Find-Isql
if (-not $env:ISC_PASSWORD) {
    $seg = Read-Host -AsSecureString "Senha do usuário $Usuario do Firebird"
    $script:Senha = (New-Object Management.Automation.PSCredential('u', $seg)).GetNetworkCredential().Password
}

# ---------- mapa do banco: só metadados (nomes e tipos), nenhum dado ----------
Write-Host "Lendo a estrutura do banco $Banco ..."
$linhas = Invoke-Isql @'
SELECT '#C|' || TRIM(rf.RDB$RELATION_NAME) || '|' || TRIM(rf.RDB$FIELD_NAME) || '|' ||
       CAST(f.RDB$FIELD_TYPE AS VARCHAR(5)) || '|' || CAST(COALESCE(f.RDB$FIELD_SUB_TYPE, 0) AS VARCHAR(5)) || '|' ||
       CAST(COALESCE(f.RDB$FIELD_SCALE, 0) AS VARCHAR(5)) || '|' || CAST(COALESCE(f.RDB$FIELD_PRECISION, 0) AS VARCHAR(5)) || '|' ||
       CAST(COALESCE(f.RDB$CHARACTER_LENGTH, f.RDB$FIELD_LENGTH, 0) AS VARCHAR(10)) || '|' ||
       CASE WHEN COALESCE(rf.RDB$NULL_FLAG, f.RDB$NULL_FLAG, 0) = 1 THEN 'S' ELSE 'N' END || '|' ||
       CASE WHEN f.RDB$COMPUTED_BLR IS NULL THEN 'N' ELSE 'S' END || '|' ||
       CASE WHEN r.RDB$VIEW_BLR IS NULL THEN 'T' ELSE 'V' END
FROM RDB$RELATION_FIELDS rf
JOIN RDB$RELATIONS r ON r.RDB$RELATION_NAME = rf.RDB$RELATION_NAME
JOIN RDB$FIELDS f ON f.RDB$FIELD_NAME = rf.RDB$FIELD_SOURCE
WHERE COALESCE(r.RDB$SYSTEM_FLAG, 0) = 0
ORDER BY rf.RDB$RELATION_NAME, rf.RDB$FIELD_POSITION;
SELECT '#K|' || TRIM(c.RDB$RELATION_NAME) || '|' || TRIM(s.RDB$FIELD_NAME)
FROM RDB$RELATION_CONSTRAINTS c
JOIN RDB$INDEX_SEGMENTS s ON s.RDB$INDEX_NAME = c.RDB$INDEX_NAME
WHERE c.RDB$CONSTRAINT_TYPE = 'PRIMARY KEY'
ORDER BY c.RDB$RELATION_NAME, s.RDB$FIELD_POSITION;
SELECT '#F|' || TRIM(c.RDB$RELATION_NAME) || '|' || TRIM(s.RDB$FIELD_NAME) || '|' || TRIM(c2.RDB$RELATION_NAME) || '|' || TRIM(s2.RDB$FIELD_NAME)
FROM RDB$RELATION_CONSTRAINTS c
JOIN RDB$REF_CONSTRAINTS rc ON rc.RDB$CONSTRAINT_NAME = c.RDB$CONSTRAINT_NAME
JOIN RDB$RELATION_CONSTRAINTS c2 ON c2.RDB$CONSTRAINT_NAME = rc.RDB$CONST_NAME_UQ
JOIN RDB$INDEX_SEGMENTS s ON s.RDB$INDEX_NAME = c.RDB$INDEX_NAME
JOIN RDB$INDEX_SEGMENTS s2 ON s2.RDB$INDEX_NAME = c2.RDB$INDEX_NAME AND s2.RDB$FIELD_POSITION = s.RDB$FIELD_POSITION
WHERE c.RDB$CONSTRAINT_TYPE = 'FOREIGN KEY'
ORDER BY c.RDB$RELATION_NAME, c.RDB$CONSTRAINT_NAME, s.RDB$FIELD_POSITION;
SELECT '#I|' || TRIM(i.RDB$RELATION_NAME) || '|' || TRIM(i.RDB$INDEX_NAME) || '|' || CAST(COALESCE(i.RDB$UNIQUE_FLAG, 0) AS VARCHAR(2)) || '|' || TRIM(s.RDB$FIELD_NAME)
FROM RDB$INDICES i
JOIN RDB$INDEX_SEGMENTS s ON s.RDB$INDEX_NAME = i.RDB$INDEX_NAME
WHERE COALESCE(i.RDB$SYSTEM_FLAG, 0) = 0
ORDER BY i.RDB$RELATION_NAME, i.RDB$INDEX_NAME, s.RDB$FIELD_POSITION;
SELECT '#P|' || TRIM(RDB$PROCEDURE_NAME) FROM RDB$PROCEDURES WHERE RDB$PROCEDURE_NAME NOT STARTING WITH 'RDB$' ORDER BY 1;
'@
$colunas = @(Get-Rows $linhas 'C' 10)
$chaves = @(Get-Rows $linhas 'K' 2)
$ligacoes = @(Get-Rows $linhas 'F' 4)
$indices = @(Get-Rows $linhas 'I' 4)
$procs = @(Get-Rows $linhas 'P' 1 | ForEach-Object { $_[0] })
if (-not $colunas) { Stop-Script 'o banco não tem tabelas de usuário. Confira o caminho em -Banco.' }

$tabelas = @($colunas | ForEach-Object { $_[0] } | Select-Object -Unique)
$ehVisao = @{}
foreach ($c in $colunas) { $ehVisao[$c[0]] = ($c[9] -eq 'V') }

$contagem = @{}
if ($ContarLinhas) {
    $soTabelas = @($tabelas | Where-Object { -not $ehVisao[$_] })
    Write-Host "Contando as linhas de $($soTabelas.Count) tabela(s) (só leitura; pode levar alguns minutos) ..."
    $sql = for ($i = 0; $i -lt $soTabelas.Count; $i++) { "SELECT '#N|$i|' || CAST(COUNT(*) AS VARCHAR(20)) FROM $(Q $soTabelas[$i]);" }
    foreach ($r in @(Get-Rows (Invoke-Isql ($sql -join "`n")) 'N' 2)) { $contagem[$soTabelas[[int]$r[0]]] = [long]$r[1] }
}

$txt = New-Object Text.StringBuilder
[void]$txt.AppendLine('MAPA DO BANCO DO DIGIFARMA')
[void]$txt.AppendLine('Só nomes e tipos de tabelas e colunas: nenhum dado de cliente, venda ou produto.')
[void]$txt.AppendLine("Banco: $Banco")
[void]$txt.AppendLine("Gerado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm')")
[void]$txt.AppendLine("Tabelas: $(@($tabelas | Where-Object { -not $ehVisao[$_] }).Count)   Visões: $(@($tabelas | Where-Object { $ehVisao[$_] }).Count)   Procedimentos: $($procs.Count)")
[void]$txt.AppendLine('Legenda: * chave primária, ! obrigatória, = calculada')
foreach ($t in $tabelas) {
    $pk = @($chaves | Where-Object { $_[0] -eq $t } | ForEach-Object { $_[1] })
    $tipoTab = if ($ehVisao[$t]) { 'visão' } else { 'tabela' }
    $qtd = if ($contagem.ContainsKey($t)) { ", $($contagem[$t].ToString('N0', [Globalization.CultureInfo]::GetCultureInfo('pt-BR'))) linha$(if ($contagem[$t] -ne 1) { 's' })" } else { '' }
    [void]$txt.AppendLine('')
    [void]$txt.AppendLine("== $t  [$tipoTab$qtd]")
    foreach ($c in @($colunas | Where-Object { $_[0] -eq $t })) {
        $marca = $(if ($pk -contains $c[1]) { '*' } else { ' ' }) + $(if ($c[7] -eq 'S') { '!' } else { ' ' }) + $(if ($c[8] -eq 'S') { '=' } else { ' ' })
        [void]$txt.AppendLine(('  {0} {1,-32} {2}' -f $marca, $c[1], (Format-Type ([int]$c[2]) ([int]$c[3]) ([int]$c[4]) ([int]$c[5]) ([int]$c[6]))))
    }
    $fks = @($ligacoes | Where-Object { $_[0] -eq $t })
    foreach ($f in $fks) { [void]$txt.AppendLine("     liga: $($f[1]) -> $($f[2]).$($f[3])") }
    $idx = @($indices | Where-Object { $_[0] -eq $t } | Group-Object { $_[1] })
    if ($idx) {
        $desc = $idx | ForEach-Object { "$(($_.Group | ForEach-Object { $_[3] }) -join '+')$(if ($_.Group[0][2] -eq '1') { ' (único)' })" }
        [void]$txt.AppendLine("     índices: $($desc -join '; ')")
    }
}
if ($procs) {
    [void]$txt.AppendLine('')
    [void]$txt.AppendLine("== PROCEDIMENTOS: $($procs -join ', ')")
}

if (-not $PastaSaida) { $PastaSaida = Join-Path $PSScriptRoot 'registros' }
New-Item -ItemType Directory -Force $PastaSaida | Out-Null
$arquivo = Join-Path (Resolve-Path -LiteralPath $PastaSaida).Path ("mapa-do-banco-$(Get-Date -Format 'yyyyMMdd-HHmm').txt")
[IO.File]::WriteAllText($arquivo, $txt.ToString(), $Utf8Bom)
Write-Host ''
Write-Host "Mapa gravado em: $arquivo"
Write-Host "($($tabelas.Count) tabelas e visões, $($colunas.Count) colunas.) Mande este arquivo na conversa para eu montar os relatórios."
if ($env:OS -eq 'Windows_NT') { Start-Process explorer.exe "/select,`"$arquivo`"" }
