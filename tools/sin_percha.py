# Borra lo que asoma de la percha por encima del cuello en un recorte con transparencia.
# Uso: python3 sin_percha.py entrada.(png|webp) salida.webp
import sys
from PIL import Image

im = Image.open(sys.argv[1]).convert('RGBA')
a = im.split()[3]
w, h = im.size
px = a.load()

def ancho(y):
    xs = [x for x in range(0, w, 2) if px[x, y] > 128]
    return (xs[-1] - xs[0]) if xs else 0

anchos = [ancho(y) for y in range(h)]
maximo = max(anchos) or 1
# Primera fila donde la camiseta ocupa el 30 % del ancho máximo: arriba de eso solo asoma la percha
y0 = next((y for y, v in enumerate(anchos) if v >= 0.3 * maximo), 0)
if y0 > 0:
    a.paste(Image.new('L', (w, y0), 0), (0, 0))
    im.putalpha(a)
im = im.crop(im.getbbox())
im.thumbnail((520, 520))
im.save(sys.argv[2], 'WEBP', quality=84, method=6)
