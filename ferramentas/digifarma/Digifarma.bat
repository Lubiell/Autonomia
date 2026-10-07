@echo off
rem DIGIFARMA - todas as ferramentas num arquivo so.
rem Ao abrir, este .bat cria (ou atualiza) nesta mesma pasta os programas guardados no fim dele:
rem   desmarcar-controlados.ps1, relatorios-digifarma.ps1 e Relatorios.bas (macro do Excel).
rem Os registros e os relatorios gerados tambem ficam nesta pasta (subpasta "registros").
rem Se o banco ou a coluna de estoque forem outros, ajuste as duas linhas "set" abaixo.
rem (Arquivo gerado por montar-digifarma-bat.py.)
setlocal
set "BANCO=localhost:C:\Digifarma\Dados\Digifarma6.FDB"
set "ESTOQUE=-Estoque ComEstoque -CampoEstoque PROD_SALDO"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass"
set "DESMARCAR=%~dp0desmarcar-controlados.ps1"
set "RELATORIOS=%~dp0relatorios-digifarma.ps1"

set "DF_BAT=%~f0"
powershell -NoProfile -Command "$t = [IO.File]::ReadAllText($env:DF_BAT); $m = [regex]::Match($t, '(?sm)^#EXTRATOR-INICIO.*?^#EXTRATOR-FIM'); if (-not $m.Success) { exit 3 }; Invoke-Expression $m.Value"
if errorlevel 1 (
  echo.
  echo   Nao consegui criar os programas na pasta "%~dp0".
  echo   - A pasta pode nao permitir gravar: coloque o .bat em C:\Ferramentas\Digifarma, por exemplo.
  echo   - O antivirus pode ter bloqueado: libere o Digifarma.bat no antivirus.
  echo   - O arquivo pode ter sido alterado ou corrompido: baixe o Digifarma.bat de novo.
  pause
  exit /b 1
)

:DF_menu
cls
echo.
echo   DIGIFARMA - FERRAMENTAS
echo   Banco: %BANCO%
echo.
echo   CONTROLADOS (altera o banco; faz backup antes)
echo     1 - Somente VER os controlados com estoque (simulacao, NAO altera nada)
echo     2 - DESMARCAR: na janela, clique nos produtos (Ctrl+clique para varios),
echo         clique OK e depois digite DESMARCAR aqui
echo     3 - Desfazer a ultima vez que desmarcou
echo.
echo   RELATORIOS (so leem o banco, nunca alteram nada)
echo     4 - Abrir a janela de relatorios (Curva ABC, Sugestao de compra e os demais, com datas)
echo     5 - Lotes vencendo (vencidos nos ultimos 30 dias e que vencem nos proximos 90)
echo     6 - Estoque negativo
echo     7 - Conferencia SNGPC (controlados: estoque x lotes)
echo     8 - Gerar o MAPA DO BANCO (mande o arquivo na conversa)
echo.
echo   PLANILHA DE COTACAO
echo     9 - Como colocar os relatorios dentro da planilha (macro do Excel)
echo.
echo     0 - Sair
echo.
choice /c 1234567890 /n /m "  Digite a opcao (0 a 9): "
if errorlevel 10 goto DF_fim
if errorlevel 9 goto DF_planilha
if errorlevel 8 goto DF_mapa
if errorlevel 7 goto DF_sngpc
if errorlevel 6 goto DF_negativo
if errorlevel 5 goto DF_lotes
if errorlevel 4 goto DF_janela
if errorlevel 3 goto DF_desfazer
if errorlevel 2 goto DF_aplicar
goto DF_simular

:DF_simular
%PS% -File "%DESMARCAR%" -Banco "%BANCO%" %ESTOQUE% -Escolher
goto DF_pausa

:DF_aplicar
%PS% -File "%DESMARCAR%" -Banco "%BANCO%" %ESTOQUE% -Escolher -Aplicar
goto DF_pausa

:DF_desfazer
set "ULTIMO="
for /f "delims=" %%d in ('dir /b /ad /o-n "%~dp0registros" 2^>nul') do if not defined ULTIMO if exist "%~dp0registros\%%d\desfazer.sql" set "ULTIMO=%~dp0registros\%%d\desfazer.sql"
if not defined ULTIMO (
  echo.
  echo   Nenhuma alteracao para desfazer em "%~dp0registros".
  goto DF_pausa
)
echo.
echo   Vai remarcar o que foi desmarcado nesta execucao:
echo   "%ULTIMO%"
choice /c SN /m "  Confirma"
if errorlevel 2 goto DF_menu
%PS% -File "%DESMARCAR%" -Banco "%BANCO%" -Desfazer "%ULTIMO%"
goto DF_pausa

:DF_janela
echo.
echo   Digite a senha do Firebird; depois a janela abre.
%PS% -File "%RELATORIOS%" -Banco "%BANCO%" -Janela
if errorlevel 1 pause
goto DF_menu

:DF_lotes
%PS% -File "%RELATORIOS%" -Banco "%BANCO%" -Relatorio LotesVencendo -Abrir
goto DF_pausa

:DF_negativo
%PS% -File "%RELATORIOS%" -Banco "%BANCO%" -Relatorio EstoqueNegativo -Abrir
goto DF_pausa

:DF_sngpc
%PS% -File "%RELATORIOS%" -Banco "%BANCO%" -Relatorio ConferenciaSNGPC -Abrir
goto DF_pausa

:DF_mapa
%PS% -File "%RELATORIOS%" -Banco "%BANCO%" -Mapa -ContarLinhas
goto DF_pausa

:DF_planilha
cls
echo.
echo   RELATORIOS DENTRO DA PLANILHA DE COTACAO (fazer uma vez so)
echo.
echo   1. Deixe a sua cotacao (Cotacao_Pronta_em_branco.xlsx) nesta pasta:
echo      "%~dp0"
echo   2. Abra a cotacao no Excel e aperte Alt+F11.
echo   3. Clique em Arquivo, Importar arquivo e escolha Relatorios.bas (desta pasta).
echo      Se ja tinha importado antes: botao direito em Relatorios, Remover, e importe de novo.
echo   4. Feche o editor, aperte Alt+F8, escolha InstalarRelatorios e clique em Executar.
echo   5. Salve como "Pasta de Trabalho Habilitada para Macro do Excel (*.xlsm)".
echo.
echo   Depois e so abrir o .xlsm, clicar em Habilitar conteudo e usar os botoes das abas.
echo.
if not exist "%~dp0Cotacao_Pronta_em_branco.xlsx" goto DF_pausa
choice /c SN /m "  Abrir a cotacao no Excel agora"
if errorlevel 2 goto DF_menu
start "" "%~dp0Cotacao_Pronta_em_branco.xlsx"
goto DF_menu

:DF_pausa
echo.
pause
goto DF_menu

:DF_fim
endlocal
exit /b 0

#EXTRATOR-INICIO
# Recria, na pasta deste .bat, os programas guardados no fim dele. Só regrava o que mudou.
$ErrorActionPreference = 'Stop'
$bat = $env:DF_BAT
$pasta = Split-Path -Parent $bat
$utf8Bom = New-Object System.Text.UTF8Encoding $true
$ansi = [System.Text.Encoding]::GetEncoding(1252)
$nome = $null
$mudou = $false
$linhas = New-Object System.Collections.Generic.List[string]
foreach ($l in [IO.File]::ReadAllLines($bat)) {
    if ($null -eq $nome) {
        if ($l.StartsWith('#ARQUIVO-INICIO ')) { $nome = $l.Substring(16).Trim(); $linhas.Clear() }
        continue
    }
    if ($l -ceq '#ARQUIVO-FIM') {
        # .bas em Windows-1252 com CRLF (o que o editor do Excel lê); .ps1 em UTF-8 com BOM, igual ao original.
        if ($nome.EndsWith('.bas')) { $enc = $ansi; $quebra = "`r`n" } else { $enc = $utf8Bom; $quebra = "`n" }
        $texto = ($linhas -join $quebra) + $quebra
        # Caractere inválido = .bat salvo em outra codificação: não estraga os programas que já estão na pasta.
        if ($texto.IndexOf([char]0xFFFD) -ge 0) { throw "o Digifarma.bat está corrompido ($nome); baixe o arquivo de novo." }
        $destino = Join-Path $pasta $nome
        $atual = $null
        if (Test-Path -LiteralPath $destino) { $atual = [IO.File]::ReadAllText($destino, $enc) }
        if ($atual -cne $texto) {
            [IO.File]::WriteAllText($destino, $texto, $enc)
            Write-Host "  Atualizado: $nome"
            $mudou = $true
        }
        $nome = $null
        continue
    }
    $linhas.Add($l)
}
if ($mudou) { Start-Sleep -Seconds 2 }   # dá tempo de ler antes do menu limpar a tela
#EXTRATOR-FIM
#ARQUIVO-INICIO desmarcar-controlados.ps1
<#
.SYNOPSIS
Desmarca "Psicotrópico" (controlado) e "Antimicrobiano" no cadastro de produtos do Digifarma (banco Firebird).

.DESCRIPTION
Sem -Aplicar, só simula: mostra os produtos marcados (com estoque) e grava a lista em CSV. Nada é alterado.
Com -Escolher, abre a lista para escolher quais produtos desmarcar; com -Codigos, desmarca só os códigos informados.
Com -Estoque ComEstoque, mostra só os produtos com saldo em estoque.
Com -Aplicar: faz backup do banco (gbak), grava a lista e um script para desfazer, e desmarca numa única transação.
Com -Desfazer <desfazer.sql>: remarca o que uma execução anterior desmarcou.
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
    [string]$CampoDescricao,
    [string]$TabelaEstoque,
    [string]$ChaveEstoque,
    [switch]$Escolher,
    [string[]]$Codigos,
    [switch]$Aplicar,
    [switch]$SemPerguntar,
    [ValidateRange(1, 10)][int]$Tentativas = 3,
    [string]$Desfazer,
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
$EsperaTrava = 5       # segundos que cada produto espera se estiver em uso em outro computador
$PausaTentativa = 10   # segundos entre uma tentativa e outra para os produtos que ficaram em uso
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
function Invoke-Isql([string]$Sql, [switch]$PodeFalhar) {
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
        if ($msg -match 'lock conflict|deadlock|concurrent update') { $msg += "`nAlgum computador está usando estes produtos; rode de novo em instantes." }
        if ($PodeFalhar) { Write-Log "ERRO: o isql falhou (código $($r.Codigo)): $msg"; return $null }
        Stop-Script "o isql falhou (código $($r.Codigo)): $msg"
    }
    return $r.Saida -split "`r?`n"
}

# Linhas marcadas com '#<tag>|' viram vetores de campos; o resto da saída do isql é ignorado.
# Número de campos diferente (código com '|' ou quebra de linha) desalinharia a chave: para tudo.
function Get-Rows($Linhas, [string]$Tag, [int]$Campos) {
    $prefixo = "#$Tag|"
    foreach ($l in $Linhas) {
        $l = $l.Trim()
        if (-not $l.StartsWith($prefixo, [StringComparison]::Ordinal)) { continue }
        $r = $l.Substring($prefixo.Length).Split('|')
        if ($r.Count -ne $Campos) {
            Stop-Script "resposta inesperada do banco (esperava $Campos campos, vieram $($r.Count)): $l`nAlgum código ou nome tem '|' ou quebra de linha; o programa parou antes de alterar."
        }
        , $r
    }
}

function Format-Equals([string]$Coluna, [string]$Literal) {
    if ($Literal -eq 'NULL') { return "$Coluna IS NULL" }
    return "$Coluna = $Literal"
}

# Estoque como o isql mostra (10.000, 1.5E+01) -> 10, 15.
function Format-Number([string]$S) {
    $d = 0.0
    if ([double]::TryParse($S, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)) {
        try { return ([decimal]$d).ToString([Globalization.CultureInfo]::InvariantCulture) } catch { }
    }
    return $S
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
        "SELECT FIRST 20 '#V|$i|' || CASE WHEN $c IS NULL THEN '1' ELSE '0' END || '|' || COALESCE(REPLACE(TRIM(CAST($c AS VARCHAR(100))), '|', '/'), '') || '|' || CAST(COUNT(*) AS VARCHAR(20)) FROM $(Q $Cols[$i].Tabela) GROUP BY $c;"
    }
    $linhas = Invoke-Isql ($sql -join "`n")
    foreach ($c in $Cols) { $c.Valores = @() }
    foreach ($r in @(Get-Rows $linhas 'V' 4)) {
        $Cols[[int]$r[0]].Valores += [pscustomobject]@{ Nulo = ($r[1] -eq '1'); Valor = $r[2]; Qtd = [long]$r[3] }
    }
}

# Descobre o par (marcado, desmarcado) pelos valores que existem na coluna; só aceita se os dois existirem.
# Devolve: literal SQL marcado, literal SQL desmarcado (pode ser NULL), texto do valor marcado como o isql o mostra.
function Resolve-Pair($Col) {
    if ($ValorMarcado) {
        $par = @($ValorMarcado, $ValorDesmarcado)
    } else {
        # Atribuição em cada ramo: um if usado como expressão desmontaria o par único do BOOLEAN.
        if ($Col.Tipo -eq $TipoBoolean) { $pares = @(, @('TRUE', 'FALSE')) } elseif ($TiposNumero -contains $Col.Tipo) { $pares = $ParesNumero } else { $pares = $ParesTexto }
        $vals = @($Col.Valores | Where-Object { -not $_.Nulo } | ForEach-Object { $_.Valor })
        $servem = @($pares | Where-Object { $p = $_; -not @($vals | Where-Object { $p -cnotcontains $_ }) })
        $par = @($servem | Where-Object { $vals -ccontains $_[0] }) + $servem | Select-Object -First 1
        if (-not $par) {
            Stop-Script ("não sei qual valor significa 'marcado' em $($Col.Tabela).$($Col.Campo). Valores encontrados: $(Format-Values $Col)`n" +
                "Rode com -Descobrir e informe -ValorMarcado e -ValorDesmarcado.") 2
        }
        if ($vals -ccontains $par[0] -and $vals -cnotcontains $par[1]) {
            Stop-Script ("em $($Col.Tabela).$($Col.Campo) há produtos com '$($par[0])', mas nenhum com '$($par[1])'. Valores: $(Format-Values $Col)`n" +
                "Veja no Digifarma como fica um produto desmarcado e informe -ValorMarcado $($par[0]) -ValorDesmarcado <valor> (NULL se ficar vazio).") 2
        }
    }
    $m = L $Col $par[0]
    $d = if ($par[1] -eq 'NULL') { 'NULL' } else { L $Col $par[1] }
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
        $todas = @($cands | ForEach-Object { $_.Tabela } | Sort-Object -Unique)
        $tabs = @($todas | Where-Object { $_ -match 'PROD' })
        if ($todas.Count -eq 0) { return @{ Erro = 'nenhuma coluna com PSICO, CONTROLAD, ANTIMIC ou ANTIBIO no nome.' } }
        if ($tabs.Count -eq 0) { return @{ Erro = "as colunas estão em $($todas -join ', '), sem PROD no nome; informe -Tabela com a tabela do cadastro de produtos." } }
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
    if (-not $CampoEstoque -or -not $ChaveEstoque) { return @{ Erro = 'com -TabelaEstoque, informe também -CampoEstoque (o saldo) e -ChaveEstoque (a coluna que aponta para o produto).' } }
    $doTab = @($Colunas | Where-Object { $_.Tabela -eq $TabelaEstoque })
    if (-not $doTab) { return @{ Erro = "tabela '$TabelaEstoque' não existe no banco." } }
    $tab = $doTab[0].Tabela
    $col = @($doTab | Where-Object { $_.Campo -eq $CampoEstoque })
    if (-not $col) { return @{ Erro = "coluna '$CampoEstoque' não existe em $tab." } }
    if ($TiposQtd -notcontains $col[0].Tipo) { return @{ Erro = "coluna $tab.$($col[0].Campo) não é numérica." } }
    $nomePk = $Alvo.Pk[0].Campo
    $chave = @($doTab | Where-Object { $_.Campo -eq $ChaveEstoque })
    if (-not $chave) { return @{ Erro = "coluna '$ChaveEstoque' não existe em $tab." } }
    $expr = "(SELECT COALESCE(SUM(E.$(Q $col[0].Campo)), 0) FROM $(Q $tab) E WHERE E.$(Q $chave[0].Campo) = P.$(Q $nomePk))"
    return @{ Erro = $null; Expr = $expr; Texto = "soma de $tab.$($col[0].Campo) por $($chave[0].Campo)" }
}

