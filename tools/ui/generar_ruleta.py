r"""
Rueda y puntero de la ruleta con la temática de la interfaz (pedido del usuario, 2026-10-17:
"la ruleta no está con la temática"): piedra volcánica con grietas de lava, separadores y
remaches dorados y un centro dorado como el ícono pintado de la ruleta (iconos/v4/spin.png).

La geometría es la de la rueda anterior (assets/ui/RuedaRuleta.png), porque SpinWheelView pone
los íconos y textos de cada premio encima con esas medidas:
    1024 x 1024, centro (512, 512), 8 casillas de 45°, la casilla 1 centrada arriba y las
    siguientes en sentido horario; las casillas llegan a r = 446 y el aro a r = 508.
El puntero mide 256 x 256 con la punta abajo al centro (128, 238), como el anterior.

Todo se dibuja al doble y se achica al final (bordes suaves). La textura es ruido de varias
escalas con pinceladas, para que pegue con las piezas pintadas de Canva.

Uso: python tools/ui/generar_ruleta.py   ->   assets/ui/ruleta_v2/{rueda,puntero,_muestra}.png
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SALIDA = os.path.join(RAIZ, "assets", "ui", "ruleta_v2")
ICONOS = os.path.join(RAIZ, "assets", "ui", "iconos", "v4")

LADO, K = 1024, 2  # tamaño final y sobremuestreo
CASILLAS, R_CASILLAS, R_ARO, R_CENTRO = 8, 446, 508, 66
CONTORNO = (34, 20, 14)
ORO_CLARO, ORO, ORO_OSCURO = (255, 236, 150), (228, 172, 52), (140, 82, 22)
PIEDRA = np.array([60, 54, 56], float)
LAVA_ROJA = np.array([138, 36, 22], float)
GRIETA, BRILLO = (255, 120, 30), (255, 214, 110)


def ruido(n, celdas, semilla):
    """Ruido suave entre 0 y 1 (rejilla aleatoria ampliada con bicúbica)."""
    r = np.random.default_rng(semilla).random((celdas, celdas)).astype(np.float32)
    img = Image.fromarray((r * 255).astype(np.uint8)).resize((n, n), Image.BICUBIC)
    return np.asarray(img, np.float32) / 255


def textura(n, semilla):
    """Ruido de varias escalas más pinceladas cortas: la piedra pintada."""
    t = 0.5 * ruido(n, 6, semilla) + 0.3 * ruido(n, 24, semilla + 1) + 0.2 * ruido(n, 90, semilla + 2)
    trazos = Image.new("L", (n, n), 128)
    d, rnd = ImageDraw.Draw(trazos), random.Random(semilla)
    for _ in range(n // 3):
        x, y, a = rnd.uniform(0, n), rnd.uniform(0, n), rnd.uniform(0, math.pi)
        largo, tono = rnd.uniform(10, 40) * K, rnd.choice((90, 170))
        d.line((x, y, x + math.cos(a) * largo, y + math.sin(a) * largo), tono, int(3 * K))
    trazos = trazos.filter(ImageFilter.GaussianBlur(2 * K))
    return t + (np.asarray(trazos, np.float32) / 255 - 0.5) * 0.5


def grietas(n, tramos, semilla):
    """Capa RGBA de grietas de lava: núcleo amarillo, cuerpo naranja y brillo difuso."""
    rnd, linea = random.Random(semilla), Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(linea)
    for puntos in tramos:
        ancho = rnd.uniform(2.5, 4) * K
        for a, b in zip(puntos, puntos[1:]):
            d.line((*a, *b), 255, int(ancho), joint="curve")
    nucleo = linea.filter(ImageFilter.GaussianBlur(0.6 * K))
    halo = linea.filter(ImageFilter.GaussianBlur(7 * K))
    capa = Image.new("RGBA", (n, n), (*GRIETA, 0))
    capa.putalpha(halo.point(lambda v: min(255, v * 2)))
    capa.alpha_composite(Image.merge("RGBA", (*Image.new("RGB", (n, n), GRIETA).split(), nucleo)))
    claro = nucleo.point(lambda v: max(0, v - 150) * 2)
    capa.alpha_composite(Image.merge("RGBA", (*Image.new("RGB", (n, n), BRILLO).split(), claro)))
    return capa


def camino(rnd, a, r0, r1, pasos, desvio):
    """Grieta quebrada que va del radio r0 al r1 cerca del ángulo a (grados desde arriba)."""
    c, puntos = LADO * K / 2, []
    for i in range(pasos + 1):
        r = (r0 + (r1 - r0) * i / pasos) * K
        ang = math.radians(a + rnd.uniform(-desvio, desvio) - 90)
        puntos.append((c + math.cos(ang) * r, c + math.sin(ang) * r))
    return puntos


def oro(d, caja, radio_luz=None):
    """Círculo dorado con contorno, sombra abajo y luz arriba a la izquierda."""
    x0, y0, x1, y1 = caja
    w = x1 - x0
    d.ellipse(caja, CONTORNO)
    g = w * 0.1
    d.ellipse((x0 + g, y0 + g, x1 - g, y1 - g), ORO_OSCURO)
    d.ellipse((x0 + g, y0 + g, x1 - g * 1.6, y1 - g * 1.6), ORO)
    s = radio_luz or w * 0.18
    d.ellipse((x0 + w * 0.28, y0 + w * 0.24, x0 + w * 0.28 + s, y0 + w * 0.24 + s * 0.8), ORO_CLARO)


def rueda():
    n, c = LADO * K, LADO * K / 2
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    dx, dy = xx - c, yy - c
    r = np.hypot(dx, dy) / K
    ang = (np.degrees(np.arctan2(dx, -dy)) + 360) % 360  # 0 = arriba, horario
    sector = np.floor(((ang + 22.5) % 360) / 45).astype(int)  # 0 = casilla 1
    off = np.abs(((ang + 22.5) % 45) - 22.5)  # grados al centro de la casilla
    al_borde = np.minimum((22.5 - off) * np.pi / 180 * r, R_CASILLAS - r)  # px al separador

    tex = textura(n, 7)[..., None]
    lava = (sector % 2 == 1)[..., None]
    base = np.where(lava, LAVA_ROJA, PIEDRA)
    calor = np.clip(1 - r / R_CASILLAS, 0, 1)[..., None]  # la lava se enciende al centro
    color = base * (0.7 + 0.6 * tex) + np.where(lava, calor * [70, 30, 0], 0)
    color *= np.clip(0.55 + al_borde[..., None] / 40, 0.55, 1)  # sombra junto a los bordes

    # Aro de piedra: 16 bloques con juntas, cada uno con su tono y bordes redondeados.
    bloque = np.floor(ang / 22.5).astype(int)
    a_junta = np.minimum(ang % 22.5, 22.5 - ang % 22.5) * np.pi / 180 * r
    en_aro = (r >= R_CASILLAS) & (r <= R_ARO)
    canto = np.minimum.reduce([r - R_CASILLAS, R_ARO - r, a_junta])
    tono = np.array([0.85 + 0.3 * random.Random(b).random() for b in range(16)])[bloque]
    piedra_aro = PIEDRA * 0.95 * (0.7 + 0.6 * textura(n, 11)[..., None]) * tono[..., None]
    piedra_aro *= np.clip(0.45 + canto[..., None] / 14, 0.45, 1.15)
    color = np.where(en_aro[..., None], piedra_aro, color)

    img = Image.fromarray(np.clip(color, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    img.putalpha(Image.fromarray(((r <= R_ARO + 2) * 255).astype(np.uint8)))

    rnd, tramos = random.Random(3), []
    for b in range(16):  # grietas del aro: por algunas juntas y algunas dentro de los bloques
        if rnd.random() < 0.6:
            tramos.append(camino(rnd, b * 22.5 + rnd.uniform(-1, 1), R_CASILLAS + 4, R_ARO - 4, 4, 1.2))
        if rnd.random() < 0.4:
            a = b * 22.5 + rnd.uniform(6, 16)
            tramos.append(camino(rnd, a, R_ARO - 6, R_CASILLAS + rnd.uniform(14, 40), 3, 2))
    img.alpha_composite(grietas(n, tramos, 5))
    finas = []  # grietas finas en las casillas de piedra, a un lado para no tapar el premio
    for s in range(0, CASILLAS, 2):
        for lado in (-1, 1):
            a = s * 45 + lado * rnd.uniform(12, 16)
            finas.append(camino(rnd, a, rnd.uniform(90, 160), rnd.uniform(330, 420), 6, 2.5))
    capa = grietas(n, finas, 9)
    capa.putalpha(capa.getchannel("A").point(lambda v: v * 0.6))
    img.alpha_composite(capa)

    d = ImageDraw.Draw(img)
    # Separadores dorados (con contorno) y bandas doradas entre las casillas y el aro.
    for s in range(CASILLAS):
        a = math.radians(s * 45 + 22.5 - 90)
        p = (c + math.cos(a) * R_CASILLAS * K, c + math.sin(a) * R_CASILLAS * K)
        d.line((c, c, *p), CONTORNO, 15 * K)
        d.line((c, c, *p), ORO_OSCURO, 10 * K)
        d.line((c, c, *p), ORO, 6 * K)
        d.line((c, c, *p), ORO_CLARO, 2 * K)
    for radio, ancho, tinta in ((R_CASILLAS + 4, 14, CONTORNO), (R_CASILLAS + 4, 9, ORO_OSCURO), (R_CASILLAS + 4, 5, ORO)):
        q = radio * K
        d.ellipse((c - q, c - q, c + q, c + q), outline=tinta, width=ancho * K)
    q = R_ARO * K
    d.ellipse((c - q, c - q, c + q, c + q), outline=CONTORNO, width=6 * K)
    # Remaches dorados: uno en el medio de cada bloque del aro.
    for b in range(16):
        a, rr = math.radians(b * 22.5 + 11.25 - 90), (R_CASILLAS + R_ARO) / 2 * K + 2 * K
        x, y, m = c + math.cos(a) * rr, c + math.sin(a) * rr, 13 * K
        oro(d, (x - m, y - m, x + m, y + m))
    # Centro dorado: aro, cúpula y brillo, como la rueda pintada del ícono.
    for radio, tinta in ((R_CENTRO, CONTORNO), (R_CENTRO - 4, ORO_OSCURO), (R_CENTRO - 7, ORO), (R_CENTRO - 22, CONTORNO)):
        q = radio * K
        d.ellipse((c - q, c - q, c + q, c + q), tinta)
    q = (R_CENTRO - 25) * K
    oro(d, (c - q, c - q, c + q, c + q), q * 0.55)
    return img.resize((LADO, LADO), Image.LANCZOS)


def puntero():
    """Gema de lava en un engaste dorado, apuntando abajo; punta en (128, 240)."""
    n = 256 * K
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 128, 98

    def triangulo(borde):  # el contorno de la gema encogido `borde` px hacia su centro
        pts = []
        for x, y in ((22, 30), (234, 30), (128, 240)):
            dx, dy = x - cx, y - cy
            k = 1 - borde / math.hypot(dx, dy) * 1.7
            pts.append(((cx + dx * k) * K, (cy + dy * k) * K))
        return pts

    for borde, tinta in ((0, CONTORNO), (8, ORO_OSCURO), (12, ORO), (22, CONTORNO)):
        d.polygon(triangulo(borde), tinta)
    a, b, p = triangulo(26)
    centro = (cx * K, (cy + 8) * K)
    d.polygon([a, b, centro], (255, 150, 40))  # cara de arriba, la más encendida
    d.polygon([b, p, centro], (232, 72, 22))  # cara derecha
    d.polygon([p, a, centro], (176, 38, 18))  # cara izquierda, en sombra
    brillo = Image.new("L", (n, n), 0)
    ImageDraw.Draw(brillo).ellipse(((cx - 26) * K, (cy - 18) * K, (cx + 26) * K, (cy + 30) * K), 255)
    luz = Image.new("RGBA", (n, n), (*BRILLO, 0))
    luz.putalpha(brillo.filter(ImageFilter.GaussianBlur(14 * K)).point(lambda v: v * 0.8))
    img.alpha_composite(luz)
    d = ImageDraw.Draw(img)
    d.polygon([(c * K, v * K) for c, v in ((74, 50), (100, 50), (87, 74))], (255, 236, 170))
    oro(d, (104 * K, 4 * K, 152 * K, 52 * K))  # remache de arriba
    img = img.filter(ImageFilter.GaussianBlur(0.4 * K))
    return img.resize((256, 256), Image.LANCZOS)


def muestra(img_rueda, img_puntero):
    """Rueda con los íconos de los premios donde los pone SpinWheelView (solo para revisar)."""
    fondo = Image.new("RGBA", (LADO, LADO + 120), (40, 34, 36, 255))
    fondo.alpha_composite(img_rueda, (0, 90))
    iconos = ("coin", "bolt", "ticket", "chest", "crown", "orca", "giftPink", "crystal")
    for i, nombre in enumerate(iconos):
        ruta = os.path.join(ICONOS, nombre + ".png")
        if not os.path.exists(ruta):
            continue
        a, rr, t = math.radians(i * 45 - 90), 0.43 * 0.56 * LADO, int(0.15 * LADO)
        ico = Image.open(ruta).convert("RGBA").resize((t, t)).rotate(-i * 45, expand=False)
        x, y = LADO / 2 + math.cos(a) * rr - t / 2, LADO / 2 + math.sin(a) * rr - t / 2 + 90
        fondo.alpha_composite(ico, (int(x), int(y)))
    t = int(0.13 * LADO)
    fondo.alpha_composite(img_puntero.resize((t, t)), (LADO // 2 - t // 2, 90 + int(0.025 * LADO) - t // 2))
    return fondo


if __name__ == "__main__":
    os.makedirs(SALIDA, exist_ok=True)
    r, p = rueda(), puntero()
    r.save(os.path.join(SALIDA, "rueda.png"))
    p.save(os.path.join(SALIDA, "puntero.png"))
    muestra(r, p).convert("RGB").save(os.path.join(SALIDA, "_muestra.png"))
    print("listo:", SALIDA)
