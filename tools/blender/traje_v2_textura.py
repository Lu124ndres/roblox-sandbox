"""
Textura de un traje v2 (1024 x 1024) dibujada por código con PIL, más su máscara de brillo
si la ficha tiene partes que brillan (lava, gemas, ojos). Los dibujos por región (DIBUJOS:
nombre de región -> función que recibe un Lienzo) están en traje_v2_<clave>_dibujo.py, o en la
ficha misma si son cortos y no usan PIL (Blender no lo trae); la paleta de
colores planos sale sola de ficha.COLORES (ficha.BRILLOS: cuánto brilla cada color).
Las formas se dan en studs, en el mismo marco que la malla (traje_v2_regiones.py), y cada
región se pinta entera (también el margen) para que el filtrado no traiga colores vecinos.

Uso (desde la raíz del repo): python tools/blender/traje_v2_textura.py --traje <clave>
Salida: assets/blender/<carpeta>/<Archivo>_color.png (y _brillo.png si algo brilla)
"""
import importlib
import importlib.util
import os
import sys
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import traje_v2_regiones as R  # noqa: E402

SS = 4  # se dibuja 4 veces más grande y se reduce (bordes suaves)
S = R.TAM_TEXTURA * SS


class Lienzo:
    """Dibuja en studs dentro de una región (a, b del cuerpo -> píxel), en color y en brillo."""

    def __init__(self, ficha, img, mascara, region):
        self.ficha, self.region = ficha, region
        self.img, self.mascara = img, mascara
        self.d, self.m = ImageDraw.Draw(img), ImageDraw.Draw(mascara)

    def tam(self):
        """Tamaño en píxeles de la región entera (para dibujos hechos aparte)."""
        x0, y0, x1, y1 = caja_px(self.ficha.REGIONES[self.region][0])
        return x1 - x0, y1 - y0

    def pegar(self, color, brillo):
        """Pega imágenes del tamaño de la región entera (color RGB y brillo L)."""
        x0, y0, _, _ = caja_px(self.ficha.REGIONES[self.region][0])
        self.img.paste(color, (x0, y0))
        self.mascara.paste(brillo, (x0, y0))

    def a_studs(self, px, py):
        """Píxel de la región entera -> (a, b) en studs (inversa de px)."""
        rect, (a0, b0, a1, b1) = self.ficha.REGIONES[self.region]
        u0, v0, u1, v1 = R.interior(rect)
        x0, y0, _, _ = caja_px(rect)
        u, v = (x0 + px) / S, 1 - (y0 + py) / S
        return a0 + (u - u0) / (u1 - u0) * (a1 - a0), b0 + (v - v0) / (v1 - v0) * (b1 - b0)

    def color(self, c):
        return self.ficha.COLORES[c] if isinstance(c, str) else c

    def px(self, a, b):
        u, v = R.uv_region(self.ficha, self.region, a, b)
        return (u * S, (1 - v) * S)

    def _pintar(self, metodo, forma, c, brillo, **kw):
        getattr(self.d, metodo)(forma, fill=self.color(c), **kw)
        getattr(self.m, metodo)(forma, fill=round(255 * brillo), **kw)

    def fondo(self, c, brillo=0.0):
        """La región entera, margen incluido."""
        x0, y0, x1, y1 = caja_px(self.ficha.REGIONES[self.region][0])
        self._pintar("rectangle", (x0, y0, x1 - 1, y1 - 1), c, brillo)

    def poligono(self, pts, c, brillo=0.0):
        self._pintar("polygon", [self.px(a, b) for a, b in pts], c, brillo)

    def caja(self, a0, b0, a1, b1, c, brillo=0.0):
        self.poligono([(a0, b0), (a1, b0), (a1, b1), (a0, b1)], c, brillo)

    def ovalo(self, a, b, ra, rb, c, brillo=0.0):
        (x0, y0), (x1, y1) = self.px(a - ra, b - rb), self.px(a + ra, b + rb)
        self._pintar("ellipse", (min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1)), c, brillo)

    def trazo(self, pts, ancho, c, brillo=0.0):
        """Línea gruesa con puntas redondas (ancho en studs)."""
        self._pintar("line", [self.px(a, b) for a, b in pts], c, brillo,
                     width=max(1, round(self.escala() * ancho)), joint="curve")
        for a, b in (pts[0], pts[-1]):
            self.ovalo(a, b, ancho / 2, ancho / 2 * self.aspecto(), c, brillo)

    def escala(self):
        return abs(self.px(1, 0)[0] - self.px(0, 0)[0])

    def aspecto(self):
        return self.escala() / abs(self.px(0, 1)[1] - self.px(0, 0)[1])


def caja_px(rect):
    u0, v0, u1, v1 = rect
    return (round(u0 * S), round((1 - v1) * S), round(u1 * S), round((1 - v0) * S))


def componer(ficha, dibujos):
    img = Image.new("RGB", (S, S), getattr(ficha, "FONDO", (255, 255, 255)))
    mascara = Image.new("L", (S, S), 0)
    # Cada región en su capa y recortada: las formas que se salen no pisan la región vecina.
    for region, dibujo in dibujos.items():
        capa, capa_m = Image.new("RGB", (S, S)), Image.new("L", (S, S), 0)
        dibujo(Lienzo(ficha, capa, capa_m, region))
        caja = caja_px(ficha.REGIONES[region][0])
        img.paste(capa.crop(caja), caja)
        mascara.paste(capa_m.crop(caja), caja)
    d, m = ImageDraw.Draw(img), ImageDraw.Draw(mascara)
    u0, v0, u1, v1 = getattr(ficha, "PALETA_RECT", R.PALETA_RECT)
    cw, ch = (u1 - u0) * S / 8, (v1 - v0) * S / 8
    brillos = getattr(ficha, "BRILLOS", {})
    for nombre, rgb in ficha.COLORES.items():
        col, fila = R.celda(ficha, nombre)
        x0, y1 = u0 * S + col * cw, (1 - v0) * S - fila * ch
        caja = (x0, y1 - ch, x0 + cw - 1, y1 - 1)
        d.rectangle(caja, fill=rgb)
        m.rectangle(caja, fill=round(255 * brillos.get(nombre, 0)))
    return img, mascara


def main():
    args = sys.argv[1:]
    clave = args[args.index("--traje") + 1] if "--traje" in args else "marinero"
    ficha = importlib.import_module("traje_v2_" + clave)
    aparte = "traje_v2_" + clave + "_dibujo"
    dibujos = (importlib.import_module(aparte).DIBUJOS if importlib.util.find_spec(aparte)
               else ficha.DIBUJOS)
    img, mascara = componer(ficha, dibujos)
    carpeta = os.path.normpath(os.path.join(HERE, "..", "..", "assets", "blender", ficha.CARPETA))
    os.makedirs(carpeta, exist_ok=True)
    tam = (R.TAM_TEXTURA, R.TAM_TEXTURA)
    img.resize(tam, Image.LANCZOS).save(os.path.join(carpeta, f"{ficha.ARCHIVO}_color.png"))
    print("TEXTURA", os.path.join(carpeta, f"{ficha.ARCHIVO}_color.png"))
    if mascara.getextrema()[1] > 0:
        mascara.resize(tam, Image.LANCZOS).save(os.path.join(carpeta, f"{ficha.ARCHIVO}_brillo.png"))
        print("BRILLO", os.path.join(carpeta, f"{ficha.ARCHIVO}_brillo.png"))


main()
