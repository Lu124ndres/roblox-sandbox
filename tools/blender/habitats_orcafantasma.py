r"""
Hábitat de la Orca fantasma: cementerio marino de Halloween.
Calabaza (cara que brilla), Lapida y LapidaCruz, BarcoHundido (farol y ventanas
fantasma), FarolFantasma (luz cian), ArbolSeco y Ataud.
"""
import math
from mathutils import Vector as V, noise
from habitats import Malla, T, girar

AZUL_FANTASMA = (110, 230, 255)
NARANJA = (255, 150, 50)


def calabaza(semilla=1, R=8.5, H=11.0):
    m, b = Malla(semilla), Malla(semilla + 50)
    lat, lon = 12, 40

    def radio(theta):
        return 0.86 + 0.14 * abs(math.cos(4 * theta)) ** 0.6

    sur, nor = m.v(V((0, 0, 0.5))), m.v(V((0, 0, H - 0.9)))
    rings = []
    for i in range(1, lat):
        phi = math.pi * i / lat
        ring = []
        for k in range(lon):
            th = 2 * math.pi * k / lon
            r = R * math.sin(phi) * radio(th)
            z = H * 0.5 * (1 - math.cos(phi))
            ring.append(m.v(V((math.cos(th) * r, math.sin(th) * r, z))))
        rings.append(ring)

    def color(i, k):
        th = 2 * math.pi * (k + 0.5) / lon
        if abs(math.cos(4 * th)) < 0.35:
            return "calabaza2"
        return "calabaza3" if 3 < i < 7 and k % 5 == 0 else "calabaza"

    for k in range(lon):
        k2 = (k + 1) % lon
        m.cara((sur, rings[0][k2], rings[0][k]), color(0, k), True)
        m.cara((nor, rings[-1][k], rings[-1][k2]), color(lat - 1, k), True)
        for i in range(len(rings) - 1):
            a, c = rings[i], rings[i + 1]
            m.cara((a[k], a[k2], c[k2], c[k]), color(i + 1, k), True)
    # tallo torcido y una hoja
    pts = [V((0, 0, H - 1.6)), V((0.2, 0.1, H + 0.4)), V((0.9, 0.3, H + 1.9)), V((1.9, 0.2, H + 2.6))]
    m.tubo(pts, [1.0, 0.85, 0.7, 0.5], 7, "tallo")
    hoja = [(0, 0), (1.6, 0.7), (3.4, 0.5), (4.6, -0.4), (3.2, -0.9), (1.4, -0.8)]
    m.placa(T(-0.6, -0.4, H - 0.6) @ girar("Z", 2.4) @ girar("X", 1.3), hoja, 0.25, "alga")
    m.tubo([V((0.5, 0, H - 0.8)), V((-1.5, -1.2, H - 0.3)), V((-2.6, -0.4, H + 0.6)), V((-1.8, 0.6, H + 0.9))],
           [0.25, 0.22, 0.2, 0.15], 5, "tallo", cerrar=True)

    # cara: ojos triangulares, nariz y boca dentada (placas en la superficie del frente, +Y)
    def en_frente(x, z, prof=0.3):
        cphi = max(-1.0, min(1.0, 1 - 2 * z / H))
        sphi = math.sqrt(1 - cphi * cphi)
        y = R
        while y > 0:
            if math.hypot(x, y) <= R * sphi * radio(math.atan2(y, x)):
                return y - prof
            y -= 0.05
        return 0.0

    def pieza(contorno, cx, cz):
        y = en_frente(cx, cz)
        inclina = math.atan2(cx, max(y, 0.1))
        M = T(cx, y, cz) @ girar("Z", -inclina)
        b.placa(M, [(x - cx, z - cz) for x, z in contorno], 1.6, "fuego", "fuego2")

    for s in (-1, 1):
        cx = 2.9 * s
        pieza([(cx - 1.6, 6.4), (cx + 1.6, 6.4), (cx + 0.4 * s, 8.7)], cx, 7.1)
    pieza([(-0.7, 5.2), (0.7, 5.2), (0, 6.2)], 0, 5.6)
    boca = [(-4.6, 4.4), (-3.4, 3.6), (-2.6, 4.2), (-1.4, 3.3), (0, 4.0), (1.4, 3.3), (2.6, 4.2),
            (3.4, 3.6), (4.6, 4.4), (3.6, 2.3), (2.2, 1.8), (1.2, 2.5), (0, 1.7), (-1.2, 2.5), (-2.2, 1.8), (-3.6, 2.3)]
    pieza(boca, 0, 3.1)
    return {"malla": m, "brillo": b, "efecto": "luz", "colorLuz": NARANJA, "llama": (0, 2, 5.5), "colorBrillo": NARANJA}


