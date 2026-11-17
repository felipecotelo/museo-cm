#!/bin/bash
# Enlaza las imágenes existentes en museo.json y publica.
cd /Users/felipecotelo/museo-cm/public && python3 -I - <<'PY'
import json,os
d=json.load(open('museo.json'))
for x in d:
  f='fotos/%s-frente.jpg'%x['id']; b='fotos/%s-espalda.jpg'%x['id']
  if os.path.exists(f): x['fotoFrente']=f
  if os.path.exists(b): x['fotoEspalda']=b
json.dump(d,open('museo.json','w'),ensure_ascii=False,indent=1)
PY
cd .. && git add -A public tools && git commit -qm "$1

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" && git push -q 2>&1|tail -2; git log --oneline -1
