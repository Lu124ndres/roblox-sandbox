"""
Textura del Marinero v2 (1024 x 1024), dibujada por código con PIL:
  - arriba a la izquierda, la cara (ojos, cejas, nariz, barba, bigote y sonrisa);
  - arriba a la derecha, el pecho (camisa a rayas, chaleco abierto, panuelo rojo, cinturón);
  - abajo a la izquierda, la espalda (chaleco y cuello de marinero);
  - abajo a la derecha, la paleta de colores planos (una celda de 64 px por color).
Las formas se dan en studs, en el mismo marco que la malla (marinero_v2_datos.REGIONES), y
cada región se pinta entera (también el margen) para que el filtrado no traiga colores vecinos.

Uso (desde la raíz del repo): python tools/blender/marinero_v2_textura.py
Salida: assets/blender/marinero_v2/Marinero_color.png
"""
import os
import sys
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import marinero_v2_datos as D  # noqa: E402

SS = 4  # se dibuja 4 veces más grande y se reduce (bordes suaves)
S = D.TAM_TEXTURA * SS
C = D.COLORES
SOMBRA_PIEL = (226, 172, 136)
ROJO_OSCURO = (158, 32, 34)


class Lienzo:
    """Dibuja en studs dentro de una región (x, z del cuerpo -> píxel)."""

    def __init__(self, img, region):
        self.d = ImageDraw.Draw(img)
        self.region = region

    def px(self, x, z):
        u, v = D.uv_region(self.region, x, z)
        return (u * S, (1 - v) * S)

    def poligono(self, pts, color):
        self.d.polygon([self.px(x, z) for x, z in pts], fill=color)

    def caja(self, x0, z0, x1, z1, color):
        self.poligono([(x0, z0), (x1, z0), (x1, z1), (x0, z1)], color)

    def ovalo(self, x, z, rx, rz, color):
        (a, b), (c, d) = self.px(x - rx, z - rz), self.px(x + rx, z + rz)
        self.d.ellipse((min(a, c), min(b, d), max(a, c), max(b, d)), fill=color)

    def trazo(self, pts, ancho, color):
        """Línea gruesa con puntas redondas (ancho en studs)."""
        self.d.line([self.px(x, z) for x, z in pts], fill=color, width=round(self.escala() * ancho),
                    joint="curve")
        for x, z in (pts[0], pts[-1]):
            self.ovalo(x, z, ancho / 2, ancho / 2 * self.aspecto(), color)

    def escala(self):
        return abs(self.px(1, 0)[0] - self.px(0, 0)[0])

    def aspecto(self):
        return self.escala() / abs(self.px(0, 1)[1] - self.px(0, 0)[1])


def fondo(img, region, color):
    (u0, v0, u1, v1), _ = D.REGIONES[region]
    ImageDraw.Draw(img).rectangle((u0 * S, (1 - v1) * S, u1 * S - 1, (1 - v0) * S - 1), fill=color)


def espejo(pts):
    return [(-x, z) for x, z in reversed(pts)]


def cara(img):
    fondo(img, "cara", C["piel"])
    L = Lienzo(img, "cara")
    pelo = [(-0.9, 4.95), (-0.47, 4.95), (-0.41, 5.01), (-0.37, 5.4), (-0.9, 5.4)]
    L.poligono(pelo, C["barba"])
    L.poligono(espejo(pelo), C["barba"])
    barba = [(-0.9, 3.9), (-0.9, 4.62), (-0.6, 4.62), (-0.52, 4.53), (-0.42, 4.46), (-0.3, 4.42),
             (-0.18, 4.44)]
    L.poligono(barba + espejo(barba), C["barba"])
    for s in (-1, 1):
        L.ovalo(s * 0.105, 4.445, 0.13, 0.05, C["barba"])  # bigote
        L.ovalo(s * 0.22, 4.73, 0.062, 0.092, C["ojo"])
        L.ovalo(s * 0.22 - 0.022, 4.765, 0.022, 0.022, C["blanco"])
        L.trazo([(s * 0.12, 4.885), (s * 0.22, 4.905), (s * 0.31, 4.895)], 0.05, C["barba"])
    L.ovalo(0, 4.56, 0.05, 0.065, SOMBRA_PIEL)  # nariz
    sonrisa = [(0.15 * t / 10, 4.365 - 0.075 * (1 - (t / 10) ** 2)) for t in range(-10, 11)]
    L.trazo(sonrisa, 0.04, C["boca"])