def lapida(semilla=2, cruz=False):
    m = Malla(semilla)
    r = m.rnd
    inclina = r.uniform(-0.18, 0.18)
    M = girar("Y", inclina) @ girar("X", r.uniform(-0.12, 0.05))
    if cruz:
        w = 1.2
        cont = [(-w, 0), (w, 0), (w, 7), (3.2, 7), (3.2, 9.2), (w, 9.2), (w, 12), (-w, 12), (-w, 9.2), (-3.2, 9.2),
                (-3.2, 7), (-w, 7)]
        m.placa(M, cont, 2.0, "lapida", "lapida2")
        aro = [M @ V((2.5 * math.cos(a), 0, 8.1 + 2.5 * math.sin(a))) for a in
               [2 * math.pi * k / 16 for k in range(17)]]
        m.tubo(aro, [0.45] * 17, 6, "lapida3")
    else:
        cont = [(-3.2, 0), (3.2, 0), (3.2, 7.2)]
        for k in range(1, 10):
            a = math.pi * k / 10
            cont.append((3.2 * math.cos(a), 7.2 + 2.6 * math.sin(a)))
        cont += [(-3.2, 7.2)]
        m.placa(M, cont, 1.6, "lapida", "lapida2")
        # cruz grabada en relieve y una grieta
        m.caja(M @ T(0, 0.85, 6.4), (0.6, 0.3, 3.6), "lapida3")
        m.caja(M @ T(0, 0.85, 7.3), (2.2, 0.3, 0.6), "lapida3")
        m.placa(M @ T(1.6, 0.82, 3.2), [(0, 0), (0.5, 1.4), (0.1, 2.6), (0.6, 3.4), (0.3, 3.4), (-0.2, 2.4), (0.2, 1.3), (-0.3, 0)], 0.2, "negro")
    # musgo y montículo
    for k in range(4):
        m.roca(M @ T(r.uniform(-2.6, 2.6), r.uniform(-1, 1), r.uniform(0.3, 1.2)), r.uniform(0.6, 1.1), "musgo2", 1, 0.3, k)
    m.roca(T(0, -1.6, 0), 4.6, "arena2", 1, 0.25, semilla, (1.1, 0.8, 0.28))
    return {"malla": m}


