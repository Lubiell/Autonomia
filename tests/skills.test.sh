#!/usr/bin/env bash
# Confere o cabeçalho (frontmatter) de skills e agents. Erro aqui falha em silêncio:
# skill sem description carrega e nunca dispara; nome diferente da pasta é recusado
# no upload para o claude.ai sem dizer por quê.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
pass=0 fail=0
ko() { fail=$((fail + 1)); echo "FALHOU: $1"; }

# Valor de uma chave no primeiro bloco ---; junta as linhas recuadas de "key: >" ou "key: |".
field() {
  awk -v key="$2" '
    /^---[[:space:]]*$/ { n++; if (n > 1) exit; next }
    n == 1 {
      if (grab) { if ($0 ~ /^[[:space:]]+[^[:space:]]/) { sub(/^[[:space:]]+/, ""); out = out (out == "" ? "" : " ") $0; next } else exit }
      if (index($0, key ":") == 1) {
        v = substr($0, length(key) + 2); sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v)
        if (v == ">" || v == "|" || v == ">-" || v == "|-" || v == "") { grab = 1; next }
        out = v; exit
      }
    }
    END { print out }
  ' "$1"
}

check() {
  local file="$1" expected="$2" name desc
  if [ "$(head -1 "$file" | tr -d '\r')" != "---" ]; then ko "$file: não abre com bloco ---"; return; fi
  name="$(field "$file" name | tr -d '\r')"
  desc="$(field "$file" description | tr -d '\r')"
  [ "$name" = "$expected" ] && pass=$((pass + 1)) || ko "$file: name '$name' difere de '$expected'"
  printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' && [ ${#name} -le 64 ] \
    && pass=$((pass + 1)) || ko "$file: name '$name' fora do padrão (minúsculas, números e hífen; até 64)"
  [ -n "$desc" ] && pass=$((pass + 1)) || ko "$file: sem description"
  [ ${#desc} -le 1024 ] && pass=$((pass + 1)) || ko "$file: description com ${#desc} caracteres (máximo 1024)"
}

n=0
for d in "$ROOT"/.claude/skills/*/; do
  [ -d "$d" ] || continue
  n=$((n + 1))
  s="${d%/}"
  if [ -f "$s/SKILL.md" ]; then check "$s/SKILL.md" "$(basename "$s")"; else ko "$s: sem SKILL.md"; fi
done
[ "$n" -gt 0 ] && pass=$((pass + 1)) || ko "nenhuma skill encontrada"

for f in "$ROOT"/.claude/agents/*.md; do
  [ -f "$f" ] || continue
  check "$f" "$(basename "$f" .md)"
done

# O próprio verificador: casos que devem falhar
T="$(mktemp -d)"; trap 'rm -r "$T"' EXIT
printf -- '---\nname: outro\ndescription: x\n---\n' > "$T/a.md"
printf -- '---\nname: b\n---\n' > "$T/b.md"
printf -- '---\nname: c\ndescription: >\n  linha um\n  linha dois\n---\n' > "$T/c.md"
before=$fail
check "$T/a.md" a >/dev/null; check "$T/b.md" b >/dev/null
caught=$((fail - before)); fail=$before
[ "$caught" = 2 ] && pass=$((pass + 1)) || ko "verificador não pegou name trocado e description ausente"
[ "$(field "$T/c.md" description)" = "linha um linha dois" ] && pass=$((pass + 1)) || ko "description em bloco (>) não foi lida"

echo "passou: $pass  falhou: $fail"
[ "$fail" = 0 ]
