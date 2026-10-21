"""Borde del jardín de entrenamiento: un seto con flores alrededor que abre paso a los caminos
de la isla. Adentro no hay nada con qué chocar: solo pasto, senderos y estanques.
Los setos que pisan el anillo de senderos elevados de la isla de bloques (en diagonal, donde la
escalera de celdas de 4 studs sale más afuera) suben gardenPathRise para no quedar enterrados."""
import generar_isla as gi
from estanques.forma import L, SUELO


SOBRE_SENDERO = {f"Seto{k}" for k in (14, 15, 16, 45, 46, 74, 75, 76, 104, 105, 106)}


def borde():
    R = L["plazaRadius"]
    hijos = gi.anillo_con_huecos("Seto", R + 2.6, 120, 2.6, 2.6, SUELO + 1.8, gi.SETO, "Grass", 7.5)
    for s in hijos:
        if s["name"] in SOBRE_SENDERO:
            s["properties"]["CFrame"][1] += L["gardenPathRise"]
    for k, s in enumerate(hijos[::3]):
        p = s["properties"]["CFrame"]
        arriba = p[1] + 1.3 + 0.25  # medio seto (2.6 / 2) y la flor apenas asomada
        hijos.append(gi.pieza(f"Flor{k}", (0.8, 0.8, 0.8), (p[0], arriba, p[2]), gi.FLORES[k % len(gi.FLORES)],
                              "SmoothPlastic", forma="Ball", **gi.FANTASMA))
    return gi.grupo("BordeJardin", hijos)
