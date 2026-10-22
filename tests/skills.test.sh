#!/usr/bin/env bash
# Confere o cabeçalho (frontmatter) de skills e agents. Erro aqui falha em silêncio:
# skill sem description carrega e nunca dispara; nome diferente da pasta é recusado
# no upload para o claude.ai sem dizer por quê.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
pass=0 fail=0
BUDGET=450
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
  # Orçamento do Autonomia: a description entra no contexto em todo turno (skill só por comando não entra)
  grep -q '^disable-model-invocation:[[:space:]]*true' "$file" || [ ${#desc} -le "$BUDGET" ] && pass=$((pass + 1)) || ko "$file: description com ${#desc} caracteres (orçamento $BUDGET; encurte)"
  # Corpo depois do cabeçalho: skill só com description dispara e não diz o que fazer
  [ "$(awk '/^---[[:space:]]*$/ { n++; next } n >= 2' "$file" | tr -d '[:space:]' | wc -c)" -ge 20 ] \
    && pass=$((pass + 1)) || ko "$file: corpo vazio depois do cabeçalho"
  printf '%s\t%s\n' "$file" "$desc" >>"$DESCS"
}

# Descrições parecidas disputam o mesmo gatilho e a skill errada dispara. Similaridade de
# Jaccard entre os conjuntos de palavras (3+ letras); acima de 0,6 falha (ideia do erphq/skillcheck).
collisions() {
  awk -F'\t' '
    { f[NR] = $1; d = tolower($2); gsub(/[[:space:][:punct:]]+/, " ", d); m = split(d, w, " ")
      for (i = 1; i <= m; i++) if (length(w[i]) > 2) s[NR, w[i]] = 1
      for (i = 1; i <= m; i++) if (length(w[i]) > 2 && !((NR, w[i]) in seen)) { seen[NR, w[i]] = 1; list[NR] = list[NR] " " w[i]; cnt[NR]++ } }
    END {
      for (a = 1; a <= NR; a++) for (b = a + 1; b <= NR; b++) {
        if (!cnt[a] || !cnt[b]) continue
        inter = 0; m = split(list[a], w, " ")
        for (i = 1; i <= m; i++) if ((b, w[i]) in s) inter++
        j = inter / (cnt[a] + cnt[b] - inter)
        if (j > 0.6) printf "%s e %s (%.2f)\n", f[a], f[b], j
      }
    }' "$1"
}

T="$(mktemp -d)"; trap 'rm -r "$T"' EXIT
DESCS="$T/descs.tsv"
n=0
for d in "$ROOT"/.claude/skills/*/; do
  [ -d "$d" ] || continue
  n=$((n + 1))
  s="${d%/}"
  if [ -f "$s/SKILL.md" ]; then check "$s/SKILL.md" "$(basename "$s")"; else ko "$s: sem SKILL.md"; fi
done
[ "$n" -gt 0 ] && pass=$((pass + 1)) || ko "nenhuma skill encontrada"

# Teto de palavras por agent: a rotina semanal acrescenta regras sozinha e não pode inchá-los
AGENT_WORDS=600
for f in "$ROOT"/.claude/agents/*.md; do
  [ -f "$f" ] || continue
  check "$f" "$(basename "$f" .md)"
  w="$(wc -w < "$f" | tr -d ' ')"
  [ "$w" -le "$AGENT_WORDS" ] && pass=$((pass + 1)) || ko "$f: $w palavras (teto $AGENT_WORDS; troque uma regra fraca em vez de somar)"
done

# Todo atalho (só por comando) aparece no roteador "atalhos", que os aciona sozinho
R="$ROOT/.claude/skills/atalhos/SKILL.md"
if [ -f "$R" ]; then
  for d in "$ROOT"/.claude/skills/*/; do
    s="${d%/}"; n="$(basename "$s")"
    grep -q '^disable-model-invocation:[[:space:]]*true' "$s/SKILL.md" 2>/dev/null || continue
    # Pacote de terceiros só por comando (com LICENSE.txt) passa pelo roteador "engenharia"
    if [ -f "$s/LICENSE.txt" ]; then
      grep -qF "| \`$n\` |" "$ROOT/.claude/skills/engenharia/SKILL.md" 2>/dev/null && pass=$((pass + 1)) || ko "método $n fora da tabela do roteador engenharia"
      continue
    fi
    grep -qF "| \`$n\` |" "$R" && pass=$((pass + 1)) || ko "atalho $n fora da tabela do roteador atalhos"
  done
fi

c="$(collisions "$DESCS")"
[ -z "$c" ] && pass=$((pass + 1)) || ko "descrições parecidas demais (disputam gatilho): $c"

# Todo hook citado no settings.json existe e está num evento que o Claude Code conhece
# (ideia do pdugan20/claudelint): hook com caminho errado falha em silêncio.
S="$ROOT/.claude/settings.json"
if [ -f "$S" ]; then
  for h in $(grep -oE '\.claude/hooks/[A-Za-z0-9._-]+' "$S" | sort -u); do
    [ -f "$ROOT/$h" ] && pass=$((pass + 1)) || ko "settings.json cita $h, que não existe"
  done
  # Lê os eventos pela indentação de hoje (4 espaços); se o JSON mudar de forma, falha em vez de não checar nada.
  events="$(sed -n '/"hooks"[[:space:]]*:/,$p' "$S" | grep -oE '^[[:space:]]{4}"[A-Za-z]+"[[:space:]]*:' | tr -d ' ":')"
  grep -q '"hooks"' "$S" && [ -z "$events" ] && ko "settings.json: bloco hooks sem evento legível (mudou a indentação?)"
  for e in $events; do
    case "$e" in
      PreToolUse | PostToolUse | PostToolUseFailure | UserPromptSubmit | Notification | Stop | SubagentStart | SubagentStop | \
        PreCompact | SessionStart | SessionEnd | PermissionRequest) pass=$((pass + 1)) ;;
      *) ko "settings.json: evento de hook desconhecido '$e'" ;;
    esac
  done
fi

# O próprio verificador: casos que devem falhar
printf -- '---\nname: outro\ndescription: x\n---\nCorpo com instruções suficientes.\n' > "$T/a.md"
printf -- '---\nname: b\n---\nCorpo com instruções suficientes.\n' > "$T/b.md"
printf -- '---\nname: c\ndescription: >\n  linha um\n  linha dois\n---\n' > "$T/c.md"
before=$fail
check "$T/a.md" a >/dev/null; check "$T/b.md" b >/dev/null
caught=$((fail - before)); fail=$before
[ "$caught" = 2 ] && pass=$((pass + 1)) || ko "verificador não pegou name trocado e description ausente"
[ "$(field "$T/c.md" description)" = "linha um linha dois" ] && pass=$((pass + 1)) || ko "description em bloco (>) não foi lida"
printf '%s\n' "x	Use para revisar contrato de prestação de serviço" "y	Use para revisar contrato de prestação de serviço digital" "z	Use para cortar vídeo" > "$T/d.tsv"
case "$(collisions "$T/d.tsv")" in "x e y ("*) true ;; *) false ;; esac && pass=$((pass + 1)) || ko "verificador não pegou descrições parecidas"
printf -- '---\nname: e\ndescription: x\n---\n\n' > "$T/e.md"
before=$fail; check "$T/e.md" e >/dev/null; caught=$((fail - before)); fail=$before
[ "$caught" = 1 ] && pass=$((pass + 1)) || ko "verificador não pegou corpo vazio"

echo "passou: $pass  falhou: $fail"
[ "$fail" = 0 ]
