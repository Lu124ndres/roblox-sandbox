r"""
Hábitat del Minotauro: laberinto minoico en ruinas.
Columna, ColumnaRota, Muro (franja roja con greca de oro), Arco (clave con cabeza de toro),
Brasero (fuego), CraneoToro y Estandarte (labrys de oro).
"""
import math
from mathutils import Vector as V
from habitats import Malla, T, girar

FUEGO = (255, 150, 50)
LABRYS = [(-0.35, -3.2), (0.35, -3.2), (0.35, -0.7), (1.0, -1.6), (2.6, -2.2), (2.2, 0), (2.6, 2.2), (1.0, 1.6),
          (0.35, 0.7), (0.35, 3.0), (0, 3.4), (-0.35, 3.0), (-0.35, 0.7), (-1.0, 1.6), (-2.6, 2.2), (-2.2, 0),
          (-2.6, -2.2), (-1.0, -1.6), (-0.35, -0.7)]


def fuste(m, z0, z1, radio, estrias=20, roto=False):
    """Fuste estriado (columna minoica: más ancha arriba)."""
    rings = []
    pasos = 5
    for i in range(pasos + 1):
        t = i / pasos
        z = z0 + (z1 - z0) * t
        r = radio * (0.86 + 0.14 * t)
        ring = []
        for k in range(estrias * 2):
            a = math.pi * k / estrias
            rr = r * (0.9 if k % 2 else 1.0)
            zz = z + (m.rnd.uniform(-1.6, 1.2) if roto and i == pasos else 0)
            ring.append(m.v(V((math.cos(a) * rr, math.sin(a) * rr, zz))))
        rings.append(ring)
    for i in range(pasos):
        m.unir(rings[i], rings[i + 1], lambda k: "marmol" if k % 2 else "marmol2")
    m.tapa(rings[-1], "marmol3" if roto else "marmol")
    return rings[-1]


def hiedra(m, alto, radio, vueltas=1.3, fase=0.0):
    pts = [V((math.cos(fase + 2 * math.pi * vueltas * t) * radio, math.sin(fase + 2 * math.pi * vueltas * t) * radio,
              0.5 + alto * t)) for t in [i / 10 for i in range(11)]]
    m.tubo(pts, [0.35] * 11, 4, "musgo2")
    for p in pts[1::2]:
        m.esfera(T(*(p * 1.04)), 0.9, "hiedra", 0, 0.2)


def columna(semilla=11, alto=30.0, rota=False):
    m = Malla(semilla)
    r = m.rnd
    m.caja(T(0, 0, 1.0), (9.0, 9.0, 2.0), "piedra2", bisel=0.15)
    m.torno(T(0, 0, 2.0), [(3.9, 0), (4.1, 0.6), (3.7, 1.3), (3.5, 1.6)], 20, "marmol2")
    if rota:
        fuste(m, 3.6, alto * 0.45, 3.4, roto=True)
        for k, (x, y, rr) in enumerate(((7, 3, 0.3), (-6, -6, 1.1))):
            M = T(x, y, 3.2) @ girar("Z", rr) @ girar("X", math.pi / 2)
            m.torno(M @ T(0, 0, -3.2), [(3.3, 0), (3.5, 6.4)], 20, lambda i, kk: "marmol2" if kk % 2 else "marmol")
        for k in range(7):
            a = r.uniform(0, 2 * math.pi)
            m.roca(T(math.cos(a) * r.uniform(4, 9), math.sin(a) * r.uniform(4, 9), 0.4), r.uniform(0.8, 1.6), "marmol3", 0, 0.3, k)
        hiedra(m, alto * 0.4, 3.6, 0.9)
    else:
        fuste(m, 3.6, alto - 4.2, 3.4)
        m.torno(T(0, 0, alto - 4.2), [(3.5, 0), (4.6, 1.0), (5.0, 1.8), (4.8, 2.4)], 20, "rojo", liso=True)
        m.caja(T(0, 0, alto - 0.9), (10.4, 10.4, 1.8), {"+z": "piedra3", "resto": "piedra"})
        m.caja(T(0, 0, alto - 1.9), (10.8, 10.8, 0.5), "oro2")
        hiedra(m, alto * 0.7, 3.5, 1.4, r.uniform(0, 6))
    for k in range(5):
        a = r.uniform(0, 2 * math.pi)
        m.roca(T(math.cos(a) * 5, math.sin(a) * 5, 0.5), r.uniform(0.9, 1.5), "musgo", 0, 0.3, k)
    return {"malla": m, "colision": True}


