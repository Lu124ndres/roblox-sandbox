r"""
Kit de interfaz "piedra" (pedido del usuario, 2026-10-17): piedra oscura tallada con bisel,
botones de piedra que se tiñen, marco de lava y gemas, para la interfaz del juego
(Interface/Style y Interface/Kit). Todo dibujado con PIL y numpy, sin IA: se puede regenerar.

Salidas en assets/ui/kit_piedra/ (fondo transparente, 9-slice: el centro de cada imagen es
liso y los bordes llevan el bisel; los rectángulos de corte están en SLICES y en
Interface/Kit):
    panel.png        fondo de ventanas y paneles: pizarra azulada con borde biselado claro
    panel_hondo.png  hueco hundido (barras, listas, casillas): el bisel al revés
    boton.png        botón de piedra casi blanco con bisel: se tiñe con ImageColor3
                     (gris piedra, verde, naranja, rojo...)
    lava.png         botón con marco de lava encendida y centro de piedra roja (TIENDA)
    gema.png         cristal azul facetado, de adorno a los costados de los paneles

Uso: python tools/ui/generar_kit_piedra.py
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SALIDA = os.path.join(RAIZ, "assets", "ui", "kit_piedra")
LUZ = np.array([-0.55, -0.65, 0.52])  # de arriba a la izquierda (x a la derecha, y hacia abajo)
LUZ = LUZ / np.linalg.norm(LUZ)
SLICES = {}  # nombre -> (x0, y0, x1, y1) del centro del 9-slice


def ruido(w, h, escala, semilla):
    """Ruido suave de valor (0..1): rejilla aleatoria agrandada con interpolación."""
    rng = np.random.default_rng(semilla)
    chico = Image.fromarray((rng.random((max(2, h // escala), max(2, w // escala))) * 255).astype(np.uint8))
    return np.asarray(chico.resize((w, h), Image.BICUBIC), dtype=np.float32) / 255


def forma(w, h, radio, margen=0):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((margen, margen, w - 1 - margen, h - 1 - margen), radio, fill=255)
    return np.asarray(m, dtype=np.float32) / 255


def facetas(w, h, bisel, semilla):
    """Alto del borde tallado: sube del contorno al plano en `bisel` px, con escalones de cincel
    (planos rotos) para que se lea como piedra tallada y no como plástico."""
    alto = np.zeros((h, w), np.float32)
    for i in range(bisel):
        alto += forma(w, h, max(4, 26 - i), margen=i)
    alto /= bisel
    cincel = ruido(w, h, max(6, bisel), semilla)
    return np.clip(alto + (cincel - 0.5) * 0.18 * (alto < 0.99), 0, 1)


def sombreado(alto, fuerza):
    gy, gx = np.gradient(alto)
    n = np.dstack((-gx * fuerza, -gy * fuerza, np.ones_like(alto)))
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return np.clip(n @ LUZ, -1, 1)


def piedra(w, h, radio, bisel, cara, borde_claro, borde_oscuro, semilla, hondo=False, grano=0.10):
    """Placa de piedra biselada. cara: color del plano; el bisel va de borde_claro (de cara a la
    luz) a borde_oscuro. hondo: el bisel baja hacia adentro (un hueco)."""
    mascara = forma(w, h, radio)
    alto = facetas(w, h, bisel, semilla)
    if hondo:
        alto = 1 - alto
    luz = sombreado(alto, 26.0)
    en_bisel = (alto > 0.02) & (alto < 0.98) if not hondo else (alto > 0.02) & (alto < 0.98)
    cara = np.array(cara, np.float32)
    claro = np.array(borde_claro, np.float32)
    oscuro = np.array(borde_oscuro, np.float32)
    t = ((luz + 1) / 2)[..., None]
    color_bisel = oscuro + (claro - oscuro) * t
    color = np.where(en_bisel[..., None], color_bisel, cara)
    # Grano y manchas de la piedra, más un leve degradado vertical (abajo más oscuro).
    g = ruido(w, h, 3, semilla + 1) * 0.6 + ruido(w, h, 18, semilla + 2) * 0.4
    color *= (1 - grano + grano * 2 * g)[..., None]
    color *= (1.06 - 0.16 * np.linspace(0, 1, h)[:, None])[..., None]
    # Contorno oscuro fino (como el borde negro del estilo de antes, pero de piedra).
    contorno = mascara - forma(w, h, max(4, radio - 2), margen=2)
    color = color * (1 - contorno[..., None] * 0.75)
    rgba = np.dstack((np.clip(color, 0, 255), mascara * 255)).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def grietas(img, semilla, color, ancho, cuantas, zona):
    """Grietas finas en zigzag dentro de `zona` (x0, y0, x1, y1)."""
    rng = np.random.default_rng(semilla)
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = zona
    for _ in range(cuantas):
        x, y = rng.uniform(x0, x1), rng.uniform(y0, y1)
        puntos = [(x, y)]
        for _ in range(rng.integers(2, 5)):
            x += rng.uniform(-14, 14)
            y += rng.uniform(-10, 10)
            puntos.append((min(max(x, x0), x1), min(max(y, y0), y1)))
        d.line(puntos, fill=color, width=ancho, joint="curve")
    return img


def panel():
    img = piedra(256, 256, 30, 20, (46, 52, 68), (150, 160, 184), (18, 20, 28), 11)
    SLICES["panel"] = (44, 44, 212, 212)
    return img


def panel_hondo():
    img = piedra(128, 128, 16, 10, (26, 29, 38), (90, 98, 118), (12, 13, 18), 21, hondo=True, grano=0.06)
    SLICES["panel_hondo"] = (22, 22, 106, 106)
    return img


def boton():
    # Casi blanco para que ImageColor3 lo tiña de cualquier color sin perder el bisel.
    img = piedra(256, 128, 24, 14, (226, 226, 226), (255, 255, 255), (96, 96, 96), 31, grano=0.07)
    SLICES["boton"] = (34, 34, 222, 94)
    return img


def lava():
    """Marco de lava: el borde es magma (amarillo adentro, rojo afuera, con costra oscura que se
    rompe) y el centro, piedra roja oscura con su bisel."""
    w, h = 256, 128
    marco = piedra(w, h, 24, 16, (150, 40, 22), (255, 170, 60), (110, 22, 10), 41, grano=0.12)
    a = np.asarray(marco, np.float32)
    mascara = forma(w, h, 24)
    alto = facetas(w, h, 16, 41)
    # Magma en el bisel: brillo según la luz y vetas de ruido.
    vetas = ruido(w, h, 7, 43)
    en_bisel = (alto > 0.02) & (alto < 0.98)
    # Más caliente hacia adentro del marco (alto alto) y con vetas suaves.
    calor = np.clip(alto * 1.1 - 0.15 + (vetas - 0.5) * 0.5, 0, 1)
    magma = np.dstack((
        255 * np.ones_like(calor),
        70 + 170 * calor,
        20 + 60 * calor ** 2,
    ))
    costra = np.array([58, 18, 12], np.float32)
    borde = np.where(((vetas < 0.3) & (alto < 0.45))[..., None], costra, magma)
    a[..., :3] = np.where(en_bisel[..., None], borde, a[..., :3])
    a[..., 3] = mascara * 255
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    # Resplandor de afuera (se ve sobre fondos oscuros).
    halo = Image.fromarray((mascara * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(5))
    fondo = Image.new("RGBA", (w, h), (255, 110, 30, 0))
    fondo.putalpha(halo.point(lambda v: int(v * 0.0)))
    img = Image.alpha_composite(fondo, img)
    SLICES["lava"] = (34, 34, 222, 94)
    return img


def gema():
    """Cristal azul facetado (rombo alargado con caras claras y oscuras y un destello)."""
    s = 128
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c, top, bot, mid, ancho = s / 2, 8, s - 8, s * 0.42, 34
    arriba, abajo = (c, top), (c, bot)
    izq, der = (c - ancho, mid), (c + ancho, mid)
    centro = (c + 4, mid + 4)
    caras = [
        ((arriba, izq, centro), (120, 200, 255)),
        ((arriba, centro, der), (60, 140, 235)),
        ((izq, abajo, centro), (40, 100, 210)),
        ((centro, abajo, der), (22, 62, 160)),
    ]
    for puntos, color in caras:
        d.polygon(puntos, fill=color + (255,))
    d.line([arriba, izq, abajo, der, arriba], fill=(12, 28, 70, 255), width=4, joint="curve")
    d.line([arriba, centro, abajo], fill=(180, 230, 255, 200), width=2)
    d.line([izq, centro, der], fill=(150, 210, 255, 160), width=2)
    d.polygon([(c - 10, top + 22), (c - 4, top + 14), (c - 2, top + 30)], fill=(240, 252, 255, 255))
    glow = img.split()[3].filter(ImageFilter.GaussianBlur(6))
    halo = Image.new("RGBA", (s, s), (90, 190, 255, 0))
    halo.putalpha(glow.point(lambda v: int(v * 0.55)))
    return Image.alpha_composite(halo, img)


def main():
    os.makedirs(SALIDA, exist_ok=True)
    for nombre, hacer in (("panel", panel), ("panel_hondo", panel_hondo), ("boton", boton),
                          ("lava", lava), ("gema", gema)):
        img = hacer()
        img.save(os.path.join(SALIDA, f"{nombre}.png"))
        print(nombre, img.size, SLICES.get(nombre))
    # Muestra para revisar: todas juntas sobre fondo oscuro y claro, el botón teñido.
    muestra = Image.new("RGBA", (900, 330), (70, 90, 110, 255))
    muestra.alpha_composite(Image.open(os.path.join(SALIDA, "panel.png")), (10, 10))
    x = 280
    for tinte in ((120, 124, 134), (80, 210, 80), (255, 150, 40), (236, 64, 56)):
        b = Image.open(os.path.join(SALIDA, "boton.png"))
        arr = np.asarray(b, np.float32)
        arr[..., :3] *= np.array(tinte, np.float32) / 255
        muestra.alpha_composite(Image.fromarray(arr.astype(np.uint8), "RGBA").resize((160, 80)), (x, 10))
        x += 150
        if x > 750:
            x = 280
    muestra.alpha_composite(Image.open(os.path.join(SALIDA, "lava.png")), (280, 110))
    muestra.alpha_composite(Image.open(os.path.join(SALIDA, "panel_hondo.png")), (550, 110))
    muestra.alpha_composite(Image.open(os.path.join(SALIDA, "gema.png")), (690, 110))
    muestra.save(os.path.join(SALIDA, "_muestra.png"))


if __name__ == "__main__":
    main()
