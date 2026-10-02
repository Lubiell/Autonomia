#!/usr/bin/env bash
# Testes do install.sh em pastas temporárias (nunca toca ~/.claude). Uso: bash tests/install.test.sh
# Requer jq para as conferências. Testa o caminho python3 e, se possível, o caminho só com jq.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0 fail=0

ok() { pass=$((pass + 1)); }
ko() { fail=$((fail + 1)); echo "FALHOU: $1"; }
assert() { if jq -e "$2" "$3" >/dev/null 2>&1; then ok; else ko "$1 ($3)"; fi; }

# PATH sem python3, para forçar o caminho jq do instalador.
NOPY="$TMP/nopy"
mkdir -p "$NOPY"
for b in bash cat cp cmp mkdir mktemp rm chmod find dirname basename date jq sed tr grep head; do
  p="$(command -v "$b")" && ln -s "$p" "$NOPY/$b"
done
modes="py"
echo x | PATH="$NOPY" cat >/dev/null 2>&1 && modes="py jq"

USER_SETTINGS='{"model":"x","permissions":{"allow":["Bash(ls:*)"],"ask":["Bash(git push:*)"]},"sandbox":{"enabled":false},"hooks":{"PreToolUse":[{"matcher":"Edit","hooks":[{"type":"command","command":"echo meu"}]}]}}'

for mode in $modes; do
  run() { if [ "$mode" = jq ]; then PATH="$NOPY" CLAUDE_HOME="$1" bash "$ROOT/install.sh"; else CLAUDE_HOME="$1" bash "$ROOT/install.sh"; fi; }

  # Instalação nova
  H="$TMP/$mode-novo"
  run "$H" >/dev/null || ko "[$mode] install.sh falhou (novo)"
  S="$H/settings.json"
  assert "[$mode] novo: hook aponta para a instalação" ".hooks.PreToolUse[0].hooks[0].command == \"bash \\\"$H/hooks/guard.sh\\\"\"" "$S"
  assert "[$mode] novo: sandbox ligado" '.sandbox.enabled == true' "$S"
  assert "[$mode] novo: ask inclui retry fora do sandbox" '.permissions.ask | index("Bash(dangerouslyDisableSandbox:true)")' "$S"
  [ -x "$H/hooks/guard.sh" ] && ok || ko "[$mode] novo: guard.sh executável"
  [ -f "$H/skills/discover-resources/decisoes.md" ] && ok || ko "[$mode] novo: skill copiada"
  echo '{"tool_input":{"command":"rm -r -f x"}}' | bash -c "$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$S")" 2>/dev/null
  [ $? = 2 ] && ok || ko "[$mode] novo: hook instalado bloqueia"

  # Mescla com settings do usuário
  H="$TMP/$mode-existente"
  mkdir -p "$H" && printf '%s\n' "$USER_SETTINGS" > "$H/settings.json"
  run "$H" >/dev/null || ko "[$mode] install.sh falhou (existente)"
  S="$H/settings.json"
  assert "[$mode] existente: mantém model e allow" '.model == "x" and .permissions.allow == ["Bash(ls:*)"]' "$S"
  assert "[$mode] existente: mantém sandbox do usuário" '.sandbox == {"enabled": false}' "$S"
  assert "[$mode] existente: mantém hook do usuário e acrescenta o guard" '[.hooks.PreToolUse[].hooks[0].command] | (.[0] == "echo meu") and (.[1] | endswith("/hooks/guard.sh\""))' "$S"
  assert "[$mode] existente: ask sem duplicata" '.permissions.ask | (length == (unique | length))' "$S"
  ls "$H"/backup-orquestrador-*/settings.json >/dev/null 2>&1 && ok || ko "[$mode] existente: backup do settings"

  # Reexecução não muda nada
  cp "$S" "$TMP/antes.json"
  out="$(run "$H")"
  case "$out" in *"settings.json (já atualizado)"*) ok ;; *) ko "[$mode] reexecução: esperado 'já atualizado'" ;; esac
  cmp -s "$S" "$TMP/antes.json" && ok || ko "[$mode] reexecução alterou o settings"
done

# Os dois caminhos geram o mesmo JSON, a menos do caminho da instalação.
if [ "$modes" = "py jq" ]; then
  for c in novo existente; do
    a="$(sed "s#$TMP/py-$c#DEST#g" "$TMP/py-$c/settings.json" | jq -S .)"
    b="$(sed "s#$TMP/jq-$c#DEST#g" "$TMP/jq-$c/settings.json" | jq -S .)"
    [ "$a" = "$b" ] && ok || ko "python e jq divergem ($c)"
  done
else
  echo "aviso: caminho só com jq não testado neste sistema"
fi

echo "passou: $pass  falhou: $fail"
[ "$fail" = 0 ]