def pecho(img):
    fondo(img, "pecho", C["blanco"])
    L = Lienzo(img, "pecho")
    z = 2.30 + 0.14
    while z < 4.2:
        L.caja(-1.3, z, 1.3, z + 0.14, C["raya"])
        z += 0.28
    L.caja(-1.3, 1.8, 1.3, 2.18, C["pantalon"])
    L.caja(-1.3, 2.18, 1.3, 2.30, C["cinturon"])
    L.caja(-0.12, 2.165, 0.12, 2.315, C["hebilla"])
    L.caja(-0.065, 2.21, 0.065, 2.27, C["cinturon"])
    chaleco = [(-1.3, 2.30), (-0.30, 2.30), (-0.24, 3.30), (-0.42, 4.2), (-1.3, 4.2)]
    L.poligono(chaleco, C["marino"])
    L.poligono(espejo(chaleco), C["marino"])
    for z in (2.55, 2.90):
        L.ovalo(-0.355, z, 0.035, 0.035, C["hebilla"])
    panuelo = [(-0.48, 4.2), (-0.30, 4.2), (0, 3.84), (0.30, 4.2), (0.48, 4.2), (0.09, 3.66),
               (-0.09, 3.66)]
    L.poligono(panuelo, C["rojo"])
    L.poligono([(-0.05, 3.70), (-0.21, 3.30), (-0.02, 3.38)], C["rojo"])
    L.poligono([(0.05, 3.70), (0.19, 3.27), (0.02, 3.38)], C["rojo"])
    L.ovalo(0, 3.71, 0.085, 0.07, ROJO_OSCURO)
    L.ovalo(0, 3.715, 0.06, 0.05, C["rojo"])


def espalda(img):
    fondo(img, "espalda", C["marino"])
    L = Lienzo(img, "espalda")
    L.caja(-1.3, 1.8, 1.3, 2.18, C["pantalon"])
    L.caja(-1.3, 2.18, 1.3, 2.30, C["cinturon"])
    L.caja(-0.62, 3.30, 0.62, 4.2, C["raya"])
    for borde in (0.07, 0.13):
        ancho = 0.03
        L.caja(-0.62 + borde, 3.30 + borde, -0.62 + borde + ancho, 4.2, C["blanco"])
        L.caja(0.62 - borde - ancho, 3.30 + borde, 0.62 - borde, 4.2, C["blanco"])
        L.caja(-0.62 + borde, 3.30 + borde, 0.62 - borde, 3.30 + borde + ancho, C["blanco"])


def paleta(img):
    d = ImageDraw.Draw(img)
    celda = S / 16
    for nombre, i in D.PALETA.items():
        col, fila = i % 8, i // 8
        x0, y1 = S / 2 + col * celda, S - fila * celda
        d.rectangle((x0, y1 - celda, x0 + celda - 1, y1 - 1), fill=C[nombre])


def main():
    img = Image.new("RGB", (S, S), C["blanco"])
    # Cada región en su capa y recortada: las formas que se salen no pisan la región vecina.
    for region, dibujo in (("cara", cara), ("pecho", pecho), ("espalda", espalda)):
        capa = Image.new("RGB", (S, S))
        dibujo(capa)
        (u0, v0, u1, v1), _ = D.REGIONES[region]
        caja = (round(u0 * S), round((1 - v1) * S), round(u1 * S), round((1 - v0) * S))
        img.paste(capa.crop(caja), caja)
    paleta(img)
    salida = os.path.join(HERE, "..", "..", "assets", "blender", "marinero_v2", "Marinero_color.png")
    os.makedirs(os.path.dirname(salida), exist_ok=True)
    img.resize((D.TAM_TEXTURA, D.TAM_TEXTURA), Image.LANCZOS).save(os.path.normpath(salida))
    print("TEXTURA", os.path.normpath(salida))


main()
