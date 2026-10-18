"""Plantas y cosas de la orilla: flores, helechos, árboles, bambú, hongos y faroles."""
import math

import generar_isla as gi
from estanques.forma import cilindro, elipsoide, orientar, tallo, variar

HOJA = ((74, 160, 72), (60, 140, 64), (92, 176, 80))
TRONCO = (112, 82, 58)
PIEDRA_FAROL = (158, 156, 150)
BAMBU = (132, 178, 74)
NUDO_BAMBU = (98, 142, 58)
PIE_HONGO = (238, 228, 204)


def flores(nombre, centro, rng, colores, n=7, radio=1.8, alto=(0.9, 1.6)):
    """Mata de flores: tallos con una cabeza redonda y un centro amarillo."""
    hijos = []
    for k in range(n):
        a, d = rng.uniform(0, 2 * math.pi), rng.uniform(0, radio)
        b = gi.add(centro, (math.cos(a) * d, 0, math.sin(a) * d))
        h = rng.uniform(*alto)
        u = tallo(rng, 14)
        hijos.append(cilindro(f"Tallo{k}", b, h, 0.12, HOJA[1], "SmoothPlastic", u, **gi.FANTASMA))
        cabeza = gi.add(b, u, h)
        hijos.append(elipsoide(f"Flor{k}", cabeza, (0.75, 0.4, 0.75), rng.choice(colores), "SmoothPlastic", **gi.FANTASMA))
        hijos.append(elipsoide(f"Centro{k}", gi.add(cabeza, (0, 0.15, 0)), (0.28, 0.18, 0.28), (255, 214, 92),
                               "SmoothPlastic", **gi.FANTASMA))
    return gi.grupo(nombre, hijos)


def helecho(nombre, base, rng, largo=2.6):
    """Helecho: frondas largas que salen del centro y se arquean hacia afuera."""
    hijos = []
    n = rng.randint(6, 8)
    for k in range(n):
        a = math.radians(k * 360 / n + rng.uniform(-10, 10))
        u = (math.cos(a) * 0.8, 0.6, math.sin(a) * 0.8)
        hijos.append(elipsoide(f"Fronda{k}", gi.add(base, u, largo * 0.45), (largo, 0.08, 0.6), rng.choice(HOJA),
                               "Grass", orientar(u), **gi.FANTASMA))
    return gi.grupo(nombre, hijos)


def arbol(nombre, base, rng, alto, copa, colores, neon=0, tronco=TRONCO):
    """Árbol de jardín: tronco algo inclinado, dos ramas y una copa de bolas de hojas.
    `neon` bolas de la copa brillan (árboles mágicos de los estanques altos)."""
    u = tallo(rng, 7)
    grueso = 0.9 + alto * 0.07
    hijos = [cilindro("Tronco", base, alto, grueso, tronco, "Wood", u, **gi.DECORADO)]
    punta = gi.add(base, u, alto)
    for k in range(2):
        a = math.radians(rng.uniform(0, 360) + k * 180)
        rama = (math.cos(a), 0.9, math.sin(a))
        hijos.append(cilindro(f"Rama{k}", gi.add(base, u, alto * 0.62), alto * 0.42, grueso * 0.5, tronco, "Wood", rama,
                              **gi.FANTASMA))
    for k in range(7):
        a = math.radians(k * 360 / 7 + rng.uniform(-20, 20))
        d = copa * (0.15 if k == 0 else rng.uniform(0.45, 0.7))
        p = gi.add(punta, (math.cos(a) * d, rng.uniform(-0.2, 0.35) * copa, math.sin(a) * d))
        s = copa * rng.uniform(0.75, 1.05)
        material = "Neon" if k < neon else "Grass"
        hijos.append(gi.pieza(f"Copa{k}", (s, s, s), p, variar(rng, rng.choice(colores), 8), material, forma="Ball",
                              **gi.FANTASMA))
    return gi.grupo(nombre, hijos)


