#!/usr/bin/env bash
# Hook PreToolUse (Bash e PowerShell): bloqueia comandos destrutivos que escapam do
# bloqueio por prefixo do settings.json (ex.: "rm -r -f", "sudo rm -fr", "git push origin main -f"),
# segredo em commit, DELETE/UPDATE sem WHERE e escrita pelo shell na configuração do Claude Code.
# Entrada: JSON do Claude Code no stdin. Saída: exit 2 + motivo no stderr bloqueia; exit 0 libera.
# Sem dependências obrigatórias: usa jq ou python3 se houver; senão analisa o JSON bruto.

input="$(cat)"

# Lê um campo de tool_input ou do primeiro nível: extract command | extract cwd.
extract() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg k "$key" '.tool_input[$k] // .[$k] // empty' 2>/dev/null && return
  fi
  if command -v python3 >/dev/null 2>&1 && python3 -c '' >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); k=sys.argv[1]; print(d.get("tool_input",{}).get(k) or d.get(k) or "")' "$key" 2>/dev/null && return
  fi
  # Último recurso: recorta o campo do JSON bruto e desfaz \" e \\.
  printf '%s' "$input" | tr '\n' ' ' |
    sed -nE 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' |
    sed -e 's/\\"/"/g' -e 's/\\\\/\\/g'
}

cmd="$(extract command)"
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

# Segredo no commit: arquivo sensível ou chave conhecida no que vai ser commitado.
# Usa $commit_dir, $commit_all (git commit -a) e $add_any (git add no mesmo comando, que
# roda depois deste hook: aí vale a árvore de trabalho inteira, inclusive arquivos novos).
scan_secrets() {
  local cwd range=--cached untracked="" bad f
  cwd="$(extract cwd)"
  [ -n "$cwd" ] && cd "$cwd" 2>/dev/null
  if [ -n "$commit_dir" ]; then cd "$commit_dir" 2>/dev/null || return 0; fi
  command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1 || return 0
  if [ "$commit_all" = 1 ] || [ "$add_any" = 1 ]; then
    git rev-parse --verify -q HEAD >/dev/null && range=HEAD
  fi
  [ "$add_any" = 1 ] && untracked="$(git ls-files -o --exclude-standard 2>/dev/null)"
  bad="$({ git diff $range --name-only --diff-filter=ACMR 2>/dev/null; printf '%s\n' "$untracked"; } |
    grep -Ei '(^|/)(\.env(\.[^/]*)?|id_(rsa|dsa|ecdsa|ed25519)|[^/]*\.(pem|key|p12|pfx)|credentials\.json|service[-_]?account[^/]*\.json)$' |
    grep -Eiv '\.(example|sample|template|dist)$' | head -3 | tr '\n' ' ')"
  [ -n "$bad" ] && block "arquivo sensível no commit: $bad"
  if {
    git diff $range -U0 --no-color --no-ext-diff 2>/dev/null | grep -E '^\+' | grep -Ev '^\+\+\+ '
    printf '%s\n' "$untracked" | while IFS= read -r f; do
      # Arquivo novo até 1 MB; maior que isso não é configuração nem código-fonte típico.
      [ -f "$f" ] && [ "$(wc -c <"$f")" -le 1048576 ] && cat -- "$f"
    done
  } | grep -Eq -- '-----BEGIN ([A-Z]+ )*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|(^|[^A-Za-z0-9])(gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{22,}|sk-ant-[A-Za-z0-9_-]{20,}|sk-(proj-)?[A-Za-z0-9_-]{32,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|glpat-[A-Za-z0-9_-]{20})'; then
    block "chave, token ou chave privada no conteúdo do commit"
  fi
}

# DELETE/UPDATE sem WHERE, quando o comando chama um cliente de banco.
if printf '%s' "$cmd" | grep -Eiq '(^|[^a-z0-9_])(sqlite3|psql|mysql|mariadb|wrangler|turso|duckdb|sqlcmd|clickhouse-client)([^a-z0-9_]|$)'; then
  while IFS= read -r st; do
    if printf '%s' "$st" | grep -Eq '(^|[^a-z0-9_])(delete[[:space:]]+from|update[[:space:]]+[^[:space:]]+[[:space:]]+set)([^a-z0-9_]|$)' &&
      ! printf '%s' "$st" | grep -Eq '(^|[^a-z0-9_])where([^a-z0-9_]|$)'; then
      block "DELETE ou UPDATE sem WHERE"
    fi
  done <<<"$(printf '%s\n' "$cmd" | tr '\n' ' ' | sed 's/\\n/ /g' | tr ';&|' '\n\n\n' | tr '[:upper:]' '[:lower:]')"
