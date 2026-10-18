"""
Accesorios del Dios del Volcán v2 (sin la cara, que está en ..._cara.py): placas de obsidiana
sobre el cuerpo de magma (pectorales, abdominales, espalda, mangas, guanteletes, muslos y
grebas), corazón de cristal con su marco, púas en la columna, los guanteletes, los nudillos,
las rodillas y las botas, hombreras en capas con púas y gotas de lava, faldones con hebilla
de calavera, cuernos con relieve y corona de púas. Solo se llama desde Blender (mathutils).
"""
import math
import traje_v2_base as B
import traje_v2_dios_del_volcan_cara as CARA
from traje_v2_formas import pieza, placa, pua

GRIETAS = ("caja", "grietas")


def frente_pecho(c, n):
    return ("region", "pecho") if n.y < -0.6 else GRIETAS


def bordes(z0, z1, borde="hierro"):
    """Roca agrietada con los cantos de arriba y abajo de hierro."""
    return lambda c, n: ("paleta", borde) if (c.z < z0 or c.z > z1) else GRIETAS


def con_brasa(base, largo, color="roca_clara"):
    """Púa (girada) de roca con la punta encendida: por distancia a su base."""
    from mathutils import Vector

    b = Vector(base)
    return lambda c, n: ("paleta", "lava_clara" if (c - b).length > largo * 0.72 else color)


def puas(nombre, hueso, lista, color="roca_clara"):
    """Varias púas: (base, dirección, largo, grueso)."""
    out = []
    for i, (base, d, largo, grueso) in enumerate(lista):
        an, m = pua(base, d, largo, grueso)
        out.append(pieza(f"{nombre}{i}", an, hueso, con_brasa(base, largo, color), matriz=m))
    return out


def torso():
    out = [pieza("espalda", placa(2.55, 3.92, 0, 0.53, 1.70, 0.10, w1=1.86), "Pecho", GRIETAS),
           pieza("marco_corazon", placa(3.06, 3.74, 0, -0.565, 0.56, 0.08), "Pecho", "roca_oscura"),
           pieza("corazon", [(3.08, 0, -0.60, 0.06, 0.06, 0.02), (3.40, 0, -0.63, 0.36, 0.17, 0.06),
                             (3.72, 0, -0.60, 0.06, 0.06, 0.02)], "Pecho", "lava_clara"),
           pieza("faldon_frente", placa(1.62, 2.30, 0, -0.60, 0.80, 0.07, w1=0.88, cy1=-0.58), "Cadera",
                 bordes(1.70, 9, "lava")),
           pieza("faldon_atras", placa(1.62, 2.30, 0, 0.60, 0.80, 0.07, w1=0.88, cy1=0.58), "Cadera",
                 bordes(1.70, 9, "lava")),
           pieza("hebilla", placa(2.04, 2.34, 0, -0.60, 0.36, 0.12), "Cadera", "roca_clara")]
    for s in (1, -1):
        out += [pieza(f"pectoral{s}", placa(3.18, 3.94, s * 0.49, -0.53, 0.86, 0.12, w1=0.92), "Pecho", frente_pecho),
                pieza(f"ojo_hebilla{s}", placa(2.20, 2.26, s * 0.075, -0.665, 0.07, 0.03), "Cadera", "lava")]
        for i, (z0, z1) in enumerate(((2.52, 2.72), (2.77, 2.97), (3.02, 3.14))):
            out.append(pieza(f"abdominal{s}{i}", placa(z0, z1, s * 0.24, -0.53, 0.42, 0.10), "Pecho", frente_pecho))
    out += puas("columna", "Pecho", [((0, 0.57, z), (0, 1, 0.55), largo, 0.22)
                                     for z, largo in ((3.75, 0.5), (3.40, 0.45), (3.05, 0.38), (2.72, 0.3))])
    out += puas("marco", "Pecho", [((x, -0.58, z), (x * 2, -0.6, (z - 3.4) * 2), 0.2, 0.09)
                                   for x, z in ((0.22, 3.62), (-0.22, 3.62), (0.22, 3.18), (-0.22, 3.18))])
    return out