def barco(semilla=3, L=46.0, B=15.0, H=11.0):
    m, b = Malla(semilla), Malla(semilla + 9)
    r = m.rnd
    Mb = T(0, 0, -2.4) @ girar("Y", math.radians(16)) @ girar("X", math.radians(-7))
    n_sec, filas = 16, 7

    def ancho(t):  # t: -1 popa .. 1 proa
        return B / 2 * (math.sqrt(max(0.0, 1 - max(0.0, t) ** 2.2)) * 0.97 + 0.03) * (0.82 + 0.18 * (1 - max(0.0, -t) ** 4))

    def borda(t):
        return H + 2.2 * t * t + (1.6 if t < -0.75 else 0)

    secciones = []
    for s in range(n_sec + 1):
        t = -1 + 2 * s / n_sec
        y = t * L / 2
        w, top = ancho(t), borda(t)
        afuera = []
        for j in range(filas + 1):
            u = j / filas
            z = top * u
            x = w * math.sqrt(1 - (1 - u) ** 2) if u < 1 else w
            afuera.append((x, z))
        cubierta = top - 1.4
        wi = w - min(0.6, w * 0.5)
        loop = [(-wi, cubierta), (-wi, top)] + [(-x, z) for x, z in reversed(afuera)] + \
               [(x, z) for x, z in afuera[1:]] + [(wi, top), (wi, cubierta)]
        secciones.append([m.v(Mb @ V((x, y, z))) for x, z in loop])
    n = len(secciones[0])
    for s in range(n_sec):
        a, c = secciones[s], secciones[s + 1]
        for k in range(n):
            k2 = (k + 1) % n
            mid = (k + 0.5) / n
            fila = abs(k - (n - 1) / 2)
            if k == n - 1:
                col = "madera3" if s % 2 else "madera"  # cubierta
            elif k in (0, n - 2, 1, n - 3):
                col = "madera2"
            elif fila < 2.5:
                col = "alga2"  # quilla con algas
            else:
                col = "madera" if int(fila) % 2 else "madera2"
            if 6 <= s <= 9 and 3 <= k <= 5:
                col = "negro"  # boquete en el costado
            m.cara((a[k], a[k2], c[k2], c[k]), col)
    m.cara(list(reversed(secciones[0])), "madera2")
    m.cara(secciones[-1], "madera2")
    # costillas sobre el boquete
    for s in (6.6, 7.6, 8.6):
        y = (-1 + 2 * s / n_sec) * L / 2
        w = ancho(-1 + 2 * s / n_sec)
        m.tubo([Mb @ V((-w - 0.2, y, 2.2)), Mb @ V((-w - 0.5, y, 5)), Mb @ V((-w - 0.2, y, 8))], [0.45, 0.45, 0.45], 5, "hueso2")
    cub = lambda x, y: Mb @ V((x, y, borda(2 * y / L) - 1.4))
    # mástil roto con verga y vela rota
    base = cub(0, 3)
    tope = base + (Mb.to_3x3() @ V((0.6, -0.4, 17)))
    m.tubo([base, base.lerp(tope, 0.5), tope], [0.9, 0.8, 0.7], 8, "madera2")
    m.placa(T(*tope) @ girar("Z", 0.4), [(-0.7, 0), (0.7, 0), (0.3, 1.4), (-0.1, 0.6), (-0.5, 1.8)], 1.4, "madera3")
    verga = tope - V((0, 0, 3))
    m.tubo([verga + V((-7, 0.5, -0.6)), verga, verga + V((6.2, -0.3, 0.4))], [0.35, 0.45, 0.35], 6, "madera2")
    vela = [(-6.5, 0), (6.0, 0.6), (5.2, -4.0), (3.8, -3.0), (2.6, -6.5), (0.8, -5.0), (-0.6, -8.4), (-2.2, -5.6),
            (-3.6, -7.0), (-4.6, -4.2), (-6.2, -5.2)]
    m.placa(T(verga.x, verga.y - 0.4, verga.z - 0.5) @ girar("X", 0.12), vela, 0.25, "tela", "tela2")
    m.tubo([cub(0.3, 15), cub(0.6, 15) + V((0.2, 2.6, 5.5))], [0.7, 0.55], 7, "madera2")  # mástil de proa partido
    # castillo de popa con ventanas que brillan y farol
    popa = cub(0, -L / 2 + 5)
    Mp = T(*popa) @ girar("Y", math.radians(16)) @ girar("X", math.radians(-7))
    m.caja(Mp @ T(0, 0, 2.6), (B * 0.62, 7, 5.2), {"+z": "madera2", "resto": "madera"})
    m.caja(Mp @ T(0, 0, 5.4), (B * 0.68, 7.8, 0.6), "madera2")
    for x in (-3, 0, 3):
        b.caja(Mp @ T(x, -3.55, 2.8), (1.6, 0.3, 2.0), "cian")
    poste = Mp @ V((B * 0.3, -3.2, 5.6))
    m.tubo([poste, poste + V((0, 0, 3.6)), poste + V((0, -1.4, 4.2))], [0.2, 0.2, 0.2], 5, "hierro")
    b.caja(T(*(poste + V((0, -1.4, 2.8)))), (1.1, 1.1, 1.5), "cian")
    m.caja(T(*(poste + V((0, -1.4, 3.75)))), (1.5, 1.5, 0.4), "hierro")
    # arena amontonada
    for k in range(7):
        m.roca(T(r.uniform(-B / 2, B / 2) * 1.3, r.uniform(-L / 2, L / 2) * 0.9, 0), r.uniform(4, 6.5), "arena2", 1, 0.25, k, (1, 1.3, 0.35))
    return {"malla": m, "brillo": b, "efecto": "luz", "colorLuz": AZUL_FANTASMA,
            "llama": tuple(poste + V((0, -1.4, 2.8))), "colorBrillo": AZUL_FANTASMA, "colision": True}


