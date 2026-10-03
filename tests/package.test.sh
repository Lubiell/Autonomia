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

# Uma skill só, e skill inexistente
OUT="$T/um" bash "$ROOT/package.sh" analise-dados >/dev/null
[ -f "$T/um/analise-dados.zip" ] && [ "$(ls "$T/um" | wc -l | tr -d ' ')" = 1 ] && ok || ko "argumento não limitou a uma skill"
OUT="$T/x" bash "$ROOT/package.sh" nao-existe >/dev/null 2>&1 && ko "skill inexistente não deu erro" || ok

# name diferente da pasta: recusa (cópia do repositório com o name trocado)
cp -r "$ROOT/.claude" "$ROOT/package.sh" "$T/" && mkdir -p "$T/repo" && mv "$T/.claude" "$T/package.sh" "$T/repo/"
sed 's/^name: analise-dados/name: outro-nome/' "$T/repo/.claude/skills/analise-dados/SKILL.md" > "$T/s" && mv "$T/s" "$T/repo/.claude/skills/analise-dados/SKILL.md"
OUT="$T/y" bash "$T/repo/package.sh" analise-dados >/dev/null 2>&1 && ko "name diferente da pasta não deu erro" || ok
[ -f "$T/y/analise-dados.zip" ] && ko "zip criado mesmo com name errado" || ok

echo "passou: $pass  falhou: $fail"
[ "$fail" = 0 ]
