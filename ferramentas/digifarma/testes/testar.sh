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
out="$(rodar -Banco "$B" -Estoque ComEstoque -Codigos 12,99 -Aplicar -Confirmar -PastaSaida "$TMP/a1")"; rc=$?
ok '[ $rc -eq 0 ]' "códigos: código $rc"
ok '[ "$(estado "$DB")" = "${ORIGINAL/12:S:N/12:N:N}" ]' "códigos: estado $(estado "$DB")"
ok 'grep -q "ignorados): 99" <<<"$out"' "códigos: aviso do código inexistente"
ok '[ -s "$TMP/a1/backup-antes.fbk" ]' "códigos: backup"
"$ISQL" -q -i "$TMP/a1/desfazer.sql" "$B" >/dev/null 2>&1
ok '[ "$(estado "$DB")" = "$ORIGINAL" ]' "desfazer.sql não voltou ao original"

# -Escolher pelo menu do console: itens 1 e 3 da lista com estoque (2 e 12), confirmação digitada
out="$(printf '1,3\nDESMARCAR\n' | rodar -Banco "$B" -Estoque ComEstoque -Escolher -Aplicar -SemBackup -PastaSaida "$TMP/a2")"; rc=$?
esperado="${ORIGINAL/2:S:N/2:N:N}"; esperado="${esperado/12:S:N/12:N:N}"
ok '[ $rc -eq 0 ]' "escolher: código $rc"
ok '[ "$(estado "$DB")" = "$esperado" ]' "escolher: estado $(estado "$DB")"
ok 'grep -q "Psicotropico: 2 desmarcado(s) de 2 previsto(s)" <<<"$out"' "escolher: conferência"
"$ISQL" -q -i "$TMP/a2/desfazer.sql" "$B" >/dev/null 2>&1

# Cancelar na confirmação não altera nada
printf '3\nnao\n' | rodar -Banco "$B" -Escolher -Aplicar -SemBackup -PastaSaida "$TMP/a3" >/dev/null; rc=$?
ok '[ $rc -eq 1 ] && [ "$(estado "$DB")" = "$ORIGINAL" ]' "cancelar: código $rc, estado $(estado "$DB")"

# Estoque em outra tabela (soma por loja): com estoque só 3 e 12
out="$(rodar -Banco "$B" -Estoque ComEstoque -TabelaEstoque ESTOQUE_LOJA -CampoEstoque QTD -ChaveEstoque PRODUTO -PastaSaida "$TMP/s2")"; rc=$?
ok '[ $rc -eq 0 ] && grep -q "Produtos marcados com estoque: 2" <<<"$out"' "tabela de estoque: $out"
ok 'grep -q "^\"3\";.*\"5\"" "$TMP/s2/produtos-a-desmarcar.csv"' "tabela de estoque: soma das lojas"

# Só psicotrópico, todos: antimicrobiano fica intacto
rodar -Banco "$B" -Desmarcar Psicotropico -Aplicar -Confirmar -SemBackup -PastaSaida "$TMP/a4" >/dev/null; rc=$?
ok '[ $rc -eq 0 ]' "só psicotrópico: código $rc"
ok '[ "$(estado "$DB")" = "$(sed "s/:S:/:N:/g" <<<"$ORIGINAL")" ]' "só psicotrópico: estado $(estado "$DB")"
ok '[ "$(sql "$DB" "SELECT COUNT(*) FROM ITENS_VENDA WHERE CONTROLADO = '"'S'"';")" -eq 1 ]' "tabela errada (ITENS_VENDA) alterada"

# Senha errada: falha sem alterar
ISC_PASSWORD=errada rodar -Banco "$B" -Aplicar -Confirmar -SemBackup -PastaSaida "$TMP/a5" >/dev/null; rc=$?
ok '[ $rc -eq 1 ]' "senha errada: código $rc"

# Outros tipos (SMALLINT 0/1 e BOOLEAN) e mais de uma tabela possível
DB2="$TMP/tipos.fdb"
criar "$DB2" <<'EOF'
CREATE TABLE MEDS (ID INTEGER NOT NULL PRIMARY KEY, NOME VARCHAR(40), PSICOTROPICO SMALLINT, ANTIMICROBIANO BOOLEAN, SALDO INTEGER);
CREATE TABLE PRODUTOS_A (ID INTEGER NOT NULL PRIMARY KEY, CONTROLADO CHAR(1));
CREATE TABLE PRODUTOS_B (ID INTEGER NOT NULL PRIMARY KEY, CONTROLADO CHAR(1));
COMMIT;
INSERT INTO MEDS VALUES (1, 'A', 1, FALSE, 3);
INSERT INTO MEDS VALUES (2, 'B', 0, TRUE, 0);
INSERT INTO MEDS VALUES (3, 'C', 1, TRUE, 1);
COMMIT;
EOF
B2="localhost:$DB2"
tipos() { sql "$DB2" "SELECT PSICOTROPICO || '/' || CAST(ANTIMICROBIANO AS VARCHAR(5)) FROM MEDS ORDER BY ID;" | tr '\n' ' '; }
rodar -Banco "$B2" -PastaSaida "$TMP/s3" >/dev/null; rc=$?
ok '[ $rc -eq 2 ]' "várias tabelas: deveria pedir -Tabela (código $rc)"
rodar -Banco "$B2" -Tabela MEDS -Aplicar -Confirmar -SemBackup -PastaSaida "$TMP/a6" >/dev/null; rc=$?
ok '[ $rc -eq 0 ]' "tipos: código $rc"
ok '[ "$(tipos)" = "0/FALSE 0/FALSE 0/FALSE " ]' "tipos: $(tipos)"
"$ISQL" -q -i "$TMP/a6/desfazer.sql" "$B2" >/dev/null 2>&1
ok '[ "$(tipos)" = "1/FALSE 0/TRUE 1/TRUE " ]' "tipos: desfazer $(tipos)"

echo "passou: $PASS  falhou: $FAIL"
[ "$FAIL" -eq 0 ]
