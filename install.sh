#!/usr/bin/env bash
# Instala o orquestrador no nível do usuário (~/.claude), valendo para todos os projetos.
# Uso: ./install.sh            (destino: ~/.claude; ou defina CLAUDE_HOME)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
BACKUP="$DEST/backup-orquestrador-$(date +%Y%m%d-%H%M%S)"

# Copia src para dst; se dst existir com conteúdo diferente, guarda cópia no backup.
install_file() {
  local src="$1" rel="$2" dst="$DEST/$2"
  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
    mkdir -p "$BACKUP/$(dirname "$rel")"
    cp "$dst" "$BACKUP/$rel"
    echo "  backup: $rel"
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  ok: $rel"
}

echo "Instalando em $DEST"
mkdir -p "$DEST"

install_file "$SRC/CLAUDE.md" "CLAUDE.md"
for f in "$SRC"/.claude/agents/*.md; do
  install_file "$f" "agents/$(basename "$f")"
done
(cd "$SRC/.claude" && find skills -type f) | while read -r rel; do
  install_file "$SRC/.claude/$rel" "$rel"
done

# settings.json: junta deny/ask às regras existentes, sem apagar nada do usuário.
SETTINGS="$DEST/settings.json"
if [ ! -f "$SETTINGS" ]; then
  cp "$SRC/.claude/settings.json" "$SETTINGS"
  echo "  ok: settings.json (novo)"
else
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  merged=1
  # "python3 -c ''" descarta o stub do macOS que existe sem o Python instalado.
  if command -v python3 >/dev/null 2>&1 && python3 -c '' >/dev/null 2>&1; then
    python3 - "$SETTINGS" "$SRC/.claude/settings.json" "$tmp" <<'EOF'
import json, sys
dst_path, src_path, out_path = sys.argv[1:4]
with open(dst_path, encoding="utf-8") as f:
    dst = json.load(f)
with open(src_path, encoding="utf-8") as f:
    src = json.load(f)
perms = dst.setdefault("permissions", {})
for key in ("deny", "ask"):
    cur = perms.setdefault(key, [])
    cur.extend(r for r in src["permissions"][key] if r not in cur)
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(dst, f, indent=2, ensure_ascii=False)
    f.write("\n")
EOF
  elif command -v jq >/dev/null 2>&1; then
    jq --slurpfile src "$SRC/.claude/settings.json" '
      .permissions.deny = ((.permissions.deny // []) + ($src[0].permissions.deny - (.permissions.deny // []))) |
      .permissions.ask  = ((.permissions.ask  // []) + ($src[0].permissions.ask  - (.permissions.ask  // [])))
    ' "$SETTINGS" > "$tmp"
  else
    echo "  AVISO: sem python3 nem jq; junte as permissões de .claude/settings.json manualmente."
    merged=0
  fi
  if [ "$merged" = 0 ]; then
    :
  elif cmp -s "$tmp" "$SETTINGS"; then
    echo "  ok: settings.json (já atualizado)"
  else
    mkdir -p "$BACKUP"
    cp "$SETTINGS" "$BACKUP/settings.json"
    echo "  backup: settings.json"
    # Grava por cima (sem mv) para preservar symlink e permissões do arquivo.
    cat "$tmp" > "$SETTINGS"
    echo "  ok: settings.json (permissões mescladas)"
  fi
fi

[ -d "$BACKUP" ] && echo "Backup dos arquivos substituídos: $BACKUP"
echo "Pronto. Remova o CLAUDE.md da raiz dos projetos que tinham cópia dele, para não carregar as regras em dobro."
