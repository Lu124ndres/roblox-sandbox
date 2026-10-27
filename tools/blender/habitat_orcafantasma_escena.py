r"""
La distribución del hábitat de la Orca fantasma: dónde va cada cosa (ángulos del cráter en
grados, radios en studs) y en qué malla. La usa habitat_orcafantasma.py (armar).
La puerta está en 270: ahí el borde queda despejado.
"""
import math
from mathutils import Vector as V
import habitats as H
from habitats import T
import habitats_orcafantasma as P
import habitat_orcafantasma_piezas as Z
import habitat_orcafantasma_huesos as HU
import habitat_orcafantasma_naufragio as N
import habitat_orcafantasma_fondo as F

CIAN, VIOLETA = (110, 230, 255), (175, 110, 255)

BARCO = (205.0, 160.0, 2.4)  # ángulo, radio, escala
FARO = (125.0, 181.0, 22.0, 24.0)  # ángulo, radio, inclinación (grados), alto de la torre
BALLENA = dict(ang0=28.0, ang1=72.0, r0=181.0, r1=129.0, alto=44.0, ancho=32.0, grosor=1.25, cabeza=1.3)
COSTILLAS = [(95, 138, 34, 22), (140, 134, 30, 18), (165, 142, 36, 24), (240, 136, 32, 20), (300, 140, 38, 26),
             (330, 133, 30, 18), (355, 141, 34, 22), (112, 145, 28, 16)]  # ang, r, largo, alto (ladera)
HILERAS = [(80, 116, 186.0, 1.7), (84, 114, 189.3, 1.3), (136, 178, 186.5, 1.6), (236, 261, 186.5, 1.5),
           (280, 350, 186.0, 1.7), (284, 346, 189.3, 1.3)]  # desde, hasta, radio, escala
FAROLES = [0, 52, 76, 100, 145, 168, 190, 214, 238, 290, 314, 338]
FAROLES_CON_LUZ = (52, 100, 190, 238, 314)
CALABAZAS = [(6, 188.0, 0.85, 10), (250, 188.0, 0.8, -15)]
ATAUDES = [(100, 187.0, 1.7, 90), (322, 187.0, 1.7, -90)]  # tendidos a lo largo del borde
ALMAS = [(100, 143, 3, 34, 7), (165, 183.5, 6, 38, 6), (240, 143, 3, 30, 6), (300, 183.5, 6, 40, 7),
         (335, 143, 3, 32, 6), (205, 160, 22, 46, 6), (15, 143, 3, 30, 5)]  # ang, r, z0, z1, n
LUCES_ALMAS = (0, 3, 5)
ANCLAS = [(255, 168, True), (150, 141, False)]  # tirada en la repisa / clavada en la ladera
CADENAS = [[(196, 172), (190, 179), (183, 176), (176, 181)], [(255, 168), (262, 175), (268, 170), (276, 176), (284, 171)],
           [(125, 177), (130, 165), (127, 152), (133, 141)], [(150, 141), (156, 150), (152, 162), (158, 172)]]
REDES = [(216, 176, 18), (300, 162, 16), (100, 158, 16), (170, 165, 14), (20, 160, 14)]


