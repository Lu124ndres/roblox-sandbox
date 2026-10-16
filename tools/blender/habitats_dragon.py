r"""
Hábitat del Dragón marino: nido volcánico.
Obsidiana (agujas negras con vetas de lava), CristalLava (cristales que brillan),
Nido (con huevos de dragón), Costillar (esqueleto gigante) y Fumarola (fuego).
"""
import math
from mathutils import Vector as V, noise
from habitats import Malla, T, girar

LAVA = (255, 110, 40)


def aguja(m, M, alto, radio, colores=("obsidiana", "obsidiana2"), lados=5):
    m.torno(M, [(radio, 0), (radio * 0.8, alto * 0.45), (radio * 0.45, alto * 0.8)], lados,
            lambda i, k: colores[(i + k) % 2], punta=alto, giro=m.rnd.uniform(0, 1))


def obsidiana(semilla=31):
    m, b = Malla(semilla), Malla(semilla + 1)
    r = m.rnd
    agujas = [(0, 0, 26, 4.2), (5, 2, 17, 3.0), (-4.5, 2.5, 19, 3.2), (2, -4.5, 13, 2.6), (-3, -4, 10, 2.2), (6, -3, 8, 1.8)]
    for x, y, h, rad in agujas:
        inclina = V((x, y, 0)).normalized() * 0.18 if (x or y) else V((0, 0, 0))
        M = T(x, y, -0.5) @ girar("X", -inclina.y) @ girar("Y", inclina.x)
        aguja(m, M, h, rad, lados=5)
        # veta de lava subiendo por la aguja
        a = r.uniform(0, 2 * math.pi)
        pts = [M @ V((math.cos(a + t * 0.8) * rad * (0.98 - 0.5 * t), math.sin(a + t * 0.8) * rad * (0.98 - 0.5 * t), h * 0.75 * t))
               for t in [i / 5 for i in range(6)]]
        b.tubo(pts, [0.45 * (1 - i / 7) for i in range(6)], 4, "lava")
    b.torno(T(0, 0, 0), [(9.5, 0.05), (9.5, 0.25)], 14, "lava2", base=False)  # charco de lava al pie
    for k in range(10):
        a = 2 * math.pi * k / 10 + r.uniform(-0.2, 0.2)
        m.roca(T(math.cos(a) * 9.5, math.sin(a) * 9.5, 0.2), r.uniform(1.6, 2.6), r.choice(("obsidiana", "obsidiana3")), 0, 0.35, k)
    return {"malla": m, "brillo": b, "efecto": "brillo", "colorLuz": LAVA, "llama": (0, 0, 3), "colorBrillo": LAVA, "colision": True}


def cristal_lava(semilla=32):
    m, b = Malla(semilla), Malla(semilla + 1)
    r = m.rnd
    m.roca(T(), 7.0, "obsidiana", 1, 0.35, 3, (1, 1, 0.45))
    for k in range(9):
        a = 2 * math.pi * k / 9 + r.uniform(-0.2, 0.2)
        d = 0 if k == 0 else r.uniform(2, 5)
        h = 18 if k == 0 else r.uniform(6, 13)
        M = T(math.cos(a) * d, math.sin(a) * d, 1.5) @ girar("X", math.sin(a) * -0.45 * (d > 0)) @ girar("Y", math.cos(a) * 0.45 * (d > 0))
        b.torno(M, [(1.4 if k else 2.4, 0), (1.4 if k else 2.4, h * 0.78)], 6,
                lambda i, kk: "cristal" if kk % 2 else "cristal2", punta=h, giro=r.uniform(0, 1))
    return {"malla": m, "brillo": b, "efecto": "luz", "colorLuz": (255, 90, 60), "llama": (0, 0, 9), "colorBrillo": (255, 100, 60)}