def brazos():
    out = []
    for s, lado in ((1, "Izq"), (-1, "Der")):
        cx, hombro = s * 1.6, "Brazo" + lado
        out += [pieza(f"hombrera{lado}", [(3.50, cx, 0, 1.36, 1.28, 0.2), (3.60, cx, 0, 1.36, 1.28, 0.2),
                                         (3.60, cx, 0, 1.30, 1.22, 0.22), (4.10, cx, 0, 1.30, 1.22, 0.30),
                                         (4.30, cx, 0, 1.16, 1.08, 0.30), (4.40, cx, 0, 0.90, 0.84, 0.25)],
                      hombro, bordes(3.61, 9)),
                pieza(f"lamina1{lado}", placa(3.36, 3.50, cx, 0, 1.28, 1.20), hombro, bordes(3.39, 3.47)),
                pieza(f"lamina2{lado}", placa(3.22, 3.36, cx, 0, 1.18, 1.10), hombro, bordes(3.25, 3.33)),
                pieza(f"manga{lado}", placa(3.0, 3.24, s * 1.52, 0, 1.04, 1.04), hombro, bordes(3.04, 3.20)),
                pieza(f"guantelete{lado}", placa(2.42, 2.80, s * 1.5, 0, 1.14, 1.14), "Codo" + lado, bordes(2.47, 2.75))]
        for j, (dy, dz) in enumerate(((-0.42, 3.5), (0.38, 3.5))):  # gotas de lava de la hombrera
            out.append(pieza(f"gota{lado}{j}", [(dz - 0.22, cx + s * 0.5, dy, 0.03, 0.03, 0.01),
                                                (dz - 0.08, cx + s * 0.5, dy, 0.09, 0.09, 0.04),
                                                (dz + 0.04, cx + s * 0.5, dy, 0.12, 0.12, 0.05)], hombro, "lava"))
        out += puas(f"pua_hombro{lado}", hombro, [((cx + s * 0.2, y, 4.22), (s * 0.6, 0, 1), largo, 0.26)
                                                  for y, largo in ((-0.36, 0.55), (0.0, 0.78), (0.36, 0.55))])
        out += puas(f"pua_guante{lado}", "Codo" + lado, [((s * 2.06, y, 2.62), (s, 0.45, 0.25), 0.4, 0.17)
                                                         for y in (-0.28, 0.05, 0.36)])
        out += puas(f"nudillo{lado}", "Mano" + lado, [((s * 1.5 + x, -0.46, 2.12), (0, -1, -0.15), 0.18, 0.1)
                                                      for x in (-0.26, 0.0, 0.26)])
    return out


def piernas():
    out = []
    for s, lado in ((1, "Izq"), (-1, "Der")):
        px = s * 0.5
        out += [pieza(f"muslo{lado}", placa(1.26, 1.86, px, -0.50, 0.86, 0.10), "Pierna" + lado, GRIETAS),
                pieza(f"greba{lado}", placa(0.42, 0.74, px, -0.55, 0.84, 0.08), "Rodilla" + lado, GRIETAS)]
        out += puas(f"rodilla{lado}", "Rodilla" + lado, [((px, -0.52, 1.0), (0, -1, 0.4), 0.38, 0.22)])
        out += puas(f"garra{lado}", "Pie" + lado, [((px + x, -0.68, 0.09), (x * 0.6, -1, -0.15), 0.2, 0.1)
                                                    for x in (-0.3, 0.0, 0.3)])
    return out


def cabeza():
    from mathutils import Matrix, Vector

    out = []
    for s in (1, -1):
        base = Vector((s * 0.52, 0.02, 4.95))
        m = Matrix.Translation(base) @ Matrix.Rotation(math.radians(s * 72), 4, "Y")
        anillos = []
        for i in range(13):  # cuerno con relieve: anillos que se ensanchan y angostan
            t = i / 12
            lado = 0.44 * (1 - 0.9 * t ** 1.1) * (1.07 if i % 2 else 1.0)
            anillos.append((1.55 * t, -s * 0.8 * t * t, 0, lado, lado * 0.92, lado * 0.32))

        def color(c, n, base=base):
            largo = (c - base).length
            return "paleta", "lava_clara" if largo > 1.42 else "lava" if largo > 1.25 else \
                "cuerno" if largo < 0.6 else "roca_clara"

        out.append(pieza(f"cuerno{s}", anillos, "Cabeza", color, matriz=m, k=4))
    for i, (x, alto, ancho) in enumerate(((0.0, 0.72, 0.26), (0.30, 0.46, 0.2), (-0.30, 0.46, 0.2))):
        tope = 5.05 + alto
        anillos = [(z, x + (z - 5.05) * 0.35 * (1 if x > 0 else -1 if x < 0 else 0), y, w, d, r)
                   for z, _, y, w, d, r in B.punta(5.05, tope, 0, 0.06, ancho, ancho * 0.85, 4, 0.1)]
        out.append(pieza(f"corona{i}", anillos, "Cabeza", B.con_punta(tope - 0.2, "roca_clara", "lava_clara")))
    out += puas("cresta", "Cabeza", [((0, y, 5.12), (0, 0.6, 1), largo, 0.16)
                                     for y, largo in ((0.25, 0.34), (0.42, 0.28))])
    return out


def accesorios():
    return torso() + brazos() + piernas() + cabeza() + CARA.piezas()
