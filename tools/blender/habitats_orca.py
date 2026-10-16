r"""
Hábitat de la Orca: arrecife de coral.
CoralRama, CoralCerebro, CoralAbanico, Alga (bosque de kelp), Almeja (perla que brilla)
y RocaPercebes (percebes, estrellas y anémonas).
"""
import math
from mathutils import Vector as V, noise
from habitats import Malla, T, girar

ESTRELLA = [(math.cos(math.pi * k / 5 + math.pi / 2) * (2.0 if k % 2 == 0 else 0.8),
             math.sin(math.pi * k / 5 + math.pi / 2) * (2.0 if k % 2 == 0 else 0.8)) for k in range(10)]


def coral_rama(semilla=21, color=("coral", "coral2", "coral3"), alto=20.0):
    m = Malla(semilla)
    r = m.rnd

    def rama(p, d, largo, radio, nivel):
        pts, rad = [p], [radio]
        for i in range(1, 4):
            d = (d + V((r.uniform(-0.3, 0.3), r.uniform(-0.3, 0.3), 0.18))).normalized()
            pts.append(pts[-1] + d * largo / 3)
            rad.append(radio * (1 - i / 5))
        m.tubo(pts, rad, 6, lambda i: color[0] if i < 2 or nivel < 2 else color[2], liso=True)
        if nivel < 3:
            for k in range(2 if nivel else 3):
                a = r.uniform(0, 2 * math.pi) if nivel == 0 else r.uniform(-1, 1)
                if nivel == 0:
                    nd = V((math.cos(a) * 0.8, math.sin(a) * 0.8, 0.7)).normalized()
                else:
                    nd = (d + V((r.uniform(-0.7, 0.7), r.uniform(-0.7, 0.7), 0.2))).normalized()
                rama(pts[r.randint(1, 3)], nd, largo * 0.8, rad[2] * 0.95, nivel + 1)

    for k in range(3):
        a = 2 * math.pi * k / 3
        rama(V((math.cos(a) * 1.5, math.sin(a) * 1.5, 0)), V((math.cos(a) * 0.3, math.sin(a) * 0.3, 1)).normalized(), alto * 0.45, 1.6, 1 if k else 0)
    m.roca(T(), 4.0, "roca3", 1, 0.3, semilla, (1, 1, 0.45))
    return {"malla": m}


def coral_cerebro(semilla=22, R=7.0):
    m = Malla(semilla)

    def surco(f):
        c = f.calc_center_median()
        n = noise.noise(c * 0.55 + V((semilla, 0, 0)))
        return "cerebro2" if math.sin(n * 14 + c.z * 1.4) > 0.35 else "cerebro"

    m.esfera(T(0, 0, R * 0.25), R, surco, 3, 0.06, semilla, liso=True, escala=(1, 1, 0.68))
    m.roca(T(), R * 0.9, "roca3", 1, 0.3, 1, (1.1, 1.1, 0.3))
    return {"malla": m}


def abanico(semilla=23):
    m = Malla(semilla)
    for k, (giro, esc, col) in enumerate(((0.0, 1.0, ("morado", "morado2")), (0.7, 0.75, ("amarillo", "amarillo2")))):
        M = T(k * 3.5 - 1.5, k * -1.5, 0) @ girar("Z", giro)
        cont = [(0, 0)]
        for i in range(13):
            a = math.pi * (0.12 + 0.76 * i / 12)
            rr = 10 * esc * (0.9 + 0.1 * math.sin(i * 2.3))
            cont.append((math.cos(a) * rr, 1.5 + math.sin(a) * rr))
        m.placa(M, cont, 0.35, col[0], col[1])
        for i in range(7):  # nervaduras
            a = math.pi * (0.15 + 0.7 * i / 6)
            m.tubo([M @ V((0, 0.25, 0.8)), M @ V((math.cos(a) * 5 * esc, 0.3, 1.5 + math.sin(a) * 5 * esc)),
                    M @ V((math.cos(a) * 9.4 * esc, 0.25, 1.5 + math.sin(a) * 9.4 * esc))], [0.35, 0.25, 0.15], 4, col[1])
    m.roca(T(), 3.6, "roca3", 1, 0.3, 4, (1.2, 1, 0.45))
    return {"malla": m}


