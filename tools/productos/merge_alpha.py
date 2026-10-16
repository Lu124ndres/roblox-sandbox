import sys
from PIL import Image, ImageFilter
src, rgbp, dst = sys.argv[1:4]
a = Image.open(src).convert('RGBA')
rgb = Image.open(rgbp).convert('RGB')
al = a.getchannel('A').resize(rgb.size, Image.LANCZOS)
# bordes del alfa más definidos (curva suave)
al = al.point(lambda v: 0 if v < 20 else 255 if v > 235 else int((v - 20) * 255 / 215))
out = rgb.copy(); out.putalpha(al)
out.save(dst)
