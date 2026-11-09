#!/usr/bin/env python3
"""Genera la paleta de Nácar con matugen y la imprime como JSON plano.

Uso: palette.py <fuente> <esquema>
  fuente: "wallpaper" (fondo actual de Plasma), "accent" (acento de KDE),
          una ruta de imagen o un color "#rrggbb".
Salida: {"source": "...", "dark": {nombre: "#hex"}, "light": {...}}
No escribe en ningún archivo de configuración: solo lee.
"""
import configparser
import json
import os
import re
import subprocess
import sys

HOME = os.path.expanduser("~")


def plasma_wallpaper():
    path = os.path.join(HOME, ".config", "plasma-org.kde.plasma.desktop-appletsrc")
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            text = f.read()
    except OSError:
        return None
    for m in re.finditer(r"^Image=(.+)$", text, re.M):
        img = m.group(1).strip()
        if img.startswith("file://"):
            img = img[7:]
        if os.path.isdir(img):  # paquete de fondo de KDE
            for sub in ("contents/images_dark", "contents/images"):
                d = os.path.join(img, sub)
                if os.path.isdir(d):
                    files = sorted(os.listdir(d))
                    if files:
                        return os.path.join(d, files[-1])
        if os.path.isfile(img):
            return img
    return None


def kde_accent():
    cp = configparser.ConfigParser(strict=False, interpolation=None)
    try:
        cp.read(os.path.join(HOME, ".config", "kdeglobals"))
        rgb = cp.get("General", "AccentColor", fallback="")
    except Exception:
        rgb = ""
    parts = [p for p in rgb.split(",") if p.strip().isdigit()]
    if len(parts) >= 3:
        return "#%02x%02x%02x" % tuple(int(p) for p in parts[:3])
    return "#8caaee"


def run(args):
    out = subprocess.run(args, capture_output=True, text=True, timeout=30)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip()[-300:])
    return json.loads(out.stdout)


def flatten(data):
    colors = data.get("colors", {})
    res = {"dark": {}, "light": {}}
    # matugen 3/4: colors.<nombre>.<modo>.color   |  matugen 2: colors.<modo>.<nombre>
    if "dark" in colors and isinstance(colors["dark"], dict) and "primary" in colors["dark"]:
        for mode in ("dark", "light"):
            for k, v in colors.get(mode, {}).items():
                res[mode][k] = v if isinstance(v, str) else v.get("color", "")
    else:
        for name, modes in colors.items():
            for mode in ("dark", "light"):
                v = modes.get(mode)
                if isinstance(v, dict):
                    v = v.get("color")
                if isinstance(v, str):
                    res[mode][name] = v
    return res


def main():
    source = sys.argv[1] if len(sys.argv) > 1 else "wallpaper"
    scheme = sys.argv[2] if len(sys.argv) > 2 else "scheme-tonal-spot"
    used = source
    base = ["matugen", "--json", "hex", "--dry-run", "-q", "-t", scheme]
    try:
        if source == "wallpaper":
            img = plasma_wallpaper()
            if not img:
                raise RuntimeError("sin fondo")
            used = img
            data = run(base[:1] + ["image", img] + base[1:] + ["--prefer", "saturation"])
        elif source.startswith("#"):
            data = run(base[:1] + ["color", "hex", source] + base[1:])
        elif source == "accent":
            used = kde_accent()
            data = run(base[:1] + ["color", "hex", used] + base[1:])
        else:
            data = run(base[:1] + ["image", source] + base[1:] + ["--prefer", "saturation"])
    except Exception:
        used = kde_accent()
        data = run(base[:1] + ["color", "hex", used] + base[1:])
    res = flatten(data)
    res["source"] = used
    print(json.dumps(res))


if __name__ == "__main__":
    main()