def nido(semilla=33):
    m = Malla(semilla)
    r = m.rnd
    m.torno(T(), [(10.5, 0), (11.2, 2.4), (10.0, 4.6), (8.2, 5.0), (6.6, 3.0), (4.0, 1.4), (0.5, 1.0)], 20,
            lambda i, k: "nido" if (i + k) % 3 else "nido2", ruido=0.08)
    for k in range(26):  # ramas y huesitos
        a = r.uniform(0, 2 * math.pi)
        p = V((math.cos(a) * 9.4, math.sin(a) * 9.4, r.uniform(3.2, 5.2)))
        d = V((-math.sin(a), math.cos(a), r.uniform(-0.2, 0.2))) * r.uniform(3, 6)
        m.tubo([p - d, p + d], [0.35, 0.3], 4, r.choice(("madera2", "nido2", "hueso2")))
    for k, (x, y, h, giro) in enumerate(((0, 0, 7.4, 0), (3.6, 2.2, 6.0, 0.4), (-3.4, 2.4, 6.4, -0.3), (0.6, -3.8, 5.6, 0.2))):
        def manchas(f, s=k):
            c = f.calc_center_median()
            n = noise.noise(c * 0.9 + V((s * 3, 0, 0)))
            return "huevo2" if n > 0.25 else ("huevo3" if n < -0.45 else "huevo")
        m.esfera(T(x, y, 1.2 + h * 0.48) @ girar("Y", giro), h * 0.48, manchas, 2, 0.02, k, liso=True, escala=(0.78, 0.78, 1))
    return {"malla": m, "colision": True}


def costillar(semilla=34, largo=42.0):
    m = Malla(semilla)
    r = m.rnd
    espina = [V((0, -largo / 2 + largo * t, 1.4 + 9.5 * math.sin(math.pi * t) + (2.5 if t > 0.92 else 0))) for t in [i / 12 for i in range(13)]]
    m.tubo(espina, [1.1 + 0.6 * math.sin(math.pi * i / 12) for i in range(13)], 7, "hueso2")
    for i, p in enumerate(espina[:-1]):
        m.torno(T(*p) @ girar("X", math.pi / 2) @ T(0, 0, -0.9), [(1.8, 0), (1.8, 1.8)], 7, "hueso", base=True)
        m.torno(T(*p), [(0.6, 0), (0.3, 3.2)], 4, "hueso3", punta=3.6)
    for i in range(2, 11):
        t = i / 12
        p = espina[i]
        alto = 16 * math.sin(math.pi * (0.15 + 0.85 * t)) + 4
        for s in (-1, 1):
            ancho = 4 + 6 * math.sin(math.pi * t)
            pts = [V((s * (0.6 + ancho * math.sin(math.pi * u / 2)), p.y + 1.2 * u,
                      max(0.3, p.z * (1 - u) + 4.5 * math.sin(math.pi * u) * (1 - 0.3 * u)))) for u in [j / 7 for j in range(8)]]
            m.tubo(pts, [0.85 - 0.07 * j for j in range(8)], 6, lambda j: "hueso" if j < 5 else "hueso2")
    # cráneo del dragón al frente (+Y), medio enterrado
    cab = espina[-1] + V((0, 5, -2.5))
    m.esfera(T(*cab), 4.0, "hueso", 1, 0.08, 2, escala=(1, 1.4, 0.75))
    m.torno(T(*(cab + V((0, 3.5, -0.6)))) @ girar("X", -math.pi / 2), [(2.6, 0), (2.0, 5.0), (1.2, 7.0)], 6, "hueso2")
    for s in (-1, 1):
        m.esfera(T(*(cab + V((s * 2.2, 1.6, 1.0)))), 1.1, "negro", 0)
        m.tubo([cab + V((s * 2.2, -2, 2)), cab + V((s * 3.6, -5.5, 4.5)), cab + V((s * 3.2, -9, 5.4))], [0.8, 0.5, 0.12], 5, "cuerno")
        for k in range(4):
            m.torno(T(*(cab + V((s * 1.6, 4.5 + k * 1.5, -1.6)))) @ girar("X", math.pi), [(0.35, 0), (0.05, 1.2)], 4, "hueso", punta=None)
    for k in range(8):
        m.roca(T(r.uniform(-9, 9), r.uniform(-largo / 2, largo / 2), 0), r.uniform(2, 3.5), "ceniza", 0, 0.3, k, (1, 1, 0.4))
    return {"malla": m, "colision": True}


