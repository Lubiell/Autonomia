#!/usr/bin/env bash
# Testa desmarcar-controlados.ps1 contra um Firebird de verdade, em bancos descartáveis.
# Precisa: servidor Firebird rodando em localhost, isql-fb, gbak, pwsh e ISC_PASSWORD do SYSDBA.
# Uso: ISC_PASSWORD=... bash ferramentas/digifarma/testes/testar.sh   (PWSH=/caminho/pwsh se não estiver no PATH)
set -u
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$DIR/desmarcar-controlados.ps1"
PWSH="${PWSH:-pwsh}"
ISQL="${ISQL:-isql-fb}"
TMP="$(mktemp -d)"
chmod 777 "$TMP"
trap 'rm -rf "$TMP"' EXIT
PASS=0
FAIL=0
ok() { if eval "$1"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FALHOU: $2"; fi; }

: "${ISC_PASSWORD:?defina ISC_PASSWORD com a senha do SYSDBA}"
export ISC_USER=SYSDBA ISC_PASSWORD

criar() { # $1 = arquivo do banco, stdin = SQL em UTF-8 (gravado em WIN1252)
  rm -f "$1"
  { echo "SET SQL DIALECT 3; CREATE DATABASE 'localhost:$1' DEFAULT CHARACTER SET WIN1252;"; iconv -f utf-8 -t cp1252; } > "$TMP/cria.sql"
  "$ISQL" -q -ch WIN1252 -i "$TMP/cria.sql" >/dev/null || { echo "não criou $1"; exit 1; }
}
sql() { printf 'SET HEADING OFF;\n%s\n' "$2" | "$ISQL" -q "localhost:$1" | sed 's/[[:space:]]*$//; /^$/d'; }
estado() { sql "$1" "SELECT CODIGO || ':' || COALESCE(CONTROLADO, '-') || ':' || COALESCE(ANTIMICROBIANO, '-') FROM PRODUTOS ORDER BY CODIGO;" | tr '\n' ' '; }
rodar() { "$PWSH" -NoProfile -File "$SCRIPT" -Isql "$(command -v "$ISQL")" "$@" 2>&1; }

DB="$TMP/digifarma.fdb"
criar "$DB" <<'EOF'
CREATE TABLE PRODUTOS (CODIGO INTEGER NOT NULL PRIMARY KEY, DESCRICAO VARCHAR(60), CONTROLADO CHAR(1),
  ANTIMICROBIANO CHAR(1), ESTOQUE NUMERIC(15,3), ESTOQUE_MINIMO NUMERIC(15,3), PRECO NUMERIC(10,2));
CREATE TABLE ITENS_VENDA (ID INTEGER NOT NULL PRIMARY KEY, PRODUTO INTEGER, CONTROLADO CHAR(1));
CREATE TABLE ESTOQUE_LOJA (PRODUTO INTEGER NOT NULL, LOJA INTEGER NOT NULL, QTD NUMERIC(15,3), PRIMARY KEY (PRODUTO, LOJA));
CREATE TABLE SNGPC (ID INTEGER NOT NULL PRIMARY KEY, CPF_RESPONSAVEL_SNGPC VARCHAR(11));
COMMIT;
INSERT INTO PRODUTOS VALUES (1, 'DIPIRONA 500MG', 'N', 'N', 50, 5, 5);
INSERT INTO PRODUTOS VALUES (2, 'CLONAZEPAM 2MG', 'S', 'N', 10, 2, 10);
INSERT INTO PRODUTOS VALUES (3, 'AMOXICILINA 500MG CÁPS', 'N', 'S', 0, 2, 20);
INSERT INTO PRODUTOS VALUES (4, 'PRODUTO "ESTRANHO" | COM; SÍMBOLOS', 'S', 'S', 5.5, 1, 1);
INSERT INTO PRODUTOS VALUES (5, 'SEM MARCAÇÃO', NULL, NULL, 1, 0, 2);
INSERT INTO PRODUTOS VALUES (6, 'AZITROMICINA', 'N', 'S', 0, 0, 3);
INSERT INTO PRODUTOS VALUES (12, 'ALPRAZOLAM 1MG', 'S', 'N', 3, 0, 4);
INSERT INTO PRODUTOS VALUES (21, 'CEFALEXINA 500MG', 'N', 'S', 7, 0, 6);
INSERT INTO ITENS_VENDA VALUES (1, 2, 'S');
INSERT INTO SNGPC VALUES (1, '98765432100');
INSERT INTO ESTOQUE_LOJA VALUES (2, 1, 0);
INSERT INTO ESTOQUE_LOJA VALUES (3, 1, 4);
INSERT INTO ESTOQUE_LOJA VALUES (3, 2, 1);
INSERT INTO ESTOQUE_LOJA VALUES (12, 1, 2);
COMMIT;
EOF
ORIGINAL="$(estado "$DB")"
B="localhost:$DB"

# Descobrir: acha PRODUTOS (não ITENS_VENDA) e o saldo ESTOQUE (não ESTOQUE_MINIMO)
out="$(rodar -Banco "$B" -Descobrir)"; rc=$?
ok '[ $rc -eq 0 ]' "descobrir: código $rc"
ok 'grep -q "Escolha automática: PRODUTOS -> Psicotropico: CONTROLADO; Antimicrobiano: ANTIMICROBIANO" <<<"$out"' "descobrir: escolha automática"
ok 'grep -q "Estoque: PRODUTOS.ESTOQUE$" <<<"$out"' "descobrir: coluna de estoque"
ok 'grep -q "ESTOQUE_LOJA: PRODUTO, LOJA, QTD" <<<"$out"' "descobrir: tabela de estoque listada"
ok '! grep -q "98765432100" <<<"$out" && grep -q "SNGPC.CPF_RESPONSAVEL_SNGPC" <<<"$out"' "descobrir: mostrou dado pessoal (CPF)"

# Simulação com estoque: lista só os marcados com saldo e não altera nada
out="$(rodar -Banco "$B" -Estoque ComEstoque -PastaSaida "$TMP/s1")"; rc=$?
ok '[ $rc -eq 0 ]' "simulação: código $rc"
ok 'grep -q "Produtos marcados com estoque: 4" <<<"$out"' "simulação: 4 com estoque"
ok '[ "$(estado "$DB")" = "$ORIGINAL" ]' "simulação alterou o banco"
csv="$(cat "$TMP/s1/produtos-a-desmarcar.csv")"
ok 'grep -q "\"CODIGO\";\"DESCRICAO\";\"ESTOQUE\";\"CONTROLADO\";\"ANTIMICROBIANO\"" <<<"$csv"' "csv: cabeçalho"
ok 'grep -q "\"4\";\"PRODUTO \"\"ESTRANHO\"\" / COM; SÍMBOLOS\";\"5.5\";\"S\";\"S\"" <<<"$csv"' "csv: acentos, aspas e estoque"
ok '! grep -q "^\"3\";" <<<"$csv"' "csv: produto sem estoque entrou"

# -Codigos: só o 12 (não confundir com 2 nem 21), com backup e desfazer.sql
out="$(rodar -Banco "$B" -Estoque ComEstoque -Codigos 12,99 -Aplicar -SemPerguntar -PastaSaida "$TMP/a1")"; rc=$?
ok '[ $rc -eq 0 ]' "códigos: código $rc"
ok '[ "$(estado "$DB")" = "${ORIGINAL/12:S:N/12:N:N}" ]' "códigos: estado $(estado "$DB")"
ok 'grep -q "ignorados): 99" <<<"$out"' "códigos: aviso do código inexistente"
ok '[ -s "$TMP/a1/backup-antes.fbk" ]' "códigos: backup"
rodar -Banco "$B" -Desfazer "$TMP/a1/desfazer.sql" >/dev/null; rc=$?
ok '[ $rc -eq 0 ] && [ "$(estado "$DB")" = "$ORIGINAL" ]' "-Desfazer não voltou ao original (código $rc)"

# -Escolher pelo menu do console: itens 1 e 3 da lista com estoque (2 e 12), confirmação digitada
out="$(printf '1,3\nDESMARCAR\n' | rodar -Banco "$B" -Estoque ComEstoque -Escolher -Aplicar -SemBackup -PastaSaida "$TMP/a2")"; rc=$?
esperado="${ORIGINAL/2:S:N/2:N:N}"; esperado="${esperado/12:S:N/12:N:N}"
ok '[ $rc -eq 0 ]' "escolher: código $rc"
ok '[ "$(estado "$DB")" = "$esperado" ]' "escolher: estado $(estado "$DB")"
ok 'grep -q "Desmarcadas: 2 de 2" <<<"$out"' "escolher: conferência"
"$ISQL" -q -i "$TMP/a2/desfazer.sql" "$B" >/dev/null 2>&1

# Cancelar na confirmação não altera nada
printf '3\nnao\n' | rodar -Banco "$B" -Escolher -Aplicar -SemBackup -PastaSaida "$TMP/a3" >/dev/null; rc=$?
ok '[ $rc -eq 1 ] && [ "$(estado "$DB")" = "$ORIGINAL" ]' "cancelar: código $rc, estado $(estado "$DB")"

# Estoque em outra tabela (soma por loja): com estoque só 3 e 12
out="$(rodar -Banco "$B" -Estoque ComEstoque -TabelaEstoque ESTOQUE_LOJA -CampoEstoque QTD -ChaveEstoque PRODUTO -PastaSaida "$TMP/s2")"; rc=$?
ok '[ $rc -eq 0 ] && grep -q "Produtos marcados com estoque: 2" <<<"$out"' "tabela de estoque: $out"
ok 'grep -q "^\"3\";.*\"5\"" "$TMP/s2/produtos-a-desmarcar.csv"' "tabela de estoque: soma das lojas"

# Sem estoque: 3 e 6; estoque em outra tabela sem -ChaveEstoque é recusado
out="$(rodar -Banco "$B" -Estoque SemEstoque -PastaSaida "$TMP/s4")"; rc=$?
ok '[ $rc -eq 0 ] && grep -q "Produtos marcados sem estoque: 2" <<<"$out"' "sem estoque: $out"
rodar -Banco "$B" -Estoque ComEstoque -TabelaEstoque ESTOQUE_LOJA -CampoEstoque QTD -PastaSaida "$TMP/s5" >/dev/null; rc=$?
ok '[ $rc -eq 2 ]' "tabela de estoque sem -ChaveEstoque: código $rc"

# Digifarma aberto, produto 21 preso o tempo todo por outra sessão: grava o 2, tenta de novo, lista o 21
( printf 'SET TRANSACTION NO WAIT;\nUPDATE PRODUTOS SET PRECO = PRECO WHERE CODIGO = 21;\n'; sleep 30 ) | "$ISQL" -q "$B" >/dev/null 2>&1 &
TRAVA=$!
sleep 2
out="$(rodar -Banco "$B" -Codigos 2,21 -Tentativas 2 -Aplicar -SemPerguntar -SemBackup -PastaSaida "$TMP/a7")"; rc=$?
wait "$TRAVA" 2>/dev/null   # a sessão que prendia o 21 termina (30 s) e o banco solta o produto
ok '[ $rc -eq 3 ] && [ "$(estado "$DB")" = "${ORIGINAL/2:S:N/2:N:N}" ]' "em uso: código $rc, estado $(estado "$DB")"
ok 'grep -q "tentando de novo" <<<"$out" && grep -q "Desmarcadas: 1 de 2" <<<"$out" && grep -q "Rode de novo mais tarde com: -Aplicar -Codigos 21" <<<"$out"' "em uso: mensagens $out"
rodar -Banco "$B" -Desfazer "$TMP/a7/desfazer.sql" >/dev/null
ok '[ "$(estado "$DB")" = "$ORIGINAL" ]' "em uso: desfazer $(estado "$DB")"

# Produto 21 preso só por 2 s (venda terminando): espera e grava, sem perder o que a venda gravou
( printf 'UPDATE PRODUTOS SET PRECO = 99 WHERE CODIGO = 21;\n'; sleep 2; printf 'COMMIT;\n' ) | "$ISQL" -q "$B" >/dev/null 2>&1 &
sleep 0.5
rodar -Banco "$B" -Codigos 21 -Aplicar -SemPerguntar -SemBackup -PastaSaida "$TMP/a10" >/dev/null; rc=$?
wait
ok '[ $rc -eq 0 ] && [ "$(estado "$DB")" = "${ORIGINAL/21:N:S/21:N:N}" ] && [ "$(sql "$DB" "SELECT CAST(PRECO AS INTEGER) FROM PRODUTOS WHERE CODIGO = 21;")" -eq 99 ]' "espera: código $rc, estado $(estado "$DB"), preço [$(sql "$DB" "SELECT CAST(PRECO AS INTEGER) FROM PRODUTOS WHERE CODIGO = 21;")]"
rodar -Banco "$B" -Desfazer "$TMP/a10/desfazer.sql" >/dev/null

# Só psicotrópico, todos: antimicrobiano fica intacto
rodar -Banco "$B" -Desmarcar Psicotropico -Aplicar -SemPerguntar -SemBackup -PastaSaida "$TMP/a4" >/dev/null; rc=$?
ok '[ $rc -eq 0 ]' "só psicotrópico: código $rc"
ok '[ "$(estado "$DB")" = "$(sed "s/:S:/:N:/g" <<<"$ORIGINAL")" ]' "só psicotrópico: estado $(estado "$DB")"
ok '[ "$(sql "$DB" "SELECT COUNT(*) FROM ITENS_VENDA WHERE CONTROLADO = '"'S'"';")" -eq 1 ]' "tabela errada (ITENS_VENDA) alterada"

# Senha errada: falha sem alterar
ISC_PASSWORD=errada rodar -Banco "$B" -Aplicar -SemPerguntar -SemBackup -PastaSaida "$TMP/a5" >/dev/null; rc=$?
ok '[ $rc -eq 1 ]' "senha errada: código $rc"

# Outros tipos (SMALLINT 0/1 e BOOLEAN) e mais de uma tabela possível
DB2="$TMP/tipos.fdb"
criar "$DB2" <<'EOF'
CREATE TABLE MEDS (ID INTEGER NOT NULL PRIMARY KEY, NOME VARCHAR(40), PSICOTROPICO SMALLINT, ANTIMICROBIANO BOOLEAN, SALDO INTEGER);
CREATE TABLE PRODUTOS_A (ID INTEGER NOT NULL PRIMARY KEY, CONTROLADO CHAR(1));
CREATE TABLE PRODUTOS_B (ID INTEGER NOT NULL PRIMARY KEY, CONTROLADO CHAR(1));
CREATE TABLE MEDNULL (ID INTEGER NOT NULL PRIMARY KEY, PSICOTROPICO CHAR(1));
CREATE TABLE MEDTXT (COD VARCHAR(10) NOT NULL PRIMARY KEY, CONTROLADO CHAR(1));
COMMIT;
INSERT INTO MEDNULL VALUES (1, 'S');
INSERT INTO MEDNULL VALUES (2, NULL);
INSERT INTO MEDTXT VALUES ('A', 'S');
INSERT INTO MEDTXT VALUES ('A|B', 'S');
INSERT INTO MEDTXT VALUES ('C', 'N');
CREATE TABLE MEDBULK (ID INTEGER NOT NULL PRIMARY KEY, CONTROLADO CHAR(1));
CREATE TABLE MEDPN (ID INTEGER NOT NULL PRIMARY KEY, PROD_DESCONTO VARCHAR(5), PROD_NOME VARCHAR(30), CONTROLADO CHAR(1));
COMMIT;
INSERT INTO MEDPN VALUES (1, 'X', 'RIVOTRIL 2MG', 'S');
INSERT INTO MEDPN VALUES (2, 'X', 'OUTRO', 'N');
COMMIT;
SET TERM ^ ;
EXECUTE BLOCK AS DECLARE I INTEGER = 1; BEGIN WHILE (I <= 300) DO BEGIN
  INSERT INTO MEDBULK VALUES (:I, IIF(MOD(:I, 2) = 0, 'S', 'N')); I = I + 1; END END^
SET TERM ; ^
INSERT INTO MEDS VALUES (1, 'A', 1, FALSE, 3);
INSERT INTO MEDS VALUES (2, 'B', 0, TRUE, 0);
INSERT INTO MEDS VALUES (3, 'C', 1, TRUE, 1);
COMMIT;
EOF
B2="localhost:$DB2"
tipos() { sql "$DB2" "SELECT PSICOTROPICO || '/' || CAST(ANTIMICROBIANO AS VARCHAR(5)) FROM MEDS ORDER BY ID;" | tr '\n' ' '; }
rodar -Banco "$B2" -PastaSaida "$TMP/s3" >/dev/null; rc=$?
ok '[ $rc -eq 2 ]' "várias tabelas: deveria pedir -Tabela (código $rc)"
rodar -Banco "$B2" -Tabela MEDS -Aplicar -SemPerguntar -SemBackup -PastaSaida "$TMP/a6" >/dev/null; rc=$?
ok '[ $rc -eq 0 ]' "tipos: código $rc"
ok '[ "$(tipos)" = "0/FALSE 0/FALSE 0/FALSE " ]' "tipos: $(tipos)"
"$ISQL" -q -i "$TMP/a6/desfazer.sql" "$B2" >/dev/null 2>&1
ok '[ "$(tipos)" = "1/FALSE 0/TRUE 1/TRUE " ]' "tipos: desfazer $(tipos)"

# Antimicrobiano só em tabela sem PROD no nome: não escolhe sozinho
rodar -Banco "$B2" -Desmarcar Antimicrobiano -PastaSaida "$TMP/s6" >/dev/null; rc=$?
ok '[ $rc -eq 2 ]' "tabela sem PROD: deveria pedir -Tabela (código $rc)"

# Desmarcado = vazio: não adivinha 'N'; com -ValorDesmarcado NULL funciona e desfaz
mednull() { sql "$DB2" "SELECT ID || ':' || COALESCE(PSICOTROPICO, '-') FROM MEDNULL ORDER BY ID;" | tr '\n' ' '; }
rodar -Banco "$B2" -Tabela MEDNULL -Desmarcar Psicotropico -PastaSaida "$TMP/s7" >/dev/null; rc=$?
ok '[ $rc -eq 2 ] && [ "$(mednull)" = "1:S 2:- " ]' "só S e vazio: deveria pedir -ValorDesmarcado (código $rc)"
rodar -Banco "$B2" -Tabela MEDNULL -Desmarcar Psicotropico -ValorMarcado S -ValorDesmarcado NULL -Aplicar -SemPerguntar -SemBackup -PastaSaida "$TMP/a8" >/dev/null; rc=$?
ok '[ $rc -eq 0 ] && [ "$(mednull)" = "1:- 2:- " ]' "desmarcar para NULL: código $rc, $(mednull)"
rodar -Banco "$B2" -Desfazer "$TMP/a8/desfazer.sql" >/dev/null
ok '[ "$(mednull)" = "1:S 2:- " ]' "desfazer NULL: $(mednull)"

# Código com '|' desalinharia a chave: para antes de alterar
rodar -Banco "$B2" -Tabela MEDTXT -Desmarcar Psicotropico -Codigos A -Aplicar -SemPerguntar -SemBackup -PastaSaida "$TMP/a9" >/dev/null; rc=$?
ok '[ $rc -eq 1 ] && [ "$(sql "$DB2" "SELECT COUNT(*) FROM MEDTXT WHERE CONTROLADO = '"'S'"';")" -eq 2 ]' "código com |: código $rc"

# Coluna de nome no estilo do Digifarma (PROD_NOME), sem confundir com PROD_DESCONTO; -CampoDescricao manda
out="$(rodar -Banco "$B2" -Tabela MEDPN -Desmarcar Psicotropico -PastaSaida "$TMP/s8")"; rc=$?
ok '[ $rc -eq 0 ] && grep -q "Descrição: MEDPN.PROD_NOME" <<<"$out" && grep -q "1 | RIVOTRIL 2MG | S" <<<"$out"' "PROD_NOME: $out"
out="$(rodar -Banco "$B2" -Tabela MEDPN -Desmarcar Psicotropico -CampoDescricao PROD_DESCONTO -PastaSaida "$TMP/s9")"; rc=$?
ok '[ $rc -eq 0 ] && grep -q "Descrição: MEDPN.PROD_DESCONTO" <<<"$out"' "-CampoDescricao: $out"

# Mapa do banco (relatorios-digifarma.ps1): nomes e tipos, nenhum dado
out="$("$PWSH" -NoProfile -File "$DIR/relatorios-digifarma.ps1" -Isql "$(command -v "$ISQL")" -Banco "$B" -Mapa -ContarLinhas -PastaSaida "$TMP/m1" 2>&1)"; rc=$?
mapa="$(cat "$TMP"/m1/mapa-do-banco-*.txt 2>/dev/null)"
ok '[ $rc -eq 0 ] && grep -q "== PRODUTOS  \[tabela, 8 linhas\]" <<<"$mapa" && grep -q "CONTROLADO .*CHAR(1)" <<<"$mapa"' "mapa: $out"
ok '! grep -q "CLONAZEPAM\|98765432100" <<<"$mapa"' "mapa: vazou dado"

# Muitos produtos (vários blocos de gravação)
out="$(rodar -Banco "$B2" -Tabela MEDBULK -Desmarcar Psicotropico -Aplicar -SemPerguntar -SemBackup -PastaSaida "$TMP/a11")"; rc=$?
ok '[ $rc -eq 0 ] && grep -q "Desmarcadas: 150 de 150" <<<"$out" && [ "$(sql "$DB2" "SELECT COUNT(*) FROM MEDBULK WHERE CONTROLADO = '"'S'"';")" -eq 0 ]' "300 produtos: código $rc"
rodar -Banco "$B2" -Desfazer "$TMP/a11/desfazer.sql" >/dev/null
ok '[ "$(sql "$DB2" "SELECT COUNT(*) FROM MEDBULK WHERE CONTROLADO = '"'S'"';")" -eq 150 ]' "300 produtos: desfazer"

# ---------- relatórios (relatorios-digifarma.ps1): Curva ABC e sugestão de compra ----------
DB3="$TMP/vendas.fdb"
criar "$DB3" <<'SQL'
CREATE TABLE PRODUTOS (CODIGO INTEGER NOT NULL PRIMARY KEY, DESCRICAO VARCHAR(60), COD_BARRAS VARCHAR(14), ESTOQUE NUMERIC(15,3));
CREATE TABLE VENDAS (VENDA_ID INTEGER NOT NULL PRIMARY KEY, DATA_VENDA TIMESTAMP, CANCELADA CHAR(1));
CREATE TABLE VENDAS_ITENS (ITEM_ID INTEGER NOT NULL PRIMARY KEY, VENDA_ID INTEGER, PRODUTO_ID INTEGER, QTD NUMERIC(15,3), VALOR_TOTAL NUMERIC(15,2));
COMMIT;
INSERT INTO PRODUTOS VALUES (1, 'DIPIRONA 500MG', '7896004713229', 50);
INSERT INTO PRODUTOS VALUES (2, 'CLONAZEPAM 2MG', '7896004700001', 10);
INSERT INTO PRODUTOS VALUES (3, 'AMOXICILINA 500MG CÁPS & "CIA"', NULL, 0);
INSERT INTO PRODUTOS VALUES (12, 'ALPRAZOLAM 1MG', '7891', 3);
INSERT INTO PRODUTOS VALUES (21, 'CEFALEXINA 500MG', '7892', 7);
INSERT INTO PRODUTOS VALUES (6, 'AZITROMICINA', '7893', -2);
INSERT INTO VENDAS VALUES (1, '2026-09-05 10:00', 'N');
INSERT INTO VENDAS VALUES (2, '2026-09-20 11:00', NULL);
INSERT INTO VENDAS VALUES (3, '2026-09-10 09:00', 'N');
INSERT INTO VENDAS VALUES (4, '2026-09-15 15:00', 'S');
INSERT INTO VENDAS VALUES (5, '2026-08-31 23:00', 'N');
INSERT INTO VENDAS VALUES (6, '2026-09-30 22:00', 'N');
INSERT INTO VENDAS VALUES (7, '2026-10-01 00:00', 'N');
INSERT INTO VENDAS_ITENS VALUES (1, 1, 1, 40, 200);
INSERT INTO VENDAS_ITENS VALUES (2, 2, 1, 20, 100);
INSERT INTO VENDAS_ITENS VALUES (3, 3, 2, 2, 20);
INSERT INTO VENDAS_ITENS VALUES (4, 3, 3, 4, 80);
INSERT INTO VENDAS_ITENS VALUES (5, 4, 12, 1, 4);
INSERT INTO VENDAS_ITENS VALUES (6, 5, 21, 3, 18);
INSERT INTO VENDAS_ITENS VALUES (7, 6, 21, 1, 6);
INSERT INTO VENDAS_ITENS VALUES (8, 7, 6, 1, 3);
COMMIT;
SQL
B3="localhost:$DB3"
printf "@{ ProdEstoque = 'ESTOQUE' }\n" > "$TMP/so-estoque.psd1"
cat > "$TMP/esquema.psd1" <<'PSD'
@{
    ProdEstoque = 'ESTOQUE'
    VendaTabela = 'VENDAS'; VendaChave = 'VENDA_ID'; VendaData = 'DATA_VENDA'; VendaCancelada = 'CANCELADA'
    ItemTabela = 'VENDAS_ITENS'; ItemVenda = 'VENDA_ID'; ItemProduto = 'PRODUTO_ID'; ItemQuantidade = 'QTD'; ItemValorTotal = 'VALOR_TOTAL'
}
PSD
# Cotação em branco mínima: aba "Cotação" com A3:B5 vazias e um contador com resultado guardado.
python3 - "$TMP/modelo.xlsx" <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1], 'w', zipfile.ZIP_DEFLATED)
z.writestr('[Content_Types].xml', '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>')
z.writestr('_rels/.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')
z.writestr('xl/workbook.xml', '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="LEIA-ME" sheetId="1" r:id="rId3"/><sheet name="Cotação" sheetId="2" r:id="rId4"/></sheets><calcPr refMode="A1"/></workbook>')
z.writestr('xl/_rels/workbook.xml.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/></Relationships>')
z.writestr('xl/worksheets/sheet1.xml', '<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData/></worksheet>')
linhas = ''.join('<row r="%d"><c r="A%d" s="12"/><c r="B%d" s="12"/></row>' % (r, r, r) for r in range(3, 6))
z.writestr('xl/worksheets/sheet2.xml', '<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData><row r="1"><c r="B1" s="5" t="n"><f aca="false">COUNTA(A3:A1002)</f><v>0</v></c></row>' + linhas + '</sheetData></worksheet>')
z.close()
PY
rel() { "$PWSH" -NoProfile -File "$DIR/relatorios-digifarma.ps1" -Isql "$(command -v "$ISQL")" -Banco "$B3" "$@" 2>&1; }
celula() { python3 -c 'import sys,zipfile,re; s=zipfile.ZipFile(sys.argv[1]).read("xl/worksheets/sheet2.xml").decode(); m=re.search(r"<c r=\"%s\"[^>]*?(/>|>.*?</c>)" % sys.argv[2], s); print(m.group(0) if m else "")' "$1" "$2"; }

