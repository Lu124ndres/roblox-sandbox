"""Lo que tienen todos los estanques: la tapa para caminar por el agua, la pieza del
ProximityPrompt, el loto grande del centro, los nenúfares y el contorno de luz. Cada
tema (estanques.temas) elige el color de los lotos y si hay kois."""
import math

import generar_isla as gi
from estanques import agua
from estanques.forma import AGUA, L, SAGRADO, SUELO, borde, centro, en_agua, radio, radio_max

def tapa_y_prompt(i, tono):
    """Tapa invisible apenas bajo el agua (se entrena parado en el estanque sin hundirse) y la
    pieza "Estanque" del ProximityPrompt (TrainingService). El sagrado, más grande, lleva cuatro
    piezas alrededor del centro para que el prompt llegue desde cualquier orilla."""
    c = centro(i)
    tapa_y = AGUA - L["pondCoverDepth"] - 0.5
    d = 2 * radio_max(i) + 1
    hijos = [gi.pieza("Tapa", (1, d, d), (c[0], tapa_y, c[2]), tono, "SmoothPlastic", gi.VERTICAL, "Cylinder",
                      Transparency=1, CanQuery=False, CanTouch=False, CastShadow=False)]
    puntos = [gi.polar(45 + k * 90, radio(i) * 0.62, 0) for k in range(4)] if i == SAGRADO else [(0, 0, 0)]
    for q in puntos:
        marcador = gi.pieza("Estanque", (2, 1, 2), (c[0] + q[0], AGUA + 1, c[2] + q[2]), tono, **gi.INVISIBLE, CanCollide=False)
        marcador["attributes"] = {"Indice": i}
        hijos.append(marcador)
    return hijos


def loto_centro(i, tono):
    """Hoja grande y loto en el centro del estanque, con el color de su nivel."""
    c = centro(i)
    flor = tuple(min(255, int(v * 0.6 + 255 * 0.4)) for v in tono)
    return [gi.pieza("HojaCentro", (0.14, 4.6, 4.6), (c[0], AGUA + 0.06, c[2]), agua.NENUFAR[0], "SmoothPlastic", gi.VERTICAL,
                     "Cylinder", **gi.FANTASMA),
            agua.loto("LotoCentro", (c[0], AGUA + 0.15, c[2]), 1.5, flor, i >= 9)]


def nenufares(i, rng, flor, n=8, neon=False, cada=3):
    """Hojas flotando entre el centro y la orilla; una de cada `cada` lleva flor."""
    hijos = []
    for k in range(n):
        g = k * 360 / n + rng.uniform(-14, 14)
        p = en_agua(i, g, rng.uniform(0.42, 0.82))
        hijos.append(agua.nenufar(f"Nenufar{k}", p, rng.uniform(1.8, 3.1), rng, flor if k % cada == 0 else None, neon))
    return hijos


def brillo_orilla(i, tono, n=44, afuera=1.2):
    """Contorno de luz del color del estanque, sobre el barro de la orilla (`afuera` studs
    por fuera del agua). El agua del terreno va en bloques de 4 studs y no sigue la curva al
    detalle: el cliente (Training/PondFx) asienta cada tramo en el suelo con un rayo y lo
    prende o apaga según si el estanque está abierto."""
    c = centro(i)
    hijos = []
    for k in range(n):
        a0, a1 = 2 * math.pi * k / n, 2 * math.pi * (k + 1) / n
        r0, r1 = borde(i, a0) + afuera, borde(i, a1) + afuera
        p0 = (c[0] + math.cos(a0) * r0, SUELO + 0.1, c[2] + math.sin(a0) * r0)
        p1 = (c[0] + math.cos(a1) * r1, SUELO + 0.1, c[2] + math.sin(a1) * r1)
        largo = math.dist(p0, p1) + 0.15
        medio = tuple((p0[q] + p1[q]) / 2 for q in range(3))
        u = gi.norm((p1[0] - p0[0], 0, p1[2] - p0[2]))
        hijos.append(gi.pieza(f"Brillo{k}", (0.8, 0.2, largo), medio, tono, "Neon", gi.base_con_z(u), **gi.FANTASMA))
    grupo = gi.grupo("BrilloOrilla", hijos)
    grupo["attributes"] = {"Indice": i}
    return grupo