def alga(semilla=24, alto=34.0):
    m = Malla(semilla)
    r = m.rnd
    for k in range(5):
        a = 2 * math.pi * k / 5 + r.uniform(-0.4, 0.4)
        base = V((math.cos(a), math.sin(a), 0)) * r.uniform(0.8, 3.0)
        h = alto * r.uniform(0.6, 1.0)
        fase = r.uniform(0, 6)
        pts = [base + V((math.sin(fase + t * 5) * 1.6, math.cos(fase + t * 4) * 1.0, h * t)) for t in [i / 8 for i in range(9)]]
        m.tubo(pts, [0.45 - 0.03 * i for i in range(9)], 5, "alga2")
        for i in range(1, 9):
            lado = 1 if i % 2 else -1
            p = pts[i]
            hoja = [(0, 0), (1.4, 0.9), (3.6, 1.6), (5.2, 1.0), (3.8, 0.2), (1.6, -0.3)]
            M = T(*p) @ girar("Z", fase + i * 1.3) @ girar("Y", -0.5 * lado) @ girar("X", math.pi / 2 * 0)
            m.placa(M @ (girar("Y", math.pi) if lado < 0 else T()), hoja, 0.16, "alga" if i % 3 else "alga3")
        m.esfera(T(*(pts[-1])), 0.7, "alga3", 0)
    m.roca(T(), 3.8, "roca3", 1, 0.3, 7, (1, 1, 0.4))
    return {"malla": m}


def concha(m, M, R, color, color2, costillas=9):
    """Valva acanalada de almeja gigante: media cúpula en +Y con borde ondulado."""
    lat = 6
    pole = m.v(M @ V((0, 0, 0)))
    rings = []
    for i in range(1, lat + 1):
        t = i / lat
        ring = []
        for k in range(costillas * 2 + 1):
            a = math.pi * k / (costillas * 2)
            onda = 1 + (0.12 * t if k % 2 == 0 else -0.04)
            rr = R * t * onda
            ring.append(m.v(M @ V((math.cos(a) * rr, math.sin(a) * rr * 0.9, math.sin(t * math.pi / 2) * R * 0.45 * (1 - 0.3 * t)))))
        rings.append(ring)
    n = len(rings[0])
    for k in range(n - 1):
        m.cara((pole, rings[0][k], rings[0][k + 1]), color)
        for i in range(lat - 1):
            m.cara((rings[i][k], rings[i + 1][k], rings[i + 1][k + 1], rings[i][k + 1]), color if k % 2 else color2)
    return rings


def almeja(semilla=25, R=8.0):
    m, b = Malla(semilla), Malla(semilla + 1)
    concha(m, T(0, -R * 0.35, R * 0.48) @ girar("X", math.pi), R, "almeja", "almeja2")
    m.caja(T(0, 0.2, R * 0.48 + 0.1), (R * 1.9, R * 0.95, 0.3), "nacar")
    concha(m, T(0, -R * 0.35, R * 0.52) @ girar("X", -0.75), R, "almeja", "almeja2")
    m.placa(T(0, -R * 0.35, R * 0.52) @ girar("X", -0.75) @ T(0, 0, -0.15) @ girar("X", math.pi / 2),
            [(math.cos(math.pi * k / 12) * R * 0.95, math.sin(math.pi * k / 12) * R * 0.85) for k in range(13)], 0.2, "nacar")
    b.esfera(T(0, R * 0.05, R * 0.48 + 2.2), 2.1, "perla", 2, liso=True)
    m.roca(T(), R * 1.1, "arena2", 1, 0.25, 2, (1.1, 0.9, 0.25))
    return {"malla": m, "brillo": b, "efecto": "brillo", "colorLuz": (255, 230, 255), "llama": (0, R * 0.05, R * 0.48 + 2.2),
            "colorBrillo": (250, 238, 255)}


