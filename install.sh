#!/usr/bin/env bash
# Instala Nácar enlazando esta carpeta en ~/.config/quickshell/nacar.
# No activa el arranque automático ni toca tu configuración actual.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/nacar"

echo "🐚 Instalando Nácar"
missing=()
for bin in qs matugen python3; do command -v "$bin" >/dev/null || missing+=("$bin"); done
if ((${#missing[@]})); then
    echo "⚠️  Faltan dependencias obligatorias: ${missing[*]}"; exit 1
fi
for bin in cava brightnessctl nmcli cliphist wl-copy fd spectacle; do
    command -v "$bin" >/dev/null || echo "   (opcional) no se encontró '$bin': alguna función quedará desactivada"
done
fc-list | grep -q "Material Symbols Rounded" || echo "⚠️  Falta la fuente 'Material Symbols Rounded' (iconos)"

mkdir -p "$(dirname "$DEST")"
if [[ -e "$DEST" && ! -L "$DEST" ]]; then
    echo "⚠️  Ya existe $DEST y no es un enlace; no lo toco."; exit 1
fi
ln -sfn "$HERE" "$DEST"
echo "✅ Enlazado en $DEST"
echo
echo "Arráncala con:      qs -c nacar"
echo "Pruébala sin perder tu shell:  ./scripts/try.sh"
echo "Ajustes:            ~/.config/nacar/config.json (se crea al primer arranque)"
