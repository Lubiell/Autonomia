#!/usr/bin/env bash
# Backup de todos os repositórios do dono no Google Drive, uma pasta por repositório:
#   <destino>/<repo>/<repo>.zip         código da branch principal
#   <destino>/<repo>/<repo>.bundle      histórico completo (git clone <repo>.bundle)
#   <destino>/<repo>/<repo>-versao.txt  commit, data e mensagem do último backup
# Só reenvia o repositório cujo último commit mudou desde o backup anterior.
#
# Variáveis:
#   BACKUP_OWNER      dono dos repositórios (obrigatória)
#   BACKUP_REMOTE     destino do rclone (padrão gdrive:Backups-GitHub)
#   BACKUP_GH_TOKEN   token opcional para incluir repositórios privados
#   BACKUP_FORCE=1    reenvia todos, mesmo sem mudança
#   BACKUP_REPOS_TSV  lista "nome<TAB>branch<TAB>url" no lugar da API (testes)
set -euo pipefail

owner="${BACKUP_OWNER:?defina BACKUP_OWNER}"
dest="${BACKUP_REMOTE:-gdrive:Backups-GitHub}"
work="$(mktemp -d)"
trap 'rm -r -f -- "$work"' EXIT

if [ -n "${BACKUP_REPOS_TSV:-}" ]; then
  repos="$BACKUP_REPOS_TSV"
elif [ -n "${BACKUP_GH_TOKEN:-}" ]; then
  repos="$(GH_TOKEN="$BACKUP_GH_TOKEN" gh api --paginate '/user/repos?affiliation=owner&per_page=100' \
    --jq '.[] | [.name, .default_branch, .clone_url] | @tsv')"
else
  repos="$(gh api --paginate "/users/$owner/repos?type=owner&per_page=100" \
    --jq '.[] | [.name, .default_branch, .clone_url] | @tsv')"
fi

feitos=0; iguais=0; falhas=0
while IFS=$'\t' read -r name branch url; do
  [ -n "$name" ] || continue
  auth_url="$url"
  if [ -n "${BACKUP_GH_TOKEN:-}" ] && [[ "$url" == https://github.com/* ]]; then
    auth_url="https://x-access-token:${BACKUP_GH_TOKEN}@${url#https://}"
  fi

  head="$(git ls-remote "$auth_url" "refs/heads/$branch" 2>/dev/null | cut -f1 || true)"
  if [ -z "$head" ]; then
    echo "$name: sem commits na branch $branch, pulando"
    continue
  fi
  last="$(rclone cat "$dest/$name/$name-versao.txt" 2>/dev/null | cut -d' ' -f1 || true)"
  if [ "$head" = "$last" ] && [ "${BACKUP_FORCE:-0}" != 1 ]; then
    echo "$name: já atualizado ($head)"
    iguais=$((iguais + 1))
    continue
  fi

  repo_dir="$work/$name.git"
  if ! git clone -q --bare "$auth_url" "$repo_dir"; then
    echo "::warning::$name: falha ao clonar"
    falhas=$((falhas + 1))
    continue
  fi
  git --git-dir="$repo_dir" bundle create -q "$work/$name.bundle" --all
  git --git-dir="$repo_dir" archive --format=zip --prefix="$name/" -o "$work/$name.zip" "$branch"
  git --git-dir="$repo_dir" log -1 --format='%H %cI %s' "$branch" > "$work/$name-versao.txt"

  # copyto sobrescreve o arquivo de mesmo nome. A versão vai por último:
  # se um envio falhar no meio, o próximo backup tenta de novo.
  rclone copyto "$work/$name.zip" "$dest/$name/$name.zip"
  rclone copyto "$work/$name.bundle" "$dest/$name/$name.bundle"
  rclone copyto "$work/$name-versao.txt" "$dest/$name/$name-versao.txt"
  echo "$name: backup enviado ($head)"
  feitos=$((feitos + 1))
  rm -r -f -- "$repo_dir" "$work/$name.zip" "$work/$name.bundle" "$work/$name-versao.txt"
done <<< "$repos"

echo "Resumo: $feitos enviados, $iguais já atualizados, $falhas falhas"
[ "$falhas" -eq 0 ]
