"""Plantas y cosas del agua: nenúfares, lotos, juncos, piedras de paso, kois y rocas de orilla."""
import math

import generar_isla as gi
from estanques.forma import AGUA, cilindro, elipsoide, orientar, tallo, variar

NENUFAR = ((72, 152, 70), (88, 170, 76), (60, 134, 64))
TALLO_VERDE = ((92, 150, 66), (106, 164, 72))
TOTORA = (112, 74, 42)
CENTRO_FLOR = (255, 214, 92)
ROCA = ((134, 136, 138), (116, 118, 124), (100, 104, 110))
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


def juncos(nombre, base, rng, n=5, alto=(3.0, 5.5), totora=True):
    """Mata de juncos: tallos finos, hojas como cintas y algunas totoras (la espiga marrón)."""
    hijos = []
    for k in range(n):
        b = gi.add(base, (rng.uniform(-0.8, 0.8), 0, rng.uniform(-0.8, 0.8)))
        h = rng.uniform(*alto)
        u = tallo(rng, 10)
        hijos.append(cilindro(f"Tallo{k}", b, h, 0.2, rng.choice(TALLO_VERDE), "SmoothPlastic", u, **gi.FANTASMA))
        if totora and k % 2 == 0:
            hijos.append(elipsoide(f"Totora{k}", gi.add(b, u, h - 0.7), (0.42, 1.3, 0.42), TOTORA, "SmoothPlastic",
                                   orientar((0, 0, 1), u), **gi.FANTASMA))
    for k in range(3):
        g = rng.uniform(0, 360)
        h = rng.uniform(*alto) * 0.75
        r = gi.mat(gi.ry(g), gi.rz(rng.uniform(-18, 18)))
        hijos.append(gi.pieza(f"Cinta{k}", (0.06, h, 0.4), gi.add(base, gi.aplicar(r, (0, h / 2, 0))), rng.choice(TALLO_VERDE),
                              "SmoothPlastic", r, **gi.FANTASMA))
    return gi.grupo(nombre, hijos)


def piedras_paso(nombre, puntos, rng):
    """Piedras planas para cruzar el agua (se puede pisar)."""
    hijos = []
    for k, p in enumerate(puntos):
        d = rng.uniform(2.2, 2.9)
        hijos.append(gi.pieza(f"Piedra{k}", (0.6, d, d * rng.uniform(0.8, 1)), (p[0], AGUA + 0.05, p[2]), variar(rng, ROCA[0]),
                              "Slate", gi.mat(gi.ry(rng.uniform(0, 360)), gi.VERTICAL), "Cylinder", **gi.DECORADO))
    return gi.grupo(nombre, hijos)


def roca(nombre, pos, s, rng, prop=True):
    """Roca de orilla: medio hundida en el agua o en el barro. Con `prop` la viste el modelo 3D
    de Blender (Roca1..3, PropDresser), como las rocas de la playa."""
    r = gi.mat(gi.ry(rng.uniform(0, 360)), gi.mat(gi.rx(rng.uniform(-12, 12)), gi.rz(rng.uniform(-12, 12))))
    tam = (s * rng.uniform(1, 1.4), s * rng.uniform(0.55, 0.8), s)
    nodo = gi.pieza(nombre, tam, gi.add(pos, (0, tam[1] * 0.2, 0)), rng.choice(ROCA), "Slate", r)
    return gi.con_prop(nodo, f"Roca{1 + rng.randrange(3)}") if prop else nodo


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