def farol(semilla=4):
    m, b = Malla(semilla), Malla(semilla + 3)
    m.torno(T(), [(1.8, 0), (1.6, 0.8), (1.0, 1.2), (0.7, 1.8)], 8, "lapida2")
    pts = [V((0, 0, 1.5)), V((0, 0, 9)), V((0.1, 0, 15)), V((0.6, 0, 17.2)), V((2.2, 0, 17.8)), V((3.4, 0, 17.2))]
    m.tubo(pts, [0.45, 0.4, 0.35, 0.32, 0.3, 0.28], 6, "hierro")
    m.tubo([V((0, 0, 14)), V((1.4, 0, 15.6)), V((2.6, 0, 17.4))], [0.18, 0.18, 0.18], 4, "hierro2")
    c = V((3.4, 0, 14.4))
    m.tubo([c + V((0, 0, 2.8)), c + V((0, 0, 2.2))], [0.12, 0.12], 4, "hierro2")
    m.torno(T(*(c + V((0, 0, 1.5)))), [(1.5, 0), (1.3, 0.3), (0.2, 1.0)], 4, "hierro", giro=math.pi / 4)
    m.torno(T(*(c - V((0, 0, 1.7)))), [(0.5, -0.3), (1.3, 0), (1.3, 0.3)], 4, "hierro", giro=math.pi / 4)
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        p = c + V((math.cos(a), math.sin(a), 0)) * 1.15
        m.caja(T(*p), (0.22, 0.22, 3.1), "hierro2")
    b.esfera(T(*c), 1.0, "cian", 1, escala=(1, 1, 1.35))
    return {"malla": m, "brillo": b, "efecto": "luz", "colorLuz": AZUL_FANTASMA, "llama": tuple(c), "colorBrillo": AZUL_FANTASMA}


def arbol(semilla=5):
    m = Malla(semilla)
    r = m.rnd

    def rama(p, d, largo, radio, nivel):
        pts, rad = [p], [radio]
        for i in range(1, 5):
            d = (d + V((r.uniform(-0.35, 0.35), r.uniform(-0.35, 0.35), r.uniform(-0.1, 0.25)))).normalized()
            pts.append(pts[-1] + d * largo / 4)
            rad.append(radio * (1 - i / 5.2))
        m.tubo(pts, rad, 7 if nivel == 0 else 5, "seco" if nivel < 2 else "seco3")
        if nivel < 2:
            for k in range(3 if nivel == 0 else 2):
                i = r.randint(2, 4)
                a = r.uniform(0, 2 * math.pi)
                nd = (d * 0.5 + V((math.cos(a), math.sin(a), 0.45))).normalized()
                rama(pts[i], nd, largo * 0.55, rad[i] * 0.7, nivel + 1)

    rama(V((0, 0, -0.5)), V((0.1, 0.05, 1)).normalized(), 24, 2.4, 0)
    for k in range(5):
        a = 2 * math.pi * k / 5 + r.uniform(-0.3, 0.3)
        d = V((math.cos(a), math.sin(a), 0))
        m.tubo([V((0, 0, 2.4)), d * 2.6 + V((0, 0, 0.8)), d * 4.8 + V((0, 0, -0.5))], [1.2, 0.8, 0.3], 5, "seco2")
    m.roca(T(), 4.2, "arena2", 1, 0.25, 3, (1, 1, 0.25))
    return {"malla": m}


