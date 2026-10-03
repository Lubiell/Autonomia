#!/usr/bin/env bash
# Testa o package.sh: um zip por skill, com a pasta da skill no topo e sem lixo.
# Roda com zip e, quando houver python, também sem zip no PATH (caso do Git Bash no Windows).
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -r "$T"' EXIT
pass=0 fail=0
ok() { pass=$((pass + 1)); }
ko() { fail=$((fail + 1)); echo "FALHOU: $1"; }

PY=""
for p in python3 python; do command -v "$p" >/dev/null 2>&1 && "$p" -c 'import zipfile' 2>/dev/null && { PY="$p"; break; }; done

entries() {
  if command -v unzip >/dev/null 2>&1; then unzip -Z1 "$1"
  else "$PY" -c 'import sys, zipfile; print("\n".join(zipfile.ZipFile(sys.argv[1]).namelist()))' "$1"
  fi | tr -d '\r'
}

# PATH sem zip: links só para o que o package.sh usa (só onde há zip para esconder)
NOZIP="$T/nozip"; mkdir -p "$NOZIP"
if command -v zip >/dev/null 2>&1; then
  for c in bash awk mkdir rm basename dirname cat "$PY"; do
    [ -n "$c" ] && p="$(command -v "$c")" && ln -s "$p" "$NOZIP/$c" 2>/dev/null
  done
fi

modes=""
command -v zip >/dev/null 2>&1 && modes="zip"
[ -n "$PY" ] && modes="$modes python"
[ -n "$modes" ] || { echo "sem zip nem python: nada a testar"; exit 1; }

skills=()
for d in "$ROOT"/.claude/skills/*/; do skills+=("$(basename "$d")"); done

for mode in $modes; do
  out="$T/out-$mode"
  if [ "$mode" = zip ]; then OUT="$out" bash "$ROOT/package.sh" >/dev/null; code=$?
  elif command -v zip >/dev/null 2>&1; then OUT="$out" PATH="$NOZIP" "$NOZIP/bash" "$ROOT/package.sh" >/dev/null; code=$?
  else OUT="$out" bash "$ROOT/package.sh" >/dev/null; code=$?  # sem zip no sistema (Git Bash): já cai no python
  fi
  [ "$code" = 0 ] && ok || ko "[$mode] package.sh saiu com $code"
  for s in "${skills[@]}"; do
    z="$out/$s.zip"
    if [ ! -f "$z" ]; then ko "[$mode] $s.zip não foi criado"; continue; fi
    list="$(entries "$z" | tr -d '\r')"
    printf '%s\n' "$list" | grep -qx "$s/SKILL.md" && ok || ko "[$mode] $s.zip sem $s/SKILL.md"
    printf '%s\n' "$list" | grep -v "^$s/" | grep -q . && ko "[$mode] $s.zip tem entrada fora de $s/" || ok
    printf '%s\n' "$list" | grep -q '__pycache__\|\.pyc$\|\\' && ko "[$mode] $s.zip tem lixo ou barra invertida" || ok
  done
  entries "$out/frontend-design.zip" | grep -qx 'frontend-design/LICENSE.txt' && ok || ko "[$mode] frontend-design sem LICENSE.txt"
  entries "$out/webapp-testing.zip" | grep -qx 'webapp-testing/scripts/with_server.py' && ok || ko "[$mode] webapp-testing sem scripts"
done

# Uma skill só, e skill inexistente (erro com mensagem, não queda do script)
OUT="$T/um" bash "$ROOT/package.sh" analise-dados >/dev/null
[ -f "$T/um/analise-dados.zip" ] && [ "$(ls "$T/um" | wc -l | tr -d ' ')" = 1 ] && ok || ko "argumento não limitou a uma skill"
err="$(OUT="$T/x" bash "$ROOT/package.sh" nao-existe 2>&1 >/dev/null)" && ko "skill inexistente não deu erro" || ok
printf '%s' "$err" | grep -q 'ERRO: nao-existe' && ok || ko "skill inexistente sem mensagem ERRO: $err"

# Cópia do repositório para os casos que mexem em arquivos
REPO="$T/repo"; mkdir -p "$REPO"
cp -r "$ROOT/.claude" "$REPO/" && cp "$ROOT/package.sh" "$REPO/"
SK="$REPO/.claude/skills/analise-dados"

# Lixo não entra no zip; SKILL.md com BOM (comum no Windows) ainda é lido
mkdir -p "$SK/__pycache__" "$SK/sub"
for f in __pycache__/a.pyc x.pyc .DS_Store sub/.DS_Store sub/ok.md; do echo x > "$SK/$f"; done
{ printf '\357\273\277'; cat "$SK/SKILL.md"; } > "$T/s" && mv "$T/s" "$SK/SKILL.md"
for mode in $modes; do
  out="$T/lixo-$mode"
  if [ "$mode" = python ] && command -v zip >/dev/null 2>&1; then OUT="$out" PATH="$NOZIP" "$NOZIP/bash" "$REPO/package.sh" analise-dados >/dev/null 2>&1
  else OUT="$out" bash "$REPO/package.sh" analise-dados >/dev/null 2>&1
  fi
  if [ -f "$out/analise-dados.zip" ]; then
    list="$(entries "$out/analise-dados.zip")"
    printf '%s\n' "$list" | grep -q 'pycache\|\.pyc$\|DS_Store' && ko "[$mode] lixo no zip: $(printf '%s ' $list)" || ok
    printf '%s\n' "$list" | grep -qx 'analise-dados/sub/ok.md' && ok || ko "[$mode] arquivo comum em subpasta ficou de fora"
  else
    ko "[$mode] SKILL.md com BOM foi recusado"
  fi
done

# name diferente da pasta: recusa com mensagem e não cria zip
sed 's/^name: analise-dados/name: outro-nome/' "$SK/SKILL.md" > "$T/s" && mv "$T/s" "$SK/SKILL.md"
err="$(OUT="$T/y" bash "$REPO/package.sh" analise-dados 2>&1 >/dev/null)" && ko "name diferente da pasta não deu erro" || ok
printf '%s' "$err" | grep -q "declara name 'outro-nome'" && ok || ko "name errado sem mensagem: $err"
[ -f "$T/y/analise-dados.zip" ] && ko "zip criado mesmo com name errado" || ok

# Pasta de skills vazia: erro claro (bash 3.2 com set -u quebrava em array vazio)
mkdir -p "$T/vazio/.claude/skills" && cp "$ROOT/package.sh" "$T/vazio/"
err="$(OUT="$T/z" bash "$T/vazio/package.sh" 2>&1 >/dev/null)" && ko "sem skills não deu erro" || ok
printf '%s' "$err" | grep -q 'nenhuma skill' && ok || ko "sem skills sem mensagem clara: $err"

echo "passou: $pass  falhou: $fail"
[ "$fail" = 0 ]
