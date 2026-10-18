"""Lo que tienen todos los estanques: la tapa para caminar por el agua, la pieza del
ProximityPrompt, el espíritu de luz sobre un loto grande en el centro y los nenúfares. Cada
tema (estanques.temas) elige el color de los lotos y si hay kois."""
import math

import generar_isla as gi
from estanques import agua
from estanques.forma import AGUA, L, SAGRADO, borde, centro, en_agua, radio, radio_max

LUCIERNAGA = (230, 255, 150)


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


def espiritu(i, tono):
    """Loto grande en el centro y, encima, el espíritu del estanque: una esfera de luz del color
    de su nivel que crece con él (la anima Training/PondFx). Desde el 7, luciérnagas alrededor."""
    c = centro(i)
    alto = AGUA + 4
    flor = tuple(min(255, int(v * 0.6 + 255 * 0.4)) for v in tono)
    hijos = [gi.pieza("HojaCentro", (0.14, 4.6, 4.6), (c[0], AGUA + 0.06, c[2]), agua.NENUFAR[0], "SmoothPlastic", gi.VERTICAL,
                      "Cylinder", **gi.FANTASMA),
             agua.loto("LotoCentro", (c[0], AGUA + 0.15, c[2]), 1.5, flor, i >= 9)]
    lado = 1.8 + i * 0.12
    bola = gi.pieza("Espiritu", (lado, lado, lado), (c[0], alto, c[2]), tono, "Neon", forma="Ball", **gi.FANTASMA)
    bola["children"] = [gi.luz(24 if i == SAGRADO else 18, 1.3, tono)]
    bola["attributes"] = {"Indice": i}
    hijos.append(bola)
    if i >= 7:
        for k in range(3):
            p = gi.add(c, gi.polar(k * 120, 2.8, alto))
            hijos.append(gi.pieza(f"Luciernaga{k + 1}", (0.35, 0.35, 0.35), p, LUCIERNAGA, "Neon", forma="Ball", **gi.FANTASMA))
    return hijos


def nenufares(i, rng, flor, n=8, neon=False, cada=3):
    """Hojas flotando entre el centro y la orilla; una de cada `cada` lleva flor."""
    hijos = []
    for k in range(n):
        g = k * 360 / n + rng.uniform(-14, 14)
        p = en_agua(i, g, rng.uniform(0.42, 0.82))
        hijos.append(agua.nenufar(f"Nenufar{k}", p, rng.uniform(1.8, 3.1), rng, flor if k % cada == 0 else None, neon))
    return hijos


def brillo_orilla(i, tono, n=44):
    """Borde de luz del color del estanque siguiendo la orilla: se ve el estanque de lejos."""
    c = centro(i)
    hijos = []
    for k in range(n):
        a0, a1 = 2 * math.pi * k / n, 2 * math.pi * (k + 1) / n
        p0 = (c[0] + math.cos(a0) * borde(i, a0), AGUA + 0.12, c[2] + math.sin(a0) * borde(i, a0))
        p1 = (c[0] + math.cos(a1) * borde(i, a1), AGUA + 0.12, c[2] + math.sin(a1) * borde(i, a1))
        largo = math.dist(p0, p1) + 0.15
        medio = tuple((p0[q] + p1[q]) / 2 for q in range(3))
        u = gi.norm((p1[0] - p0[0], 0, p1[2] - p0[2]))
        hijos.append(gi.pieza(f"Brillo{k}", (0.7, 0.15, largo), medio, tono, "Neon", gi.base_con_z(u), **gi.FANTASMA))
    return gi.grupo("BrilloOrilla", hijos)
