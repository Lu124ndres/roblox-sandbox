"""Zona de entrenamiento: un jardín con estanques naturales.

El terreno (pasto, senderos de arena, la hoya y la orilla de barro de cada estanque) lo arma
server/World/GardenShape con la misma forma de orilla que estanques.forma. Acá salen las
piezas: en cada estanque la tapa, el prompt y el espíritu de luz (estanques.base), y lo que
lo distingue (estanques.temas y temas_altos); alrededor, el borde y el prado del jardín
(estanques.jardin).

Lo usa tools/generar_isla.py. Cada estanque tiene su propia semilla: cambiar uno no mueve
las piezas de los demás.
"""
import random

import generar_isla as gi
from estanques import base, jardin, temas, temas_altos
from estanques.forma import SAGRADO

TEMAS = {1: temas.prado, 2: temas.juncos, 3: temas.lirios, 4: temas.bambu, 5: temas.hongos, **temas_altos.TEMAS}


def estanque(i):
    tono = gi.COLORES_ESTANQUE[(i - 1) % len(gi.COLORES_ESTANQUE)]
    rng = random.Random(1000 + i)
    hijos = base.tapa_y_prompt(i, tono)
    if i != SAGRADO:
        hijos += base.espiritu(i, tono)
    hijos += TEMAS[i](i, tono, rng)
    return gi.grupo(f"Estanque{i}", hijos)


def zona_entrenamiento():
    estanques = gi.grupo("Estanques", [estanque(i) for i in range(1, SAGRADO + 1)], "Folder")
    return gi.grupo("ZonaEntrenamiento", [estanques, jardin.borde(), jardin.prado()])