def armar(mallas, rnd):
    h1, h2, h3, h4, h5, h6, cian, violeta = mallas
    luces, ocupado = [], []

    # ---- protagonistas ----
    luz, rocas = N.barco(h1, cian, *BARCO, rnd)
    luces.append((luz, CIAN, 40))
    ocupado.append((Z.polar(BARCO[0], BARCO[1]), 50.0))
    ang, r, inclina, alto = FARO
    luz, pie = N.faro(h1, cian, ang, r, inclina, alto)
    luces.append((luz, CIAN, 50))
    ocupado.append((pie, 10.0))
    b = BALLENA

    def camino(s):
        suave = s * s * (3 - 2 * s)
        return Z.polar(b["ang0"] + (b["ang1"] - b["ang0"]) * s, b["r0"] + (b["r1"] - b["r0"]) * suave)

    ojo = HU.ballena(h2, cian, camino, b["alto"], b["ancho"], b["grosor"], b["cabeza"], rnd)
    luces.append((ojo, CIAN, 30))
    for k in range(9):
        ocupado.append((camino(k / 8), b["ancho"] * 0.8))
    for ang, r, largo, alto in COSTILLAS:
        HU.costilla_suelta(h2, ang, r, largo, alto, rnd)
        ocupado.append((Z.polar(ang, r), largo / 2))

    # ---- anclas, cadenas, redes ----
    for ang, r, tirada in ANCLAS:
        if tirada:
            M = T(*Z.polar(ang, r, Z.piso(r) + 1.0)) @ H.girar("Z", math.radians(ang + 60)) @ H.girar("X", -math.pi / 2 + 0.06)
        else:
            M = T(*Z.polar(ang, r, Z.piso(r) - 3.0)) @ H.girar("Z", math.radians(-ang)) @ H.girar("Y", 0.28)
        F.ancla(h2, M)
        ocupado.append((Z.polar(ang, r), 9.0))
    for cad in CADENAS:
        F.cadena(h1, [Z.polar(a, r) for a, r in cad], rnd)
    for ang, r, ancho in REDES:
        F.red(h4, ang, r, ancho, rnd)

    # ---- borde: lápidas, faroles, ataúdes, calabazas ----
    for a0, a1, r, esc in HILERAS:
        F.hilera(h5, a0, a1, r, esc, rnd)
    for ang in FAROLES:
        c = F.farol(h5, cian, ang + rnd.uniform(-3, 3), 189.8, rnd.uniform(21, 26), rnd)
        if ang in FAROLES_CON_LUZ:
            luces.append((c, CIAN, 34))
    for ang, r, esc, giro in ATAUDES:
        info = P.ataud(int(ang))
        M = Z.marco(ang, r, Z.piso(r) - 0.6, esc, giro)
        Z.volcar(h5, info["malla"], M)
        Z.volcar(cian, info["brillo"], M, apoyar=False)
    for k, (ang, r, esc, giro) in enumerate(CALABAZAS):
        info = P.calabaza(1 + k)
        M = Z.marco(ang, r, Z.piso(r) - 1.2, esc, giro)
        Z.volcar(h1, info["malla"], M)
        Z.volcar(violeta, info["brillo"], M, apoyar=False)

    # ---- almas ----
    for k, (ang, r, z0, z1, n) in enumerate(ALMAS):
        Z.columna_almas(violeta, ang, r, z0, z1, n, rnd)
        if k in LUCES_ALMAS:
            luces.append((Z.polar(ang, r, (z0 + z1) / 2), VIOLETA, 34))

    # ---- suelo, rocas, coral, tablas, algas, musgo ----
    Z.suelo(h3, [128, 136, 143, 149, 155, 161, 167, 172, 177, 181, 185, 188, 189.6], 144)
    libre = lambda p, rr: all((p.xy - c.xy).length > rr + rc for c, rc in ocupado)
    for p in rocas:  # bajo la proa del barco
        Z.roca(h3, math.degrees(math.atan2(-p.y, p.x)), p.xy.length, rnd.uniform(7, 9), rnd)
    ang = 0.0
    while ang < 360:  # pie del acantilado
        if abs(ang - 270) > 12:
            Z.roca(h3, ang, rnd.uniform(186, 193), rnd.uniform(3, 5.5), rnd)
        ang += rnd.uniform(9, 13)

    def sembrar(cuantas, r0, r1, radio, poner):
        puestas, intentos = 0, 0
        while puestas < cuantas and intentos < cuantas * 40:
            intentos += 1
            a, r = rnd.uniform(0, 360), rnd.uniform(r0, r1)
            p = Z.polar(a, r)
            if libre(p, radio) and not (abs(a - 300) < 5 and r < 150):  # la fumarola de CraterVents
                poner(a, r)
                ocupado.append((p, radio))
                puestas += 1

    sembrar(22, 150, 182, 4, lambda a, r: Z.roca(h3, a, r, rnd.uniform(3, 6), rnd))
    sembrar(10, 138, 148, 6, lambda a, r: Z.roca(h3, a, r, rnd.uniform(5, 8), rnd))
    sembrar(16, 150, 182, 3, lambda a, r: F.domo(h3, a, r, rnd.uniform(2.2, 4.0), rnd))
    sembrar(32, 150, 182, 2.5, lambda a, r: F.coral(h4, a, r, rnd.uniform(4, 8), rnd))
    sembrar(18, 136, 149, 3, lambda a, r: F.coral(h4, a, r, rnd.uniform(9, 15), rnd))
    sembrar(36, 150, 186, 1.5, lambda a, r: F.tabla(h4, Z.polar(a, r), rnd))
    for _ in range(26):  # tablas del barco desparramadas
        F.tabla(h4, Z.polar(BARCO[0] + rnd.uniform(-28, 28), rnd.uniform(146, 186)), rnd)
    sembrar(58, 128, 148, 2, lambda a, r: Z.alga(h6, a, r, rnd))
    sembrar(30, 150, 182, 2, lambda a, r: Z.alga(h6, a, r, rnd))
    for k in range(26):
        a = k * 360 / 26 + rnd.uniform(-4, 4)
        if abs(a - 270) > 16:
            Z.musgo(h6, a, rnd)
    return luces
