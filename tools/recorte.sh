#!/bin/bash
# Recorta la camiseta del fondo: recorte.sh <id> <frente|espalda>  -> public/recortes/<id>-<lado>.webp
M=/Users/felipecotelo/museo-cm; B=$M/tools/bin/recortar
[ -x "$B" ] || swiftc -O $M/tools/recortar.swift -o "$B" || exit 1
T=$(mktemp -t recorte).png
"$B" "$M/public/fotos/$1-$2.jpg" "$T" >/dev/null || { echo "no se pudo recortar $1-$2"; exit 1; }
python3 - "$T" "$M/public/recortes/$1-$2.webp" <<'PY'
import sys
from PIL import Image
im=Image.open(sys.argv[1]);im=im.crop(im.getbbox());im.thumbnail((520,520))
im.save(sys.argv[2],'WEBP',quality=84,method=6)
PY
rm -f "$T"; echo "recorte $1-$2"
