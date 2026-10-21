#!/usr/bin/env bash
# Hook Stop: antes de o Claude encerrar a resposta, roda a verificação do projeto se o código mudou
# desde a última verificação. Falhou: exit 2 com o fim da saída, e o Claude continua para corrigir.
# Ideia do Stop hook de searlsco/prove_it (MIT), reescrita sem dependências.
# Comando: primeira linha útil de .claude/verify-cmd na raiz do repositório ("off" desliga);
# sem o arquivo, "npm test" (script de teste real e node_modules presente) ou "pytest -q"
# (configuração do pytest presente). Sem comando, libera.
# Segurança: o comando vem do repositório, então só roda depois que o usuário o aprova no próprio
# terminal (verify-stop.sh --aprovar na raiz). A aprovação fica em .git, que não vem no clone.
# Nunca bloqueia duas vezes seguidas (stop_hook_active), nem duas vezes pelo mesmo código que já
# falhou, nem por erro do próprio hook.

# Acha o comando do repositório em que o shell está.
find_cmd() {
  cmd=""
  if [ -f .claude/verify-cmd ]; then
    cmd="$(grep -v '^[[:space:]]*#' .claude/verify-cmd | grep -m1 '[^[:space:]]' | tr -d '\r')"
  elif [ -f package.json ] && [ -d node_modules ] && grep -q '"test"[[:space:]]*:' package.json &&
    ! grep -q 'no test specified' package.json; then
    cmd="npm test --silent"
  elif command -v pytest >/dev/null 2>&1 && { [ -f pytest.ini ] || [ -f conftest.py ] ||
    grep -qs '^\[tool\.pytest' pyproject.toml || grep -qs '^\[tool:pytest\]' setup.cfg; }; then
    cmd="pytest -q"
  fi
}

if [ "$1" = --aprovar ]; then
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Rode dentro de um repositório Git." >&2; exit 1; }
  cd "$root" || exit 1
  find_cmd
  [ -z "$cmd" ] || [ "$cmd" = off ] && { echo "Nenhum comando de verificação neste repositório." >&2; exit 1; }
  printf '%s\n' "$cmd" >"$(git rev-parse --absolute-git-dir)/autonomia-verify-ok" || exit 1
  echo "Aprovado para $root: $cmd"
  exit 0
fi

input="$(cat)"
printf '%s' "$input" | tr -d '[:space:]' | grep -q '"stop_hook_active":true' && exit 0

cwd=""
if command -v jq >/dev/null 2>&1; then
  cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
elif command -v python3 >/dev/null 2>&1 && python3 -c '' >/dev/null 2>&1; then
  cwd="$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("cwd") or "")' 2>/dev/null)"
else
  cwd="$(printf '%s' "$input" | tr '\n' ' ' | sed -nE 's/.*"cwd"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' | sed 's/\\\\/\\/g')"
fi
[ -n "$cwd" ] && { cd "$cwd" 2>/dev/null || exit 0; }
command -v git >/dev/null 2>&1 || exit 0
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0
gdir="$(git rev-parse --absolute-git-dir 2>/dev/null)" || exit 0
state="$gdir/autonomia-verified"
find_cmd
[ -z "$cmd" ] || [ "$cmd" = off ] && exit 0

# Impressão digital do código: commit atual, diff e arquivos novos fora do .gitignore.
head="$(git rev-parse -q --verify HEAD 2>/dev/null)"
untracked="$(git -c core.quotepath=off ls-files -o --exclude-standard 2>/dev/null)"
fp="$({
  echo "$head"
  git diff HEAD --no-color --no-ext-diff 2>/dev/null
  printf '%s\n' "$untracked" | while IFS= read -r f; do [ -f "$f" ] && echo "$f" && cksum <"$f"; done
} | cksum | tr -d ' \t')"
old_fp="" old_head="" failed_fp=""
[ -f "$state" ] && { old_fp="$(sed -n 1p "$state")"; old_head="$(sed -n 2p "$state")"; failed_fp="$(sed -n 3p "$state")"; }
save() { printf '%s\n%s\n%s\n' "$1" "$2" "$3" >"$state" 2>/dev/null; }

# Já verificado, ou já avisado da falha deste mesmo código.
[ "$fp" = "$old_fp" ] || [ "$fp" = "$failed_fp" ] && exit 0
# Primeira vez neste repositório com a árvore limpa: só marca o ponto de partida.
if [ -z "$old_fp" ] && [ -z "$untracked" ] && git diff HEAD --quiet 2>/dev/null; then
  save "$fp" "$head" ""; exit 0
fi
# Só documentação mudou desde a última verificação: não roda os testes.
if [ -n "$old_head" ] && git rev-parse -q --verify "$old_head^{commit}" >/dev/null 2>&1; then
  changed="$({ git -c core.quotepath=off diff --name-only "$old_head" 2>/dev/null; printf '%s\n' "$untracked"; } | grep -v '^$')"
  if [ -n "$changed" ] && ! printf '%s\n' "$changed" | grep -Eqv '\.(md|txt|rst)$|(^|/)(LICENSE|CHANGELOG)[^/]*$'; then
    save "$fp" "$head" ""; exit 0
  fi
fi

# Comando ainda não aprovado pelo usuário: avisa uma vez por comando e não roda.
ok_file="$gdir/autonomia-verify-ok"
if [ "$(cat "$ok_file" 2>/dev/null)" != "$cmd" ]; then
  asked="$gdir/autonomia-verify-asked"
  [ "$(cat "$asked" 2>/dev/null)" = "$cmd" ] && exit 0
  printf '%s\n' "$cmd" >"$asked" 2>/dev/null || exit 0
  echo "Este repositório tem um comando de verificação ainda não aprovado: $cmd" >&2
  echo "Não rode nem aprove você mesmo. Diga ao usuário que, se confiar no comando, ele rode no próprio terminal, na raiz do repositório: bash \"${BASH_SOURCE[0]}\" --aprovar" >&2
  exit 2
fi

out="$(mktemp 2>/dev/null)" || exit 0
bash -c "$cmd" >"$out" 2>&1 </dev/null
code=$?
if [ "$code" = 0 ]; then
  save "$fp" "$head" ""; rm -f "$out"; exit 0
fi
save "$old_fp" "$old_head" "$fp"
{
  echo "Verificação falhou antes de encerrar (comando: $cmd, saída $code). Últimas linhas:"
  tail -n 40 "$out"
  echo "Corrija e rode de novo. Se a falha não for desta alteração, diga isso ao usuário com a evidência."
} >&2
rm -f "$out"
exit 2
