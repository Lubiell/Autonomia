#!/usr/bin/env bash
# Instala o orquestrador no nível do usuário (~/.claude), valendo para todos os projetos.
# Uso: ./install.sh            (destino: ~/.claude; ou defina CLAUDE_HOME)
#      AUTONOMIA_SEM_SANDBOX=1 ./install.sh   não liga o sandbox (sessão na nuvem, que já roda isolada)
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
(cd "$SRC/.claude" && find skills hooks -type f 2>/dev/null) | while read -r rel; do
  install_file "$SRC/.claude/$rel" "$rel"
done
[ -f "$DEST/hooks/guard.sh" ] && chmod +x "$DEST/hooks/guard.sh"

# settings.json: junta deny/ask, hooks e sandbox aos existentes, sem apagar nada do usuário.
# O caminho ${CLAUDE_PROJECT_DIR}/.claude/ dos hooks vira o da instalação ($DEST/).
# A seção "sandbox" só entra se o usuário ainda não tiver uma e AUTONOMIA_SEM_SANDBOX não for 1.
NOSB="${AUTONOMIA_SEM_SANDBOX:-0}"
SETTINGS="$DEST/settings.json"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
if [ -f "$SETTINGS" ]; then cur="$SETTINGS"; else cur=""; fi
merged=1
# "python3 -c ''" descarta o stub do macOS que existe sem o Python instalado.
if command -v python3 >/dev/null 2>&1 && python3 -c '' >/dev/null 2>&1; then
  python3 - "$cur" "$SRC/.claude/settings.json" "$tmp" "$DEST" "$NOSB" <<'EOF'
import json, sys
dst_path, src_path, out_path, dest, nosb = sys.argv[1:6]
dst = {}
if dst_path:
    with open(dst_path, encoding="utf-8") as f:
        txt = f.read()
    # Arquivo vazio ou só com espaços conta como configuração vazia.
    dst = json.loads(txt) if txt.strip() else {}
with open(src_path, encoding="utf-8") as f:
    src = json.load(f)
perms = dst.setdefault("permissions", {})
for key in ("deny", "ask"):
    cur = perms.setdefault(key, [])
    cur.extend(r for r in src["permissions"][key] if r not in cur)
for event, groups in src.get("hooks", {}).items():
    cur = dst.setdefault("hooks", {}).setdefault(event, [])
    known = [h.get("command") for g in cur for h in g.get("hooks", [])]
    for g in groups:
        g = json.loads(json.dumps(g).replace("${CLAUDE_PROJECT_DIR}/.claude/", dest + "/"))
        if not any(h.get("command") in known for h in g.get("hooks", [])):
            cur.append(g)
if nosb != "1" and "sandbox" in src and "sandbox" not in dst:
    dst["sandbox"] = src["sandbox"]
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(dst, f, indent=2, ensure_ascii=False)
    f.write("\n")
EOF
elif command -v jq >/dev/null 2>&1; then
  { if [ -n "$cur" ] && grep -q '[^[:space:]]' "$cur"; then cat "$cur"; else echo '{}'; fi; } |
    jq --slurpfile src "$SRC/.claude/settings.json" --arg dest "$DEST/" --arg nosb "$NOSB" '
      $src[0] as $s |
      .permissions.deny = ((.permissions.deny // []) + ($s.permissions.deny - (.permissions.deny // []))) |
      .permissions.ask  = ((.permissions.ask  // []) + ($s.permissions.ask  - (.permissions.ask  // []))) |
      reduce (($s.hooks // {}) | to_entries[]) as $e (.;
        reduce ($e.value[] | .hooks |= map(.command |= sub("\\$\\{CLAUDE_PROJECT_DIR\\}/\\.claude/"; $dest))) as $g (.;
          if ([.hooks[$e.key][]?.hooks[]?.command] | any(. as $c | [$g.hooks[].command] | index($c)))
          then . else .hooks[$e.key] = ((.hooks[$e.key] // []) + [$g]) end)) |
      if ($nosb != "1" and $s.sandbox != null and .sandbox == null) then .sandbox = $s.sandbox else . end
    ' > "$tmp"
else
  echo "  AVISO: sem python3 nem jq; junte permissões, hooks e sandbox de .claude/settings.json manualmente."
  merged=0
fi
if [ "$merged" = 0 ]; then
  :
elif [ -z "$cur" ]; then
  cat "$tmp" > "$SETTINGS"
  echo "  ok: settings.json (novo)"
elif cmp -s "$tmp" "$SETTINGS"; then
  echo "  ok: settings.json (já atualizado)"
else
  mkdir -p "$BACKUP"
  cp "$SETTINGS" "$BACKUP/settings.json"
  echo "  backup: settings.json"
  # Grava por cima (sem mv) para preservar symlink e permissões do arquivo.
  cat "$tmp" > "$SETTINGS"
  echo "  ok: settings.json (mesclado)"
fi

[ -d "$BACKUP" ] && echo "Backup dos arquivos substituídos: $BACKUP"
echo "Pronto. Remova o CLAUDE.md da raiz dos projetos que tinham cópia dele, para não carregar as regras em dobro."
