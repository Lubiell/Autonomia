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
   início for no passado). Só lotes de produtos com estoque.
-Relatorio EstoqueNegativo: produtos com estoque abaixo de zero (não usa datas).
-Relatorio ConferenciaSNGPC: psicotrópicos e antimicrobianos cujo estoque não bate com a soma dos lotes, com
   estoque negativo, lote vencido com saldo ou lote com saldo negativo (não usa datas).
-Mapa: arquivo de texto com as tabelas e colunas do banco (só nomes e tipos, nenhum dado).
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
    [string]$ArquivoSaida   # usado pela macro da planilha: resultado em texto separado por tabulação
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
        foreach ($k in @('LoteProduto', 'LoteNumero', 'LoteVencimento', 'LoteQuantidade')) {
            if ($e[$k]) { $e[$k] = (Find-Column $e.LoteTabela $e[$k] $k)[1] }
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
    foreach ($k in @('ProdPsicotropico', 'ProdAntimicrobiano')) { if ($e[$k]) { $marcas += "P.$(Q $e[$k]) = '$($e.ProdMarcadoValor)'" } }
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
if (-not ($Janela -or $Mapa -or $Relatorio)) { Stop-Script 'escolha o que fazer: -Janela, -Mapa ou -Relatorio CurvaABC/SugestaoCompra.' 2 }
if ($ArquivoSaida -and -not $Relatorio) { Stop-Script '-ArquivoSaida só vale junto com -Relatorio.' 2 }
if ($RelatoriosComData -contains $Relatorio) {
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
