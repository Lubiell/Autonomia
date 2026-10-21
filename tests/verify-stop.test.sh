#!/usr/bin/env bash
# Testes do hook .claude/hooks/verify-stop.sh. Uso: bash tests/verify-stop.test.sh
# Roda com o parser disponível (jq/python3) e de novo sem eles (JSON bruto).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/.claude/hooks/verify-stop.sh"
BASH_BIN="${BASH:-$(command -v bash)}"
pass=0 fail=0
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

# PATH mínimo, sem jq nem python3, para testar o modo de JSON bruto.
BARE="$T/bin"; mkdir "$BARE"
for b in cat sed tr grep head tail git cksum mktemp rm bash test; do
  p="$(command -v "$b")" && [ "${p#/}" != "$p" ] && ln -s "$p" "$BARE/$b"
done
modes="full bare"
if ! echo x | PATH="$BARE" cat >/dev/null 2>&1; then
  modes="full"; echo "aviso: modo sem jq/python3 indisponível neste sistema; testando só o modo completo"
fi

# run <esperado> <descrição> [stop_hook_active]: roda o hook com cwd=$R e confere o código de saída.
# $STUB vem antes no PATH (npm falso).
run() {
  local want="$1" what="$2" active="${3:-false}" code json path="$STUB:$PATH"
  [ "$mode" = bare ] && path="$STUB:$BARE"
  json="{\"session_id\":\"s\",\"hook_event_name\":\"Stop\",\"stop_hook_active\":$active,\"cwd\":\"$R\"}"
  printf '%s' "$json" | PATH="$path" "$BASH_BIN" "$HOOK" 2>"$T/err"; code=$?
  [ "$code" = "$want" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FALHOU [$mode]: $what (esperado $want, veio $code)"; }
}
repo() {
  mkdir -p "$1" && git -C "$1" init -q && git -C "$1" config user.email t@t && git -C "$1" config user.name t
}

for mode in $modes; do
  STUB="$T/stub-$mode"; mkdir -p "$STUB"
  FLAG="$T/falha-$mode"   # existe = a verificação falha; fora do repositório para não contar como mudança
  R="$T/repo-$mode"; repo "$R"; mkdir "$R/.claude"
  echo 'a=1' >"$R/app.sh"
  git -C "$R" add -A && git -C "$R" commit -qm inicio

  run 0 "sem comando de verificação, libera"
  printf '# comentário\n\ntest ! -f "%s"\n' "$FLAG" >"$R/.claude/verify-cmd"
  git -C "$R" add -A && git -C "$R" commit -qm cmd
  touch "$FLAG"
  run 0 "primeira vez com árvore limpa só marca o ponto de partida"
  echo 'a=2' >"$R/app.sh"
  run 2 "comando não aprovado: avisa uma vez, sem rodar"
  grep -q 'ainda não aprovado' "$T/err" && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FALHOU [$mode]: aviso de aprovação ausente"; }
  echo 'a=22' >"$R/app.sh"
  run 0 "comando não aprovado: não avisa de novo nem roda"
  (cd "$R" && "$BASH_BIN" "$HOOK" --aprovar >/dev/null 2>&1)
  run 2 "aprovado, código mudou e a verificação falha: bloqueia"
  grep -q 'Verificação falhou' "$T/err" && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FALHOU [$mode]: mensagem de falha ausente"; }
  run 0 "stop_hook_active: nunca bloqueia duas vezes seguidas" true
  run 0 "mesmo código que já falhou: não bloqueia de novo (turno só de conversa)"
  echo 'a=2' >"$R/app.sh"
  run 2 "código mudou de novo e ainda falha: bloqueia"
  rm "$FLAG"; echo 'a=3' >"$R/app.sh"
  run 0 "verificação passa: libera e marca"
  touch "$FLAG"
  run 0 "nada mudou desde a última verificação que passou: não roda"
  git -C "$R" add -A && git -C "$R" commit -qm a2
  run 2 "commit novo depois da verificação conta como mudança"
  # Depois de uma falha, o mesmo código não roda de novo: a correção é uma mudança de código.
  rm "$FLAG"; echo 'b=1' >"$R/lib.sh"; git -C "$R" add -A && git -C "$R" commit -qm b
  run 0 "corrigido e commitado: marca"; touch "$FLAG"
  echo 'nota' >"$R/LEIA.md"; echo 'nova' >"$R/NOTAS.txt"
  run 0 "só documentação mudou: não roda os testes"
  echo 'novo' >"$R/novo.sh"
  run 2 "arquivo de código novo (não rastreado) roda a verificação"
  rm "$R/novo.sh"; rm "$FLAG"; run 0 "marca"; touch "$FLAG"
  mkdir -p "$R/pasta com espaço"; echo 'x' >"$R/pasta com espaço/ação.sh"
  run 2 "arquivo novo com espaço e acento no nome roda a verificação"
  echo 'y' >"$R/pasta com espaço/ação.sh"
  run 2 "edição em arquivo novo acentuado também conta"
  rm -r "$R/pasta com espaço"; rm "$FLAG"; run 0 "marca"; touch "$FLAG"
  echo 'false' >"$R/.claude/verify-cmd"; echo 'a=4' >"$R/app.sh"
  run 2 "comando trocado precisa de nova aprovação: avisa"
  grep -q 'ainda não aprovado' "$T/err" && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FALHOU [$mode]: troca de comando sem pedir aprovação"; }
  echo 'off' >"$R/.claude/verify-cmd"; echo 'a=5' >"$R/app.sh"
  run 0 "off desliga"
  rm "$FLAG"

  # Detecção automática do npm: script de teste real e node_modules presente.
  R="$T/npm-$mode"; repo "$R"; mkdir "$R/node_modules"
  echo '{"scripts":{"test":"node t.js"}}' >"$R/package.json"
  printf '#!/bin/sh\nexit 1\n' >"$STUB/npm"; chmod +x "$STUB/npm"
  echo 'x' >"$R/a.js"
  (cd "$R" && "$BASH_BIN" "$HOOK" --aprovar >/dev/null 2>&1)
  run 2 "npm test detectado, aprovado e falhando: bloqueia (sem ponto de partida, árvore suja)"
  rm -r "$R/node_modules"
  run 0 "sem node_modules não roda npm"
  echo '{"scripts":{"test":"echo \"Error: no test specified\" && exit 1"}}' >"$R/package.json"; mkdir "$R/node_modules"
  run 0 "script de teste padrão do npm init não conta"

  R="$T"; run 0 "fora de repositório Git, libera"
  R="$T/nao-existe"; run 0 "cwd inexistente, libera"
done

echo "passou: $pass  falhou: $fail"
[ "$fail" = 0 ]
