"""
Arma la hoja de íconos del Índice de peces (Interface/Icons, hoja 4).

Entrada: la hoja de 3x3 que pintó la IA de Canva (media MAHYsz8cTOc), exportada a
1080 px desde el lienzo auxiliar DAHYr01q5ww, en
assets/ui/iconos/v4/indice/crudo/hoja_indice.png. Por filas: libro (Todos), medallones
Común, Poco común, Raro, Épico, Legendario, Mítico, trébol (suerte) y candado.

Corta las 9 celdas de 360 px, les quita el fondo con las mismas funciones que las hojas
del equipo (armar_hojas_equipo.py) y las pone en una hoja de 4x4 celdas de 256 px
(1024x1024, como las demás hojas de Icons) en assets/ui/iconos/v4/iconos_v4_indice.png.
Cada ícono suelto queda también en assets/ui/iconos/v4/indice/NN.png.

Uso: py tools/ui/armar_hoja_indice.py
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import armar_hojas_equipo as equipo  # noqa: E402

V4 = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "ui", "iconos", "v4")
CRUDO = os.path.join(V4, "indice", "crudo", "hoja_indice.png")
CELDA = 256
COLUMNAS = 4
LADO_3X3 = 3


def main():
    hoja = Image.open(CRUDO).convert("RGB")
    paso = hoja.width // LADO_3X3
    salida = Image.new("RGBA", (CELDA * COLUMNAS, CELDA * COLUMNAS))
    equipo.CELDA = CELDA  # encajar() usa el tamaño de celda del módulo
    for indice in range(LADO_3X3 * LADO_3X3):
        x, y = (indice % LADO_3X3) * paso, (indice // LADO_3X3) * paso
        crudo = hoja.crop((x, y, x + paso, y + paso))
        icono = equipo.encajar(equipo.quitar_fondo(crudo))
        icono.save(os.path.join(V4, "indice", f"{indice:02d}.png"))
        salida.paste(icono, ((indice % COLUMNAS) * CELDA, (indice // COLUMNAS) * CELDA))
    destino = os.path.join(V4, "iconos_v4_indice.png")
    salida.save(destino)
    print(f"hoja -> {destino}")


if __name__ == "__main__":
    main()
