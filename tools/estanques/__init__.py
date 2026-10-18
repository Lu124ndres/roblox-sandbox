"""Zona de entrenamiento: un jardín con estanques naturales.

El terreno (pasto, senderos de arena, la hoya y la orilla de barro de cada estanque) lo arma
server/World/GardenShape con la misma forma de orilla que estanques.forma. Acá salen las
piezas: en cada estanque la tapa, el prompt, el espíritu de luz y los nenúfares
(estanques.base), con el color de lotos y los kois de su tema (estanques.temas); alrededor,
el seto del borde (estanques.jardin). En la orilla no hay nada: los jugadores no chocan.

Lo usa tools/generar_isla.py. Cada estanque tiene su propia semilla: cambiar uno no mueve
las piezas de los demás.
"""
import random

import generar_isla as gi
from estanques import base, jardin, temas
from estanques.forma import SAGRADO


def estanque(i):
    tono = gi.COLORES_ESTANQUE[(i - 1) % len(gi.COLORES_ESTANQUE)]
    rng = random.Random(1000 + i)
    hijos = base.tapa_y_prompt(i, tono) + base.espiritu(i, tono) + temas.tema(i, rng)
    return gi.grupo(f"Estanque{i}", hijos)


def zona_entrenamiento():
    estanques = gi.grupo("Estanques", [estanque(i) for i in range(1, SAGRADO + 1)], "Folder")
    return gi.grupo("ZonaEntrenamiento", [estanques, jardin.borde()])