def fumarola(semilla=35):
    m, b = Malla(semilla), Malla(semilla + 1)
    m.torno(T(), [(9, 0), (7.4, 2.4), (5.2, 6.0), (3.6, 9.0), (3.2, 10.0), (2.4, 9.4)], 12,
            lambda i, k: "ceniza" if (i + k) % 2 else "ceniza2", ruido=0.08)
    b.torno(T(0, 0, 9.3), [(2.6, 0), (2.6, 0.3)], 10, "lava", base=True)
    for k in range(5):  # chorreadas de lava por la ladera
        a = 2 * math.pi * k / 5 + 0.3
        pts = [V((math.cos(a) * rr, math.sin(a) * rr, z)) for rr, z in ((3.3, 9.6), (4.6, 7.4), (6.0, 4.6), (7.8, 1.6), (8.8, 0.2))]
        b.tubo(pts, [0.7, 0.65, 0.55, 0.45, 0.3], 4, "lava2" if k % 2 else "lava")
    for k in range(6):
        a = 2 * math.pi * k / 6
        m.roca(T(math.cos(a) * 10, math.sin(a) * 10, 0.2), m.rnd.uniform(1.4, 2.4), "obsidiana", 0, 0.35, k)
    return {"malla": m, "brillo": b, "efecto": "fuego", "colorLuz": LAVA, "llama": (0, 0, 10.5), "colorBrillo": LAVA}


PROPS = [
    ("Obsidiana", lambda: obsidiana()),
    ("CristalLava", lambda: cristal_lava()),
    ("Nido", lambda: nido()),
    ("Costillar", lambda: costillar()),
    ("Fumarola", lambda: fumarola()),
]

# Distribución inicial (Config/Habitats): ángulo en grados desde +X del cráter (x = cos, z = sin),
# radio en studs; giro: grados extra sobre "el frente mira hacia afuera, a los jugadores del borde".
# Radio 158-178: repisa bajo el agua (props medianos). Radio 194-197: ladera del acantilado,
# junto al camino del borde (props altos y finos que se ven de cerca).
SUGERIDO = [
    {"prop": "Nido", "angulo": 90, "radio": 164, "escala": 2.4, "giro": 0},
    {"prop": "Costillar", "angulo": 240, "radio": 168, "escala": 1.8, "giro": 95},
    {"prop": "Obsidiana", "angulo": 30, "radio": 170, "escala": 2.0, "giro": 0},
    {"prop": "Obsidiana", "angulo": 150, "radio": 172, "escala": 1.8, "giro": 70},
    {"prop": "Obsidiana", "angulo": 310, "radio": 168, "escala": 2.2, "giro": -40},
    {"prop": "Fumarola", "angulo": 0, "radio": 160, "escala": 2.2, "giro": 0},
    {"prop": "Fumarola", "angulo": 180, "radio": 158, "escala": 2.0, "giro": 0},
    {"prop": "Fumarola", "angulo": 275, "radio": 172, "escala": 1.8, "giro": 0},
    {"prop": "CristalLava", "angulo": 60, "radio": 196, "escala": 2.2, "giro": 0},
    {"prop": "CristalLava", "angulo": 120, "radio": 196, "escala": 2.0, "giro": 0},
    {"prop": "CristalLava", "angulo": 200, "radio": 196, "escala": 2.2, "giro": 0},
    {"prop": "CristalLava", "angulo": 345, "radio": 196, "escala": 2.0, "giro": 0},
    {"prop": "CristalLava", "angulo": 280, "radio": 196, "escala": 1.8, "giro": 0},
]