out="$(rel -Esquema "$TMP/so-estoque.psd1" -Relatorio CurvaABC -DataInicio 01/09/2026 -DataFim 30/09/2026 -PastaSaida "$TMP/r0")"; rc=$?
ok '[ $rc -eq 2 ] && grep -q "ainda falta configurar onde ficam as vendas" <<<"$out"' "relatórios sem configurar vendas: código $rc $out"
out="$(rel -Esquema "$TMP/esquema.psd1" -Relatorio CurvaABC -DataInicio 30/09/2026 -DataFim 01/09/2026 -PastaSaida "$TMP/r0")"; rc=$?
ok '[ $rc -eq 1 ] && grep -q "data de início é depois" <<<"$out"' "período invertido: código $rc"
out="$(rel -Esquema "$TMP/esquema.psd1" -Relatorio CurvaABC -DataInicio 01/01/2026 -DataFim 31/01/2026 -PastaSaida "$TMP/r0")"; rc=$?
ok '[ $rc -eq 1 ] && grep -q "não houve vendas" <<<"$out"' "período sem vendas: código $rc"

# Curva ABC de setembro: cancelada e fora do período não contam; a venda das 22h do último dia conta
out="$(rel -Esquema "$TMP/esquema.psd1" -Relatorio CurvaABC -DataInicio 01/09/2026 -DataFim 30/09/2026 -PastaSaida "$TMP/r1")"; rc=$?
abc="$(cat "$TMP"/r1/curva-abc_2026-09-01_a_2026-09-30.csv 2>/dev/null)"
ok '[ $rc -eq 0 ] && grep -q "A: 2  B: 1  C: 1" <<<"$out"' "curva ABC: código $rc $out"
ok 'grep -q "^\"A\";\"1\";\"1\";\"7896004713229\";\"DIPIRONA 500MG\";\"60\";\"300,00\";\"73,89\";\"73,89\";\"50\"" <<<"$abc"' "curva ABC: linha da DIPIRONA"
ok 'grep -q "^\"C\";\"4\";\"21\";.*\"1\";\"6,00\"" <<<"$abc" && ! grep -q "ALPRAZOLAM\|AZITROMICINA" <<<"$abc"' "curva ABC: cancelada/fora do período"

