"""Borde del jardín de entrenamiento: un seto con flores alrededor que abre paso a los caminos
de la isla. Adentro no hay nada con qué chocar: solo pasto, senderos y estanques."""
import generar_isla as gi
from estanques.forma import L, SUELO


def borde():
    R = L["plazaRadius"]
    hijos = gi.anillo_con_huecos("Seto", R + 2.6, 120, 2.6, 2.6, SUELO + 1.8, gi.SETO, "Grass", 7.5)
    for k, s in enumerate(hijos[::3]):
        p = s["properties"]["CFrame"]
        hijos.append(gi.pieza(f"Flor{k}", (0.8, 0.8, 0.8), (p[0], SUELO + 2.05, p[2]), gi.FLORES[k % len(gi.FLORES)],
                              "SmoothPlastic", forma="Ball", **gi.FANTASMA))
    return gi.grupo("BordeJardin", hijos)
