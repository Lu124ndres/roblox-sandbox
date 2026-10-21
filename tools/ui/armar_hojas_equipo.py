"""
Arma las hojas de íconos v4 del equipo de la tienda (cañas, canastas y botas).

Entrada: los PNG crudos de Canva (200 px, fondo claro liso) en
assets/ui/iconos/v4/equipo/crudo/<categoria>/NN.png, uno por nivel (ver
tools/ui/equipo_v4.json para los prompts).

1. Quita el fondo: inundación desde los bordes por los píxeles parecidos al
   color del fondo (el contorno marrón grueso de los íconos frena la
   inundación) y suaviza el borde con un alfa según la distancia al fondo.
2. Guarda cada ícono transparente en assets/ui/iconos/v4/equipo/<categoria>/NN.png.
3. Arma hojas de 5x4 celdas de 200 px (1000x800, Roblox achica lo que pase de
   1024): hoja 1 = niveles 1-20, hoja 2 = 21-40, en
   assets/ui/iconos/v4/equipo/equipo_<categoria>_<hoja>.png.

Uso: py tools/ui/armar_hojas_equipo.py
"""

import os
from collections import deque

from PIL import Image

RAIZ = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "ui", "iconos", "v4", "equipo")
CATEGORIAS = ("rod", "basket", "boots")
CELDA = 200
COLUMNAS, FILAS = 5, 4
POR_HOJA = COLUMNAS * FILAS
TOLERANCIA = 40  # distancia de color hasta la que un píxel cuenta como fondo
BORDE = 30  # más allá de TOLERANCIA, rango en que el alfa sube de 0 a 255
MARGEN = 6  # aire alrededor del ícono dentro de la celda
HUECO_TOLERANCIA = 14  # un hueco cerrado tiene que ser casi exactamente del color del fondo
HUECO_MINIMO = 40  # y medir al menos esto (los brillos chicos de los íconos se quedan)


def distancia(a, b):
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


def inundar(px, marcado, cola, fondo, tolerancia):
    ancho, alto = len(marcado), len(marcado[0])
    pixeles = []
    while cola:
        x, y = cola.popleft()
        if marcado[x][y] or distancia(px[x, y], fondo) > tolerancia:
            continue
        marcado[x][y] = True
        pixeles.append((x, y))
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < ancho and 0 <= ny < alto and not marcado[nx][ny]:
                cola.append((nx, ny))
    return pixeles


def quitar_fondo(imagen):
    rgb = imagen.convert("RGB")
    ancho, alto = rgb.size
    px = rgb.load()
    esquinas = [px[0, 0], px[ancho - 1, 0], px[0, alto - 1], px[ancho - 1, alto - 1]]
    fondo = tuple(sorted(c[i] for c in esquinas)[1] for i in range(3))
    fuera = [[False] * alto for _ in range(ancho)]
    cola = deque()
    for x in range(ancho):
        cola.extend(((x, 0), (x, alto - 1)))
    for y in range(alto):
        cola.extend(((0, y), (ancho - 1, y)))
    inundar(px, fuera, cola, fondo, TOLERANCIA)
    # Huecos cerrados (entre la caña y el hilo, el asa de una canasta): manchas grandes
    # del color del fondo casi puro que no tocan el borde.
    visto = [fila[:] for fila in fuera]
    for x in range(ancho):
        for y in range(alto):
            if not visto[x][y] and distancia(px[x, y], fondo) <= HUECO_TOLERANCIA:
                pixeles = inundar(px, visto, deque([(x, y)]), fondo, HUECO_TOLERANCIA)
                if len(pixeles) >= HUECO_MINIMO:
                    for hx, hy in pixeles:
                        fuera[hx][hy] = True
    salida = Image.new("RGBA", (ancho, alto))
    out = salida.load()
    for x in range(ancho):
        for y in range(alto):
            r, g, b = px[x, y]
            if fuera[x][y]:
                out[x, y] = (r, g, b, 0)
                continue
            # Borde: los píxeles del objeto que tocan el fondo se aclaran según cuánto se le parecen.
            vecino_fuera = any(
                0 <= nx < ancho and 0 <= ny < alto and fuera[nx][ny]
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))
            )
            alfa = 255
            if vecino_fuera:
                d = distancia((r, g, b), fondo)
                alfa = max(0, min(255, int((d - TOLERANCIA) / BORDE * 255)))
            out[x, y] = (r, g, b, alfa)
    return salida


def encajar(icono):
    caja = icono.getbbox()
    if caja:
        icono = icono.crop(caja)
    lado = CELDA - MARGEN * 2
    escala = min(lado / icono.width, lado / icono.height)
    icono = icono.resize(
        (max(1, round(icono.width * escala)), max(1, round(icono.height * escala))),
        Image.LANCZOS,
    )
    celda = Image.new("RGBA", (CELDA, CELDA))
    celda.paste(icono, ((CELDA - icono.width) // 2, (CELDA - icono.height) // 2), icono)
    return celda


def armar(categoria):
    crudos = os.path.join(RAIZ, "crudo", categoria)
    if not os.path.isdir(crudos):
        return
    limpios = os.path.join(RAIZ, categoria)
    os.makedirs(limpios, exist_ok=True)
    nombres = sorted(n for n in os.listdir(crudos) if n.endswith(".png"))
    celdas = {}
    for nombre in nombres:
        nivel = int(nombre[:-4])
        celda = encajar(quitar_fondo(Image.open(os.path.join(crudos, nombre))))
        celda.save(os.path.join(limpios, nombre))
        celdas[nivel] = celda
    hojas = (max(celdas) - 1) // POR_HOJA + 1 if celdas else 0
    for hoja in range(hojas):
        lienzo = Image.new("RGBA", (CELDA * COLUMNAS, CELDA * FILAS))
        for indice in range(POR_HOJA):
            celda = celdas.get(hoja * POR_HOJA + indice + 1)
            if celda:
                lienzo.paste(celda, ((indice % COLUMNAS) * CELDA, (indice // COLUMNAS) * CELDA))
        destino = os.path.join(RAIZ, f"equipo_{categoria}_{hoja + 1}.png")
        lienzo.save(destino)
        print(f"{categoria}: hoja {hoja + 1} -> {destino}")
    print(f"{categoria}: {len(celdas)} íconos")


if __name__ == "__main__":
    for categoria in CATEGORIAS:
        armar(categoria)