# Sugestão de compra (30 dias) preenchendo a cotação em branco
out="$(rel -Esquema "$TMP/esquema.psd1" -Modelo "$TMP/modelo.xlsx" -Relatorio SugestaoCompra -DataInicio 01/09/2026 -DataFim 30/09/2026 -PastaSaida "$TMP/r2")"; rc=$?
cot="$(ls "$TMP"/r2/Cotacao_*.xlsx 2>/dev/null | head -1)"
ok '[ $rc -eq 0 ] && grep -q "Sugestão de compra: 2 produtos" <<<"$out" && [ -n "$cot" ]' "sugestão: código $rc $out"
ok 'grep -q "^\"1\";\"7896004713229\";\"DIPIRONA 500MG\";\"60\";\"2,00\";\"50\";\"10\"" "$TMP"/r2/sugestao-compra_*.csv' "sugestão: DIPIRONA 10"
ok '[ "$(celula "$cot" A3)" = "<c r=\"A3\" s=\"12\" t=\"inlineStr\"><is><t xml:space=\"preserve\">AMOXICILINA 500MG CÁPS &amp; &quot;CIA&quot;</t></is></c>" ]' "cotação A3: $(celula "$cot" A3)"
ok '[ "$(celula "$cot" B4)" = "<c r=\"B4\" s=\"12\"><v>10</v></c>" ] && [ "$(celula "$cot" A5)" = "<c r=\"A5\" s=\"12\"/>" ]' "cotação B4/A5"
ok '[ "$(celula "$cot" B1)" = "<c r=\"B1\" s=\"5\" t=\"n\"><f aca=\"false\">COUNTA(A3:A1002)</f></c>" ]' "cotação: resultado guardado da fórmula não foi tirado: $(celula "$cot" B1)"
ok 'unzip -p "$cot" xl/workbook.xml | grep -q "fullCalcOnLoad=\"1\""' "cotação: recálculo ao abrir"
ok 'unzip -p "$TMP/modelo.xlsx" xl/worksheets/sheet2.xml | grep -q "<c r=\"A3\" s=\"12\"/>"' "o modelo em branco foi alterado"
out="$(rel -Esquema "$TMP/esquema.psd1" -Modelo "$cot" -Relatorio SugestaoCompra -DataInicio 01/09/2026 -DataFim 30/09/2026 -PastaSaida "$TMP/r3")"; rc=$?
ok '[ $rc -eq 1 ] && grep -q "não está em branco" <<<"$out"' "cotação já preenchida como modelo: código $rc"

echo "passou: $PASS  falhou: $FAIL"
[ "$FAIL" -eq 0 ]
