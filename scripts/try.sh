#!/usr/bin/env bash
# Prueba Nácar SIN instalar nada y sin perder tu shell actual:
#  1. pausa las shells de Quickshell que tengas abiertas (anota cómo arrancarlas),
#  2. lanza Nácar desde esta carpeta,
#  3. al salir (Ctrl+C) vuelve a arrancar tu shell anterior tal como estaba.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAVED=()

for pid in $(pgrep -x quickshell; pgrep -x qs); do
    cmd="$(tr '\0' '\037' < "/proc/$pid/cmdline" 2>/dev/null || true)"
    [[ -z "$cmd" || "$cmd" == *"$HERE"* ]] && continue
    SAVED+=("$cmd")
    echo "⏸  Pausando tu shell actual (pid $pid)"
    kill "$pid" 2>/dev/null || true
done

restore() {
    echo
    for cmd in "${SAVED[@]}"; do
        IFS=$'\037' read -r -a argv <<< "$cmd"
        echo "▶  Restaurando: ${argv[*]}"
        setsid -f "${argv[@]}" >/dev/null 2>&1 || true
    done
}
trap restore EXIT

echo "🐚 Arrancando Nácar (Ctrl+C para volver a tu shell)…"
qs -p "$HERE" || true
