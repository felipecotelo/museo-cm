#!/bin/bash
# Recorta la camiseta del fondo: recorte.sh <id> <frente|espalda>  -> public/recortes/<id>-<lado>.webp
M=/Users/felipecotelo/museo-cm; B=$M/tools/bin/recortar
[ -x "$B" ] || swiftc -O $M/tools/recortar.swift -o "$B" || exit 1
T=$(mktemp -t recorte).png
"$B" "$M/public/fotos/$1-$2.jpg" "$T" >/dev/null || { echo "no se pudo recortar $1-$2"; exit 1; }
python3 "$M/tools/sin_percha.py" "$T" "$M/public/recortes/$1-$2.webp"
rm -f "$T"; echo "recorte $1-$2"
