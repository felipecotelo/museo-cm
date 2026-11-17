#!/bin/bash
# Mueve la última imagen bajada de Gemini al museo: guardar.sh <id> <frente|espalda>
# Espera hasta 40 s a que termine la descarga.
for i in $(seq 1 40); do
  f=$(ls -t ~/Downloads/Gemini_Generated_Image_*.* 2>/dev/null | grep -v '\.crdownload$' | head -1)
  [ -n "$f" ] && break; sleep 1
done
[ -z "$f" ] && { echo "no hay imagen"; exit 1; }
sips -Z 1100 -s format jpeg -s formatOptions 82 "$f" --out "/Users/felipecotelo/museo-cm/public/fotos/$1-$2.jpg" >/dev/null && rm "$f" && echo "ok $1-$2"
[ -f "/Users/felipecotelo/museo-cm/public/fotos/$1-$2.jpg" ] && /Users/felipecotelo/museo-cm/tools/recorte.sh "$1" "$2"
