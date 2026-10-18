"""Lo que vive en el agua de los estanques: nenúfares, lotos y kois."""
import math

import generar_isla as gi
from estanques.forma import AGUA, elipsoide, orientar

NENUFAR = ((72, 152, 70), (88, 170, 76), (60, 134, 64))
CENTRO_FLOR = (255, 214, 92)
KOI = ((255, 132, 50), (250, 248, 240), (255, 196, 60))


def loto(nombre, pos, escala, petalo, neon=False, centro=CENTRO_FLOR):
    """Flor de loto: dos coronas de pétalos que se abren hacia afuera y un centro."""
    hijos = []
    material = "Neon" if neon else "SmoothPlastic"
    for capa, (n, largo, inclinacion, giro) in enumerate(((6, 1.15, 28, 0), (5, 0.85, 58, 36))):
        tono = petalo if capa == 0 else tuple(min(255, c + 28) for c in petalo)
        for k in range(n):
            a = math.radians(k * 360 / n + giro)
            t = math.radians(inclinacion)
            u = (math.cos(a) * math.cos(t), math.sin(t), math.sin(a) * math.cos(t))
            p = gi.add(pos, u, largo * escala * 0.5)
            hijos.append(elipsoide(f"Petalo{capa}_{k}", p, (largo * escala, 0.16 * escala, 0.5 * escala), tono, material,
                                   orientar(u), **gi.FANTASMA))
    hijos.append(elipsoide("Centro", gi.add(pos, (0, 0.15 * escala, 0)), (0.5 * escala, 0.3 * escala, 0.5 * escala), centro,
                           "Neon" if neon else "SmoothPlastic", **gi.FANTASMA))
    return gi.grupo(nombre, hijos)


def nenufar(nombre, pos, diam, rng, flor=None, neon=False):
    """Hoja redonda flotando y, a veces, una flor de loto encima."""
    p = (pos[0], AGUA + 0.06, pos[2])
    hijos = [gi.pieza("Hoja", (0.12, diam, diam), p, rng.choice(NENUFAR), "SmoothPlastic", gi.VERTICAL, "Cylinder",
                      **gi.FANTASMA)]
    if flor:
        hijos.append(loto("Flor", gi.add(p, (0, 0.1, 0)), diam * 0.32, flor, neon))
    return gi.grupo(nombre, hijos)


def koi(nombre, centro, radio, fase, rng):
    """Pez koi bajo la superficie: lo hace nadar en círculo PondFx (atributos Radio y Fase)."""
    a = math.radians(fase)
    p = (centro[0] + math.cos(a) * radio, AGUA - 0.45, centro[2] + math.sin(a) * radio)
    frente = (-math.sin(a), 0, math.cos(a))  # tangente: nada en sentido antihorario
    giro = gi.columnas(gi.cross((0, 1, 0), frente), (0, 1, 0), frente)
    tono = KOI[rng.randrange(3)]
    modelo = gi.grupo(nombre, [
        elipsoide("Cuerpo", p, (0.55, 0.42, 1.8), tono, "SmoothPlastic", giro, **gi.FANTASMA),
        gi.pieza("Cola", (0.08, 0.5, 0.7), gi.add(p, frente, -1.05), KOI[1] if tono != KOI[1] else KOI[0], "SmoothPlastic",
                 giro, **gi.FANTASMA),
    ])
    modelo["attributes"] = {"Radio": radio, "Fase": fase}
    return modelo