fi

# Escrita pelo shell em .claude/settings* ou .claude/hooks (Edit/Write já são protegidos pelo Claude Code).
# Aqui "$" não separa trechos, para "$HOME/.claude/settings.json" ficar junto do ">" ou do comando.
while IFS= read -r seg; do
  case "$seg" in
    *.claude/settings* | *.claude/hooks* | *.claudesettings* | *.claudehooks*) ;;
    *) continue ;;
  esac
  cfg='\.claude/?(settings|hooks)'
  if printf '%s' "$seg" | grep -Eq ">[[:space:]]*[^[:space:]]*$cfg|(^|[[:space:]/])(sed|perl)([[:space:]].*)?[[:space:]](-[a-z]*i|--in-place)|(^|[[:space:]/])(tee|rm|mv|ln|truncate|chmod|dd|set-content|add-content|out-file|new-item|remove-item|move-item)([[:space:]]|$)"; then
    block "escrita pelo shell na configuração do Claude Code (.claude/settings ou .claude/hooks)"
  fi
  # Cópia só bloqueia quando o destino (último argumento) é a configuração.
  read -ra w <<<"$seg"
  n=${#w[@]}
  for ((i = 0; i < n; i++)); do
    case "${w[i]##*/}" in
      cp | install | copy-item)
        printf '%s' "${w[n - 1]}" | grep -Eq "$cfg" && block "escrita pelo shell na configuração do Claude Code (.claude/settings ou .claude/hooks)"
        ;;
    esac
  done
done <<<"$(printf '%s\n' "$cmd" | sed 's/\\n/\
/g' | tr ';|&()`' '\n\n\n\n\n\n' | tr -d "\"'\\\\" | tr '[:upper:]' '[:lower:]')"

# Separa em trechos por ; | & && || ( ) $( ` e quebras de linha; tira aspas e escapes.
# Só tr e sed com quebra de linha literal: o sed do macOS não entende \n na substituição.
# osegments mantém maiúsculas (caminhos); segments vai em minúsculas (comandos e flags).
osegments="$(printf '%s\n' "$cmd" | sed 's/\\n/\
/g' | tr ';|&()`$' '\n\n\n\n\n\n\n' | tr -d "\"'\\\\")"
segments="$(printf '%s\n' "$osegments" | tr '[:upper:]' '[:lower:]')"

commit=0 commit_all=0 add_any=0 commit_dir="" wd=""
while IFS= read -r seg && IFS= read -r oseg <&3; do
  read -ra w <<<"$seg"
  read -ra ow <<<"$oseg"
  n=${#w[@]}
  # Acompanha "cd dir" para saber em que repositório o commit roda.
  if [ "${w[0]}" = cd ] && [ -n "${ow[1]}" ]; then
    d="${ow[1]}"
    case "$d" in
      "~"*) wd="$HOME${d#\~}" ;;
      /*) wd="$d" ;;
      *) wd="${wd:+$wd/}$d" ;;
    esac
  fi
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
        sub="" rest=() gdir=""
        for ((j = i + 1; j < n; j++)); do
          t="${w[j]}"
          if [ -z "$sub" ]; then
            case "$t" in
              -c | --git-dir | --work-tree | --namespace)
                [ "${ow[j]}" = -C ] && gdir="${ow[j + 1]}"
                j=$((j + 1))
                ;;
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
          add)
            add_any=1
            ;;
          commit)
            commit=1
            case "$gdir" in
              "") commit_dir="$wd" ;;
              /*) commit_dir="$gdir" ;;
              *) commit_dir="${wd:+$wd/}$gdir" ;;
            esac
            for t in "${rest[@]}"; do
              case "$t" in
                --all) commit_all=1 ;;
                --*) ;;
                -*a*) commit_all=1 ;;
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
done <<<"$segments" 3<<<"$osegments"

[ "$commit" = 1 ] && scan_secrets
exit 0
