<#
.SYNOPSIS
Desmarca "Psicotrópico" (controlado) e "Antimicrobiano" no cadastro de produtos do Digifarma (banco Firebird).

.DESCRIPTION
Sem -Aplicar, só simula: mostra os produtos marcados (com estoque) e grava a lista em CSV. Nada é alterado.
Com -Escolher, abre a lista para escolher quais produtos desmarcar; com -Codigos, desmarca só os códigos informados.
Com -Estoque ComEstoque, mostra só os produtos com saldo em estoque.
Com -Aplicar: faz backup do banco (gbak), grava a lista e um script para desfazer, e desmarca numa única transação.
Usa o isql e o gbak que vêm com o Firebird; não instala nada.
Leia o README.md desta pasta antes de usar (há implicações no SNGPC).

.EXAMPLE
.\desmarcar-controlados.ps1 -Banco 'localhost:C:\Digifarma\Digifarma6.FDB' -Descobrir
.\desmarcar-controlados.ps1 -Banco 'localhost:C:\Digifarma\Digifarma6.FDB' -Estoque ComEstoque -Escolher
.\desmarcar-controlados.ps1 -Banco 'localhost:C:\Digifarma\Digifarma6.FDB' -Estoque ComEstoque -Escolher -Aplicar
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Banco,
    [string]$Usuario = 'SYSDBA',
    [switch]$Descobrir,
    [string]$Tabela,
    [string]$CampoPsicotropico,
    [string]$CampoAntimicrobiano,
    [ValidateSet('Ambos', 'Psicotropico', 'Antimicrobiano')][string]$Desmarcar = 'Ambos',
    [string]$ValorMarcado,
    [string]$ValorDesmarcado,
    [ValidateSet('Todos', 'ComEstoque', 'SemEstoque')][string]$Estoque = 'Todos',
    [string]$CampoEstoque,
    [string]$TabelaEstoque,
    [string]$ChaveEstoque,
    [switch]$Escolher,
    [string[]]$Codigos,
    [switch]$Aplicar,
    [switch]$Confirmar,
    [switch]$SemBackup,
    [string]$Isql,
    [string]$PastaSaida
)
$ErrorActionPreference = 'Stop'

$Utf8Bom = New-Object Text.UTF8Encoding $true
$Utf8Estrito = New-Object Text.UTF8Encoding $false, $true
$Ansi = [Text.Encoding]::GetEncoding(1252)
$TiposNumero = @(7, 8, 16)            # SMALLINT, INTEGER, BIGINT
$TiposTexto = @(14, 37)               # CHAR, VARCHAR
$TipoBoolean = 23
$TiposQtd = @(7, 8, 16, 10, 27)       # inteiros, NUMERIC/DECIMAL, FLOAT, DOUBLE
$NomesTipo = @{ 7 = 'SMALLINT'; 8 = 'INTEGER'; 16 = 'BIGINT'; 14 = 'CHAR'; 37 = 'VARCHAR'; 23 = 'BOOLEAN' }
# Pares (marcado, desmarcado) reconhecidos sozinhos; outros valores exigem -ValorMarcado/-ValorDesmarcado.
$ParesTexto = @(@('S', 'N'), @('T', 'F'), @('Y', 'N'), @('V', 'F'), @('1', '0'), @('s', 'n'))
$ParesNumero = @(@('1', '0'), @('-1', '0'))
# Colunas de estoque que não são o saldo (mínimo, máximo, datas, valores).
$NaoESaldo = 'MIN|MAX|IDEAL|SEGUR|REPOS|PEDID|ULT|DATA|DT_|VALOR|VLR|CUSTO|PRECO'
$script:LogFile = $null
$script:Senha = $null

function Write-Log([string]$Msg) {
    Write-Host $Msg
    if ($script:LogFile) {
        [IO.File]::AppendAllText($script:LogFile, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $Msg + [Environment]::NewLine, $Utf8Bom)
    }
}