def muro(semilla=12, largo=32.0, alto=16.0, grueso=4.0):
    m = Malla(semilla)
    r = m.rnd
    hiladas = 6
    h = alto / hiladas
    for i in range(hiladas):
        x = -largo / 2 + (0 if i % 2 else -2.0)
        corte = largo / 2 - (i - 2) * 3.5 if i >= 3 else largo / 2  # extremo derecho derrumbado
        while x < corte - 0.5:
            w = min(r.uniform(4.2, 6.4), corte - x)
            if x + w > -largo / 2 + 0.5:
                x0 = max(x, -largo / 2)
                col = r.choice(("piedra", "piedra", "piedra2", "piedra3"))
                m.caja(T((x0 + x + w) / 2, 0, h * i + h / 2), ((x + w - x0) - 0.25, grueso, h - 0.25), col, bisel=0.12)
            x += w
    # franja roja con greca de oro al frente (+Y) en la 4.ª hilada
    zf = h * 3.5
    banda_largo = largo - 8
    m.caja(T(-4, grueso / 2 + 0.1, zf), (banda_largo, 0.3, h * 0.8), "rojo2")
    paso = 2.4
    n = int(banda_largo / paso)
    for k in range(n):
        x = -4 - banda_largo / 2 + paso * (k + 0.5)
        y = grueso / 2 + 0.3
        s = h * 0.62
        m.caja(T(x, y, zf - s / 2), (paso, 0.2, 0.32), "oro")
        m.caja(T(x - paso / 2 + 0.16, y, zf), (0.32, 0.2, s), "oro")
        m.caja(T(x - paso * 0.1, y, zf + s / 2), (paso * 0.8, 0.2, 0.32), "oro")
        m.caja(T(x + paso * 0.3, y, zf + s * 0.1), (0.32, 0.2, s * 0.8), "oro")
    # piedras caídas y musgo
    for k in range(8):
        m.caja(T(largo / 2 + r.uniform(-3, 5), r.uniform(-5, 5), 1.0) @ girar("Z", r.uniform(0, 3)) @ girar("X", r.uniform(-0.3, 0.3)),
               (r.uniform(3, 5), r.uniform(2.5, 4), r.uniform(1.8, 2.6)), r.choice(("piedra", "piedra2")), bisel=0.2)
    for k in range(10):
        m.roca(T(r.uniform(-largo / 2, largo / 2), r.choice((-1, 1)) * grueso / 2, r.uniform(0, alto * 0.5)), r.uniform(0.7, 1.4), "musgo", 0, 0.3, k)
    return {"malla": m, "colision": True}


def arco(semilla=13, ancho=22.0, alto_pilar=16.0):
    m = Malla(semilla)
    r = m.rnd
    half = ancho / 2
    for s in (-1, 1):
        for i in range(5):
            h = alto_pilar / 5
            m.caja(T(s * (half - 2.5), 0, h * i + h / 2), (5.0 - 0.2, 5.0, h - 0.2), r.choice(("piedra", "piedra2", "piedra3")), bisel=0.1)
        m.caja(T(s * (half - 2.5), 0, alto_pilar + 0.4), (6.0, 6.0, 0.8), "piedra3")
    radio = half - 2.5
    n = 11
    zc = alto_pilar + 0.8
    for k in range(n):
        a0, a1 = math.pi * k / n + 0.012, math.pi * (k + 1) / n - 0.012
        clave = k == n // 2
        ri, ro = radio - 2.5, radio + (3.2 if clave else 2.5)
        fondo = 2.8 if clave else 2.5
        col = "oro2" if clave else r.choice(("piedra", "piedra3", "piedra"))
        vs = {}
        for i, a in enumerate((a0, a1)):
            for j, rr in enumerate((ri, ro)):
                for l, y in enumerate((-fondo, fondo)):
                    vs[i, j, l] = m.v(V((math.cos(a) * rr, y, zc + math.sin(a) * rr)))
        for cara in (((0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)), ((0, 0, 1), (0, 1, 1), (1, 1, 1), (1, 0, 1)),
                     ((0, 0, 0), (0, 1, 0), (0, 1, 1), (0, 0, 1)), ((1, 0, 0), (1, 0, 1), (1, 1, 1), (1, 1, 0)),
                     ((0, 0, 0), (0, 0, 1), (1, 0, 1), (1, 0, 0)), ((0, 1, 0), (1, 1, 0), (1, 1, 1), (0, 1, 1))):
            m.cara([vs[c] for c in cara], col)
    # cabeza de toro de oro en la clave (frente +Y)
    top = V((0, 3.4, alto_pilar + 0.8 + radio + 0.6))
    m.esfera(T(*top), 1.6, "oro", 1, escala=(1, 0.7, 1.15))
    m.caja(T(*(top + V((0, 0.4, -1.4)))), (1.8, 1.2, 1.4), "oro")
    for s in (-1, 1):
        m.tubo([top + V((s * 1.2, 0, 0.7)), top + V((s * 2.8, 0.2, 1.0)), top + V((s * 3.4, 0.3, 2.6))], [0.55, 0.4, 0.15], 5, "oro2")
    for k in range(6):
        m.roca(T(r.uniform(-half, half), r.uniform(-4, 4), 0.3), r.uniform(0.7, 1.3), "musgo", 0, 0.3, k)
    return {"malla": m, "colision": True}


