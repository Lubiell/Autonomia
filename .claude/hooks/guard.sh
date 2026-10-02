#!/usr/bin/env bash
# Hook PreToolUse (Bash e PowerShell): bloqueia comandos destrutivos que escapam do
# bloqueio por prefixo do settings.json (ex.: "rm -r -f", "sudo rm -fr", "git push origin main -f").
# Entrada: JSON do Claude Code no stdin. Saída: exit 2 + motivo no stderr bloqueia; exit 0 libera.
# Sem dependências obrigatórias: usa jq ou python3 se houver; senão analisa o JSON bruto.

input="$(cat)"

extract() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null && return
  fi
  if command -v python3 >/dev/null 2>&1 && python3 -c '' >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null && return
  fi
  # Último recurso: recorta o campo "command" do JSON bruto e desfaz \" e \\.
  printf '%s' "$input" | tr '\n' ' ' |
    sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' |
    sed -e 's/\\"/"/g' -e 's/\\\\/\\/g'
}

cmd="$(extract)"
[ -z "$cmd" ] && exit 0

block() {
  echo "Bloqueado pelo hook guard.sh: $1. Se for mesmo necessário, peça ao usuário para rodar o comando manualmente." >&2
  exit 2
}

# Baixar e executar direto (curl ... | sh).
dl='(curl|wget|iwr|irm|invoke-webrequest|invoke-restmethod)'
if printf '%s' "$cmd" | grep -Eiq "$dl[^|]*\\|[[:space:]]*(sudo([[:space:]]+-[^[:space:]]+)*[[:space:]]+)?(ba|z|da|k)?sh([[:space:]]|\$)|$dl[^|]*\\|[[:space:]]*(iex|invoke-expression)|(ba|z|da|k)?sh[[:space:]]+(-c[[:space:]]+)?[\"']?(\\\$\\(|<\\()[[:space:]]*$dl"; then
  block "download executado direto no shell (curl | sh)"
fi

# Separa em trechos por ; | & && || ( ) $( ` e quebras de linha; tira aspas e escapes; minúsculas.
# Só tr e sed com quebra de linha literal: o sed do macOS não entende \n na substituição.
segments="$(printf '%s\n' "$cmd" | sed 's/\\n/\
/g' | tr ';|&()`$' '\n\n\n\n\n\n\n' | tr -d "\"'\\\\" | tr '[:upper:]' '[:lower:]')"

while IFS= read -r seg; do
  read -ra w <<<"$seg"
  n=${#w[@]}
  for ((i = 0; i < n; i++)); do
    base="${w[i]##*/}"
    case "$base" in
      rm)
        rec=0 force=0
        for ((j = i + 1; j < n; j++)); do
          t="${w[j]}"
          case "$t" in
            --recursive) rec=1 ;;
            --force) force=1 ;;
            --*) ;;
            -re*) block "Remove-Item recursivo (rm -Recurse)" ;;
            -*) [[ "$t" == *r* ]] && rec=1; [[ "$t" == *f* ]] && force=1 ;;
          esac
        done
        [ "$rec" = 1 ] && [ "$force" = 1 ] && block "rm recursivo forçado"
        ;;
      remove-item | ri | del | erase | rd | rmdir)
        for ((j = i + 1; j < n; j++)); do
          t="${w[j]}"
          [[ "$t" == -r || "$t" == -re* ]] && block "Remove-Item recursivo"
        done
        ;;
      git)
        sub="" rest=()
        for ((j = i + 1; j < n; j++)); do
          t="${w[j]}"
          if [ -z "$sub" ]; then
            case "$t" in
              -C | -c | --git-dir | --work-tree | --namespace) j=$((j + 1)) ;;
              -*) ;;
              *) sub="$t" ;;
            esac
          else
            rest+=("$t")
          fi
        done
        case "$sub" in
          push)
            for t in "${rest[@]}"; do
              case "$t" in
                --force) block "git push forçado" ;;
                --*) ;;
                -*f*) block "git push forçado" ;;
                +*) block "git push forçado (refspec com +)" ;;
              esac
            done
            ;;
          reset)
            for t in "${rest[@]}"; do [ "$t" = "--hard" ] && block "git reset --hard"; done
            ;;
          clean)
            dry=0 force=0
            for t in "${rest[@]}"; do
              case "$t" in
                -n | --dry-run) dry=1 ;;
                --force) force=1 ;;
                --*) ;;
                -*) [[ "$t" == *n* ]] && dry=1; [[ "$t" == *f* ]] && force=1 ;;
              esac
            done
            [ "$force" = 1 ] && [ "$dry" = 0 ] && block "git clean forçado"
            ;;
        esac
        ;;
    esac
  done
done <<<"$segments"

exit 0