def ataud(semilla=6):
    m, b = Malla(semilla), Malla(semilla + 1)
    cont = [(0, -6), (2.2, -4.2), (1.6, 6), (-1.6, 6), (-2.2, -4.2)]
    G = girar("Z", 0.3)
    m.placa(G @ T(0, 0, 1.0) @ girar("X", math.pi / 2), cont, 2.0, "madera2", "madera")
    b.placa(G @ T(0, 0, 2.03) @ girar("X", math.pi / 2), [(x * 0.8, z * 0.88) for x, z in cont], 0.08, "verde")
    F = G @ T(1.5, 0.6, 2.6) @ girar("Z", 0.35) @ girar("Y", 0.14)
    m.placa(F @ girar("X", math.pi / 2), [(x * 1.05, z * 1.02) for x, z in cont], 0.5, "madera3", "madera2")
    m.caja(F @ T(0, 1.6, 0.32), (0.5, 4.2, 0.18), "oro2")
    m.caja(F @ T(0, 2.6, 0.32), (2.4, 0.5, 0.18), "oro2")
    m.roca(T(), 5.2, "arena2", 1, 0.2, 2, (0.8, 1.4, 0.22))
    return {"malla": m, "brillo": b, "efecto": "luz", "colorLuz": (130, 255, 150), "llama": (0, 0, 3), "colorBrillo": (130, 255, 150)}


PROPS = [
    ("Calabaza", lambda: calabaza()),
    ("Lapida", lambda: lapida(2, False)),
    ("LapidaCruz", lambda: lapida(7, True)),
    ("BarcoHundido", lambda: barco()),
    ("FarolFantasma", lambda: farol()),
    ("ArbolSeco", lambda: arbol()),
    ("Ataud", lambda: ataud()),
]

# Distribución inicial (Config/Habitats): ángulo en grados desde +X del cráter (x = cos, z = sin),
# radio en studs; giro: grados extra sobre "el frente mira hacia afuera, a los jugadores del borde".
# Radio 158-178: repisa bajo el agua (props medianos). Radio 194-197: ladera del acantilado,
# junto al camino del borde (props altos y finos que se ven de cerca).
SUGERIDO = [
    {"prop": "BarcoHundido", "angulo": 205, "radio": 168, "escala": 1.8, "giro": 75},
    {"prop": "Calabaza", "angulo": 20, "radio": 168, "escala": 2.4, "giro": 0},
    {"prop": "Calabaza", "angulo": 120, "radio": 170, "escala": 1.8, "giro": 20},
    {"prop": "Calabaza", "angulo": 300, "radio": 165, "escala": 2.0, "giro": -20},
    {"prop": "Calabaza", "angulo": 245, "radio": 175, "escala": 1.5, "giro": 0},
    {"prop": "Lapida", "angulo": 95, "radio": 160, "escala": 2.4, "giro": -5},
    {"prop": "LapidaCruz", "angulo": 103, "radio": 168, "escala": 2.2, "giro": 10},
    {"prop": "Lapida", "angulo": 110, "radio": 158, "escala": 2.0, "giro": 15},
    {"prop": "Lapida", "angulo": 280, "radio": 162, "escala": 2.2, "giro": -10},
    {"prop": "LapidaCruz", "angulo": 140, "radio": 160, "escala": 2.4, "giro": 5},
    {"prop": "LapidaCruz", "angulo": 330, "radio": 165, "escala": 2.0, "giro": 0},
    {"prop": "Ataud", "angulo": 345, "radio": 160, "escala": 2.2, "giro": 30},
    {"prop": "Ataud", "angulo": 175, "radio": 165, "escala": 2.0, "giro": -40},
    {"prop": "ArbolSeco", "angulo": 70, "radio": 196, "escala": 2.2, "giro": 0},
    {"prop": "ArbolSeco", "angulo": 255, "radio": 196, "escala": 2.0, "giro": -90},
    {"prop": "ArbolSeco", "angulo": 150, "radio": 196, "escala": 1.8, "giro": 40},
    {"prop": "FarolFantasma", "angulo": 45, "radio": 197, "escala": 2.2, "giro": 0},
    {"prop": "FarolFantasma", "angulo": 165, "radio": 197, "escala": 2.2, "giro": 0},
    {"prop": "FarolFantasma", "angulo": 330, "radio": 197, "escala": 2.2, "giro": 0},
    {"prop": "FarolFantasma", "angulo": 280, "radio": 197, "escala": 2.2, "giro": 0},
]