def bambu(nombre, centro, rng, n=7, alto=(9, 14)):
    """Bosquecito de bambú: cañas con nudos y hojas finas arriba."""
    hijos = []
    for k in range(n):
        a, d = rng.uniform(0, 2 * math.pi), rng.uniform(0, 2.6)
        b = gi.add(centro, (math.cos(a) * d, 0, math.sin(a) * d))
        h = rng.uniform(*alto)
        u = tallo(rng, 5)
        hijos.append(cilindro(f"Cana{k}", b, h, 0.5, variar(rng, BAMBU, 8), "SmoothPlastic", u, **gi.DECORADO))
        for j in range(1, int(h // 2.6)):
            hijos.append(cilindro(f"Nudo{k}_{j}", gi.add(b, u, j * 2.6), 0.16, 0.62, NUDO_BAMBU, "SmoothPlastic", u,
                                  **gi.FANTASMA))
        for j in range(3):
            g = math.radians(rng.uniform(0, 360))
            v = (math.cos(g), -0.35, math.sin(g))
            hijos.append(elipsoide(f"Hoja{k}_{j}", gi.add(gi.add(b, u, h - 0.4), v, 0.8), (1.8, 0.05, 0.35), HOJA[2],
                                   "SmoothPlastic", orientar(v), **gi.FANTASMA))
    return gi.grupo(nombre, hijos)


def hongo(nombre, base, alto, sombrero, rng, brillo=None):
    """Hongo de pie claro y sombrero redondo con pintas; con `brillo`, el sombrero se enciende."""
    u = tallo(rng, 9)
    tope = gi.add(base, u, alto)
    tono = brillo or (210, 70, 60)
    sombrero_ = elipsoide("Sombrero", tope, (sombrero, sombrero * 0.55, sombrero), tono, "Neon" if brillo else "SmoothPlastic",
                          orientar((1, 0, 0), u), **gi.FANTASMA)
    if brillo:
        sombrero_["children"].append(gi.luz(10 + sombrero * 2, 0.8, brillo))
    hijos = [cilindro("Pie", base, alto, sombrero * 0.28, PIE_HONGO, "SmoothPlastic", u, **gi.FANTASMA), sombrero_]
    for k in range(4):
        a = math.radians(k * 90 + rng.uniform(-20, 20))
        p = gi.add(tope, (math.cos(a) * sombrero * 0.28, sombrero * 0.2, math.sin(a) * sombrero * 0.28))
        hijos.append(gi.pieza(f"Pinta{k}", (0.3, 0.3, 0.3), p, (255, 250, 240), "SmoothPlastic", forma="Ball", **gi.FANTASMA))
    return gi.grupo(nombre, hijos)


def farol_piedra(nombre, base, luz_rgb=gi.LUZ_FAROLA, escala=1.0):
    """Farol de piedra de jardín: base, columna, caja de luz y techo escalonado."""
    e, y = escala, base[1]

    def en(h):
        return (base[0], y + h * e, base[2])

    luz_ = gi.pieza("Luz", (0.7 * e, 0.7 * e, 0.7 * e), en(2.75), luz_rgb, "Neon", **gi.FANTASMA)
    luz_["children"] = [gi.luz(16 * e, 0.9, luz_rgb)]
    return gi.grupo(nombre, [
        gi.pieza("Base", (1.7 * e, 0.5 * e, 1.7 * e), en(0.25), PIEDRA_FAROL, "Slate", **gi.DECORADO),
        gi.pieza("Columna", (1.6 * e, 0.75 * e, 0.75 * e), en(1.3), PIEDRA_FAROL, "Slate", gi.VERTICAL, "Cylinder", **gi.DECORADO),
        gi.pieza("Caja", (1.3 * e, 0.2 * e, 1.3 * e), en(2.2), PIEDRA_FAROL, "Slate", **gi.DECORADO),
        luz_,
        gi.pieza("Techo", (2.2 * e, 0.35 * e, 2.2 * e), en(3.3), variar_gris(), "Slate", gi.ry(45), **gi.DECORADO),
        gi.pieza("Techo2", (1.3 * e, 0.35 * e, 1.3 * e), en(3.6), PIEDRA_FAROL, "Slate", gi.ry(45), **gi.DECORADO),
        gi.pieza("Remate", (0.55 * e, 0.55 * e, 0.55 * e), en(3.95), PIEDRA_FAROL, "Slate", forma="Ball", **gi.DECORADO),
    ])


def variar_gris():
    return tuple(c - 14 for c in PIEDRA_FAROL)


def farolillo(nombre, base, color_, alto=5.5):
    """Farolillo de papel colgado de un poste de madera con un brazo."""
    brazo = gi.add(base, (0, alto, 0))
    luz_ = elipsoide("Farolillo", gi.add(brazo, (1.2, -1.0, 0)), (1, 1.3, 1), color_, "Neon", **gi.FANTASMA)
    luz_["children"].append(gi.luz(14, 0.9, color_))
    return gi.grupo(nombre, [
        cilindro("Poste", base, alto + 0.3, 0.35, gi.MADERA_OSCURA, "Wood", **gi.DECORADO),
        cilindro("Brazo", brazo, 1.4, 0.2, gi.MADERA_OSCURA, "Wood", (1, 0, 0), **gi.FANTASMA),
        cilindro("Cordel", gi.add(brazo, (1.2, -0.35, 0)), 0.35, 0.06, (40, 30, 24), "SmoothPlastic", **gi.FANTASMA),
        luz_,
    ])
