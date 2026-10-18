"""Borde y prado del jardín de entrenamiento: setos con flores alrededor, faroles de piedra
junto al sendero en anillo y, entre los estanques, árboles, arbustos y macizos de flores."""
import random

import generar_isla as gi
from estanques import tierra
from estanques.forma import L, SUELO
from estanques.temas import AMARILLAS, BLANCAS, ROSAS, VIOLETAS

rng = random.Random(77)
HOJAS_ARBOL = ((74, 160, 72), (60, 140, 64), (92, 176, 80))


def borde():
    """Seto con flores por fuera del jardín y faroles de piedra junto al sendero en anillo; todo
    abre paso a los caminos de la isla."""
    R = L["plazaRadius"]
    hijos = gi.anillo_con_huecos("Seto", R + 2.6, 120, 2.6, 2.6, SUELO + 1.8, gi.SETO, "Grass", 7.5)
    for k, s in enumerate(hijos[::3]):
        p = s["properties"]["CFrame"]
        hijos.append(gi.pieza(f"Flor{k}", (0.8, 0.8, 0.8), (p[0], SUELO + 2.05, p[2]), gi.FLORES[k % len(gi.FLORES)],
                              "SmoothPlastic", forma="Ball", **gi.FANTASMA))
    fuera = L["gardenRingRadius"] + L["gardenPathHalfWidth"] + 2
    for k in range(18):
        a = 10 + k * 20
        if not gi.sobre_camino(a, 7):
            hijos.append(tierra.farol_piedra(f"Farol{k}", gi.polar(a, fuera, SUELO)))
    return gi.grupo("BordeJardin", hijos)


def prado():
    """Lo que crece entre los estanques y el claro del centro: un árbol de sombra con arbusto y
    flores en los huecos sin sendero (menos los dos de las vitrinas de trajes, junto al camino
    de la aparición) y macizos de flores a los lados de cada sendero al entrar al claro."""
    hijos = []
    colores = (ROSAS, AMARILLAS, VIOLETAS, BLANCAS)
    vitrinas = (L["spawnAngle"] - 36, L["spawnAngle"] + 36)
    for k, a in enumerate(a + 36 for a in L["gardenSpokeAngles"]):
        if any(abs((a - v + 180) % 360 - 180) < 10 for v in vitrinas):
            continue
        p = gi.polar(a, 46, SUELO)
        hijos.append(tierra.arbol(f"Arbol{k}", p, rng, 8, 5.5, HOJAS_ARBOL))
        hijos.append(gi.arbusto(f"Arbusto{k}", gi.add(p, gi.polar(a + 90, 6, 0))))
        hijos.append(tierra.flores(f"Flores{k}", gi.add(p, gi.polar(a - 90, 5.5, 0)), rng, colores[k % 4], n=9, radio=2.2))
    claro = L["gardenClearingRadius"] + L["gardenPathHalfWidth"] + 4
    for k, a in enumerate(L["gardenSpokeAngles"]):
        for lado in (-1, 1):
            p = gi.polar(a + lado * 11, claro, SUELO)
            hijos.append(tierra.flores(f"Entrada{k}_{lado}", p, rng, colores[(k + lado) % 4], n=8, radio=1.8))
    return gi.grupo("PradoJardin", hijos)