def roca_percebes(semilla=26):
    m = Malla(semilla)
    r = m.rnd
    centros = [V((0, 0, 3)), V((5, 2, 2)), V((-4, 3, 2.2)), V((1.5, -4, 1.8))]
    for k, c in enumerate(centros):
        m.roca(T(*c), [7, 4.5, 4, 3.6][k], "roca" if k % 2 else "roca3", 1, 0.35, k * 3, (1, 1, 0.75))
    for k in range(26):  # percebes
        a, h = r.uniform(0, 2 * math.pi), r.uniform(0.15, 0.85)
        c = centros[k % 4]
        rad = [7, 4.5, 4, 3.6][k % 4]
        n = V((math.cos(a) * math.cos(h), math.sin(a) * math.cos(h), math.sin(h) * 0.75)).normalized()
        p = c + V((n.x * rad * 0.95, n.y * rad * 0.95, n.z * rad * 0.7))
        rot = n.to_track_quat("Z", "Y").to_matrix().to_4x4()
        m.torno(T(*p) @ rot, [(0.7, -0.3), (0.55, 0.6), (0.25, 0.9)], 5, "percebe" if k % 3 else "percebe2", base=True)
    for k, (p, giro, col) in enumerate(((V((2.5, 5.4, 4.6)), 0.3, "estrella"), (V((-5.5, 1, 3.2)), 1.2, "azul"))):
        m.placa(T(*p) @ girar("Z", giro) @ girar("X", 0.9), ESTRELLA, 0.5, col, col if col != "estrella" else "estrella2")
    for k in range(6):  # anémona
        a = 2 * math.pi * k / 6
        base = V((-1.2, -2.4, 6.5))
        m.tubo([base, base + V((math.cos(a) * 1.0, math.sin(a) * 1.0, 1.6)), base + V((math.cos(a) * 1.6, math.sin(a) * 1.6, 2.4))],
               [0.32, 0.26, 0.18], 4, "turquesa", liso=True)
    return {"malla": m, "colision": True}


PROPS = [
    ("CoralRama", lambda: coral_rama()),
    ("CoralRamaNaranja", lambda: coral_rama(27, ("naranja", "naranja2", "amarillo"), 15.0)),
    ("CoralCerebro", lambda: coral_cerebro()),
    ("CoralAbanico", lambda: abanico()),
    ("Alga", lambda: alga()),
    ("Almeja", lambda: almeja()),
    ("RocaPercebes", lambda: roca_percebes()),
]

# Distribución inicial (Config/Habitats): ángulo en grados desde +X del cráter (x = cos, z = sin),
# radio en studs; giro: grados extra sobre "el frente mira hacia afuera, a los jugadores del borde".
# Radio 158-178: repisa bajo el agua (props medianos). Radio 194-197: ladera del acantilado,
# junto al camino del borde (props altos y finos que se ven de cerca).
SUGERIDO = [
    {"prop": "Almeja", "angulo": 90, "radio": 162, "escala": 2.6, "giro": 0},
    {"prop": "RocaPercebes", "angulo": 30, "radio": 168, "escala": 2.2, "giro": 0},
    {"prop": "RocaPercebes", "angulo": 215, "radio": 165, "escala": 2.4, "giro": -60},
    {"prop": "CoralRama", "angulo": 60, "radio": 165, "escala": 2.2, "giro": 0},
    {"prop": "CoralRama", "angulo": 170, "radio": 170, "escala": 2.0, "giro": -90},
    {"prop": "CoralRama", "angulo": 300, "radio": 160, "escala": 2.4, "giro": 20},
    {"prop": "CoralRamaNaranja", "angulo": 120, "radio": 160, "escala": 2.2, "giro": 40},
    {"prop": "CoralRamaNaranja", "angulo": 250, "radio": 172, "escala": 2.2, "giro": 10},
    {"prop": "CoralRamaNaranja", "angulo": 5, "radio": 160, "escala": 2.0, "giro": 0},
    {"prop": "CoralCerebro", "angulo": 140, "radio": 166, "escala": 2.2, "giro": 0},
    {"prop": "CoralCerebro", "angulo": 330, "radio": 170, "escala": 2.0, "giro": 0},
    {"prop": "CoralCerebro", "angulo": 200, "radio": 175, "escala": 1.8, "giro": 0},
    {"prop": "CoralAbanico", "angulo": 10, "radio": 178, "escala": 2.2, "giro": 0},
    {"prop": "CoralAbanico", "angulo": 195, "radio": 178, "escala": 2.0, "giro": 0},
    {"prop": "CoralAbanico", "angulo": 270, "radio": 175, "escala": 2.0, "giro": 0},
    {"prop": "Alga", "angulo": 45, "radio": 194, "escala": 2.0, "giro": 0},
    {"prop": "Alga", "angulo": 160, "radio": 194, "escala": 1.8, "giro": 70},
    {"prop": "Alga", "angulo": 275, "radio": 194, "escala": 2.0, "giro": -40},
    {"prop": "Alga", "angulo": 100, "radio": 194, "escala": 1.8, "giro": 0},
    {"prop": "Alga", "angulo": 340, "radio": 194, "escala": 1.9, "giro": 0},
]
