r"""
Kit "lava" de la interfaz, hecho en Canva (pedido del usuario, 2026-10-17: "usa canva para
mayor exactitud de diseño", con dos imágenes de referencia: la tienda MEJORAS de piedra volcánica
con grietas de lava y los botones MEJORAS / TIENDA).

Las piezas se generaron con la IA de Canva usando las referencias, se les quitó el fondo en
Canva y se exportaron como PNG transparente a assets/ui/kit_canva/crudo/. Este script recorta
cada una a lo que ocupa (sin el margen transparente), la achica para que su canto mida lo mismo
que en el kit anterior y la guarda en assets/ui/kit_canva/. Los centros 9-slice (en píxeles de
la imagen final) quedan en cortes.json y en Interface/Kit.

Uso: python tools/ui/recortar_kit_canva.py
"""
import json
import os

from PIL import Image

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
CRUDO = os.path.join(RAIZ, "assets", "ui", "kit_canva", "crudo")
SALIDA = os.path.join(RAIZ, "assets", "ui", "kit_canva")

# nombre: (archivo crudo, borde 9-slice en fracción del lado corto, borde en px de la imagen final).
# El borde en px es el mismo del kit anterior (kit_piedra): así los SliceScale que ya ajustaron
# las pantallas siguen dando el mismo canto. Sin borde (None): no se estira, se achica a `px`
# de lado largo.
PIEZAS = {
    "panel": ("panel.png", 0.16, 44),
    "boton": ("boton.png", 0.22, 34),
    "lava": ("lava.png", 0.22, 34),
    "casilla": ("casilla.png", 0.18, 34),
    "hueco": ("hueco.png", 0.22, 22),
    "cristales": ("cristales.png", None, 256),
    "pedestal": ("pedestal.png", None, 512),
}


def recortar(img, umbral=8):
    """Recorta al rectángulo de píxeles con alfa > umbral."""
    alfa = img.split()[3].point(lambda v: 255 if v > umbral else 0)
    caja = alfa.getbbox()
    return img.crop(caja) if caja else img


def main():
    cortes = {}
    for nombre, (archivo, borde, px) in PIEZAS.items():
        ruta = os.path.join(CRUDO, archivo)
        if not os.path.exists(ruta):
            print("falta", ruta)
            continue
        img = recortar(Image.open(ruta).convert("RGBA"))
        k = px / max(img.size) if borde is None else px / (min(img.size) * borde)
        img = img.resize((max(1, round(img.width * k)), max(1, round(img.height * k))), Image.LANCZOS)
        img.save(os.path.join(SALIDA, f"{nombre}.png"))
        if borde is not None:
            b = px
            cortes[nombre] = [b, b, img.width - b, img.height - b]
        print(nombre, img.size, cortes.get(nombre))
    with open(os.path.join(SALIDA, "cortes.json"), "w", encoding="utf-8") as f:
        json.dump(cortes, f, indent=2)


if __name__ == "__main__":
    main()
