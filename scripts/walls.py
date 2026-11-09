#!/usr/bin/env python3
"""Lista fondos de pantalla de las carpetas dadas (JSON por stdout).
Para paquetes de fondos de KDE (…/contents/images/) elige solo la imagen
más grande de cada paquete. Solo lee: no modifica nada."""
import json
import os
import re
import sys

EXT = (".png", ".jpg", ".jpeg", ".webp", ".avif")
LIMIT = 300


def res(name):
    m = re.search(r"(\d{3,5})x(\d{3,5})", name)
    return int(m.group(1)) * int(m.group(2)) if m else 0


def main():
    out, packages = [], {}
    for d in sys.argv[1:]:
        d = os.path.expanduser(d)
        if not os.path.isdir(d):
            continue
        for root, dirs, files in os.walk(d):
            if root[len(d):].count(os.sep) > 4:
                dirs[:] = []
                continue
            dirs[:] = [x for x in dirs if not x.startswith(".") and x != "images_dark"]
            for f in files:
                if not f.lower().endswith(EXT):
                    continue
                p = os.path.join(root, f)
                if "/contents/images/" in p:
                    pkg = p.split("/contents/images/")[0]
                    if pkg not in packages or res(f) > res(os.path.basename(packages[pkg])):
                        packages[pkg] = p
                elif "/contents/" in p:
                    continue  # capturas de vista previa de los paquetes
                else:
                    out.append(p)
    out += packages.values()
    seen, uniq = set(), []
    for p in sorted(out, key=lambda x: os.path.basename(x).lower()):
        if p not in seen:
            seen.add(p)
            uniq.append(p)
    print(json.dumps(uniq[:LIMIT]))


if __name__ == "__main__":
    main()
