#!/bin/sh
# Genera las capturas de docs/screenshots en una pantalla VIRTUAL aislada
# (KWin sin ventana + bus D-Bus propio). No toca tu escritorio ni tu config.
# Requiere: kwin_wayland, spectacle, dbus-run-session, quickshell.
#   uso:  ./scripts/screenshots.sh
set -e
P="$(cd "$(dirname "$0")/.." && pwd)"
if [ -z "$NACAR_SHOTS_INNER" ]; then
    exec env NACAR_SHOTS_INNER=1 dbus-run-session -- "$0" "$@"
fi
T="$(mktemp -d)"; O="$P/docs/screenshots"; mkdir -p "$O" "$T/config"
W="$P/wallpapers/nacar-aurora.jpg"
printf '{"drawWallpaper": true, "wallpaper": "%s", "themeSource": "%s", "wallpaperDirs": []}\n' "$W" "$W" > "$T/config/config.json"
export NACAR_HOME="$T" NACAR_DEMO=1 USER=nacar

kwin_wayland --virtual --no-lockscreen --socket nacar-shots --width 1920 --height 1080 >/dev/null 2>&1 &
KW=$!
sleep 3
export WAYLAND_DISPLAY=nacar-shots QT_QPA_PLATFORM=wayland
python3 "$P/scripts/demo-player.py" "Nácar" "Tu shell" "$P/docs/assets/cover.jpg" &
DP=$!
qs -p "$P" >/dev/null 2>&1 &
QS=$!
sleep 10

shot() { spectacle -b -n -f -o "$O/$1.png" >/dev/null 2>&1; sleep 0.5; }
c() { qs -p "$P" ipc call nacar "$@"; }

shot escritorio
c island player; sleep 1.5; shot isla-musica; c island ""
notify-send -a Nácar -i dialog-information "¡Hola!" "Así llegan los avisos a la isla ✨"; sleep 1.2; shot isla-aviso
sleep 4; c calendar; sleep 1.8; shot calendario; c close; sleep 1
c focus; c center; sleep 1.8; shot centro; c close; c focusStop; sleep 1
c omniWith "=sqrt(2)*pi"; sleep 1.5; shot omni-calc; c close; sleep 1
c omniWith ""; sleep 1.5; shot omni; c close; sleep 1
c wallpapers; sleep 2.5; shot fondos; c close; sleep 1
c session; sleep 1.2; shot sesion; c close; sleep 1
c applyWall "$P/wallpapers/nacar-coral.jpg"; sleep 4; shot tema-coral
c applyWall "$P/wallpapers/nacar-oceano.jpg"; sleep 4; shot tema-oceano

kill $QS $DP $KW 2>/dev/null || true
# Cierra los servicios que este bus de prueba haya despertado (portales, etc.).
for pid in $(pgrep -u "$(id -u)"); do
    if tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -qx "DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"; then
        [ "$pid" != "$$" ] && kill "$pid" 2>/dev/null || true
    fi
done
rm -rf "$T"
echo "Capturas en $O"