def brasero(semilla=14):
    m, b = Malla(semilla), Malla(semilla + 1)
    for k in range(3):
        a = 2 * math.pi * k / 3
        d = V((math.cos(a), math.sin(a), 0))
        m.tubo([d * 3.0, d * 2.2 + V((0, 0, 3.5)), d * 1.6 + V((0, 0, 6.2))], [0.4, 0.35, 0.35], 5, "oro2")
        m.esfera(T(*(d * 3.0 + V((0, 0, 0.3)))), 0.6, "oro2", 0)
    m.torno(T(0, 0, 5.6), [(1.2, 0), (3.6, 1.2), (4.4, 2.6), (4.6, 3.0), (4.0, 3.0)], 12, "oro", liso=True, base=True)
    for k in range(9):
        a = m.rnd.uniform(0, 2 * math.pi)
        rr = m.rnd.uniform(0, 2.8)
        m.roca(T(math.cos(a) * rr, math.sin(a) * rr, 8.3), m.rnd.uniform(0.6, 1.0), "carbon", 0, 0.3, k)
    for k, (x, y, h, rad) in enumerate(((0, 0, 5.5, 1.6), (1.4, 0.6, 3.8, 1.1), (-1.2, -0.8, 4.2, 1.2), (0.4, -1.4, 3.0, 0.9))):
        b.torno(T(x, y, 8.4), [(rad, 0), (rad * 0.8, h * 0.4)], 6, "fuego", punta=h, giro=k)
    return {"malla": m, "brillo": b, "efecto": "fuego", "colorLuz": FUEGO, "llama": (0, 0, 9.5), "colorBrillo": (255, 140, 40)}


def craneo(semilla=15):
    m = Malla(semilla)
    M = T(0, 0, 2.6) @ girar("X", -0.25) @ girar("Y", 0.15)
    m.esfera(M @ T(0, -1, 2.2), 3.8, "hueso", 1, 0.08, escala=(1, 1.05, 0.9))
    m.torno(M @ T(0, 1.6, 1.6) @ girar("X", -math.pi / 2), [(2.6, 0), (2.4, 3.0), (1.9, 5.8), (1.6, 6.6)], 8, "hueso2")
    for s in (-1, 1):
        m.esfera(M @ T(s * 1.9, 2.2, 3.3), 1.05, "negro", 0)
        m.esfera(M @ T(s * 0.7, 8.0, 1.3), 0.45, "negro", 0)
        m.tubo([M @ V((s * 3.0, -1.4, 3.6)), M @ V((s * 6.0, -1.0, 4.6)), M @ V((s * 8.4, 0.6, 7.0)), M @ V((s * 8.8, 2.4, 9.4))],
               [1.15, 0.9, 0.6, 0.15], 7, lambda i: "cuerno" if i < 2 else "hueso3")
    aro = [M @ V((1.0 * math.cos(a), 8.3, 0.4 + 1.0 * math.sin(a))) for a in [2 * math.pi * k / 10 for k in range(11)]]
    m.tubo(aro, [0.22] * 11, 5, "oro")
    for k in range(5):
        m.roca(T(m.rnd.uniform(-5, 5), m.rnd.uniform(-5, 6), 0), m.rnd.uniform(1, 2), "arena2", 0, 0.3, k, (1, 1, 0.5))
    return {"malla": m}


