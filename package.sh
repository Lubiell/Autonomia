#!/usr/bin/env bash
# Empacota as skills de .claude/skills/ em zips para enviar ao claude.ai
# (Personalizar > Skills), onde valem no chat, no app de desktop e no Cowork.
# Uso: ./package.sh [skill ...]    (sem argumento, empacota todas)
# Saída: dist/<skill>.zip, com a pasta da skill no topo do zip, como o claude.ai exige.
# Pasta de saída: defina OUT para mudar (padrão: dist/ na raiz do repositório).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/.claude/skills"
OUT="${OUT:-$ROOT/dist}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

if command -v zip >/dev/null 2>&1; then
  tool=zip
else
  tool=""
  for p in python3 python; do
    if command -v "$p" >/dev/null 2>&1 && "$p" -c 'import zipfile' >/dev/null 2>&1; then tool="$p"; break; fi
  done
  if [ -z "$tool" ]; then
    echo "Precisa de zip ou python. No Windows, use: powershell -File .\\package.ps1" >&2
    exit 1
  fi
fi

if [ $# -gt 0 ]; then names=("$@"); else
  names=()
  for d in "$SRC"/*/; do [ -d "$d" ] && names+=("$(basename "$d")"); done
fi

status=0
for name in "${names[@]}"; do
  skill="$SRC/$name/SKILL.md"
  if [ ! -f "$skill" ]; then echo "ERRO: $name: não existe $skill" >&2; status=1; continue; fi
  declared="$(awk '/^---[[:space:]]*$/ { n++; if (n > 1) exit; next } n == 1 && /^name:/ { sub(/^name:[[:space:]]*/, ""); sub(/[[:space:]\r]+$/, ""); print; exit }' "$skill")"
  if [ "$declared" != "$name" ]; then
    echo "ERRO: $name: o SKILL.md declara name '$declared'; o claude.ai recusa nome diferente da pasta" >&2
    status=1; continue
  fi
  zipf="$OUT/$name.zip"
  rm -f "$zipf"
  if [ "$tool" = zip ]; then
    (cd "$SRC" && zip -qr -X "$zipf" "$name" -x '*/__pycache__/*' '*.pyc' '*/.DS_Store')
  else
    (cd "$SRC" && "$tool" - "$name" "$zipf" <<'PY'
import os, sys, zipfile
name, dest = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as z:
    for base, dirs, files in os.walk(name):
        dirs[:] = sorted(d for d in dirs if d != "__pycache__")
        for f in sorted(files):
            if f.endswith(".pyc") or f == ".DS_Store":
                continue
            p = os.path.join(base, f)
            z.write(p, p.replace(os.sep, "/"))
PY
    )
  fi
  echo "ok: $zipf"
done

[ "$status" = 0 ] && echo "Envie em claude.ai > Personalizar > Skills > enviar skill, e ative cada uma."
exit "$status"