# "1,3,5-8" -> 1,3,5,6,7,8 (dentro de 1..Max); $null se algo não for válido.
function ConvertFrom-Ranges([string]$Texto, [int]$Max) {
    $nums = New-Object Collections.Generic.List[int]
    foreach ($t in ($Texto -split '[,;\s]+' | Where-Object { $_ })) {
        if ($t -match '^(\d{1,6})(-(\d{1,6}))?$') {
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
                if ($script:TemEstoque) {
                    $o['Estoque'] = $Lista[$i].Estoque
                    try { $o['Estoque'] = [decimal]::Parse($Lista[$i].Estoque, [Globalization.CultureInfo]::InvariantCulture) } catch { }
                }
                for ($k = 0; $k -lt $alvo.Alvos.Count; $k++) { $o[$alvo.Alvos[$k].Col.Campo] = $Lista[$i].Flags[$k] }
                [pscustomobject]$o
            }
            $titulo = if ($Aplicar) {
                'DESMARCAR: clique nos produtos (Ctrl+clique para vários, Shift+clique para uma sequência) e depois em OK. Em seguida confirme na janela preta.'
            } else {
                'SIMULAÇÃO (não altera nada): clique nos produtos (Ctrl+clique para vários) e em OK. Para desmarcar de verdade, use a opção 2 do menu.'
            }
            $esc = @($itens | Out-GridView -Title $titulo -PassThru)
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
foreach ($n in @($Tabela, $CampoPsicotropico, $CampoAntimicrobiano, $CampoEstoque, $TabelaEstoque, $ChaveEstoque, $CampoDescricao)) {
    if ($n -and $n -notmatch '^[A-Za-z_][A-Za-z0-9_$]*$') { Stop-Script "nome inválido: '$n'." }
}
foreach ($v in @($ValorMarcado, $ValorDesmarcado)) {
    if ($v -and $v -notmatch '^-?[A-Za-z0-9]{1,20}$') { Stop-Script "valor inválido: '$v' (use letras ou números, ex.: S, N, 1, 0)." }
}
if ([bool]$ValorMarcado -ne [bool]$ValorDesmarcado) { Stop-Script 'informe -ValorMarcado e -ValorDesmarcado juntos.' }
if ($ValorMarcado -and $ValorMarcado -ceq $ValorDesmarcado) { Stop-Script '-ValorMarcado e -ValorDesmarcado não podem ser iguais.' }
if ($ValorMarcado -eq 'NULL') { Stop-Script '-ValorMarcado não pode ser NULL (só -ValorDesmarcado).' }
if (($CampoPsicotropico -or $CampoAntimicrobiano) -and -not $Tabela) { Stop-Script 'ao informar a coluna, informe também -Tabela.' }
if ($ChaveEstoque -and -not $TabelaEstoque) { Stop-Script '-ChaveEstoque só vale junto com -TabelaEstoque.' }
if ($Escolher -and $Codigos) { Stop-Script 'use -Escolher ou -Codigos, não os dois.' }
$Codigos = @($Codigos | ForEach-Object { $_ -split '[,;\s]+' } | Where-Object { $_ })

$script:IsqlExe = Find-Isql
if (-not $env:ISC_PASSWORD) {
    $seg = Read-Host -AsSecureString "Senha do usuário $Usuario do Firebird"
    $script:Senha = (New-Object Management.Automation.PSCredential('u', $seg)).GetNetworkCredential().Password
}

# ---------- modo -Desfazer ----------
if ($Desfazer) {
    if (-not (Test-Path -LiteralPath $Desfazer -PathType Leaf)) { Stop-Script "arquivo '$Desfazer' não encontrado." }
    $conteudo = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Desfazer).Path, $Ansi)
    if (-not $conteudo.StartsWith('/* Remarca os produtos desmarcados')) { Stop-Script "'$Desfazer' não é um desfazer.sql gerado por este programa." }
    Write-Host "Rodando $Desfazer em $Banco ..."
    Invoke-Isql $conteudo | Out-Null
    Write-Host 'Pronto: os produtos desmarcados por aquela execução voltaram a ficar marcados (os que ainda estavam desmarcados).'
    exit 0
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
$Colunas = @(Get-Rows $linhas 'M' 5 | ForEach-Object {
        [pscustomobject]@{ Tabela = $_[0]; Campo = $_[1]; Tipo = [int]$_[2]; Escala = [int]$_[3]; Calculado = ($_[4] -eq '1'); Kind = (Get-Kind $_[1]); Valores = @() }
    })
$Chaves = @(Get-Rows $linhas 'K' 2)
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
    # Valores só das colunas de marcar: as outras (SNGPC, classe terapêutica) podem ter CPF, nomes etc.
    $mostrar = @($cands | Where-Object { $_.Kind -ne 'Outro' -and $_.Campo -notmatch 'CPF|CNPJ|NOME|RG|FONE|EMAIL|ENDERECO' })
    Write-Host "Contando os valores de $($mostrar.Count) coluna(s) (pode demorar em tabelas grandes) ..."
    Add-Values $mostrar
    Write-Host ''
    Write-Host 'Colunas candidatas (tabela.coluna  tipo  provável  valores=quantidade):'
    foreach ($c in $cands) {
        Write-Host ("  {0}.{1}  {2}  {3}" -f $c.Tabela, $c.Campo, $NomesTipo[$c.Tipo], $c.Kind)
        if ($mostrar -contains $c) { Write-Host ("      {0}" -f (Format-Values $c)) } else { Write-Host '      (valores não exibidos)' }
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
    $a | Add-Member -NotePropertyName Marcado -NotePropertyValue $par[0]
    $a | Add-Member -NotePropertyName Desmarcado -NotePropertyValue $par[1]
    $a | Add-Member -NotePropertyName TextoMarcado -NotePropertyValue $par[2]
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
    $r = @(Get-Rows (Invoke-Isql ($sql -join "`n")) 'C' 2)
    return @($r | Sort-Object { [int]$_[0] } | ForEach-Object { [long]$_[1] })
}
$antes = Get-Counts
for ($i = 0; $i -lt $alvo.Alvos.Count; $i++) { Write-Log "  Marcados como $($alvo.Alvos[$i].Kind) (todos): $($antes[$i])" }

# Lista dos produtos marcados (com o filtro de estoque): chave, descrição, estoque e valores atuais.
$textos = @($alvo.Colunas | Where-Object { $TiposTexto -contains $_.Tipo })
$desc = $null
if ($CampoDescricao) {
    $desc = $textos | Where-Object { $_.Campo -eq $CampoDescricao } | Select-Object -First 1
    if (-not $desc) { Stop-Script "não há coluna de texto '$CampoDescricao' em $T. Colunas de texto: $(($textos | ForEach-Object { $_.Campo }) -join ', ')" }
} else {
    # No Digifarma as colunas de PRODUTOS começam com PROD_ (PROD_SALDO): PROD_NOME, PROD_DESC...
    $padroes = @('^(PROD_?)?DESCRICAO$', '^(PROD_?)?NOME$', '^(PROD_?)?DESCR$', '^(PROD_?)?DESC$',
        '^DESCRICAO_?PRODUTO$', '^NOME_?PRODUTO$', 'DESCRICAO', 'DESCRI', '^NOME', 'NOME$', '^PRODUTO$')
    foreach ($padrao in $padroes) {
        $desc = $textos | Where-Object { $_.Campo -match $padrao } | Select-Object -First 1
        if ($desc) { break }
    }
}
if ($desc) {
    Write-Log "  Descrição: $T.$($desc.Campo)"
} else {
    Write-Log "  Descrição: não encontrada. Informe -CampoDescricao com uma destas colunas de texto: $(($textos | ForEach-Object { $_.Campo }) -join ', ')"
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
$lista = @(Get-Rows (Invoke-Isql "SELECT '#L|' || $($expr -join " || '|' || ") FROM $(Q $T) P WHERE $where ORDER BY $ordem;") 'L' ($n + 2 + $alvo.Alvos.Count) | ForEach-Object {
        $campos = @($_ | ForEach-Object { $_.TrimEnd() })
        $chave = @()
        if ($n) { $chave = @($campos[0..($n - 1)]) }
        [pscustomobject]@{
            Chave     = $chave
            Descricao = $campos[$n]
            Estoque   = (Format-Number $campos[$n + 1])
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
Write-Host 'gera divergência na ANVISA (veja o README). Pode deixar o Digifarma aberto, mas ninguém deve'
Write-Host 'estar com o cadastro destes produtos aberto: ao salvar, o Digifarma pode gravar a marcação de volta.'
if (-not $SemPerguntar) {
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
$itens = New-Object Collections.Generic.List[object]
$volta = New-Object Collections.Generic.List[string]
if ($pk) {
    foreach ($row in $sel) {
        $cond = (@(for ($k = 0; $k -lt $n; $k++) { "$(Q $pk[$k].Campo) = $(L $pk[$k] $row.Chave[$k])" })) -join ' AND '
        for ($i = 0; $i -lt $alvo.Alvos.Count; $i++) {
            $a = $alvo.Alvos[$i]
            if ($row.Flags[$i] -cne $a.TextoMarcado) { continue }
            $c = Q $a.Col.Campo
            $itens.Add([pscustomobject]@{ Sql = "UPDATE $(Q $T) SET $c = $($a.Desmarcado) WHERE $cond AND $c = $($a.Marcado);"; Codigo = ($row.Chave -join '/') })
            $volta.Add("UPDATE $(Q $T) SET $c = $($a.Marcado) WHERE $cond AND $(Format-Equals $c $a.Desmarcado);")
        }
    }
}
if ($volta.Count) {
    $desfazer = Join-Path $PastaSaida 'desfazer.sql'
    $volta.Insert(0, "/* Remarca os produtos desmarcados em $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'). Banco: $Banco */")
    $volta.Insert(1, "/* Uso: .\desmarcar-controlados.ps1 -Banco <banco> -Desfazer desfazer.sql */")
    $volta.Add('COMMIT;')
    [IO.File]::WriteAllLines($desfazer, $volta, $Ansi)
    Write-Log "Script para desfazer: $desfazer"
} else {
    Write-Log "Sem chave primária em ${T}: não gerei desfazer.sql (use o backup para voltar)."
}

# Com o Digifarma aberto, um produto pode estar em uso (venda baixando estoque, cadastro sendo salvo):
# a transação espera até $EsperaTrava s por ele em vez de falhar na hora.
$Transacao = "SET TRANSACTION READ WRITE WAIT ISOLATION LEVEL READ COMMITTED LOCK TIMEOUT $EsperaTrava"

if (-not $pk) {
    $upd = foreach ($a in $alvo.Alvos) {
        $filtro = @{ Todos = ''; ComEstoque = " AND $($est.Expr) > 0"; SemEstoque = " AND $($est.Expr) <= 0" }[$Estoque]
        "UPDATE $(Q $T) P SET $(Q $a.Col.Campo) = $($a.Desmarcado) WHERE P.$(Q $a.Col.Campo) = $($a.Marcado)$filtro;"
    }
    $res = Invoke-Isql ("$Transacao;`n" + ($upd -join "`n") + "`nCOMMIT;") -PodeFalhar
    $depois = Get-Counts
    if ($null -eq $res) {
        if (-not @(for ($i = 0; $i -lt $alvo.Alvos.Count; $i++) { if ($antes[$i] -ne $depois[$i]) { $i } })) {
            Stop-Script 'o banco desfez a transação inteira; nada foi alterado.'
        }
        Stop-Script "as contagens mudaram apesar do erro (antes: $($antes -join '/'); depois: $($depois -join '/')). Confira no Digifarma; para voltar, use o backup."
    }
    for ($i = 0; $i -lt $alvo.Alvos.Count; $i++) {
        Write-Log "  $($alvo.Alvos[$i].Kind): $($antes[$i] - $depois[$i]) desmarcado(s) de $($esperado[$i]) previsto(s); ainda marcados (todos): $($depois[$i])"
    }
    Write-Log 'Concluído. Confira alguns produtos no Digifarma.'
    exit 0
}

# Com chave primária: blocos de produtos, cada um na sua transação. Produto que continua em uso depois
# da espera fica de fora sem desfazer os outros (WHEN ANY) e é tentado de novo nas próximas rodadas.
# Devolve quantas linhas foram alteradas e as posições (em $Lote) dos comandos que falharam.
function Invoke-Updates($Lote) {
    $sql = New-Object Text.StringBuilder
    [void]$sql.AppendLine('SET TERM ^ ;')
    $i = 0
    while ($i -lt $Lote.Count) {
        [void]$sql.AppendLine("$Transacao^")
        [void]$sql.AppendLine("EXECUTE BLOCK RETURNS (R VARCHAR(1000)) AS DECLARE N INTEGER = 0; DECLARE F VARCHAR(900) = ''; BEGIN")
        $inicio = $sql.Length
        while ($i -lt $Lote.Count -and ($sql.Length - $inicio) -lt 8000) {
            [void]$sql.AppendLine("BEGIN $($Lote[$i].Sql) N = N + ROW_COUNT; WHEN ANY DO F = F || '$i,'; END")
            $i++
        }
        [void]$sql.AppendLine("R = '#U|' || N || '|' || F; SUSPEND; END^")
        [void]$sql.AppendLine('COMMIT^')
    }
    [void]$sql.AppendLine('SET TERM ; ^')
    $res = Invoke-Isql $sql.ToString() -PodeFalhar
    if ($null -eq $res) { return $null }
    $ok = 0
    $falhas = @()
    foreach ($r in @(Get-Rows $res 'U' 2)) {
        $ok += [int]$r[0]
        $falhas += @($r[1].Split(',') | Where-Object { $_ } | ForEach-Object { [int]$_ })
    }
    return @{ Ok = $ok; Falhas = $falhas }
}

$pendentes = @(0..($itens.Count - 1))
$feitos = 0
# (o contador não pode se chamar $t: o PowerShell não diferencia maiúsculas e ele apagaria $T, a tabela)
for ($rodada = 1; $rodada -le $Tentativas -and $pendentes.Count; $rodada++) {
    if ($rodada -gt 1) {
        Write-Log "  $($pendentes.Count) marcação(ões) em produto em uso em outro computador; tentando de novo em $PausaTentativa s ($rodada de $Tentativas) ..."
        Start-Sleep -Seconds $PausaTentativa
    }
    $r = Invoke-Updates @($pendentes | ForEach-Object { $itens[$_] })
    if ($null -eq $r) {
        Stop-Script "a gravação parou no meio; o que já foi gravado continua gravado. Rode a simulação de novo para ver o que falta; para voltar, use -Desfazer $desfazer."
    }
    $feitos += $r.Ok
    $pendentes = @($r.Falhas | ForEach-Object { $pendentes[$_] })
}

$depois = Get-Counts
for ($i = 0; $i -lt $alvo.Alvos.Count; $i++) { Write-Log "  Ainda marcados como $($alvo.Alvos[$i].Kind) (todos): $($depois[$i])" }
Write-Log "  Desmarcadas: $feitos de $($itens.Count) marcação(ões) escolhida(s)."
$outros = $itens.Count - $feitos - $pendentes.Count
if ($outros -gt 0) { Write-Log "  $outros marcação(ões) já tinham sido mudadas por alguém no Digifarma durante a execução." }
$emUso = @($pendentes | ForEach-Object { $itens[$_].Codigo } | Sort-Object -Unique)
if ($emUso) {
    Write-Log "ATENÇÃO: $($emUso.Count) produto(s) continuaram em uso em outro computador e seguem marcados: $($emUso -join ', ')"
    if ($pk.Count -eq 1) { Write-Log "  Rode de novo mais tarde com: -Aplicar -Codigos $($emUso -join ',')" }
    exit 3
}
Write-Log 'Concluído. Se algum computador estiver com a tela de um destes produtos aberta, feche e abra de novo; confira alguns produtos no Digifarma.'
#ARQUIVO-FIM
#ARQUIVO-INICIO relatorios-digifarma.ps1
<#
.SYNOPSIS
Relatórios do Digifarma (banco Firebird). Só lê o banco: nunca altera nada.

.DESCRIPTION
-Janela: abre uma janela com data de início, data de fim e um botão para cada relatório.
-Relatorio CurvaABC: produtos vendidos no período, do maior para o menor faturamento, com a classe A, B ou C.
-Relatorio SugestaoCompra: quanto comprar de cada produto para durar -DiasEstoque dias, pela venda média do período.
   Grava uma planilha (CSV) e, se houver a planilha de cotação em branco (-Modelo), uma cópia dela com
   PRODUTO e QUANT preenchidos na aba Cotação. A planilha em branco nunca é alterada.
-Relatorio LotesVencendo: lotes com saldo que vencem entre -DataInicio e -DataFim (inclui os já vencidos, se o
   início for no passado). Só lotes de produtos com estoque. Sem as datas: de 30 dias atrás a 90 dias à frente.
-Relatorio EstoqueNegativo: produtos com estoque abaixo de zero (não usa datas).
-Relatorio ConferenciaSNGPC: psicotrópicos e antimicrobianos cujo estoque não bate com a soma dos lotes, com
   estoque negativo, lote vencido com saldo ou lote com saldo negativo (não usa datas).
-Mapa: arquivo de texto com as tabelas e colunas do banco (só nomes e tipos, nenhum dado).
-Abrir (com -Relatorio): abre a planilha CSV do relatório assim que ela fica pronta.
-ArquivoSaida (com -Relatorio): grava o resultado em texto separado por tabulação, números com ponto, para a
   macro da planilha de cotação (Relatorios.bas) ler e escrever nas abas dos relatórios.
Onde ficam as vendas no banco do Digifarma é configurado no bloco $EsquemaPadrao (ou num arquivo -Esquema .psd1).

.EXAMPLE
.\relatorios-digifarma.ps1 -Banco 'localhost:C:\Digifarma\Dados\Digifarma6.FDB' -Janela
.\relatorios-digifarma.ps1 -Banco 'localhost:C:\Digifarma\Dados\Digifarma6.FDB' -Relatorio CurvaABC -DataInicio 01/09/2026 -DataFim 30/09/2026
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Banco,
    [string]$Usuario = 'SYSDBA',
    [switch]$Janela,
    [switch]$Mapa,
    [switch]$ContarLinhas,
    [ValidateSet('CurvaABC', 'SugestaoCompra', 'LotesVencendo', 'EstoqueNegativo', 'ConferenciaSNGPC')][string]$Relatorio,
    [string]$DataInicio,
    [string]$DataFim,
    [ValidateRange(1, 365)][int]$DiasEstoque = 30,
    [string]$Modelo,
    [string]$Esquema,
    [string]$Isql,
    [string]$PastaSaida,
    [string]$ArquivoSaida,  # usado pela macro da planilha: resultado em texto separado por tabulação
    [switch]$Abrir          # abre o CSV gerado (usado pelo Digifarma.bat)
)
$ErrorActionPreference = 'Stop'

$Utf8Bom = New-Object Text.UTF8Encoding $true
$Utf8SemBom = New-Object Text.UTF8Encoding $false
$Utf8Estrito = New-Object Text.UTF8Encoding $false, $true
$Ansi = [Text.Encoding]::GetEncoding(1252)
$BR = [Globalization.CultureInfo]::GetCultureInfo('pt-BR')
$Inv = [Globalization.CultureInfo]::InvariantCulture
$TiposTexto = @(14, 37)
$TiposQtd = @(7, 8, 16, 10, 27)
$script:Senha = $null
$script:ModoJanela = $false
$script:Meta = $null
$RelatoriosComData = @('CurvaABC', 'SugestaoCompra', 'LotesVencendo')
if (-not $PastaSaida) { $PastaSaida = Join-Path $PSScriptRoot 'registros' }
if (-not $Modelo) { $Modelo = Join-Path $PSScriptRoot 'Cotacao_Pronta_em_branco.xlsx' }

# Onde ficam as vendas no banco do Digifarma. Vazio = ainda não confirmado pelo mapa do banco.
# ProdChave e ProdDescricao vazios são descobertos sozinhos (chave primária e coluna de nome).
$EsquemaPadrao = [ordered]@{
    ProdTabela          = 'PRODUTOS'
    ProdChave           = $null
    ProdDescricao       = $null
    ProdCodBarras       = $null
    ProdEstoque         = 'PROD_SALDO'
    ProdPsicotropico    = 'PSICOTROPICO'      # marcas do cadastro; coluna que não existir fica de fora
    ProdAntimicrobiano  = 'ANTIMICROBIANO'
    ProdMarcadoValor    = 'S'
    LoteTabela          = 'LOTES'             # lotes: nomes vistos no -Descobrir do seu banco
    LoteProduto         = 'PRODUTO_ID'
    LoteNumero          = 'NUM_LOTE'
    LoteVencimento      = 'LOTE_VENCIMENTO'
    LoteQuantidade      = 'LOTE_QUANTIDADE'   # saldo atual do lote
    VendaTabela         = $null   # cabeçalho da venda (data, cancelada)
    VendaChave          = $null
    VendaData           = $null
    VendaCancelada      = $null
    VendaCanceladaValor = 'S'
    ItemTabela          = $null   # itens vendidos
    ItemVenda           = $null   # coluna do item que aponta para a venda
    ItemProduto         = $null
    ItemQuantidade      = $null
    ItemValorTotal      = $null   # valor total do item; ou ItemPrecoUnitario (quantidade × preço)
    ItemPrecoUnitario   = $null
    ItemData            = $null   # se a data estiver no próprio item (sem VendaTabela)
    ItemCancelado       = $null
    ItemCanceladoValor  = 'S'
}

# Na janela o erro vira mensagem na tela; na linha de comando, encerra com código de saída.
function Stop-Script([string]$Msg, [int]$Codigo = 1) {
    if ($script:ModoJanela) { throw $Msg }
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
    # Na janela, continua atendendo o Windows enquanto espera (senão ela aparece como "Não está respondendo").
    if ($script:ModoJanela) {
        while (-not $p.WaitForExit(100)) { [Windows.Forms.Application]::DoEvents() }
    }
    $p.WaitForExit()
    $t1.Wait(); $t2.Wait()
    return [pscustomobject]@{ Codigo = $p.ExitCode; Saida = (Convert-Bytes $out.ToArray()); Erro = (Convert-Bytes $err.ToArray()) }
}

# Executa SQL só de leitura pelo isql (-b: para no primeiro erro) e devolve as linhas da saída.
function Invoke-Isql([string]$Sql) {
    $tmp = [IO.Path]::GetTempFileName()
    try {
        # Transação só de leitura e sem fotografia longa do banco: não atrapalha as vendas do Digifarma.
        [IO.File]::WriteAllText($tmp, "SET HEADING OFF;`nSET TRANSACTION READ ONLY ISOLATION LEVEL READ COMMITTED;`n$Sql`n", $Ansi)
        $r = Start-Tool $script:IsqlExe @('-b', '-q', '-ch', 'NONE', '-user', $Usuario, '-i', $tmp, $Banco)
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
    $msg = (($r.Erro -split "`r?`n") | Where-Object { $_.Trim() -and $_.Trim() -ne 'Rolling back work.' }) -join "`n"
    if ($r.Codigo -ne 0 -or $msg) {
        if (-not $msg) { $msg = (@($r.Saida -split "`r?`n" | Where-Object { $_.Trim() }) | Select-Object -Last 5) -join "`n" }
        Stop-Script "o isql falhou (código $($r.Codigo)): $msg"
    }
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
    # Primeiro a pasta do Firebird: o SQL Server também instala um isql.exe que pode estar no PATH.
    foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if (-not $base) { continue }
        foreach ($padrao in @('Firebird\*\isql.exe', 'Firebird\*\bin\isql.exe')) {
            $achado = Get-ChildItem -Path (Join-Path $base $padrao) -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
            if ($achado) { return $achado.FullName }
        }
    }
    $cmd = Get-Command 'isql.exe', 'isql-fb' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
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

function ConvertTo-Number([string]$S) {
    $d = 0.0
    if ([double]::TryParse($S, [Globalization.NumberStyles]::Float, $Inv, [ref]$d)) { return $d }
    return 0.0
}

function New-OutputPath([string]$Nome) {
    New-Item -ItemType Directory -Force $PastaSaida | Out-Null
    return Join-Path (Resolve-Path -LiteralPath $PastaSaida).Path $Nome
}

# CSV para o Excel em português: separador ';', UTF-8 com BOM, tudo entre aspas.
function Write-Csv([string]$Arquivo, [string[]]$Cabecalho, $Linhas) {
    $saida = New-Object Collections.Generic.List[string]
    foreach ($campos in @(, $Cabecalho) + @($Linhas)) {
        $saida.Add((($campos | ForEach-Object { '"' + ([string]$_).Replace('"', '""') + '"' }) -join ';'))
    }
    [IO.File]::WriteAllLines($Arquivo, $saida, $Utf8Bom)
}

# Texto separado por tabulação, UTF-8 sem BOM, números com ponto: lido pela macro da planilha.
function Write-Tsv([string]$Arquivo, [string[]]$Cabecalho, $Linhas) {
    $saida = New-Object Collections.Generic.List[string]
    foreach ($campos in @(, $Cabecalho) + @($Linhas)) {
        $saida.Add((($campos | ForEach-Object { ([string]$_) -replace "[`t`r`n]", ' ' }) -join "`t"))
    }
    $pasta = Split-Path -Parent $Arquivo
    if ($pasta) { New-Item -ItemType Directory -Force $pasta | Out-Null }
    [IO.File]::WriteAllLines($Arquivo, $saida, $Utf8SemBom)
}

function Format-Inv([double]$X) { return $X.ToString('0.##########', $Inv) }

# ---------- estrutura do banco (só metadados) ----------
function Get-Meta {
    if ($script:Meta) { return $script:Meta }
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
    if (-not $colunas) { Stop-Script 'o banco não tem tabelas de usuário. Confira o caminho em -Banco.' }
    $script:Meta = @{
        Colunas  = $colunas
        Chaves   = @(Get-Rows $linhas 'K' 2)
        Ligacoes = @(Get-Rows $linhas 'F' 4)
        Indices  = @(Get-Rows $linhas 'I' 4)
        Procs    = @(Get-Rows $linhas 'P' 1 | ForEach-Object { $_[0] })
    }
    return $script:Meta
}

# ---------- mapa do banco: só nomes e tipos, nenhum dado ----------
function New-Mapa([bool]$Contar) {
    $m = Get-Meta
    $tabelas = @($m.Colunas | ForEach-Object { $_[0] } | Select-Object -Unique)
    $ehVisao = @{}
    foreach ($c in $m.Colunas) { $ehVisao[$c[0]] = ($c[9] -eq 'V') }

    $contagem = @{}
    if ($Contar) {
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
    [void]$txt.AppendLine("Tabelas: $(@($tabelas | Where-Object { -not $ehVisao[$_] }).Count)   Visões: $(@($tabelas | Where-Object { $ehVisao[$_] }).Count)   Procedimentos: $($m.Procs.Count)")
    [void]$txt.AppendLine('Legenda: * chave primária, ! obrigatória, = calculada')
    foreach ($t in $tabelas) {
        $pk = @($m.Chaves | Where-Object { $_[0] -eq $t } | ForEach-Object { $_[1] })
        $tipoTab = if ($ehVisao[$t]) { 'visão' } else { 'tabela' }
        $qtd = if ($contagem.ContainsKey($t)) { ", $($contagem[$t].ToString('N0', $BR)) linha$(if ($contagem[$t] -ne 1) { 's' })" } else { '' }
        [void]$txt.AppendLine('')
        [void]$txt.AppendLine("== $t  [$tipoTab$qtd]")
        foreach ($c in @($m.Colunas | Where-Object { $_[0] -eq $t })) {
            $marca = $(if ($pk -contains $c[1]) { '*' } else { ' ' }) + $(if ($c[7] -eq 'S') { '!' } else { ' ' }) + $(if ($c[8] -eq 'S') { '=' } else { ' ' })
            [void]$txt.AppendLine(('  {0} {1,-32} {2}' -f $marca, $c[1], (Format-Type ([int]$c[2]) ([int]$c[3]) ([int]$c[4]) ([int]$c[5]) ([int]$c[6]))))
        }
        foreach ($f in @($m.Ligacoes | Where-Object { $_[0] -eq $t })) { [void]$txt.AppendLine("     liga: $($f[1]) -> $($f[2]).$($f[3])") }
        $idx = @($m.Indices | Where-Object { $_[0] -eq $t } | Group-Object { $_[1] })
        if ($idx) {
            $desc = $idx | ForEach-Object { "$(($_.Group | ForEach-Object { $_[3] }) -join '+')$(if ($_.Group[0][2] -eq '1') { ' (único)' })" }
            [void]$txt.AppendLine("     índices: $($desc -join '; ')")
        }
    }
    if ($m.Procs) {
        [void]$txt.AppendLine('')
        [void]$txt.AppendLine("== PROCEDIMENTOS: $($m.Procs -join ', ')")
    }
    $arquivo = New-OutputPath "mapa-do-banco-$(Get-Date -Format 'yyyyMMdd-HHmm').txt"
    [IO.File]::WriteAllText($arquivo, $txt.ToString(), $Utf8Bom)
    Write-Host "Mapa gravado em: $arquivo ($($tabelas.Count) tabelas e visões, $($m.Colunas.Count) colunas)."
    return $arquivo
}

# ---------- onde ficam produtos e vendas ----------
function Find-Column($Tabela, [string]$Coluna, [string]$Chave) {
    $c = @((Get-Meta).Colunas | Where-Object { $_[0] -eq $Tabela -and $_[1] -eq $Coluna })
    if (-not $c) { Stop-Script "configuração $Chave = '$Coluna': essa coluna não existe em $Tabela." }
    return $c[0]
}

# Uso: 'Produtos' (só o cadastro), 'Lotes' (cadastro e lotes) ou 'Vendas' (cadastro e vendas).
function Resolve-Esquema([string]$Uso = 'Vendas') {
    $e = [ordered]@{}
    foreach ($k in $EsquemaPadrao.Keys) { $e[$k] = $EsquemaPadrao[$k] }
    if ($Esquema) {
        if (-not (Test-Path -LiteralPath $Esquema -PathType Leaf)) { Stop-Script "arquivo de configuração '$Esquema' não encontrado." }
        $cfg = Import-PowerShellDataFile -LiteralPath $Esquema
        foreach ($k in $cfg.Keys) {
            if (-not $e.Contains($k)) { Stop-Script "chave desconhecida '$k' em $Esquema." }
            $e[$k] = $cfg[$k]
        }
    }
    foreach ($k in @($e.Keys)) {
        if ($e[$k] -and $k -notmatch 'Valor$' -and $e[$k] -notmatch '^[A-Za-z_][A-Za-z0-9_$]*$') { Stop-Script "configuração $k = '$($e[$k])': nome inválido." }
        if ($e[$k] -and $k -match 'Valor$' -and $e[$k] -notmatch '^[A-Za-z0-9]{1,10}$') { Stop-Script "configuração $k = '$($e[$k])': valor inválido." }
    }
    $m = Get-Meta
    $tabelas = @($m.Colunas | ForEach-Object { $_[0] } | Select-Object -Unique)
    foreach ($k in @('ProdTabela', 'VendaTabela', 'ItemTabela')) {
        if (-not $e[$k]) { continue }
        $achada = @($tabelas | Where-Object { $_ -eq $e[$k] })
        if (-not $achada) { Stop-Script "configuração $k = '$($e[$k])': essa tabela não existe no banco." }
        $e[$k] = $achada[0]
    }

    # Produtos: chave primária e coluna de nome descobertas sozinhas quando não informadas.
    $prod = $e.ProdTabela
    $colsProd = @($m.Colunas | Where-Object { $_[0] -eq $prod })
    if (-not $e.ProdChave) {
        $pk = @($m.Chaves | Where-Object { $_[0] -eq $prod })
        if ($pk.Count -ne 1) { Stop-Script "não achei a chave de $prod; informe ProdChave na configuração." }
        $e.ProdChave = $pk[0][1]
    }
    if (-not $e.ProdDescricao) {
        $textos = @($colsProd | Where-Object { $TiposTexto -contains [int]$_[2] })
        foreach ($padrao in @('^(PROD_?)?DESCRICAO$', '^(PROD_?)?NOME$', '^(PROD_?)?DESCR$', '^(PROD_?)?DESC$', '^DESCRICAO_?PRODUTO$', '^NOME_?PRODUTO$', 'DESCRICAO', 'DESCRI', '^NOME', 'NOME$')) {
            $d = $textos | Where-Object { $_[1] -match $padrao } | Select-Object -First 1
            if ($d) { $e.ProdDescricao = $d[1]; break }
        }
        if (-not $e.ProdDescricao) { Stop-Script "não achei a coluna com o nome do produto em $prod; informe ProdDescricao na configuração." }
    }
    if (-not $e.ProdCodBarras) {
        $b = $colsProd | Where-Object { $TiposTexto -contains [int]$_[2] -and $_[1] -match 'BARRA|EAN|GTIN' } | Select-Object -First 1
        if ($b) { $e.ProdCodBarras = $b[1] }
    }
    foreach ($k in @('ProdChave', 'ProdDescricao', 'ProdCodBarras', 'ProdEstoque')) {
        if ($e[$k]) { $e[$k] = (Find-Column $prod $e[$k] $k)[1] }
    }
    # Marcas de controlado: se a coluna não existir, o relatório sai sem essa informação.
    foreach ($k in @('ProdPsicotropico', 'ProdAntimicrobiano')) {
        if (-not $e[$k]) { continue }
        $c = @($colsProd | Where-Object { $_[1] -eq $e[$k] })
        if ($c) { $e[$k] = $c[0][1] } else { $e[$k] = $null }
    }
    if ($Uso -eq 'Produtos') { return $e }

    if ($Uso -eq 'Lotes') {
        $achada = @($tabelas | Where-Object { $_ -eq $e.LoteTabela })
        if (-not $e.LoteTabela -or -not $achada) { Stop-Script "configuração LoteTabela = '$($e.LoteTabela)': essa tabela não existe no banco." 2 }
        $e.LoteTabela = $achada[0]
        foreach ($k in @('LoteProduto', 'LoteVencimento', 'LoteQuantidade')) {
            if (-not $e[$k]) { Stop-Script "falta configurar $k (coluna da tabela $($e.LoteTabela))." 2 }
        }
        foreach ($k in @('LoteProduto', 'LoteVencimento', 'LoteQuantidade')) {
            $e[$k] = (Find-Column $e.LoteTabela $e[$k] $k)[1]
        }
        # Número do lote é só informativo: se a coluna não existir, sai em branco.
        if ($e.LoteNumero) {
            $c = @((Get-Meta).Colunas | Where-Object { $_[0] -eq $e.LoteTabela -and $_[1] -eq $e.LoteNumero })
            if ($c) { $e.LoteNumero = $c[0][1] } else { $e.LoteNumero = $null }
        }
        $tipo = [int](Find-Column $e.LoteTabela $e.LoteVencimento 'LoteVencimento')[2]
        if (@(12, 35) -notcontains $tipo) { Stop-Script "configuração LoteVencimento = '$($e.LoteVencimento)': essa coluna não é de data." 2 }
        if ($tipo -eq 12) { $e['LoteVencimentoTipo'] = 'DATE' } else { $e['LoteVencimentoTipo'] = 'TIMESTAMP' }
        if ($TiposQtd -notcontains [int](Find-Column $e.LoteTabela $e.LoteQuantidade 'LoteQuantidade')[2]) {
            Stop-Script "configuração LoteQuantidade = '$($e.LoteQuantidade)': essa coluna não é numérica." 2
        }
        return $e
    }

    # Vendas: sem essas informações não há como somar o que foi vendido no período.
    $faltam = @()
    foreach ($k in @('ItemTabela', 'ItemProduto', 'ItemQuantidade')) { if (-not $e[$k]) { $faltam += $k } }
    if (-not $e.ItemValorTotal -and -not $e.ItemPrecoUnitario) { $faltam += 'ItemValorTotal' }
    if ($e.VendaTabela -and -not $e.VendaChave) {
        $pkVenda = @($m.Chaves | Where-Object { $_[0] -eq $e.VendaTabela })
        if ($pkVenda.Count -eq 1) { $e.VendaChave = $pkVenda[0][1] }
    }
    if (-not $e.ItemData) {
        foreach ($k in @('VendaTabela', 'VendaChave', 'ItemVenda', 'VendaData')) { if (-not $e[$k]) { $faltam += $k } }
    }
    if ($faltam) {
        Stop-Script ("ainda falta configurar onde ficam as vendas no seu Digifarma ($($faltam -join ', ')).`n" +
            'Gere o mapa do banco (botão "Gerar mapa do banco") e mande o arquivo na conversa.') 2
    }
    foreach ($k in @('ItemVenda', 'ItemProduto', 'ItemQuantidade', 'ItemValorTotal', 'ItemPrecoUnitario', 'ItemData', 'ItemCancelado')) {
        if ($e[$k]) { $e[$k] = (Find-Column $e.ItemTabela $e[$k] $k)[1] }
    }
    if ($e.VendaTabela) {
        foreach ($k in @('VendaChave', 'VendaData', 'VendaCancelada')) {
            if ($e[$k]) { $e[$k] = (Find-Column $e.VendaTabela $e[$k] $k)[1] }
        }
    }
    return $e
}

# Soma, por produto, o que foi vendido entre as duas datas (dia final inteiro incluído).
function Get-Vendas([datetime]$Inicio, [datetime]$Fim) {
    $e = Resolve-Esquema
    $i = 'I.'; $p = 'P.'
    $chave = "COALESCE(REPLACE(CAST($p$(Q $e.ProdChave) AS VARCHAR(40)), '|', '/'), '')"
    $desc = "COALESCE(REPLACE(REPLACE(REPLACE(SUBSTRING($p$(Q $e.ProdDescricao) FROM 1 FOR 100), '|', '/'), ASCII_CHAR(13), ' '), ASCII_CHAR(10), ' '), '')"
    $barras = if ($e.ProdCodBarras) { "COALESCE(REPLACE(TRIM(CAST($p$(Q $e.ProdCodBarras) AS VARCHAR(40))), '|', '/'), '')" } else { "''" }
    $estoque = if ($e.ProdEstoque) { "COALESCE(CAST($p$(Q $e.ProdEstoque) AS VARCHAR(40)), '0')" } else { "'0'" }
    $qtd = "$i$(Q $e.ItemQuantidade)"
    $valor = if ($e.ItemValorTotal) { "$i$(Q $e.ItemValorTotal)" } else { "$qtd * $i$(Q $e.ItemPrecoUnitario)" }
    $de = "CAST('$($Inicio.ToString('yyyy-MM-dd', $Inv))' AS TIMESTAMP)"
    $ate = "CAST('$($Fim.AddDays(1).ToString('yyyy-MM-dd', $Inv))' AS TIMESTAMP)"

    $from = "FROM $(Q $e.ItemTabela) I"
    $usaVenda = -not $e.ItemData
    if ($usaVenda) {
        $from += " JOIN $(Q $e.VendaTabela) V ON V.$(Q $e.VendaChave) = I.$(Q $e.ItemVenda)"
        $data = "V.$(Q $e.VendaData)"
    } else {
        $data = "I.$(Q $e.ItemData)"
    }
    $from += " JOIN $(Q $e.ProdTabela) P ON P.$(Q $e.ProdChave) = I.$(Q $e.ItemProduto)"
    $where = "$data >= $de AND $data < $ate"
    if ($usaVenda -and $e.VendaCancelada) { $where += " AND (V.$(Q $e.VendaCancelada) IS NULL OR V.$(Q $e.VendaCancelada) <> '$($e.VendaCanceladaValor)')" }
    if ($e.ItemCancelado) { $where += " AND (I.$(Q $e.ItemCancelado) IS NULL OR I.$(Q $e.ItemCancelado) <> '$($e.ItemCanceladoValor)')" }
    $grupo = @("$p$(Q $e.ProdChave)", "$p$(Q $e.ProdDescricao)")
    if ($e.ProdCodBarras) { $grupo += "$p$(Q $e.ProdCodBarras)" }
    if ($e.ProdEstoque) { $grupo += "$p$(Q $e.ProdEstoque)" }

    $sql = "SELECT '#V|' || $chave || '|' || $desc || '|' || $barras || '|' || COALESCE(CAST(SUM($qtd) AS VARCHAR(40)), '0') || '|' || " +
        "COALESCE(CAST(SUM($valor) AS VARCHAR(40)), '0') || '|' || $estoque $from WHERE $where GROUP BY $($grupo -join ', ');"
    Write-Host "Somando as vendas de $($Inicio.ToString('dd/MM/yyyy')) a $($Fim.ToString('dd/MM/yyyy')) ..."
    return @(Get-Rows (Invoke-Isql $sql) 'V' 6 | ForEach-Object {
            [pscustomobject]@{
                Codigo     = $_[0].TrimEnd()
                Descricao  = $_[1].TrimEnd()
                CodBarras  = $_[2].Trim()
                Quantidade = (ConvertTo-Number $_[3])
                Valor      = (ConvertTo-Number $_[4])
                Estoque    = (ConvertTo-Number $_[5])
            }
        })
}

function Test-Periodo([datetime]$Inicio, [datetime]$Fim) {
    if ($Inicio.Date -gt $Fim.Date) { Stop-Script 'a data de início é depois da data de fim.' }
}

# ---------- Curva ABC ----------
# Classe pelo faturamento acumulado ANTES do produto: até 80% = A, até 95% = B, o resto = C.
function New-CurvaABC([datetime]$Inicio, [datetime]$Fim) {
    Test-Periodo $Inicio $Fim
    $vendas = @(Get-Vendas $Inicio $Fim | Where-Object { $_.Valor -gt 0 } | Sort-Object -Property @{ Expression = 'Valor'; Descending = $true }, Descricao)
    if (-not $vendas) { Stop-Script 'não houve vendas nesse período.' }
    $total = ($vendas | Measure-Object -Property Valor -Sum).Sum
    $acum = 0.0
    $pos = 0
    $resumo = @{ A = 0; B = 0; C = 0 }
    $ranking = @(foreach ($v in $vendas) {
        $pos++
        $antes = $acum / $total
        $acum += $v.Valor
        $classe = if ($antes -lt 0.8) { 'A' } elseif ($antes -lt 0.95) { 'B' } else { 'C' }
        $resumo[$classe]++
        [pscustomobject]@{ Classe = $classe; Posicao = $pos; Venda = $v; Fatia = $v.Valor / $total; Acumulado = $acum / $total }
    })
    $texto = "Curva ABC: $($vendas.Count) produtos, faturamento R$ $($total.ToString('N2', $BR)). A: $($resumo.A)  B: $($resumo.B)  C: $($resumo.C)."
    if ($ArquivoSaida) {
        Write-Tsv $ArquivoSaida @('Classe', 'Posicao', 'Codigo', 'CodBarras', 'Descricao', 'Quantidade', 'Faturamento', 'Fatia', 'Acumulado', 'Estoque') @(
            foreach ($r in $ranking) {
                , @($r.Classe, $r.Posicao, $r.Venda.Codigo, $r.Venda.CodBarras, $r.Venda.Descricao, (Format-Inv $r.Venda.Quantidade),
                    (Format-Inv $r.Venda.Valor), (Format-Inv $r.Fatia), (Format-Inv $r.Acumulado), (Format-Inv $r.Venda.Estoque))
            })
        Write-Host $texto
        return [pscustomobject]@{ Arquivo = $ArquivoSaida; Resumo = $texto }
    }
    $linhas = @(foreach ($r in $ranking) {
        $v = $r.Venda
        , @($r.Classe, $r.Posicao, $v.Codigo, $v.CodBarras, $v.Descricao, $v.Quantidade.ToString('0.###', $BR), $v.Valor.ToString('0.00', $BR),
            ($r.Fatia * 100).ToString('0.00', $BR), ($r.Acumulado * 100).ToString('0.00', $BR), $v.Estoque.ToString('0.###', $BR))
    })
    $arquivo = New-OutputPath "curva-abc_$($Inicio.ToString('yyyy-MM-dd'))_a_$($Fim.ToString('yyyy-MM-dd')).csv"
    Write-Csv $arquivo @('Classe', 'Posição', 'Código', 'Código de barras', 'Descrição', 'Quantidade vendida', 'Faturamento (R$)',
        '% do faturamento', '% acumulado', 'Estoque atual') $linhas
    Write-Host $texto
    Write-Host "Arquivo: $arquivo"
    return [pscustomobject]@{ Arquivo = $arquivo; Resumo = $texto }
}

# ---------- Sugestão de compra ----------
# Média de venda por dia no período × dias de estoque desejados − estoque atual (negativo conta como zero).
function New-SugestaoCompra([datetime]$Inicio, [datetime]$Fim, [int]$Dias) {
    Test-Periodo $Inicio $Fim
    $diasPeriodo = ($Fim.Date - $Inicio.Date).Days + 1
    $itens = @(foreach ($v in @(Get-Vendas $Inicio $Fim)) {
            if ($v.Quantidade -le 0) { continue }
            $media = $v.Quantidade / $diasPeriodo
            $sugestao = [math]::Ceiling([math]::Round($media * $Dias - [math]::Max($v.Estoque, 0), 6))
            if ($sugestao -le 0) { continue }
            $v | Add-Member -NotePropertyName Media -NotePropertyValue $media -PassThru |
                Add-Member -NotePropertyName Sugestao -NotePropertyValue ([long]$sugestao) -PassThru
        })
    if (-not $itens) { Stop-Script "pelas vendas desse período, o estoque atual já dá para $Dias dias; não há o que comprar." }
    $itens = @($itens | Sort-Object Descricao)
    if ($ArquivoSaida) {
        # NaCotacao = 1 nos que cabem na aba Cotação (1000 linhas): os mais vendidos.
        $cabem = @{}
        foreach ($v in @($itens | Sort-Object Quantidade -Descending | Select-Object -First 1000)) { $cabem[$v.Codigo] = $true }
        Write-Tsv $ArquivoSaida @('Codigo', 'CodBarras', 'Descricao', 'Quantidade', 'MediaDia', 'Estoque', 'Comprar', 'NaCotacao') @(
            foreach ($v in $itens) {
                , @($v.Codigo, $v.CodBarras, $v.Descricao, (Format-Inv $v.Quantidade), (Format-Inv $v.Media), (Format-Inv $v.Estoque),
                    $v.Sugestao, $(if ($cabem.ContainsKey($v.Codigo)) { 1 } else { 0 }))
            })
        $texto = "Sugestão de compra: $($itens.Count) produtos para $Dias dias de estoque (vendas de $diasPeriodo dias)."
        Write-Host $texto
        return [pscustomobject]@{ Arquivo = $ArquivoSaida; Resumo = $texto }
    }
    $arquivo = New-OutputPath "sugestao-compra_$($Inicio.ToString('yyyy-MM-dd'))_a_$($Fim.ToString('yyyy-MM-dd')).csv"
    $linhas = @(foreach ($v in $itens) {
        , @($v.Codigo, $v.CodBarras, $v.Descricao, $v.Quantidade.ToString('0.###', $BR), $v.Media.ToString('0.00', $BR),
            $v.Estoque.ToString('0.###', $BR), $v.Sugestao)
    })
    Write-Csv $arquivo @('Código', 'Código de barras', 'Descrição', 'Vendido no período', 'Média por dia', 'Estoque atual', "Comprar (para $Dias dias)") $linhas
    $texto = "Sugestão de compra: $($itens.Count) produtos para $Dias dias de estoque (vendas de $diasPeriodo dias)."
    Write-Host $texto
    Write-Host "Planilha: $arquivo"
    $cotacao = $null
    if (Test-Path -LiteralPath $Modelo -PathType Leaf) {
        $cotacao = New-OutputPath "Cotacao_$(Get-Date -Format 'yyyy-MM-dd_HHmm').xlsx"
        try {
            $escritos = Write-Cotacao $itens $Modelo $cotacao
        } catch {
            $falha = "a cotação não foi gerada: $($_.Exception.Message) A planilha CSV com a sugestão foi gravada em $arquivo."
            if (-not $script:ModoJanela) { Stop-Script $falha }
            $cotacao = $null
            $texto += " ATENÇÃO: $falha"
        }
        if ($cotacao) {
            Write-Host "Cotação preenchida ($escritos produtos): $cotacao"
            if ($escritos -lt $itens.Count) { $texto += " A cotação tem lugar para $escritos produtos; os outros estão só na planilha CSV." }
        }
    } else {
        $texto += " (Não achei a cotação em branco em $Modelo; gerei só a planilha CSV.)"
        Write-Host "Cotação em branco não encontrada em $Modelo; só o CSV foi gerado."
    }
    return [pscustomobject]@{ Arquivo = $(if ($cotacao) { $cotacao } else { $arquivo }); Csv = $arquivo; Cotacao = $cotacao; Resumo = $texto }
}

# ---------- estoque e lotes (não dependem das vendas) ----------
# Pedaços de SQL do cadastro do produto (tabela com apelido P), no mesmo formato de Get-Vendas.
function Get-ProdSql($e) {
    $x = @{
        Chave    = "COALESCE(REPLACE(CAST(P.$(Q $e.ProdChave) AS VARCHAR(40)), '|', '/'), '')"
        Desc     = "COALESCE(REPLACE(REPLACE(REPLACE(SUBSTRING(P.$(Q $e.ProdDescricao) FROM 1 FOR 100), '|', '/'), ASCII_CHAR(13), ' '), ASCII_CHAR(10), ' '), '')"
        Barras   = "''"
        Estoque  = "'0'"
        Controle = "''"
        Grupo    = @("P.$(Q $e.ProdChave)", "P.$(Q $e.ProdDescricao)")
    }
    if ($e.ProdCodBarras) {
        $x.Barras = "COALESCE(REPLACE(TRIM(CAST(P.$(Q $e.ProdCodBarras) AS VARCHAR(40))), '|', '/'), '')"
        $x.Grupo += "P.$(Q $e.ProdCodBarras)"
    }
    if ($e.ProdEstoque) {
        $x.Estoque = "COALESCE(CAST(P.$(Q $e.ProdEstoque) AS VARCHAR(40)), '0')"
        $x.Grupo += "P.$(Q $e.ProdEstoque)"
    }
    # Controle: 'P' psicotrópico, 'A' antimicrobiano, 'PA' os dois.
    $partes = @()
    foreach ($par in @(@('ProdPsicotropico', 'P'), @('ProdAntimicrobiano', 'A'))) {
        if (-not $e[$par[0]]) { continue }
        $partes += "CASE WHEN P.$(Q $e[$par[0]]) = '$($e.ProdMarcadoValor)' THEN '$($par[1])' ELSE '' END"
        $x.Grupo += "P.$(Q $e[$par[0]])"
    }
    if ($partes) { $x.Controle = $partes -join ' || ' }
    return $x
}

function Format-Controle([string]$C) {
    switch ($C.Trim()) {
        'PA' { return 'Psicotrópico e antimicrobiano' }
        'P' { return 'Psicotrópico' }
        'A' { return 'Antimicrobiano' }
    }
    return ''
}

function Format-Qtd([double]$X) { return $X.ToString('0.###', $BR) }

# Grava o resultado: texto para a macro (-ArquivoSaida) ou CSV. Sem linhas, não grava CSV.
function Save-Relatorio([string]$Nome, [string]$Texto, [string[]]$CabCsv, $LinhasCsv, [string[]]$CabTsv, $LinhasTsv) {
    Write-Host $Texto
    if ($ArquivoSaida) {
        Write-Tsv $ArquivoSaida $CabTsv $LinhasTsv
        return [pscustomobject]@{ Arquivo = $ArquivoSaida; Resumo = $Texto }
    }
    if (-not @($LinhasCsv).Count) { return [pscustomobject]@{ Arquivo = $null; Resumo = $Texto } }
    $arquivo = New-OutputPath $Nome
    Write-Csv $arquivo $CabCsv $LinhasCsv
    Write-Host "Arquivo: $arquivo"
    if ($Abrir -and $env:OS -eq 'Windows_NT') {
        try { Start-Process -FilePath $arquivo } catch { Write-Host 'Não consegui abrir a planilha sozinho; abra o arquivo acima.' }
    }
    return [pscustomobject]@{ Arquivo = $arquivo; Resumo = $Texto }
}

function New-EstoqueNegativo {
    $e = Resolve-Esquema 'Produtos'
    if (-not $e.ProdEstoque) { Stop-Script "falta configurar ProdEstoque (coluna do estoque em $($e.ProdTabela))." 2 }
    $x = Get-ProdSql $e
    $sql = "SELECT '#N|' || $($x.Chave) || '|' || $($x.Desc) || '|' || $($x.Barras) || '|' || $($x.Estoque) || '|' || $($x.Controle) " +
        "FROM $(Q $e.ProdTabela) P WHERE P.$(Q $e.ProdEstoque) < 0 ORDER BY P.$(Q $e.ProdEstoque), P.$(Q $e.ProdDescricao);"
    Write-Host 'Procurando produtos com estoque negativo ...'
    $itens = @(Get-Rows (Invoke-Isql $sql) 'N' 5 | ForEach-Object {
            [pscustomobject]@{
                Codigo    = $_[0].TrimEnd()
                Descricao = $_[1].TrimEnd()
                CodBarras = $_[2].Trim()
                Estoque   = (ConvertTo-Number $_[3])
                Controle  = (Format-Controle $_[4])
            }
        })
    $controlados = @($itens | Where-Object { $_.Controle }).Count
    if ($itens) { $texto = "Estoque negativo: $($itens.Count) produtos, $controlados deles controlados (SNGPC)." }
    else { $texto = 'Nenhum produto com estoque negativo.' }
    $csv = @(foreach ($v in $itens) { , @($v.Codigo, $v.CodBarras, $v.Descricao, (Format-Qtd $v.Estoque), $v.Controle) })
    $tsv = @(foreach ($v in $itens) { , @($v.Codigo, $v.CodBarras, $v.Descricao, (Format-Inv $v.Estoque), $v.Controle) })
    return Save-Relatorio "estoque-negativo_$((Get-Date).ToString('yyyy-MM-dd_HHmm')).csv" $texto `
        @('Código', 'Código de barras', 'Descrição', 'Estoque atual', 'Controle') $csv `
        @('Codigo', 'CodBarras', 'Descricao', 'Estoque', 'Controle') $tsv
}

# Lotes com saldo que vencem no período, de produtos com estoque (lote de produto zerado já saiu).
function New-LotesVencendo([datetime]$Inicio, [datetime]$Fim) {
    Test-Periodo $Inicio $Fim
    $e = Resolve-Esquema 'Lotes'
    $x = Get-ProdSql $e
    $tipo = $e.LoteVencimentoTipo
    $venc = "L.$(Q $e.LoteVencimento)"
    $qtd = "L.$(Q $e.LoteQuantidade)"
    $lote = "''"
    if ($e.LoteNumero) { $lote = "COALESCE(REPLACE(TRIM(CAST(L.$(Q $e.LoteNumero) AS VARCHAR(100))), '|', '/'), '')" }
    $where = "$venc >= CAST('$($Inicio.ToString('yyyy-MM-dd', $Inv))' AS $tipo) AND $venc < CAST('$($Fim.AddDays(1).ToString('yyyy-MM-dd', $Inv))' AS $tipo) AND $qtd > 0"
    if ($e.ProdEstoque) { $where += " AND P.$(Q $e.ProdEstoque) > 0" }
    # Data montada com EXTRACT: funciona também em banco de dialeto 1, onde DATE tem hora.
    $data = "CAST(EXTRACT(YEAR FROM $venc) AS VARCHAR(4)) || '-' || CAST(EXTRACT(MONTH FROM $venc) AS VARCHAR(2)) || '-' || CAST(EXTRACT(DAY FROM $venc) AS VARCHAR(2))"
    $sql = "SELECT '#L|' || $data || '|' || $($x.Chave) || '|' || $($x.Desc) || '|' || $($x.Barras) || '|' || " +
        "$lote || '|' || CAST($qtd AS VARCHAR(40)) || '|' || $($x.Estoque) || '|' || $($x.Controle) " +
        "FROM $(Q $e.LoteTabela) L JOIN $(Q $e.ProdTabela) P ON P.$(Q $e.ProdChave) = L.$(Q $e.LoteProduto) " +
        "WHERE $where ORDER BY $venc, P.$(Q $e.ProdDescricao);"
    Write-Host "Procurando lotes que vencem de $($Inicio.ToString('dd/MM/yyyy')) a $($Fim.ToString('dd/MM/yyyy')) ..."
    $hoje = (Get-Date).Date
    $itens = @(Get-Rows (Invoke-Isql $sql) 'L' 8 | ForEach-Object {
            $v = [datetime]::ParseExact($_[0].Trim(), 'yyyy-M-d', $Inv)
            [pscustomobject]@{
                Vencimento = $v
                Dias       = ($v - $hoje).Days
                Codigo     = $_[1].TrimEnd()
                Descricao  = $_[2].TrimEnd()
                CodBarras  = $_[3].Trim()
                Lote       = $_[4].Trim()
                QtdLote    = (ConvertTo-Number $_[5])
                Estoque    = (ConvertTo-Number $_[6])
                Controle   = (Format-Controle $_[7])
            }
        })
    $vencidos = @($itens | Where-Object { $_.Dias -lt 0 }).Count
    $produtos = @($itens | ForEach-Object { $_.Codigo } | Select-Object -Unique).Count
    $periodo = "$($Inicio.ToString('dd/MM/yyyy')) a $($Fim.ToString('dd/MM/yyyy'))"
    if ($itens) { $texto = "Lotes que vencem de ${periodo}: $($itens.Count) lotes de $produtos produtos; $vencidos já vencidos." }
    else { $texto = "Nenhum lote com saldo vence de $periodo." }
    $csv = @(foreach ($v in $itens) {
            if ($v.Dias -lt 0) { $sit = 'VENCIDO' } elseif ($v.Dias -le 30) { $sit = 'vence em até 30 dias' } else { $sit = '' }
            , @($v.Vencimento.ToString('dd/MM/yyyy'), $v.Dias, $v.Codigo, $v.CodBarras, $v.Descricao, $v.Lote, (Format-Qtd $v.QtdLote),
                (Format-Qtd $v.Estoque), $v.Controle, $sit)
        })
    $tsv = @(foreach ($v in $itens) {
            , @($v.Vencimento.ToString('yyyy-MM-dd', $Inv), $v.Dias, $v.Codigo, $v.CodBarras, $v.Descricao, $v.Lote, (Format-Inv $v.QtdLote),
                (Format-Inv $v.Estoque), $v.Controle)
        })
    return Save-Relatorio "lotes-vencendo_$($Inicio.ToString('yyyy-MM-dd'))_a_$($Fim.ToString('yyyy-MM-dd')).csv" $texto `
        @('Vencimento', 'Dias para vencer', 'Código', 'Código de barras', 'Descrição', 'Lote', 'Saldo do lote', 'Estoque do produto', 'Controle', 'Situação') $csv `
        @('Vencimento', 'Dias', 'Codigo', 'CodBarras', 'Descricao', 'Lote', 'QtdLote', 'Estoque', 'Controle') $tsv
}

# Controlados (psicotrópico/antimicrobiano): o estoque do produto tem de bater com a soma dos saldos dos lotes.
function New-ConferenciaSNGPC {
    $e = Resolve-Esquema 'Lotes'
    if (-not $e.ProdPsicotropico -and -not $e.ProdAntimicrobiano) {
        Stop-Script "não achei as colunas de psicotrópico/antimicrobiano em $($e.ProdTabela); informe ProdPsicotropico e ProdAntimicrobiano na configuração." 2
    }
    if (-not $e.ProdEstoque) { Stop-Script "falta configurar ProdEstoque (coluna do estoque em $($e.ProdTabela))." 2 }
    $x = Get-ProdSql $e
    $qtd = "L.$(Q $e.LoteQuantidade)"
    $venc = "L.$(Q $e.LoteVencimento)"
    $hoje = "CAST('$((Get-Date).ToString('yyyy-MM-dd', $Inv))' AS $($e.LoteVencimentoTipo))"
    $marcas = @()
    $usadas = @()
    foreach ($k in @('ProdPsicotropico', 'ProdAntimicrobiano')) {
        if ($e[$k]) { $marcas += "P.$(Q $e[$k]) = '$($e.ProdMarcadoValor)'"; $usadas += "$($e[$k]) = '$($e.ProdMarcadoValor)'" }
    }
    Write-Host "Controlados: produtos com $($usadas -join ' ou ')."
    $sql = "SELECT '#S|' || $($x.Chave) || '|' || $($x.Desc) || '|' || $($x.Barras) || '|' || $($x.Estoque) || '|' || $($x.Controle) || '|' || " +
        "COALESCE(CAST(SUM($qtd) AS VARCHAR(40)), '0') || '|' || " +
        "COALESCE(CAST(SUM(CASE WHEN $venc < $hoje AND $qtd > 0 THEN $qtd ELSE 0 END) AS VARCHAR(40)), '0') || '|' || " +
        "CAST(SUM(CASE WHEN $qtd < 0 THEN 1 ELSE 0 END) AS VARCHAR(10)) " +
        "FROM $(Q $e.ProdTabela) P LEFT JOIN $(Q $e.LoteTabela) L ON L.$(Q $e.LoteProduto) = P.$(Q $e.ProdChave) " +
        "WHERE ($($marcas -join ' OR ')) GROUP BY $($x.Grupo -join ', ');"
    Write-Host 'Conferindo estoque e lotes dos controlados ...'
    $todos = @(Get-Rows (Invoke-Isql $sql) 'S' 8)
    $itens = @(foreach ($r in $todos) {
            $est = ConvertTo-Number $r[3]
            $soma = ConvertTo-Number $r[5]
            $vencida = ConvertTo-Number $r[6]
            $negativos = [int](ConvertTo-Number $r[7])
            $dif = [math]::Round($est - $soma, 3)
            $prob = @()
            if ($dif -ne 0) { $prob += 'estoque diferente da soma dos lotes' }
            if ($est -lt 0) { $prob += 'estoque negativo' }
            if ($vencida -gt 0) { $prob += 'lote vencido com saldo' }
            if ($negativos -gt 0) { $prob += 'lote com saldo negativo' }
            if ($prob) {
                [pscustomobject]@{
                    Codigo = $r[0].TrimEnd(); Descricao = $r[1].TrimEnd(); CodBarras = $r[2].Trim(); Controle = (Format-Controle $r[4])
                    Estoque = $est; SomaLotes = $soma; Diferenca = $dif; QtdVencida = $vencida; LotesNegativos = $negativos; Situacao = ($prob -join '; ')
                }
            }
        })
    $itens = @($itens | Sort-Object Descricao)
    if ($itens) { $texto = "Conferência SNGPC: $($todos.Count) controlados conferidos; $($itens.Count) com problema." }
    else { $texto = "Conferência SNGPC: $($todos.Count) controlados conferidos; nenhum problema encontrado." }
    $csv = @(foreach ($v in $itens) {
            , @($v.Codigo, $v.CodBarras, $v.Descricao, $v.Controle, (Format-Qtd $v.Estoque), (Format-Qtd $v.SomaLotes), (Format-Qtd $v.Diferenca),
                (Format-Qtd $v.QtdVencida), $v.LotesNegativos, $v.Situacao)
        })
    $tsv = @(foreach ($v in $itens) {
            , @($v.Codigo, $v.CodBarras, $v.Descricao, $v.Controle, (Format-Inv $v.Estoque), (Format-Inv $v.SomaLotes), (Format-Inv $v.Diferenca),
                (Format-Inv $v.QtdVencida), $v.LotesNegativos, $v.Situacao)
        })
    return Save-Relatorio "conferencia-sngpc_$((Get-Date).ToString('yyyy-MM-dd_HHmm')).csv" $texto `
        @('Código', 'Código de barras', 'Descrição', 'Controle', 'Estoque do produto', 'Soma dos lotes', 'Diferença', 'Saldo em lotes vencidos',
            'Lotes com saldo negativo', 'Situação') $csv `
        @('Codigo', 'CodBarras', 'Descricao', 'Controle', 'Estoque', 'SomaLotes', 'Diferenca', 'QtdVencida', 'LotesNegativos', 'Situacao') $tsv
}

# ---------- planilha de cotação ----------
# Copia a cotação em branco e preenche PRODUTO (coluna A) e QUANT (coluna B) da aba "Cotação" a partir
# da linha 3, mexendo direto no XML do .xlsx (não precisa do Excel). Fórmulas e formatação ficam como estão;
# o Excel recalcula tudo ao abrir. Devolve quantos produtos couberam.
function Write-Cotacao($Itens, [string]$ModeloXlsx, [string]$Destino) {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $primeira = 3
    $ultima = 1002
    $lista = @($Itens)
    if ($lista.Count -gt ($ultima - $primeira + 1)) {
        # Cabem 1000: ficam os mais vendidos, em ordem alfabética.
        $lista = @($lista | Sort-Object Quantidade -Descending | Select-Object -First ($ultima - $primeira + 1) | Sort-Object Descricao)
    }
    Copy-Item -LiteralPath $ModeloXlsx -Destination $Destino -Force
    # A cópia não herda "baixado da internet" (Modo Protegido não recalcula) nem "somente leitura".
    if (Get-Command Unblock-File -ErrorAction SilentlyContinue) { try { Unblock-File -LiteralPath $Destino } catch { } }
    (Get-Item -LiteralPath $Destino).IsReadOnly = $false
    $ok = $false
    $zip = [IO.Compression.ZipFile]::Open($Destino, [IO.Compression.ZipArchiveMode]::Update)
    try {
        $ler = {
            param($Nome)
            $ent = $zip.GetEntry($Nome)
            if (-not $ent) { throw "a planilha modelo não tem '$Nome'; ela é mesmo um .xlsx?" }
            $sr = New-Object IO.StreamReader($ent.Open(), $Utf8SemBom)
            try { return $sr.ReadToEnd() } finally { $sr.Dispose() }
        }
        $gravar = {
            param($Nome, $Texto)
            $zip.GetEntry($Nome).Delete()
            $ent = $zip.CreateEntry($Nome, [IO.Compression.CompressionLevel]::Optimal)
            $sw = New-Object IO.StreamWriter($ent.Open(), $Utf8SemBom)
            try { $sw.Write($Texto) } finally { $sw.Dispose() }
        }
        # Aba "Cotação" -> arquivo da aba, pelo workbook.xml e suas relações.
        $wb = & $ler 'xl/workbook.xml'
        $rid = $null
        $abaCotacao = "Cota$([char]0xE7)$([char]0xE3)o"   # "Cotação" sem depender da codificação deste arquivo
        foreach ($s in [regex]::Matches($wb, '<sheet\b[^>]*>')) {
            $nome = [regex]::Match($s.Value, '\bname="([^"]*)"').Groups[1].Value
            if ($nome -eq $abaCotacao) { $rid = [regex]::Match($s.Value, '\br:id="([^"]*)"').Groups[1].Value }
        }
        if (-not $rid) { throw "a planilha modelo não tem a aba '$abaCotacao'." }
        $rels = & $ler 'xl/_rels/workbook.xml.rels'
        $alvo = $null
        foreach ($r in [regex]::Matches($rels, '<Relationship\b[^>]*>')) {
            if ([regex]::Match($r.Value, '\bId="([^"]*)"').Groups[1].Value -eq $rid) { $alvo = [regex]::Match($r.Value, '\bTarget="([^"]*)"').Groups[1].Value }
        }
        if (-not $alvo) { throw 'a planilha modelo está com a aba Cotação sem arquivo.' }
        $caminho = if ($alvo.StartsWith('/')) { $alvo.TrimStart('/') } else { "xl/$alvo" }

        $preencher = @{}
        for ($k = 0; $k -lt $lista.Count; $k++) {
            $v = $lista[$k]
            $nomeProduto = if ($v.CodBarras) { "$($v.Descricao) - $($v.CodBarras)" } else { $v.Descricao }
            $nomeProduto = [Security.SecurityElement]::Escape(($nomeProduto -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''))
            $preencher["A$($primeira + $k)"] = '<is><t xml:space="preserve">' + $nomeProduto + '</t></is>'
            $preencher["B$($primeira + $k)"] = '<v>' + ([long]$v.Sugestao).ToString($Inv) + '</v>'
        }
        $estado = @{ Feitos = 0 }
        $folha = & $ler $caminho
        # Só célula vazia (<c r="A3" s="12"/>) é preenchida: se a aba já tiver produtos, nada casa e o programa para.
        $folha = [regex]::Replace($folha, '<c r="([AB]\d+)"((?:\s+s="\d+")?)\s*/>', [Text.RegularExpressions.MatchEvaluator] {
                param($m)
                $ref = $m.Groups[1].Value
                if (-not $preencher.ContainsKey($ref)) { return $m.Value }
                $estado.Feitos++
                $tipo = if ($ref.StartsWith('A')) { ' t="inlineStr"' } else { '' }
                return "<c r=`"$ref`"$($m.Groups[2].Value)$tipo>$($preencher[$ref])</c>"
            })
        if ($estado.Feitos -ne $preencher.Count) {
            throw "a aba Cotação do modelo não está em branco nas linhas $primeira a $($primeira + $lista.Count - 1) (ou mudou de formato). Use a planilha em branco."
        }
        # Tira das fórmulas o resultado guardado (feito com a planilha vazia): sem ele, Excel e LibreOffice
        # recalculam tudo ao abrir, inclusive os totais do topo e as abas de fornecedores.
        # Texto (t="str") fica com <v></v>, como no próprio modelo; número e outros perdem <v> e o tipo.
        $semCache = '<c\b([^>]*)>(<f\b[^>]*(?:/>|>[^<]*</f>))<v>[^<]+</v></c>'
        $tirarCache = [Text.RegularExpressions.MatchEvaluator] {
            param($m)
            $atr = $m.Groups[1].Value
            if ($atr -match '\bt="str"') { return "<c$atr>$($m.Groups[2].Value)<v></v></c>" }
            return "<c$($atr -replace '\s+t="[^"]*"', '')>$($m.Groups[2].Value)</c>"
        }
        & $gravar $caminho ([regex]::Replace($folha, $semCache, $tirarCache))
        $outras = @($zip.Entries | Where-Object { $_.FullName -like 'xl/worksheets/*.xml' -and $_.FullName -ne $caminho } | ForEach-Object { $_.FullName })
        foreach ($nome in $outras) { & $gravar $nome ([regex]::Replace((& $ler $nome), $semCache, $tirarCache)) }
        # Pede ao Excel para recalcular todas as fórmulas ao abrir.
        if ($wb -match '<calcPr\b[^>]*\bfullCalcOnLoad=') {
            $wb = $wb -replace '(<calcPr\b[^>]*\bfullCalcOnLoad=)"[^"]*"', '$1"1"'
        } elseif ($wb -match '<calcPr\b') {
            $wb = $wb -replace '<calcPr\b', '<calcPr fullCalcOnLoad="1"'
        } elseif ($wb -match '</definedNames>') {
            $wb = $wb -replace '</definedNames>', '</definedNames><calcPr fullCalcOnLoad="1"/>'
        } else {
            $wb = $wb -replace '</sheets>', '</sheets><calcPr fullCalcOnLoad="1"/>'
        }
        & $gravar 'xl/workbook.xml' $wb
        $ok = $true
    } finally {
        $zip.Dispose()
        if (-not $ok) { Remove-Item -LiteralPath $Destino -Force -ErrorAction SilentlyContinue }
    }
    return $lista.Count
}

function Read-Data([string]$Texto, [string]$Nome) {
    $d = [datetime]::MinValue
    if ([datetime]::TryParseExact($Texto, [string[]]@('dd/MM/yyyy', 'd/M/yyyy', 'yyyy-MM-dd'), $Inv, [Globalization.DateTimeStyles]::None, [ref]$d)) { return $d }
    Stop-Script "$Nome '$Texto' inválida; use dd/mm/aaaa (ex.: 01/09/2026)." 2
}

# ---------- janela ----------
function Show-Janela {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [Windows.Forms.Application]::EnableVisualStyles()
    $script:ModoJanela = $true

    $f = New-Object Windows.Forms.Form
    $f.Text = 'Relatórios do Digifarma'
    $f.StartPosition = 'CenterScreen'
    $f.FormBorderStyle = 'FixedDialog'
    $f.MaximizeBox = $false
    $f.Font = New-Object Drawing.Font('Segoe UI', 10)
    $f.ClientSize = New-Object Drawing.Size(580, 400)
    $script:Form = $f
    $script:Ocupado = $false
    $f.Add_FormClosing({
            param($origem, $ev)
            if ($script:Ocupado) {
                $ev.Cancel = $true
                [void][Windows.Forms.MessageBox]::Show('Aguarde o relatório terminar.', 'Relatório em andamento', [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
            }
        })

    $novoRotulo = {
        param($Texto, $X, $Y, $L)
        $r = New-Object Windows.Forms.Label
        $r.Text = $Texto
        $r.Location = New-Object Drawing.Point($X, $Y)
        $r.Size = New-Object Drawing.Size($L, 24)
        $f.Controls.Add($r)
    }
    & $novoRotulo 'Período da pesquisa (vendas; nos lotes, a data de vencimento):' 16 14 550
    & $novoRotulo 'De' 16 46 30
    $script:DIni = New-Object Windows.Forms.DateTimePicker
    $script:DIni.Format = [Windows.Forms.DateTimePickerFormat]::Short
    $script:DIni.Location = New-Object Drawing.Point(48, 42)
    $script:DIni.Width = 130
    $script:DIni.Value = (Get-Date).Date.AddDays(-29)
    $f.Controls.Add($script:DIni)
    & $novoRotulo 'até' 192 46 34
    $script:DFim = New-Object Windows.Forms.DateTimePicker
    $script:DFim.Format = [Windows.Forms.DateTimePickerFormat]::Short
    $script:DFim.Location = New-Object Drawing.Point(228, 42)
    $script:DFim.Width = 130
    $script:DFim.Value = (Get-Date).Date
    $f.Controls.Add($script:DFim)

    & $novoRotulo 'Sugestão de compra: comprar para quantos dias de estoque?' 16 86 430
    $script:NDias = New-Object Windows.Forms.NumericUpDown
    $script:NDias.Minimum = 1
    $script:NDias.Maximum = 365
    $script:NDias.Value = [decimal]$DiasEstoque
    $script:NDias.Location = New-Object Drawing.Point(456, 83)
    $script:NDias.Width = 70
    $f.Controls.Add($script:NDias)

    $script:Botoes = @()
    $novoBotao = {
        param($Texto, $X, $Y, $L, $H, $Acao)
        $b = New-Object Windows.Forms.Button
        $b.Text = $Texto
        $b.Location = New-Object Drawing.Point($X, $Y)
        $b.Size = New-Object Drawing.Size($L, $H)
        $b.Tag = $Acao
        $b.Add_Click({ param($origem) Invoke-Botao $origem.Tag })
        $f.Controls.Add($b)
        $script:Botoes += $b
    }
    & $novoBotao 'Gerar Curva ABC' 16 128 270 44 'CurvaABC'
    & $novoBotao 'Gerar Sugestão de compra (cotação)' 294 128 270 44 'SugestaoCompra'
    & $novoBotao 'Lotes vencendo (no período)' 16 180 176 44 'LotesVencendo'
    & $novoBotao 'Estoque negativo' 202 180 176 44 'EstoqueNegativo'
    & $novoBotao 'Conferência SNGPC' 388 180 176 44 'ConferenciaSNGPC'
    & $novoBotao 'Gerar mapa do banco' 16 236 270 34 'Mapa'

    $script:Status = New-Object Windows.Forms.Label
    $script:Status.Location = New-Object Drawing.Point(16, 282)
    $script:Status.Size = New-Object Drawing.Size(548, 106)
    $script:Status.Text = 'Escolha o período e clique no relatório. Os arquivos vão para a pasta "registros".'
    $f.Controls.Add($script:Status)

    [void]$f.ShowDialog()
}

function Invoke-Botao([string]$Acao) {
    $ini = $script:DIni.Value.Date
    $fim = $script:DFim.Value.Date
    if ($RelatoriosComData -contains $Acao -and $ini -gt $fim) {
        [void][Windows.Forms.MessageBox]::Show('A data de início está depois da data de fim.', 'Período inválido', [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    # Com a data de fim até hoje, o relatório de lotes só traria os já vencidos.
    if ($Acao -eq 'LotesVencendo' -and $fim -le (Get-Date).Date) {
        $resp = [Windows.Forms.MessageBox]::Show("A data de fim ($($fim.ToString('dd/MM/yyyy'))) não passa de hoje: só vão aparecer lotes JÁ VENCIDOS.`n`n" +
            "Para ver os que vão vencer, ponha uma data de fim no futuro (por exemplo, daqui a 90 dias).`n`nGerar assim mesmo?",
            'Lotes vencendo', [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Question)
        if ($resp -ne [Windows.Forms.DialogResult]::Yes) { return }
    }
    $script:Ocupado = $true
    foreach ($b in $script:Botoes) { $b.Enabled = $false }
    $script:Form.Cursor = [Windows.Forms.Cursors]::WaitCursor
    $script:Status.Text = 'Gerando... aguarde (pode levar alguns minutos).'
    [Windows.Forms.Application]::DoEvents()
    try {
        switch ($Acao) {
            'CurvaABC' { $r = New-CurvaABC $ini $fim }
            'SugestaoCompra' { $r = New-SugestaoCompra $ini $fim ([int]$script:NDias.Value) }
            'LotesVencendo' { $r = New-LotesVencendo $ini $fim }
            'EstoqueNegativo' { $r = New-EstoqueNegativo }
            'ConferenciaSNGPC' { $r = New-ConferenciaSNGPC }
            'Mapa' { $arq = New-Mapa $true; $r = [pscustomobject]@{ Arquivo = $arq; Resumo = 'Mapa do banco gerado. Mande este arquivo na conversa.' } }
        }
        $script:Status.Text = "$($r.Resumo)`n$($r.Arquivo)"
        if (-not $r.Arquivo) {
            [void][Windows.Forms.MessageBox]::Show($r.Resumo, 'Pronto', [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
            return
        }
        $resp = [Windows.Forms.MessageBox]::Show("$($r.Resumo)`n`nArquivo:`n$($r.Arquivo)`n`nAbrir agora?", 'Pronto', [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Information)
        if ($resp -eq [Windows.Forms.DialogResult]::Yes) { Start-Process -FilePath $r.Arquivo }
    } catch {
        $script:Status.Text = "Não deu certo: $($_.Exception.Message)"
        [void][Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Não deu certo', [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
    } finally {
        $script:Ocupado = $false
        foreach ($b in $script:Botoes) { $b.Enabled = $true }
        $script:Form.Cursor = [Windows.Forms.Cursors]::Default
    }
}

# ---------- início ----------
if (-not ($Janela -or $Mapa -or $Relatorio)) { Stop-Script 'escolha o que fazer: -Janela, -Mapa ou -Relatorio (CurvaABC, SugestaoCompra, LotesVencendo, EstoqueNegativo ou ConferenciaSNGPC).' 2 }
if ($ArquivoSaida -and -not $Relatorio) { Stop-Script '-ArquivoSaida só vale junto com -Relatorio.' 2 }
if ($Relatorio -eq 'LotesVencendo' -and -not $DataInicio -and -not $DataFim) {
    $ini = (Get-Date).Date.AddDays(-30)
    $fim = (Get-Date).Date.AddDays(90)
    Write-Host "Sem datas: lotes que venceram nos últimos 30 dias e que vencem nos próximos 90."
} elseif ($RelatoriosComData -contains $Relatorio) {
    if (-not $DataInicio -or -not $DataFim) { Stop-Script 'informe -DataInicio e -DataFim (dd/mm/aaaa).' 2 }
    $ini = Read-Data $DataInicio 'data de início'
    $fim = Read-Data $DataFim 'data de fim'
    Test-Periodo $ini $fim
}

$script:IsqlExe = Find-Isql
if (-not $env:ISC_PASSWORD) {
    $seg = Read-Host -AsSecureString "Senha do usuário $Usuario do Firebird"
    $script:Senha = (New-Object Management.Automation.PSCredential('u', $seg)).GetNetworkCredential().Password
}
# Confere banco e senha antes de abrir a janela ou gerar qualquer coisa.
[void](Get-Rows (Invoke-Isql "SELECT '#O|1' FROM RDB`$DATABASE;") 'O' 1)

if ($Janela) { Show-Janela; exit 0 }
if ($Mapa) {
    $arquivo = New-Mapa $ContarLinhas.IsPresent
    Write-Host 'Mande este arquivo na conversa para eu montar os relatórios.'
    if ($env:OS -eq 'Windows_NT') { Start-Process explorer.exe "/select,`"$arquivo`"" }
}
if ($Relatorio -eq 'CurvaABC') { [void](New-CurvaABC $ini $fim) }
if ($Relatorio -eq 'SugestaoCompra') { [void](New-SugestaoCompra $ini $fim $DiasEstoque) }
if ($Relatorio -eq 'LotesVencendo') { [void](New-LotesVencendo $ini $fim) }
if ($Relatorio -eq 'EstoqueNegativo') { [void](New-EstoqueNegativo) }
if ($Relatorio -eq 'ConferenciaSNGPC') { [void](New-ConferenciaSNGPC) }
#ARQUIVO-FIM
#ARQUIVO-INICIO Relatorios.bas
Attribute VB_Name = "Relatorios"
' Relatórios do Digifarma dentro da planilha de cotação (Excel).
' Os botões das abas "Curva ABC", "Sugestão de compra", "Lotes vencendo", "Estoque negativo" e
' "Conferência SNGPC" chamam o relatorios-digifarma.ps1, que só lê o banco do Digifarma, esperam o resultado
' e escrevem na aba. A sugestão também preenche PRODUTO e QUANT da aba "Cotação".
' Instalação (uma vez): Alt+F11 > Arquivo > Importar arquivo > Relatorios.bas; depois Alt+F8 >
' InstalarRelatorios > Executar; por fim salve como "Pasta de Trabalho Habilitada para Macro (*.xlsm)".
Option Explicit

Private Const ABA_ABC As String = "Curva ABC"
Private Const ABA_SUG As String = "Sugestão de compra"
Private Const ABA_CFG As String = "Config relatórios"
Private Const ABA_COT As String = "Cotação"
Private Const ABA_LOT As String = "Lotes vencendo"
Private Const ABA_NEG As String = "Estoque negativo"
Private Const ABA_SNG As String = "Conferência SNGPC"
Private Const TXT_SENHA As String = " A senha do Firebird é pedida numa janela preta."
Private Const LINHA_CAB As Long = 8      ' cabeçalho do resultado
Private Const LINHA_DADOS As Long = 9    ' primeira linha do resultado
Private Const COT_PRIMEIRA As Long = 3   ' aba Cotação: PRODUTO e QUANT de A3 a B1002
Private Const COT_ULTIMA As Long = 1002
Private Const BANCO_PADRAO As String = "localhost:C:\Digifarma\Dados\Digifarma6.FDB"

' ---------- instalação: cria as abas, os campos e os botões ----------
Public Sub InstalarRelatorios()
    Dim cfg As Worksheet, abc As Worksheet, sug As Worksheet, banco As String, pasta As String, usuario As String
    Dim lot As Worksheet, neg As Worksheet, sng As Worksheet
    On Error GoTo Falha
    Application.ScreenUpdating = False
    Set sug = PegarOuCriarAba(ABA_SUG, ABA_COT)
    Set abc = PegarOuCriarAba(ABA_ABC, ABA_SUG)
    Set lot = PegarOuCriarAba(ABA_LOT, ABA_ABC)
    Set neg = PegarOuCriarAba(ABA_NEG, ABA_LOT)
    Set sng = PegarOuCriarAba(ABA_SNG, ABA_NEG)
    Set cfg = PegarOuCriarAba(ABA_CFG, "")

    ' Instalar de novo mantém o que já foi configurado.
    banco = Trim$(CStr(cfg.Range("B3").Value))
    pasta = Trim$(CStr(cfg.Range("B4").Value))
    usuario = Trim$(CStr(cfg.Range("B5").Value))
    If banco = "" Then banco = BANCO_PADRAO
    If pasta = "" Then pasta = ThisWorkbook.Path
    If usuario = "" Then usuario = "SYSDBA"
    With cfg
        .Cells.Clear
        .Range("A1").Value = "CONFIGURAÇÃO DOS RELATÓRIOS DO DIGIFARMA"
        .Range("A1").Font.Bold = True
        .Range("A1").Font.Size = 14
        .Range("A3").Value = "Banco do Digifarma:"
        .Range("B3").Value = banco
        .Range("A4").Value = "Pasta do relatorios-digifarma.ps1:"
        .Range("B4").Value = pasta
        .Range("A5").Value = "Usuário do Firebird:"
        .Range("B5").Value = usuario
        .Range("A3:A5").Font.Bold = True
        .Range("B3:B5").Interior.Color = RGB(255, 255, 204)
        .Range("A7").Value = "A senha do Firebird é pedida numa janela preta a cada relatório; ela não fica gravada na planilha."
        .Range("A8").Value = "Os relatórios só leem o banco do Digifarma; nada é alterado nele."
        .Columns("A").ColumnWidth = 34
        .Columns("B").ColumnWidth = 60
    End With
    DefinirNome "CfgBanco", cfg.Range("B3")
    DefinirNome "CfgPasta", cfg.Range("B4")
    DefinirNome "CfgUsuario", cfg.Range("B5")

    MontarAba abc, "CURVA ABC", "Preencha as datas (dd/mm/aaaa) e clique no botão." & TXT_SENHA, _
              "Gerar Curva ABC", "GerarCurvaABC", True, False
    MontarAba sug, "SUGESTÃO DE COMPRA", "Preencha as datas (dd/mm/aaaa) e os dias e clique no botão." & TXT_SENHA, _
              "Gerar sugestão de compra", "GerarSugestaoCompra", True, True
    MontarAba lot, "LOTES VENCENDO", "Lotes com saldo que vencem entre as duas datas; com o início no passado, " & _
              "aparecem também os já vencidos." & TXT_SENHA, "Gerar lotes vencendo", "GerarLotesVencendo", True, False, _
              "Vencimento de:", "Vencimento até:", -30, 90
    MontarAba neg, "ESTOQUE NEGATIVO", "Produtos com estoque abaixo de zero. Clique no botão." & TXT_SENHA, _
              "Gerar estoque negativo", "GerarEstoqueNegativo", False, False
    MontarAba sng, "CONFERÊNCIA SNGPC", "Psicotrópicos e antimicrobianos com estoque diferente da soma dos lotes, " & _
              "estoque negativo, lote vencido com saldo ou lote negativo. Clique no botão." & TXT_SENHA, _
              "Gerar conferência SNGPC", "GerarConferenciaSNGPC", False, False

    Application.ScreenUpdating = True
    abc.Activate
    MsgBox "Pronto: abas """ & ABA_SUG & """, """ & ABA_ABC & """, """ & ABA_LOT & """, """ & ABA_NEG & """, """ & _
           ABA_SNG & """ e """ & ABA_CFG & """ criadas." & vbLf & vbLf & _
           "Agora salve como ""Pasta de Trabalho Habilitada para Macro do Excel (*.xlsm)"".", vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' Cria a aba logo depois de "depoisDe" (ou no fim, se ela não existir).
Private Function PegarOuCriarAba(ByVal nome As String, ByVal depoisDe As String) As Worksheet
    Dim ws As Worksheet, ref As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets(nome)
    If Len(depoisDe) > 0 Then Set ref = ThisWorkbook.Worksheets(depoisDe)
    On Error GoTo 0
    If ws Is Nothing Then
        If ref Is Nothing Then Set ref = ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count)
        Set ws = ThisWorkbook.Worksheets.Add(After:=ref)
        ws.Name = nome
    End If
    Set PegarOuCriarAba = ws
End Function

Private Sub DefinirNome(ByVal nome As String, ByVal alvo As Range)
    On Error Resume Next
    ThisWorkbook.Names(nome).Delete
    On Error GoTo 0
    ThisWorkbook.Names.Add Name:=nome, RefersTo:="='" & alvo.Worksheet.Name & "'!" & alvo.Address
End Sub

Private Sub MontarAba(ByVal ws As Worksheet, ByVal titulo As String, ByVal instrucao As String, _
                     ByVal textoBotao As String, ByVal macro As String, ByVal comDatas As Boolean, _
                     ByVal comDias As Boolean, Optional ByVal rotuloIni As String = "Data de início:", _
                     Optional ByVal rotuloFim As String = "Data de fim:", Optional ByVal iniPadrao As Long = -29, _
                     Optional ByVal fimPadrao As Long = 0)
    Dim b As Object, ini As Variant, fim As Variant, dias As Variant
    ' Instalar de novo mantém as datas e os dias já preenchidos e não duplica os botões.
    ini = ws.Range("B3").Value
    fim = ws.Range("B4").Value
    dias = ws.Range("B5").Value
    If Not IsDate(ini) Then ini = Date + iniPadrao
    If Not IsDate(fim) Then fim = Date + fimPadrao
    If VarType(dias) <> vbDouble Then dias = 30
    If ws.Buttons.Count > 0 Then ws.Buttons.Delete
    ws.Cells.Clear
    ws.Range("A1").Value = titulo
    ws.Range("A1").Font.Bold = True
    ws.Range("A1").Font.Size = 14
    ws.Range("A2").Value = instrucao
    ws.Range("A2").Font.Italic = True
    If comDatas Then
        ws.Range("A3").Value = rotuloIni
        ws.Range("B3").Value = ini
        ws.Range("A4").Value = rotuloFim
        ws.Range("B4").Value = fim
        ws.Range("B3:B4").NumberFormat = "dd/mm/yyyy"
        ws.Range("B3:B4").Interior.Color = RGB(255, 255, 204)
    End If
    If comDias Then
        ws.Range("A5").Value = "Dias de estoque desejados:"
        ws.Range("B5").Value = dias
        ws.Range("B5").Interior.Color = RGB(255, 255, 204)
    End If
    ws.Range("A3:A5").Font.Bold = True
    ws.Columns("A").ColumnWidth = 26
    ws.Columns("B").ColumnWidth = 14
    Set b = ws.Buttons.Add(ws.Range("D3").Left, ws.Range("D3").Top, 220, 34)
    b.Placement = xlFreeFloating   ' não estica quando o relatório muda a largura das colunas
    b.OnAction = macro
    b.Caption = textoBotao
    b.Name = "btn" & macro
End Sub

' ---------- Curva ABC ----------
Public Sub GerarCurvaABC()
    Dim ws As Worksheet, ini As Date, fim As Date, arq As String, d As Variant
    Dim n As Long, i As Long, saida() As Variant, total As Double, qa As Long, qb As Long, qc As Long
    On Error GoTo Falha
    Set ws = ThisWorkbook.Worksheets(ABA_ABC)
    If Not LerPeriodo(ws, ini, fim) Then Exit Sub
    arq = ArquivoTemporario("abc")
    If Not RodarPrograma("CurvaABC", ini, fim, 30, arq) Then Exit Sub
    d = LerTabela(arq)
    ApagarArquivo arq
    If IsEmpty(d) Then Exit Sub

    ' Arquivo: Classe, Posicao, Codigo, CodBarras, Descricao, Quantidade, Faturamento, Fatia, Acumulado, Estoque
    n = UBound(d, 1) - 1
    ReDim saida(1 To n, 1 To 10)
    For i = 1 To n
        saida(i, 1) = d(i + 1, 1)
        saida(i, 2) = CLng(Val(d(i + 1, 2)))
        saida(i, 3) = d(i + 1, 3)
        saida(i, 4) = d(i + 1, 4)
        saida(i, 5) = d(i + 1, 5)
        saida(i, 6) = Val(d(i + 1, 6))
        saida(i, 7) = Val(d(i + 1, 7))
        saida(i, 8) = Val(d(i + 1, 8))
        saida(i, 9) = Val(d(i + 1, 9))
        saida(i, 10) = Val(d(i + 1, 10))
        total = total + saida(i, 7)
        Select Case saida(i, 1)
            Case "A": qa = qa + 1
            Case "B": qb = qb + 1
            Case Else: qc = qc + 1
        End Select
    Next i

    Application.ScreenUpdating = False
    LimparResultado ws
    EscreverCabecalho ws, Array("Classe", "Posição", "Código", "Código de barras", "Descrição", "Quantidade vendida", _
                                "Faturamento (R$)", "% do faturamento", "% acumulado", "Estoque atual")
    ws.Cells(LINHA_DADOS, 3).Resize(n, 3).NumberFormat = "@"
    ws.Cells(LINHA_DADOS, 1).Resize(n, 10).Value = saida
    ws.Cells(LINHA_DADOS, 7).Resize(n, 1).NumberFormat = "#,##0.00"
    ws.Cells(LINHA_DADOS, 8).Resize(n, 2).NumberFormat = "0.00%"
    ' O arquivo vem na ordem da posição, então as classes ficam em faixas seguidas: A, depois B, depois C.
    If qa > 0 Then ws.Cells(LINHA_DADOS, 1).Resize(qa, 1).Interior.Color = RGB(198, 239, 206)
    If qb > 0 Then ws.Cells(LINHA_DADOS + qa, 1).Resize(qb, 1).Interior.Color = RGB(255, 235, 156)
    If qc > 0 Then ws.Cells(LINHA_DADOS + qa + qb, 1).Resize(qc, 1).Interior.Color = RGB(230, 230, 230)
    ws.Columns("C:D").ColumnWidth = 16
    ws.Columns("E").ColumnWidth = 50
    ws.Columns("F:J").ColumnWidth = 15
    ws.Range("A6").Value = "Período: " & Format$(ini, "dd\/mm\/yyyy") & " a " & Format$(fim, "dd\/mm\/yyyy") & _
                           "   |   Produtos: " & n & "   |   Faturamento: R$ " & Format$(total, "#,##0.00") & _
                           "   |   A: " & qa & "   B: " & qb & "   C: " & qc
    ws.Range("A6").Font.Bold = True
    Application.ScreenUpdating = True
    ws.Activate
    MsgBox "Curva ABC pronta: " & n & " produtos (A: " & qa & ", B: " & qb & ", C: " & qc & ").", vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    If Len(arq) > 0 Then ApagarArquivo arq
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' ---------- Sugestão de compra ----------
Public Sub GerarSugestaoCompra()
    Dim ws As Worksheet, ini As Date, fim As Date, dias As Long, arq As String, d As Variant
    Dim n As Long, i As Long, saida() As Variant, fora As Long, naCotacao As Long, msg As String
    On Error GoTo Falha
    Set ws = ThisWorkbook.Worksheets(ABA_SUG)
    If Not LerPeriodo(ws, ini, fim) Then Exit Sub
    If Not IsNumeric(ws.Range("B5").Value) Then
        MsgBox "Preencha em B5 quantos dias de estoque comprar (de 1 a 365).", vbExclamation, "Relatórios do Digifarma"
        Exit Sub
    End If
    dias = CLng(ws.Range("B5").Value)
    If dias < 1 Or dias > 365 Then
        MsgBox "Os dias de estoque (B5) devem ser de 1 a 365.", vbExclamation, "Relatórios do Digifarma"
        Exit Sub
    End If
    arq = ArquivoTemporario("sugestao")
    If Not RodarPrograma("SugestaoCompra", ini, fim, dias, arq) Then Exit Sub
    d = LerTabela(arq)
    ApagarArquivo arq
    If IsEmpty(d) Then Exit Sub

    ' Arquivo: Codigo, CodBarras, Descricao, Quantidade, MediaDia, Estoque, Comprar, NaCotacao
    n = UBound(d, 1) - 1
    ReDim saida(1 To n, 1 To 7)
    For i = 1 To n
        saida(i, 1) = d(i + 1, 1)
        saida(i, 2) = d(i + 1, 2)
        saida(i, 3) = d(i + 1, 3)
        saida(i, 4) = Val(d(i + 1, 4))
        saida(i, 5) = Val(d(i + 1, 5))
        saida(i, 6) = Val(d(i + 1, 6))
        saida(i, 7) = CLng(Val(d(i + 1, 7)))
        If d(i + 1, 8) <> "1" Then fora = fora + 1
    Next i

    Application.ScreenUpdating = False
    LimparResultado ws
    EscreverCabecalho ws, Array("Código", "Código de barras", "Descrição", "Vendido no período", "Média por dia", _
                                "Estoque atual", "Comprar (para " & dias & " dias)")
    ws.Cells(LINHA_DADOS, 1).Resize(n, 3).NumberFormat = "@"
    ws.Cells(LINHA_DADOS, 1).Resize(n, 7).Value = saida
    ws.Cells(LINHA_DADOS, 5).Resize(n, 1).NumberFormat = "0.00"
    ws.Cells(LINHA_DADOS, 7).Resize(n, 1).Font.Bold = True
    ws.Columns("A:B").ColumnWidth = 16
    ws.Columns("C").ColumnWidth = 50
    ws.Columns("D:G").ColumnWidth = 16
    ws.Range("A6").Value = "Período: " & Format$(ini, "dd\/mm\/yyyy") & " a " & Format$(fim, "dd\/mm\/yyyy") & _
                           "   |   Produtos para comprar: " & n & "   |   Estoque para " & dias & " dias"
    ws.Range("A6").Font.Bold = True
    Application.ScreenUpdating = True

    naCotacao = PreencherCotacao(d, n)
    msg = "Sugestão de compra pronta: " & n & " produtos."
    Select Case naCotacao
        Case -2: msg = msg & vbLf & "Não achei a aba """ & ABA_COT & """ nesta planilha."
        Case -1: msg = msg & vbLf & "A aba """ & ABA_COT & """ não foi alterada."
        Case Else: msg = msg & vbLf & "A aba """ & ABA_COT & """ foi preenchida com " & naCotacao & " produtos (PRODUTO e QUANT)."
    End Select
    If fora > 0 And naCotacao >= 0 Then msg = msg & vbLf & fora & " produtos não couberam na Cotação (ela tem 1000 linhas); eles estão só nesta aba."
    ws.Activate
    MsgBox msg, vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    If Len(arq) > 0 Then ApagarArquivo arq
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' Preenche PRODUTO (nome - código de barras) e QUANT da aba Cotação. Devolve quantos produtos escreveu,
' -1 se o usuário não quis substituir o que já estava lá, -2 se a aba não existe.
Private Function PreencherCotacao(d As Variant, ByVal n As Long) As Long
    Dim wc As Worksheet, protegida As Boolean, prod() As Variant, k As Long, i As Long, nome As String
    Dim usadas As Long, numErro As Long, descErro As String
    On Error Resume Next
    Set wc = ThisWorkbook.Worksheets(ABA_COT)
    On Error GoTo 0
    If wc Is Nothing Then
        PreencherCotacao = -2
        Exit Function
    End If
    ' Colunas digitadas à mão: A-B (produto, quant), E-P (preços), R (desempate), S-AD (condições).
    ' C, D e Q são fórmulas e ficam como estão.
    With Application.WorksheetFunction
        usadas = .CountA(wc.Range("A" & COT_PRIMEIRA & ":B" & COT_ULTIMA)) + _
                 .CountA(wc.Range("E" & COT_PRIMEIRA & ":P" & COT_ULTIMA)) + _
                 .CountA(wc.Range("R" & COT_PRIMEIRA & ":AD" & COT_ULTIMA))
    End With
    If usadas > 0 Then
        If MsgBox("A aba """ & ABA_COT & """ já está preenchida. Substituir pelos produtos da sugestão de compra?" & vbLf & vbLf & _
                  "Isso apaga os produtos, as quantidades e também os preços, desempates e condições já digitados " & _
                  "(colunas A, B, E a P e R a AD), porque eles não valeriam para os produtos novos.", _
                  vbYesNo + vbQuestion + vbDefaultButton2, "Relatórios do Digifarma") <> vbYes Then
            PreencherCotacao = -1
            Exit Function
        End If
    End If
    ReDim prod(1 To COT_ULTIMA - COT_PRIMEIRA + 1, 1 To 2)
    For i = 2 To n + 1
        If d(i, 8) = "1" And k < COT_ULTIMA - COT_PRIMEIRA + 1 Then
            k = k + 1
            nome = d(i, 3)
            If Len(d(i, 2)) > 0 Then nome = nome & " - " & d(i, 2)
            If Len(nome) > 0 Then
                If InStr("=+-@", Left$(nome, 1)) > 0 Then nome = "'" & nome   ' não virar fórmula
            End If
            prod(k, 1) = nome
            prod(k, 2) = CLng(Val(d(i, 7)))
        End If
    Next i
    protegida = wc.ProtectContents
    On Error GoTo Falha
    If protegida Then wc.Unprotect
    wc.Range("A" & COT_PRIMEIRA & ":B" & COT_ULTIMA).ClearContents
    wc.Range("E" & COT_PRIMEIRA & ":P" & COT_ULTIMA).ClearContents
    wc.Range("R" & COT_PRIMEIRA & ":AD" & COT_ULTIMA).ClearContents
    If k > 0 Then wc.Range("A" & COT_PRIMEIRA).Resize(k, 2).Value = prod
    If protegida Then ProtegerCotacao wc
    PreencherCotacao = k
    Exit Function
Falha:
    numErro = Err.Number
    descErro = Err.Description
    Resume Restaurar
Restaurar:
    On Error Resume Next
    If protegida Then ProtegerCotacao wc
    On Error GoTo 0
    Err.Raise numErro, , descErro
End Function

' Mesma proteção da planilha original: sem senha, com a formatação de linhas e colunas liberada.
Private Sub ProtegerCotacao(ByVal wc As Worksheet)
    wc.Protect DrawingObjects:=False, Contents:=True, Scenarios:=False, _
               AllowFormattingColumns:=True, AllowFormattingRows:=True
End Sub

' ---------- Lotes vencendo ----------
Public Sub GerarLotesVencendo()
    Dim ws As Worksheet, ini As Date, fim As Date, arq As String, d As Variant
    Dim n As Long, i As Long, nv As Long, n30 As Long, resumo As String
    On Error GoTo Falha
    Set ws = ThisWorkbook.Worksheets(ABA_LOT)
    If Not LerPeriodo(ws, ini, fim) Then Exit Sub
    arq = ArquivoTemporario("lotes")
    If Not RodarPrograma("LotesVencendo", ini, fim, 30, arq) Then Exit Sub
    d = LerTabela(arq, True)
    ApagarArquivo arq
    If IsEmpty(d) Then Exit Sub

    ' Arquivo: Vencimento, Dias, Codigo, CodBarras, Descricao, Lote, QtdLote, Estoque, Controle (do mais antigo ao mais novo)
    n = UBound(d, 1) - 1
    For i = 2 To n + 1
        If Val(d(i, 2)) < 0 Then
            nv = nv + 1
        ElseIf Val(d(i, 2)) <= 30 Then
            n30 = n30 + 1
        End If
    Next i
    Application.ScreenUpdating = False
    EscreverDados ws, d, Array("Vencimento", "Dias para vencer", "Código", "Código de barras", "Descrição", "Lote", _
                               "Saldo do lote", "Estoque do produto", "Controle"), "DITTTTNNT"
    ' Na ordem do vencimento: primeiro os vencidos (vermelho), depois os que vencem em até 30 dias (amarelo).
    If nv > 0 Then ws.Cells(LINHA_DADOS, 1).Resize(nv, 9).Interior.Color = RGB(255, 199, 206)
    If n30 > 0 Then ws.Cells(LINHA_DADOS + nv, 1).Resize(n30, 9).Interior.Color = RGB(255, 235, 156)
    ws.Columns("C:D").ColumnWidth = 16
    ws.Columns("E").ColumnWidth = 50
    ws.Columns("F:I").ColumnWidth = 16
    If n = 0 Then
        resumo = "Nenhum lote com saldo vence de " & Format$(ini, "dd\/mm\/yyyy") & " a " & Format$(fim, "dd\/mm\/yyyy") & "."
    Else
        resumo = "Vencimento de " & Format$(ini, "dd\/mm\/yyyy") & " a " & Format$(fim, "dd\/mm\/yyyy") & _
                 "   |   Lotes: " & n & "   |   Já vencidos: " & nv & "   |   Vencem em até 30 dias: " & n30
    End If
    ws.Range("A6").Value = resumo
    ws.Range("A6").Font.Bold = True
    Application.ScreenUpdating = True
    ws.Activate
    MsgBox resumo, vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    If Len(arq) > 0 Then ApagarArquivo arq
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' ---------- Estoque negativo ----------
Public Sub GerarEstoqueNegativo()
    Dim ws As Worksheet, arq As String, d As Variant, n As Long, i As Long, nc As Long, resumo As String
    On Error GoTo Falha
    Set ws = ThisWorkbook.Worksheets(ABA_NEG)
    arq = ArquivoTemporario("negativo")
    If Not RodarPrograma("EstoqueNegativo", Date, Date, 30, arq, False) Then Exit Sub
    d = LerTabela(arq, True)
    ApagarArquivo arq
    If IsEmpty(d) Then Exit Sub

    ' Arquivo: Codigo, CodBarras, Descricao, Estoque, Controle (do mais negativo ao menos negativo)
    n = UBound(d, 1) - 1
    For i = 2 To n + 1
        If Len(d(i, 5)) > 0 Then nc = nc + 1
    Next i
    Application.ScreenUpdating = False
    EscreverDados ws, d, Array("Código", "Código de barras", "Descrição", "Estoque atual", "Controle"), "TTTNT"
    ws.Columns("A:B").ColumnWidth = 16
    ws.Columns("C").ColumnWidth = 50
    ws.Columns("D:E").ColumnWidth = 18
    If n = 0 Then
        resumo = "Nenhum produto com estoque negativo."
    Else
        resumo = "Produtos com estoque negativo: " & n & "   |   Controlados (SNGPC): " & nc
    End If
    ws.Range("A6").Value = resumo & "   |   Consultado em " & Format$(Now, "dd\/mm\/yyyy hh:nn")
    ws.Range("A6").Font.Bold = True
    Application.ScreenUpdating = True
    ws.Activate
    MsgBox resumo, vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    If Len(arq) > 0 Then ApagarArquivo arq
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' ---------- Conferência SNGPC ----------
Public Sub GerarConferenciaSNGPC()
    Dim ws As Worksheet, arq As String, d As Variant, n As Long, resumo As String
    On Error GoTo Falha
    Set ws = ThisWorkbook.Worksheets(ABA_SNG)
    arq = ArquivoTemporario("sngpc")
    If Not RodarPrograma("ConferenciaSNGPC", Date, Date, 30, arq, False) Then Exit Sub
    d = LerTabela(arq, True)
    ApagarArquivo arq
    If IsEmpty(d) Then Exit Sub

    ' Arquivo: Codigo, CodBarras, Descricao, Controle, Estoque, SomaLotes, Diferenca, QtdVencida, LotesNegativos, Situacao
    n = UBound(d, 1) - 1
    Application.ScreenUpdating = False
    EscreverDados ws, d, Array("Código", "Código de barras", "Descrição", "Controle", "Estoque do produto", "Soma dos lotes", _
                               "Diferença", "Saldo em lotes vencidos", "Lotes com saldo negativo", "Situação"), "TTTTNNNNIT"
    ws.Columns("A:B").ColumnWidth = 16
    ws.Columns("C").ColumnWidth = 45
    ws.Columns("D").ColumnWidth = 18
    ws.Columns("E:I").ColumnWidth = 14
    ws.Columns("J").ColumnWidth = 60
    If n = 0 Then
        resumo = "Nenhum problema encontrado nos psicotrópicos e antimicrobianos."
    Else
        resumo = "Controlados com problema: " & n
    End If
    ws.Range("A6").Value = resumo & "   |   Consultado em " & Format$(Now, "dd\/mm\/yyyy hh:nn")
    ws.Range("A6").Font.Bold = True
    Application.ScreenUpdating = True
    ws.Activate
    MsgBox resumo, vbInformation, "Relatórios do Digifarma"
    Exit Sub
Falha:
    Application.ScreenUpdating = True
    If Len(arq) > 0 Then ApagarArquivo arq
    MsgBox "Não deu certo: " & Err.Description, vbCritical, "Relatórios do Digifarma"
End Sub

' ---------- apoio ----------
Private Function LerPeriodo(ByVal ws As Worksheet, ByRef ini As Date, ByRef fim As Date) As Boolean
    If Not IsDate(ws.Range("B3").Value) Or Not IsDate(ws.Range("B4").Value) Then
        MsgBox "Preencha a data de início (B3) e a data de fim (B4) no formato dd/mm/aaaa.", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    ini = CDate(ws.Range("B3").Value)
    fim = CDate(ws.Range("B4").Value)
    If ini > fim Then
        MsgBox "A data de início está depois da data de fim.", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    LerPeriodo = True
End Function

Private Function ValorCfg(ByVal nome As String) As String
    On Error Resume Next
    ValorCfg = Trim$(CStr(ThisWorkbook.Names(nome).RefersToRange.Value))
    If Err.Number <> 0 Then ValorCfg = ""
    On Error GoTo 0
End Function

Private Function ArquivoTemporario(ByVal prefixo As String) As String
    Dim arq As String
    arq = Environ$("TEMP") & "\digifarma-" & prefixo & "-" & Format$(Now, "yyyymmdd-hhnnss") & ".tsv"
    ApagarArquivo arq
    ArquivoTemporario = arq
End Function

' Dir$ dá erro com caminho inválido (por exemplo, endereço do OneDrive); aí conta como "não existe".
Private Function Existe(ByVal arq As String) As Boolean
    On Error Resume Next
    Existe = Len(Dir$(arq)) > 0
End Function

Private Sub ApagarArquivo(ByVal arq As String)
    On Error Resume Next
    If Existe(arq) Then Kill arq
    On Error GoTo 0
End Sub

' Roda o relatorios-digifarma.ps1 numa janela preta (onde a senha é digitada) e espera terminar.
' Se der erro, a janela fica aberta (pause) mostrando o motivo.
Private Function RodarPrograma(ByVal relatorio As String, ByVal ini As Date, ByVal fim As Date, _
                               ByVal dias As Long, ByVal arq As String, Optional ByVal comDatas As Boolean = True) As Boolean
    Dim pasta As String, ps1 As String, banco As String, usuario As String, cmd As String, datas As String
    pasta = ValorCfg("CfgPasta")
    If pasta = "" Then pasta = ThisWorkbook.Path
    If Right$(pasta, 1) = "\" Then pasta = Left$(pasta, Len(pasta) - 1)
    ps1 = pasta & "\relatorios-digifarma.ps1"
    If InStr(pasta, "://") > 0 Then
        MsgBox "A pasta """ & pasta & """ é um endereço da internet (OneDrive/SharePoint)." & vbLf & _
               "Informe a pasta do computador onde está o relatorios-digifarma.ps1 na aba """ & ABA_CFG & """ (célula B4).", _
               vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    If pasta = "" Or Not Existe(ps1) Then
        MsgBox "Não achei o relatorios-digifarma.ps1 na pasta """ & pasta & """." & vbLf & _
               "Informe a pasta certa na aba """ & ABA_CFG & """ (célula B4).", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    banco = ValorCfg("CfgBanco")
    usuario = ValorCfg("CfgUsuario")
    If usuario = "" Then usuario = "SYSDBA"
    If banco = "" Then
        MsgBox "Informe o banco do Digifarma na aba """ & ABA_CFG & """ (célula B3).", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    If InStr(pasta & banco & usuario & arq, """") > 0 Or InStr(pasta & banco & usuario & arq, "%") > 0 Then
        MsgBox "O banco, a pasta e o usuário (aba """ & ABA_CFG & """) não podem ter aspas ("") nem o sinal %.", _
               vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    If comDatas Then datas = " -DataInicio " & Format$(ini, "dd\/mm\/yyyy") & " -DataFim " & Format$(fim, "dd\/mm\/yyyy")
    cmd = "cmd.exe /c powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & ps1 & """" & _
          " -Banco """ & banco & """ -Usuario """ & usuario & """ -Relatorio " & relatorio & datas & _
          " -DiasEstoque " & dias & " -ArquivoSaida """ & arq & """ || pause"
    CreateObject("WScript.Shell").Run cmd, 1, True
    If Not Existe(arq) Then
        MsgBox "O relatório não foi gerado. O motivo apareceu na janela preta.", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    RodarPrograma = True
End Function

' Lê o arquivo de texto (UTF-8, separado por tabulação) para uma matriz: linha 1 = cabeçalho.
' permitirVazio: aceita arquivo só com o cabeçalho (nada encontrado).
Private Function LerTabela(ByVal arq As String, Optional ByVal permitirVazio As Boolean = False) As Variant
    Dim st As Object, txt As String, linhas() As String, campos() As String
    Dim n As Long, i As Long, j As Long, k As Long, ncol As Long, d() As String
    Set st = CreateObject("ADODB.Stream")
    st.Type = 2
    st.Charset = "utf-8"
    st.Open
    st.LoadFromFile arq
    txt = st.ReadText(-1)
    st.Close
    If Len(txt) > 0 Then
        If AscW(Left$(txt, 1)) = &HFEFF Then txt = Mid$(txt, 2)
    End If
    txt = Replace(txt, vbCr, "")
    linhas = Split(txt, vbLf)
    For i = 0 To UBound(linhas)
        If Len(linhas(i)) > 0 Then n = n + 1
    Next i
    If n < 1 Or (n < 2 And Not permitirVazio) Then
        MsgBox "O relatório veio vazio.", vbExclamation, "Relatórios do Digifarma"
        Exit Function
    End If
    ncol = UBound(Split(linhas(0), vbTab)) + 1
    ReDim d(1 To n, 1 To ncol)
    For i = 0 To UBound(linhas)
        If Len(linhas(i)) > 0 Then
            j = j + 1
            campos = Split(linhas(i), vbTab)
            For k = 0 To ncol - 1
                If k <= UBound(campos) Then d(j, k + 1) = campos(k)
            Next k
        End If
    Next i
    LerTabela = d
End Function

Private Sub LimparResultado(ByVal ws As Worksheet)
    ws.Range(ws.Rows(LINHA_CAB - 2), ws.Rows(ws.Rows.Count)).Clear
End Sub

Private Sub EscreverCabecalho(ByVal ws As Worksheet, ByVal titulos As Variant)
    Dim r As Range
    Set r = ws.Cells(LINHA_CAB, 1).Resize(1, UBound(titulos) - LBound(titulos) + 1)
    r.Value = titulos
    r.Font.Bold = True
    r.Interior.Color = RGB(221, 235, 247)
    r.WrapText = True
End Sub

' Escreve a tabela lida (linha 1 = cabeçalho do arquivo) com os títulos em LINHA_CAB e os dados a partir de
' LINHA_DADOS. tipos: uma letra por coluna: T = texto, N = número, I = inteiro, D = data (aaaa-mm-dd).
Private Sub EscreverDados(ByVal ws As Worksheet, d As Variant, ByVal titulos As Variant, ByVal tipos As String)
    Dim n As Long, nc As Long, i As Long, j As Long, saida() As Variant, v As String
    n = UBound(d, 1) - 1
    nc = Len(tipos)
    LimparResultado ws
    EscreverCabecalho ws, titulos
    If n < 1 Then Exit Sub
    ReDim saida(1 To n, 1 To nc)
    For i = 1 To n
        For j = 1 To nc
            v = d(i + 1, j)
            Select Case Mid$(tipos, j, 1)
                Case "N"
                    saida(i, j) = Val(v)
                Case "I"
                    saida(i, j) = CLng(Val(v))
                Case "D"
                    If Len(v) = 10 Then saida(i, j) = DateSerial(CInt(Left$(v, 4)), CInt(Mid$(v, 6, 2)), CInt(Mid$(v, 9, 2)))
                Case Else
                    saida(i, j) = v
            End Select
        Next j
    Next i
    For j = 1 To nc
        Select Case Mid$(tipos, j, 1)
            Case "T": ws.Cells(LINHA_DADOS, j).Resize(n, 1).NumberFormat = "@"
            Case "D": ws.Cells(LINHA_DADOS, j).Resize(n, 1).NumberFormat = "dd/mm/yyyy"
            Case "I": ws.Cells(LINHA_DADOS, j).Resize(n, 1).NumberFormat = "0"
        End Select
    Next j
    ws.Cells(LINHA_DADOS, 1).Resize(n, nc).Value = saida
End Sub
#ARQUIVO-FIM