def estandarte(semilla=16, alto=30.0):
    m = Malla(semilla)
    m.torno(T(), [(2.4, 0), (2.2, 1.0), (1.2, 1.4)], 8, "piedra2")
    m.tubo([V((0, 0, 1)), V((0, 0, alto))], [0.55, 0.45], 8, "madera2")
    m.esfera(T(0, 0, alto + 0.6), 0.9, "oro", 1)
    m.tubo([V((-5, 0, alto - 1.6)), V((5, 0, alto - 1.6))], [0.35, 0.35], 6, "madera2")
    for s in (-1, 1):
        m.esfera(T(s * 5.2, 0, alto - 1.6), 0.55, "oro", 0)
    largo = alto * 0.55
    tela = [(-4.4, 0), (4.4, 0), (4.6, -largo * 0.8), (2.4, -largo * 0.7), (0, -largo), (-2.4, -largo * 0.7),
            (-4.6, -largo * 0.8)]
    M = T(0, 0.75, alto - 1.9)
    m.placa(M, tela, 0.25, "rojo", "rojo2")
    m.placa(M @ T(0, 0.2, -largo * 0.42) @ girar("Y", math.pi / 2) @ girar("Y", -math.pi / 2), [(x * 1.1, z * 1.1) for x, z in LABRYS], 0.18, "oro")
    for z in (-0.8, -largo * 0.62):
        m.caja(M @ T(0, 0.2, z), (8.4, 0.18, 0.45), "oro2")
    return {"malla": m}


PROPS = [
    ("Columna", lambda: columna()),
    ("ColumnaRota", lambda: columna(17, rota=True)),
    ("Muro", lambda: muro()),
    ("Arco", lambda: arco()),
    ("Brasero", lambda: brasero()),
    ("CraneoToro", lambda: craneo()),
    ("Estandarte", lambda: estandarte()),
]

# Distribución inicial (Config/Habitats): ángulo en grados desde +X del cráter (x = cos, z = sin),
# radio en studs; giro: grados extra sobre "el frente mira hacia afuera, a los jugadores del borde".
# Radio 158-178: repisa bajo el agua (props medianos). Radio 194-197: ladera del acantilado,
# junto al camino del borde (props altos y finos que se ven de cerca).
SUGERIDO = [
    {"prop": "Arco", "angulo": 90, "radio": 168, "escala": 2.2, "giro": 0},
    {"prop": "Muro", "angulo": 30, "radio": 165, "escala": 1.8, "giro": 10},
    {"prop": "Muro", "angulo": 150, "radio": 165, "escala": 1.8, "giro": -10},
    {"prop": "Muro", "angulo": 250, "radio": 162, "escala": 1.7, "giro": -20},
    {"prop": "ColumnaRota", "angulo": 300, "radio": 168, "escala": 2.0, "giro": 40},
    {"prop": "ColumnaRota", "angulo": 340, "radio": 160, "escala": 1.8, "giro": -20},
    {"prop": "ColumnaRota", "angulo": 200, "radio": 165, "escala": 1.8, "giro": 0},
    {"prop": "CraneoToro", "angulo": 270, "radio": 160, "escala": 2.4, "giro": 20},
    {"prop": "Brasero", "angulo": 80, "radio": 180, "escala": 2.4, "giro": 0},
    {"prop": "Brasero", "angulo": 100, "radio": 180, "escala": 2.4, "giro": 0},
    {"prop": "Columna", "angulo": 65, "radio": 196, "escala": 1.8, "giro": 0},
    {"prop": "Columna", "angulo": 115, "radio": 196, "escala": 1.8, "giro": 0},
    {"prop": "Columna", "angulo": 200, "radio": 196, "escala": 1.9, "giro": 0},
    {"prop": "Columna", "angulo": 320, "radio": 196, "escala": 1.8, "giro": 0},
    {"prop": "Estandarte", "angulo": 10, "radio": 197, "escala": 2.0, "giro": 0},
    {"prop": "Estandarte", "angulo": 180, "radio": 197, "escala": 2.0, "giro": 0},
    {"prop": "Estandarte", "angulo": 230, "radio": 197, "escala": 1.8, "giro": 0},
    {"prop": "Brasero", "angulo": 225, "radio": 196, "escala": 2.2, "giro": 0},
    {"prop": "Brasero", "angulo": 315, "radio": 196, "escala": 2.2, "giro": 0},
]