function Stop-Script([string]$Msg, [int]$Codigo = 1) {
    Write-Log "ERRO: $Msg"
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

# Roda isql/gbak sem janela; a senha vai por ISC_PASSWORD só para o processo filho, nunca na linha de comando.
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

# Executa SQL pelo isql (-b: para no primeiro erro e não faz commit) e devolve as linhas da saída.
function Invoke-Isql([string]$Sql) {
    $tmp = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllText($tmp, "SET HEADING OFF;`n$Sql`n", $Ansi)
        $r = Start-Tool $script:IsqlExe @('-b', '-q', '-ch', 'NONE', '-user', $Usuario, '-i', $tmp, $Banco)
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
    # "Rolling back work." sai ao fechar a transação padrão do isql depois do COMMIT; não é erro.
    $msg = (($r.Erro -split "`r?`n") | Where-Object { $_.Trim() -and $_.Trim() -ne 'Rolling back work.' }) -join "`n"
    if ($r.Codigo -ne 0 -or $msg) {
        if ($msg -match 'lock conflict|deadlock|concurrent update') { $msg += "`nFeche o Digifarma em todos os computadores e rode de novo." }
        Stop-Script "o isql falhou (código $($r.Codigo)): $msg"
    }
    return $r.Saida -split "`r?`n"
}

# Linhas marcadas com '#<tag>|' viram vetores de campos; o resto da saída do isql é ignorado.
function Get-Rows($Linhas, [string]$Tag) {
    $prefixo = "#$Tag|"
    foreach ($l in $Linhas) {
        $l = $l.Trim()
        if ($l.StartsWith($prefixo, [StringComparison]::Ordinal)) { , ($l.Substring($prefixo.Length).Split('|')) }
    }
}

# Identificador SQL: nome comum vai como está; o resto entre aspas.
function Q([string]$Nome) {
    if ($Nome -cmatch '^[A-Z][A-Z0-9_$]*$') { return $Nome }
    return '"' + $Nome.Replace('"', '""') + '"'
}

# Literal SQL conforme o tipo da coluna.
function L($Col, [string]$V) {
    if ($Col.Tipo -eq $TipoBoolean) {
        if ($V -notmatch '^(TRUE|FALSE)$') { Stop-Script "$($Col.Campo) é BOOLEAN; use TRUE ou FALSE, não '$V'." }
        return $V.ToUpper()
    }
    if ($TiposNumero -contains $Col.Tipo) {
        if ($V -notmatch '^-?\d+$') { Stop-Script "$($Col.Campo) é numérico; '$V' não é número." }
        return $V
    }
    return "'" + $V.Replace("'", "''") + "'"
}

function Get-Kind([string]$Campo) {
    if ($Campo -match 'PSICO|CONTROLAD') { return 'Psicotropico' }
    if ($Campo -match 'ANTIMIC|ANTIBIO') { return 'Antimicrobiano' }
    if ($Campo -match 'TERAPEUT|SNGPC|PORTARIA') { return 'Outro' }
    return $null
}

function Test-FlagType($Col) {
    if ($Col.Calculado) { return $false }
    if ($Col.Tipo -eq $TipoBoolean -or $TiposTexto -contains $Col.Tipo) { return $true }
    return ($TiposNumero -contains $Col.Tipo -and $Col.Escala -eq 0)
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

function Format-Values($Col) {
    if (-not $Col.Valores) { return '(tabela vazia)' }
    $txt = ($Col.Valores | ForEach-Object { if ($_.Nulo) { "(vazio)=$($_.Qtd)" } else { "'$($_.Valor)'=$($_.Qtd)" } }) -join '  '
    if (@($Col.Valores).Count -ge 20) { $txt += '  ... (muitos valores: não parece caixa de marcar)' }
    return $txt
}

# Distribuição de valores de cada coluna (no máximo 20 valores distintos por coluna).
function Add-Values($Cols) {
    $Cols = @($Cols)
    if (-not $Cols) { return }
    $sql = for ($i = 0; $i -lt $Cols.Count; $i++) {
        $c = Q $Cols[$i].Campo
        "SELECT FIRST 20 '#V|$i|' || CASE WHEN $c IS NULL THEN '1' ELSE '0' END || '|' || COALESCE(TRIM(CAST($c AS VARCHAR(100))), '') || '|' || CAST(COUNT(*) AS VARCHAR(20)) FROM $(Q $Cols[$i].Tabela) GROUP BY $c;"
    }
    $linhas = Invoke-Isql ($sql -join "`n")
    foreach ($c in $Cols) { $c.Valores = @() }
    foreach ($r in @(Get-Rows $linhas 'V')) {
        $Cols[[int]$r[0]].Valores += [pscustomobject]@{ Nulo = ($r[1] -eq '1'); Valor = $r[2]; Qtd = [long]$r[3] }
    }
}

# Descobre o par (marcado, desmarcado) pelos valores que existem na coluna.
# Devolve: literal SQL marcado, literal SQL desmarcado, texto do valor marcado como o isql o mostra.
function Resolve-Pair($Col) {
    if ($ValorMarcado) {
        $par = @($ValorMarcado, $ValorDesmarcado)
    } elseif ($Col.Tipo -eq $TipoBoolean) {
        $par = @('TRUE', 'FALSE')
    } else {
        $pares = if ($TiposNumero -contains $Col.Tipo) { $ParesNumero } else { $ParesTexto }
        $vals = @($Col.Valores | Where-Object { -not $_.Nulo } | ForEach-Object { $_.Valor })
        $servem = @($pares | Where-Object { $p = $_; -not @($vals | Where-Object { $p -cnotcontains $_ }) })
        $par = @($servem | Where-Object { $vals -ccontains $_[0] }) + $servem | Select-Object -First 1
        if (-not $par) {
            Stop-Script ("não sei qual valor significa 'marcado' em $($Col.Tabela).$($Col.Campo). Valores encontrados: $(Format-Values $Col)`n" +
                "Rode com -Descobrir e informe -ValorMarcado e -ValorDesmarcado.") 2
        }
    }
    $m = L $Col $par[0]
    $d = L $Col $par[1]
    $texto = if ($Col.Tipo -eq $TipoBoolean) { $m } elseif ($TiposNumero -contains $Col.Tipo) { [string][long]$par[0] } else { $par[0] }
    return @($m, $d, $texto)
}

# Escolhe tabela e colunas: as informadas ou, se não houver dúvida, as encontradas pelo nome.
function Resolve-Target($Colunas) {
    $precisa = @()
    if ($Desmarcar -ne 'Antimicrobiano') { $precisa += 'Psicotropico' }
    if ($Desmarcar -ne 'Psicotropico') { $precisa += 'Antimicrobiano' }
    $explicito = @{ Psicotropico = $CampoPsicotropico; Antimicrobiano = $CampoAntimicrobiano }
    $cands = @($Colunas | Where-Object { $precisa -contains $_.Kind -and (Test-FlagType $_) })

    $tab = $Tabela
    if (-not $tab) {
        $tabs = @($cands | ForEach-Object { $_.Tabela } | Sort-Object -Unique)
        if ($tabs.Count -gt 1) {
            $prod = @($tabs | Where-Object { $_ -match 'PROD' })
            if ($prod.Count -eq 1) { $tabs = $prod }
        }
        if ($tabs.Count -eq 0) { return @{ Erro = 'nenhuma coluna com PSICO, CONTROLAD, ANTIMIC ou ANTIBIO no nome.' } }
        if ($tabs.Count -gt 1) { return @{ Erro = "mais de uma tabela possível ($($tabs -join ', ')); informe -Tabela." } }
        $tab = $tabs[0]
    }
    $doTab = @($Colunas | Where-Object { $_.Tabela -eq $tab })
    if (-not $doTab) { return @{ Erro = "tabela '$tab' não existe no banco." } }

    $alvos = @()
    foreach ($k in $precisa) {
        if ($explicito[$k]) {
            $col = @($doTab | Where-Object { $_.Campo -eq $explicito[$k] })
            if (-not $col) { return @{ Erro = "coluna '$($explicito[$k])' não existe em $tab." } }
            if (-not (Test-FlagType $col[0])) { return @{ Erro = "coluna $tab.$($col[0].Campo) não é de marcar (tipo $($col[0].Tipo))." } }
        } else {
            $col = @($cands | Where-Object { $_.Tabela -eq $tab -and $_.Kind -eq $k })
            $param = if ($k -eq 'Psicotropico') { '-CampoPsicotropico' } else { '-CampoAntimicrobiano' }
            if ($col.Count -eq 0) { return @{ Erro = "nenhuma coluna de $k em $tab; informe $param ou use -Desmarcar." } }
            if ($col.Count -gt 1) { return @{ Erro = "mais de uma coluna de $k em $tab ($(($col | ForEach-Object { $_.Campo }) -join ', ')); informe $param." } }
        }
        $alvos += [pscustomobject]@{ Kind = $k; Col = $col[0] }
    }
    $pk = @($Chaves | Where-Object { $_[0] -eq $doTab[0].Tabela } | ForEach-Object { $nome = $_[1]; $doTab | Where-Object { $_.Campo -eq $nome } })
    return @{ Erro = $null; Tabela = $doTab[0].Tabela; Alvos = $alvos; Colunas = $doTab; Pk = $pk }
}

# Saldo de estoque: coluna na própria tabela de produtos ou soma numa tabela de estoque (por loja, lote...).
# Devolve a expressão SQL (tabela de produtos com apelido P) e a descrição, ou o motivo de não achar.
function Resolve-Stock($Alvo) {
    $saldo = { $TiposQtd -contains $_.Tipo -and $_.Campo -notmatch $NaoESaldo }
    if (-not $TabelaEstoque) {
        if ($CampoEstoque) {
            $col = @($Alvo.Colunas | Where-Object { $_.Campo -eq $CampoEstoque })
            if (-not $col) { return @{ Erro = "coluna '$CampoEstoque' não existe em $($Alvo.Tabela)." } }
        } else {
            $col = @($Alvo.Colunas | Where-Object $saldo | Where-Object { $_.Campo -match 'ESTOQUE|SALDO' })
            if ($col.Count -eq 0) { return @{ Erro = "nenhuma coluna de estoque em $($Alvo.Tabela); informe -CampoEstoque ou -TabelaEstoque." } }
            if ($col.Count -gt 1) { return @{ Erro = "mais de uma coluna de estoque em $($Alvo.Tabela) ($(($col | ForEach-Object { $_.Campo }) -join ', ')); informe -CampoEstoque." } }
        }
        if ($TiposQtd -notcontains $col[0].Tipo) { return @{ Erro = "coluna $($Alvo.Tabela).$($col[0].Campo) não é numérica." } }
        return @{ Erro = $null; Expr = "COALESCE(P.$(Q $col[0].Campo), 0)"; Texto = "$($Alvo.Tabela).$($col[0].Campo)" }
    }
    if ($Alvo.Pk.Count -ne 1) { return @{ Erro = "estoque em outra tabela exige chave primária de uma coluna em $($Alvo.Tabela)." } }
    $doTab = @($Colunas | Where-Object { $_.Tabela -eq $TabelaEstoque })
    if (-not $doTab) { return @{ Erro = "tabela '$TabelaEstoque' não existe no banco." } }
    $tab = $doTab[0].Tabela
    if ($CampoEstoque) {
        $col = @($doTab | Where-Object { $_.Campo -eq $CampoEstoque })
        if (-not $col) { return @{ Erro = "coluna '$CampoEstoque' não existe em $tab." } }
    } else {
        $col = @($doTab | Where-Object $saldo | Where-Object { $_.Campo -match 'ESTOQUE|SALDO|QTD|QUANT' })
        if ($col.Count -ne 1) { return @{ Erro = "não sei qual coluna de $tab é o saldo; informe -CampoEstoque." } }
    }
    if ($TiposQtd -notcontains $col[0].Tipo) { return @{ Erro = "coluna $tab.$($col[0].Campo) não é numérica." } }
    $nomePk = $Alvo.Pk[0].Campo
    $chave = if ($ChaveEstoque) { @($doTab | Where-Object { $_.Campo -eq $ChaveEstoque }) } else { @($doTab | Where-Object { $_.Campo -eq $nomePk }) }
    if (-not $chave) { return @{ Erro = "não sei qual coluna de $tab liga ao produto ($($Alvo.Tabela).$nomePk); informe -ChaveEstoque." } }
    $expr = "(SELECT COALESCE(SUM(E.$(Q $col[0].Campo)), 0) FROM $(Q $tab) E WHERE E.$(Q $chave[0].Campo) = P.$(Q $nomePk))"
    return @{ Erro = $null; Expr = $expr; Texto = "soma de $tab.$($col[0].Campo) por $($chave[0].Campo)" }
}

# "1,3,5-8" -> 1,3,5,6,7,8 (dentro de 1..Max); $null se algo não for válido.
function ConvertFrom-Ranges([string]$Texto, [int]$Max) {
    $nums = New-Object Collections.Generic.List[int]
    foreach ($t in ($Texto -split '[,;\s]+' | Where-Object { $_ })) {
        if ($t -match '^(\d+)(-(\d+))?$') {
            $a = [int]$Matches[1]
            $b = if ($Matches[3]) { [int]$Matches[3] } else { $a }
            if ($a -lt 1 -or $b -gt $Max -or $a -gt $b) { return $null }
            foreach ($n in $a..$b) { $nums.Add($n) }
        } else { return $null }
    }
    if ($nums.Count -eq 0) { return $null }
    return @($nums | Sort-Object -Unique)
}

function Format-Row($R) {
    $partes = @($R.Chave -join '/') + @($R.Descricao)
    if ($script:TemEstoque) { $partes += $R.Estoque }
    return ($partes + $R.Flags) -join ' | '
}

function Get-Header {
    $partes = @((@($alvo.Pk | ForEach-Object { $_.Campo })) -join '/') + @('Descrição')
    if ($script:TemEstoque) { $partes += 'Estoque' }
    return ($partes + @($alvo.Alvos | ForEach-Object { $_.Col.Campo })) -join ' | '
}

# Lista para o usuário escolher: janela (Out-GridView) no Windows PowerShell; senão, menu numerado no console.
function Select-Products($Lista) {
    if (Get-Command Out-GridView -ErrorAction SilentlyContinue) {
        try {
            $itens = for ($i = 0; $i -lt $Lista.Count; $i++) {
                $o = [ordered]@{ Item = $i + 1; Codigo = ($Lista[$i].Chave -join '/'); Descricao = $Lista[$i].Descricao }
                if ($script:TemEstoque) { $o['Estoque'] = $Lista[$i].Estoque }
                for ($k = 0; $k -lt $alvo.Alvos.Count; $k++) { $o[$alvo.Alvos[$k].Col.Campo] = $Lista[$i].Flags[$k] }
                [pscustomobject]$o
            }
            $esc = @($itens | Out-GridView -Title 'Selecione os produtos a DESMARCAR (Ctrl ou Shift para vários) e clique OK' -PassThru)
            return @($esc | ForEach-Object { $Lista[$_.Item - 1] })
        } catch {
            Write-Host "Janela de seleção indisponível ($($_.Exception.Message)); usando a lista no console."
        }
    }
    Write-Host ''
    Write-Host ('  Item  ' + (Get-Header))
    for ($i = 0; $i -lt $Lista.Count; $i++) { Write-Host ('  {0,4}  {1}' -f ($i + 1), (Format-Row $Lista[$i])) }
    while ($true) {
        $resp = "$(Read-Host 'Itens a desmarcar (ex.: 1,3,5-8), T para todos, Enter para cancelar')".Trim()
        if (-not $resp) { return @() }
        if ($resp -match '^(t|todos)$') { return $Lista }
        $idx = ConvertFrom-Ranges $resp $Lista.Count
        if ($idx) { return @($idx | ForEach-Object { $Lista[$_ - 1] }) }
        Write-Host "Não entendi. Use os números da coluna Item (1 a $($Lista.Count)), separados por vírgula, ou faixas como 5-8."
    }
}

# ---------- validação dos parâmetros ----------
foreach ($n in @($Tabela, $CampoPsicotropico, $CampoAntimicrobiano, $CampoEstoque, $TabelaEstoque, $ChaveEstoque)) {
    if ($n -and $n -notmatch '^[A-Za-z_][A-Za-z0-9_$]*$') { Stop-Script "nome inválido: '$n'." }
}
foreach ($v in @($ValorMarcado, $ValorDesmarcado)) {
    if ($v -and $v -notmatch '^-?[A-Za-z0-9]{1,20}$') { Stop-Script "valor inválido: '$v' (use letras ou números, ex.: S, N, 1, 0)." }
}
if ([bool]$ValorMarcado -ne [bool]$ValorDesmarcado) { Stop-Script 'informe -ValorMarcado e -ValorDesmarcado juntos.' }
if ($ValorMarcado -and $ValorMarcado -ceq $ValorDesmarcado) { Stop-Script '-ValorMarcado e -ValorDesmarcado não podem ser iguais.' }
if (($CampoPsicotropico -or $CampoAntimicrobiano) -and -not $Tabela) { Stop-Script 'ao informar a coluna, informe também -Tabela.' }
if ($ChaveEstoque -and -not $TabelaEstoque) { Stop-Script '-ChaveEstoque só vale junto com -TabelaEstoque.' }
if ($Escolher -and $Codigos) { Stop-Script 'use -Escolher ou -Codigos, não os dois.' }
$Codigos = @($Codigos | ForEach-Object { $_ -split '[,;\s]+' } | Where-Object { $_ })

$script:IsqlExe = Find-Isql
if (-not $env:ISC_PASSWORD) {
    $seg = Read-Host -AsSecureString "Senha do usuário $Usuario do Firebird"
    $script:Senha = (New-Object Management.Automation.PSCredential('u', $seg)).GetNetworkCredential().Password
}

# ---------- estrutura do banco ----------
Write-Host "Lendo a estrutura do banco $Banco ..."
$linhas = Invoke-Isql @'
SELECT '#M|' || TRIM(rf.RDB$RELATION_NAME) || '|' || TRIM(rf.RDB$FIELD_NAME) || '|' || CAST(f.RDB$FIELD_TYPE AS VARCHAR(5)) || '|' ||
       CAST(COALESCE(f.RDB$FIELD_SCALE, 0) AS VARCHAR(5)) || '|' || CASE WHEN f.RDB$COMPUTED_BLR IS NULL THEN '0' ELSE '1' END
FROM RDB$RELATION_FIELDS rf
JOIN RDB$RELATIONS r ON r.RDB$RELATION_NAME = rf.RDB$RELATION_NAME
JOIN RDB$FIELDS f ON f.RDB$FIELD_NAME = rf.RDB$FIELD_SOURCE
WHERE COALESCE(r.RDB$SYSTEM_FLAG, 0) = 0 AND r.RDB$VIEW_BLR IS NULL
ORDER BY rf.RDB$RELATION_NAME, rf.RDB$FIELD_POSITION;
SELECT '#K|' || TRIM(c.RDB$RELATION_NAME) || '|' || TRIM(s.RDB$FIELD_NAME)
FROM RDB$RELATION_CONSTRAINTS c
JOIN RDB$INDEX_SEGMENTS s ON s.RDB$INDEX_NAME = c.RDB$INDEX_NAME
WHERE c.RDB$CONSTRAINT_TYPE = 'PRIMARY KEY'
ORDER BY c.RDB$RELATION_NAME, s.RDB$FIELD_POSITION;
'@
$Colunas = @(Get-Rows $linhas 'M' | ForEach-Object {
        [pscustomobject]@{ Tabela = $_[0]; Campo = $_[1]; Tipo = [int]$_[2]; Escala = [int]$_[3]; Calculado = ($_[4] -eq '1'); Kind = (Get-Kind $_[1]); Valores = @() }
    })
$Chaves = @(Get-Rows $linhas 'K')
if (-not $Colunas) { Stop-Script 'o banco não tem tabelas de usuário. Confira o caminho em -Banco.' }

# ---------- modo -Descobrir ----------
if ($Descobrir) {
    $cands = @($Colunas | Where-Object { $_.Kind -and (Test-FlagType $_) })
    if (-not $cands) {
        Write-Host 'Nenhuma coluna com PSICO, CONTROLAD, ANTIMIC, ANTIBIO, TERAPEUT, SNGPC ou PORTARIA no nome.'
        Write-Host 'Tabelas com PROD no nome e suas colunas:'
        $Colunas | Where-Object { $_.Tabela -match 'PROD' } | Group-Object Tabela | ForEach-Object {
            Write-Host "  $($_.Name): $(($_.Group | ForEach-Object { $_.Campo }) -join ', ')"
        }
        exit 2
    }
    Write-Host "Contando os valores de $($cands.Count) coluna(s) (pode demorar em tabelas grandes) ..."
    Add-Values $cands
    Write-Host ''
    Write-Host 'Colunas candidatas (tabela.coluna  tipo  provável  valores=quantidade):'
    foreach ($c in $cands) {
        Write-Host ("  {0}.{1}  {2}  {3}" -f $c.Tabela, $c.Campo, $NomesTipo[$c.Tipo], $c.Kind)
        Write-Host ("      {0}" -f (Format-Values $c))
    }
    Write-Host ''
    Write-Host 'Colunas de estoque possíveis:'
    $Colunas | Where-Object { $_.Tabela -match 'ESTOQ|LOTE|SALDO' -or ($_.Tabela -match 'PROD' -and $TiposQtd -contains $_.Tipo -and $_.Campo -match 'ESTOQUE|SALDO') } |
        Group-Object Tabela | ForEach-Object { Write-Host "  $($_.Name): $(($_.Group | ForEach-Object { $_.Campo }) -join ', ')" }
    Write-Host ''
    $alvo = Resolve-Target $Colunas
    if ($alvo.Erro) {
        Write-Host "Escolha automática: não foi possível, $($alvo.Erro)"
        Write-Host 'Informe -Tabela e -CampoPsicotropico / -CampoAntimicrobiano conforme a lista acima.'
    } else {
        Write-Host "Escolha automática: $($alvo.Tabela) -> $(($alvo.Alvos | ForEach-Object { "$($_.Kind): $($_.Col.Campo)" }) -join '; ')"
        $est = Resolve-Stock $alvo
        if ($est.Erro) { Write-Host "Estoque: não identificado, $($est.Erro)" } else { Write-Host "Estoque: $($est.Texto)" }
        Write-Host 'Confira se são mesmo as caixas e o estoque da tela de cadastro de produtos antes de usar -Aplicar.'
    }
    exit 0
}

# ---------- simulação / aplicação ----------
$alvo = Resolve-Target $Colunas
if ($alvo.Erro) { Stop-Script "$($alvo.Erro) Rode com -Descobrir para ver as colunas candidatas." 2 }
$T = $alvo.Tabela
$pk = $alvo.Pk
if (($Escolher -or $Codigos) -and -not $pk) { Stop-Script "$T não tem chave primária; não dá para escolher produtos. Rode sem -Escolher/-Codigos." }
if ($Codigos -and $pk.Count -ne 1) { Stop-Script "-Codigos exige chave primária de uma coluna em $T; use -Escolher." }
Add-Values ($alvo.Alvos | ForEach-Object { $_.Col })
foreach ($a in $alvo.Alvos) {
    $par = Resolve-Pair $a.Col
    $a | Add-Member Marcado $par[0]
    $a | Add-Member Desmarcado $par[1]
    $a | Add-Member TextoMarcado $par[2]
}
$est = Resolve-Stock $alvo
if ($est.Erro -and ($Estoque -ne 'Todos' -or $CampoEstoque -or $TabelaEstoque)) { Stop-Script "estoque: $($est.Erro) Rode com -Descobrir para ver as colunas de estoque." 2 }
$script:TemEstoque = -not $est.Erro

if (-not $PastaSaida) { $PastaSaida = Join-Path (Join-Path $PSScriptRoot 'registros') (Get-Date -Format 'yyyyMMdd-HHmmss') }
New-Item -ItemType Directory -Force $PastaSaida | Out-Null
$PastaSaida = (Resolve-Path -LiteralPath $PastaSaida).Path
$script:LogFile = Join-Path $PastaSaida 'log.txt'
Write-Log "Banco: $Banco | usuário: $Usuario | modo: $(if ($Aplicar) { 'APLICAR' } else { 'simulação' })"
foreach ($a in $alvo.Alvos) {
    Write-Log "  $($a.Kind): $T.$($a.Col.Campo) de $($a.Marcado) para $($a.Desmarcado)  [valores hoje: $(Format-Values $a.Col)]"
}
if ($script:TemEstoque) { Write-Log "  Estoque: $($est.Texto) | filtro: $Estoque" } else { Write-Log "  Estoque: não exibido ($($est.Erro))" }

function Get-Counts {
    $sql = for ($i = 0; $i -lt $alvo.Alvos.Count; $i++) {
        $a = $alvo.Alvos[$i]
        "SELECT '#C|$i|' || CAST(COUNT(*) AS VARCHAR(20)) FROM $(Q $T) WHERE $(Q $a.Col.Campo) = $($a.Marcado);"
    }
    $r = @(Get-Rows (Invoke-Isql ($sql -join "`n")) 'C')
    return @($r | Sort-Object { [int]$_[0] } | ForEach-Object { [long]$_[1] })
}
$antes = Get-Counts
for ($i = 0; $i -lt $alvo.Alvos.Count; $i++) { Write-Log "  Marcados como $($alvo.Alvos[$i].Kind) (todos): $($antes[$i])" }

# Lista dos produtos marcados (com o filtro de estoque): chave, descrição, estoque e valores atuais.
$desc = $null
foreach ($padrao in @('^DESCRICAO$', '^DESCRICAO_?PRODUTO$', '^NOME$', '^NOME_?PRODUTO$', '^DESCR', 'DESCRI', '^NOME')) {
    $desc = $alvo.Colunas | Where-Object { $TiposTexto -contains $_.Tipo -and $_.Campo -match $padrao } | Select-Object -First 1
    if ($desc) { break }
}
$expr = @($pk | ForEach-Object { "COALESCE(CAST(P.$(Q $_.Campo) AS VARCHAR(100)), '')" })
$expr += if ($desc) {
    "COALESCE(REPLACE(REPLACE(REPLACE(SUBSTRING(P.$(Q $desc.Campo) FROM 1 FOR 100), '|', '/'), ASCII_CHAR(13), ' '), ASCII_CHAR(10), ' '), '')"
} else { "''" }
$expr += if ($script:TemEstoque) { "CAST($($est.Expr) AS VARCHAR(40))" } else { "''" }
$expr += @($alvo.Alvos | ForEach-Object { "COALESCE(CAST(P.$(Q $_.Col.Campo) AS VARCHAR(20)), '')" })
$where = '(' + (($alvo.Alvos | ForEach-Object { "P.$(Q $_.Col.Campo) = $($_.Marcado)" }) -join ' OR ') + ')'
if ($Estoque -eq 'ComEstoque') { $where += " AND $($est.Expr) > 0" }
if ($Estoque -eq 'SemEstoque') { $where += " AND $($est.Expr) <= 0" }
$ordem = if ($pk) { ($pk | ForEach-Object { "P.$(Q $_.Campo)" }) -join ', ' } else { '1' }
$n = $pk.Count
$lista = @(Get-Rows (Invoke-Isql "SELECT '#L|' || $($expr -join " || '|' || ") FROM $(Q $T) P WHERE $where ORDER BY $ordem;") 'L' | ForEach-Object {
        $campos = @($_ | ForEach-Object { $_.TrimEnd() })
        $chave = @()
        if ($n) { $chave = @($campos[0..($n - 1)]) }
        [pscustomobject]@{
            Chave     = $chave
            Descricao = $campos[$n]
            Estoque   = $(if ($campos[$n + 1] -match '^-?\d+\.\d*$') { $campos[$n + 1].TrimEnd('0').TrimEnd('.') } else { $campos[$n + 1] })
            Flags     = @($campos[($n + 2)..($campos.Count - 1)])
        }
    })
$filtroTxt = @{ Todos = ''; ComEstoque = ' com estoque'; SemEstoque = ' sem estoque' }[$Estoque]
Write-Log "  Produtos marcados$($filtroTxt): $($lista.Count)"

# Escolha: todos da lista, os códigos informados ou os que o usuário marcar.
if ($Codigos) {
    $sel = @($lista | Where-Object { $Codigos -contains $_.Chave[0] })
    $achados = @($sel | ForEach-Object { $_.Chave[0] })
    $faltam = @($Codigos | Where-Object { $achados -notcontains $_ })
    if ($faltam) { Write-Log "  Códigos fora da lista de marcados$($filtroTxt) (ignorados): $($faltam -join ', ')" }
} elseif ($Escolher -and $lista.Count) {
    $sel = @(Select-Products $lista)
} else {
    $sel = $lista
}
if ($Codigos -or $Escolher) { Write-Log "  Escolhidos: $($sel.Count)" }

$csv = Join-Path $PastaSaida 'produtos-a-desmarcar.csv'
$cab = @($pk | ForEach-Object { $_.Campo }) + @($(if ($desc) { $desc.Campo } else { 'DESCRICAO' }))
if ($script:TemEstoque) { $cab += 'ESTOQUE' }
$cab += @($alvo.Alvos | ForEach-Object { $_.Col.Campo })
$linhasCsv = New-Object Collections.Generic.List[string]
foreach ($campos in @(, $cab) + @($sel | ForEach-Object { , (@($_.Chave) + @($_.Descricao) + $(if ($script:TemEstoque) { @($_.Estoque) } else { @() }) + $_.Flags) })) {
    $linhasCsv.Add((($campos | ForEach-Object { '"' + ([string]$_).Replace('"', '""') + '"' }) -join ';'))
}
[IO.File]::WriteAllLines($csv, $linhasCsv, $Utf8Bom)
Write-Log "  Lista ($($sel.Count) produto(s), valores de antes): $csv"
if (-not $Escolher -and $sel.Count) {
    Write-Host ('    ' + (Get-Header))
    $sel | Select-Object -First 20 | ForEach-Object { Write-Host ('    ' + (Format-Row $_)) }
    if ($sel.Count -gt 20) { Write-Host "    ... e mais $($sel.Count - 20) (veja o CSV)" }
}

# Quantas marcações cada coluna vai perder.
$esperado = @(for ($i = 0; $i -lt $alvo.Alvos.Count; $i++) { $k = $i; @($sel | Where-Object { $_.Flags[$k] -ceq $alvo.Alvos[$k].TextoMarcado }).Count })
$total = ($esperado | Measure-Object -Sum).Sum
if ($total -eq 0) { Write-Log 'Nenhuma marcação a desfazer. Nada foi alterado.'; exit 0 }
if (-not $Aplicar) {
    Write-Log "SIMULAÇÃO: nada foi alterado. Seriam desmarcadas $total marcação(ões) em $($sel.Count) produto(s)."
    if (($Escolher -or $Codigos) -and $pk.Count -eq 1 -and $sel.Count -le 200) {
        Write-Log "  Para aplicar exatamente esta escolha, rode de novo com: -Aplicar -Codigos $(($sel | ForEach-Object { $_.Chave[0] }) -join ',')"
    } else {
        Write-Log '  Confira a lista e, para desmarcar, rode de novo com -Aplicar (e os mesmos filtros).'
    }
    exit 0
}

Write-Host ''
Write-Host 'ATENÇÃO: produto que já foi enviado ao SNGPC como controlado/antimicrobiano e for desmarcado'
Write-Host 'gera divergência na ANVISA (veja o README). Feche o Digifarma em todos os computadores.'
if (-not $Confirmar) {
    $resp = Read-Host "Digite DESMARCAR para alterar $total marcação(ões) em $($sel.Count) produto(s) de $T"
    if ($resp -cne 'DESMARCAR') { Write-Log 'Cancelado pelo usuário. Nada foi alterado.'; exit 1 }
}

if ($SemBackup) {
    Write-Log 'Backup NÃO feito (-SemBackup).'
} else {
    $gbak = Join-Path (Split-Path $script:IsqlExe) ('gbak' + [IO.Path]::GetExtension($script:IsqlExe))
    if (-not (Test-Path -LiteralPath $gbak)) { Stop-Script "gbak não encontrado em $gbak. Faça o backup pelo Digifarma e rode com -SemBackup." }
    $fbk = Join-Path $PastaSaida 'backup-antes.fbk'
    Write-Log "Fazendo backup em $fbk (pode demorar) ..."
    $r = Start-Tool $gbak @('-b', '-user', $Usuario, $Banco, $fbk)
    if ($r.Codigo -ne 0 -or -not (Test-Path -LiteralPath $fbk) -or (Get-Item -LiteralPath $fbk).Length -eq 0) {
        Stop-Script "o backup falhou; nada foi alterado. $($r.Erro.Trim())"
    }
    Write-Log "Backup ok ($([math]::Round((Get-Item -LiteralPath $fbk).Length / 1MB, 1)) MB)."
}

# Comandos de alteração: um por produto e coluna (com chave primária) ou um por coluna (sem chave).
$upd = New-Object Collections.Generic.List[string]
$volta = New-Object Collections.Generic.List[string]
if ($pk) {
    foreach ($row in $sel) {
        $cond = (@(for ($k = 0; $k -lt $n; $k++) { "$(Q $pk[$k].Campo) = $(L $pk[$k] $row.Chave[$k])" })) -join ' AND '
        for ($i = 0; $i -lt $alvo.Alvos.Count; $i++) {
            $a = $alvo.Alvos[$i]
            if ($row.Flags[$i] -cne $a.TextoMarcado) { continue }
            $c = Q $a.Col.Campo
            $upd.Add("UPDATE $(Q $T) SET $c = $($a.Desmarcado) WHERE $cond AND $c = $($a.Marcado);")
            $volta.Add("UPDATE $(Q $T) SET $c = $($a.Marcado) WHERE $cond AND $c = $($a.Desmarcado);")
        }
    }
} else {
    foreach ($a in $alvo.Alvos) {
        $filtro = @{ Todos = ''; ComEstoque = " AND $($est.Expr) > 0"; SemEstoque = " AND $($est.Expr) <= 0" }[$Estoque]
        $upd.Add("UPDATE $(Q $T) P SET $(Q $a.Col.Campo) = $($a.Desmarcado) WHERE P.$(Q $a.Col.Campo) = $($a.Marcado)$filtro;")
    }
}
if ($volta.Count) {
    $desfazer = Join-Path $PastaSaida 'desfazer.sql'
    $volta.Insert(0, "-- Remarca os produtos desmarcados em $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'). Banco: $Banco")
    $volta.Insert(1, "-- Uso: isql -user $Usuario -i desfazer.sql <banco>")
    $volta.Add('COMMIT;')
    [IO.File]::WriteAllLines($desfazer, $volta, $Ansi)
    Write-Log "Script para desfazer: $desfazer"
} else {
    Write-Log "Sem chave primária em ${T}: não gerei desfazer.sql (use o backup para voltar)."
}

Invoke-Isql ("SET TRANSACTION READ WRITE NO WAIT ISOLATION LEVEL READ COMMITTED;`n" + ($upd -join "`n") + "`nCOMMIT;") | Out-Null

$depois = Get-Counts
$ok = $true
for ($i = 0; $i -lt $alvo.Alvos.Count; $i++) {
    $feito = $antes[$i] - $depois[$i]
    Write-Log "  $($alvo.Alvos[$i].Kind): $feito desmarcado(s) de $($esperado[$i]) previsto(s); ainda marcados (todos): $($depois[$i])"
    if ($feito -ne $esperado[$i]) { $ok = $false }
}
if (-not $ok) { Stop-Script 'o número de produtos desmarcados não bate com o previsto (alguém alterou produtos ao mesmo tempo ou um gatilho do banco reverteu). Confira antes de rodar de novo.' }
Write-Log 'Concluído. Abra o Digifarma e confira alguns produtos da lista.'
