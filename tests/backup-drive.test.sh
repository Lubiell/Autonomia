#!/usr/bin/env bash
# Testa .github/scripts/backup-drive.sh sem Drive nem GitHub: repositórios git
# locais e um rclone falso que grava numa pasta.
set -euo pipefail

raiz="$(cd "$(dirname "$0")/.." && pwd)"
script="$raiz/.github/scripts/backup-drive.sh"
tmp="$(mktemp -d)"
trap 'rm -r -f -- "$tmp"' EXIT

# rclone falso: "cat <remoto>:<caminho>" e "copyto <local> <remoto>:<caminho>".
mkdir -p "$tmp/bin" "$tmp/drive"
cat > "$tmp/bin/rclone" <<'EOF'
#!/usr/bin/env bash
set -e
local_de() { printf '%s/%s' "$FAKE_DRIVE" "${1#*:}"; }
case "$1" in
  cat) cat "$(local_de "$2")" ;;
  copyto) mkdir -p "$(dirname "$(local_de "$3")")"; cp "$2" "$(local_de "$3")" ;;
  *) echo "rclone falso: comando $1 não suportado" >&2; exit 2 ;;
esac
EOF
chmod +x "$tmp/bin/rclone"
export PATH="$tmp/bin:$PATH" FAKE_DRIVE="$tmp/drive"
export BACKUP_OWNER=teste BACKUP_REMOTE="gdrive:Backups-GitHub"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

origem="$tmp/origem"
git init -q -b main "$origem"
git -C "$origem" commit -q --allow-empty -m inicial
export BACKUP_REPOS_TSV="repo	main	$origem"
pasta="$tmp/drive/Backups-GitHub/repo"

falhas=0
confere() { # descrição, saída esperada (trecho), saída obtida
  if [[ "$3" == *"$2"* ]]; then echo "ok: $1"; else echo "FALHOU: $1"; echo "$3"; falhas=$((falhas + 1)); fi
}

saida="$(bash "$script")"
confere "primeiro backup envia" "repo: backup enviado" "$saida"
for f in repo.zip repo.bundle repo-versao.txt repo-refs.txt; do
  [ -s "$pasta/$f" ] || { echo "FALHOU: $f não foi criado"; falhas=$((falhas + 1)); }
done

saida="$(bash "$script")"
confere "sem mudança não reenvia" "repo: já atualizado" "$saida"

git -C "$origem" branch outra
git -C "$origem" checkout -q outra
git -C "$origem" commit -q --allow-empty -m "só na outra branch"
git -C "$origem" checkout -q main
saida="$(bash "$script")"
confere "push em branch que não é a principal reenvia" "repo: backup enviado" "$saida"
git clone -q "$pasta/repo.bundle" "$tmp/restaurado"
git -C "$tmp/restaurado" log --oneline origin/outra | grep -q "só na outra branch" \
  && echo "ok: bundle traz a outra branch" || { echo "FALHOU: bundle sem a outra branch"; falhas=$((falhas + 1)); }

git -C "$origem" tag v1
saida="$(bash "$script")"
confere "tag nova reenvia" "repo: backup enviado" "$saida"

saida="$(BACKUP_FORCE=1 bash "$script")"
confere "BACKUP_FORCE reenvia sem mudança" "repo: backup enviado" "$saida"

[ "$falhas" -eq 0 ] && echo "backup-drive: todos os testes passaram"
exit "$falhas"
