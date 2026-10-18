"""
Accesorios del Rey del Mar v2 (sin la cara, que está en ..._cara.py): peto y espaldar con
filo de oro y gemas 3D, gorguera, hebilla, faldones que siguen a las piernas,
hombreras de concha en capas (nervios, láminas, cresta y cristales), brazales y grebas con
aletas, rodilleras con gema, punteras de oro, y la corona de dos pisos con gemas, cresta y
aletas del casco. Cada pieza es un tubo cerrado metido un poco en lo que la lleva.
"""
import traje_v2_base as B
import traje_v2_rey_del_mar_cara as CARA
from traje_v2_formas import pieza, placa

ARMADURA = ("caja", "armadura")


def frente_o(frente, resto):
    """Color por cara: `frente` en las caras que miran adelante, `resto` en las demás."""
    return lambda c, n: frente if n.y < -0.6 else resto


def rombo(nombre, z, y, ancho, alto, hueso, fondo=0.12, x=0.0):
    """Gema tallada (rombo de frente) que sobresale hacia -y."""
    return pieza(nombre, [(z - alto, x, y + 0.02, 0.05, 0.05, 0.02),
                          (z, x, y - 0.01, ancho, fondo, min(ancho, fondo) * 0.35),
                          (z + alto, x, y + 0.02, 0.05, 0.05, 0.02)], hueso, "gema")


def torso():
    out = [pieza("filo_peto", placa(2.44, 3.97, 0, -0.52, 1.66, 0.08, w1=1.94), "Pecho", "oro"),
           pieza("peto", placa(2.47, 3.94, 0, -0.535, 1.58, 0.11, w1=1.86), "Pecho",
                 frente_o(("region", "pecho"), ("paleta", "oro"))),
           pieza("engaste", placa(3.02, 3.64, 0, -0.585, 0.50, 0.08), "Pecho", "oro"),
           rombo("gema_pecho", 3.33, -0.63, 0.34, 0.27, "Pecho", 0.14),
           pieza("filo_espaldar", placa(2.44, 3.97, 0, 0.52, 1.66, 0.08, w1=1.94), "Pecho", "oro"),
           pieza("espaldar", placa(2.47, 3.94, 0, 0.535, 1.58, 0.11, w1=1.86), "Pecho",
                 lambda c, n: ("region", "espalda") if n.y > 0.6 else ("paleta", "oro")),
           pieza("engaste_espalda", placa(3.10, 3.56, 0, 0.585, 0.40, 0.08), "Pecho", "oro"),
           rombo("gema_espalda", 3.33, 0.62, 0.26, 0.2, "Pecho", 0.12),
           pieza("gorguera", [(3.92, 0, 0, 1.40, 1.12, 0.3), (4.02, 0, 0, 1.46, 1.18, 0.32),
                              (4.14, 0, 0, 1.36, 1.08, 0.28)], "Pecho", "oro", k=4),
           rombo("gema_gorguera", 4.03, -0.60, 0.12, 0.08, "Pecho", 0.08),
           pieza("hebilla", placa(2.22, 2.50, 0, -0.56, 0.38, 0.08), "Cadera", "oro"),
           rombo("gema_hebilla", 2.36, -0.61, 0.13, 0.1, "Cadera", 0.08)]
    for s, lado in ((1, "Izq"), (-1, "Der")):  # faldones: arriba en la cadera, abajo con la pierna
        def pesos(co, lado=lado):
            cadera = 0.4 + 0.6 * max(0.0, min(1.0, (co.z - 1.60) / 0.70))
            return {"Cadera": cadera, "Pierna" + lado: 1 - cadera}

        def color(c, n):
            return ("paleta", "oro") if c.z < 1.69 or n.y > -0.6 else ARMADURA

        out.append(pieza(f"faldon{lado}", placa(1.60, 2.30, s * 0.49, -0.64, 0.84, 0.07, w1=0.80, cy1=-0.585),
                         color=color, pesos=pesos))
    return out


def hombreras():
    out = []
    for s, lado in ((1, "Izq"), (-1, "Der")):
        cx, hueso = s * 1.55, "Brazo" + lado
        perfil = [(3.70, 1.18, 1.12), (3.80, 1.22, 1.16), (3.90, 1.18, 1.12), (4.00, 1.16, 1.10),
                  (4.08, 1.12, 1.06), (4.16, 1.04, 0.98), (4.23, 0.92, 0.88), (4.29, 0.74, 0.70),
                  (4.34, 0.46, 0.44)]  # nervios de concha: anillos que suben y bajan

        def concha(c, n):
            return ("paleta", "mar_claro") if n.z > 0.85 else ARMADURA

        out += [pieza(f"filo_hombrera{lado}", placa(3.60, 3.72, cx, 0, 1.28, 1.22), hueso, "oro"),
                pieza(f"hombrera{lado}", [(z, cx, 0, w, d, min(w, d) * 0.36) for z, w, d in perfil], hueso, concha, k=4),
                pieza(f"lamina1{lado}", placa(3.46, 3.60, cx, 0, 1.22, 1.16), hueso,
                      lambda c, n: ("paleta", "oro" if c.z < 3.49 else "mar_claro")),
                pieza(f"lamina2{lado}", placa(3.32, 3.46, cx, 0, 1.14, 1.08), hueso,
                      lambda c, n: ("paleta", "oro" if c.z < 3.35 else "mar")),
                pieza(f"cresta_hombrera{lado}", [(4.18, cx, 0.0, 0.07, 0.90, 0.03), (4.42, cx, 0.06, 0.06, 0.62, 0.025),
                                                 (4.53, cx, 0.12, 0.04, 0.24, 0.015)], hueso, "oro")]
        for j, (dx, cy, alto) in enumerate(((0.22, -0.26, 0.5), (0.28, 0.2, 0.4), (0.12, 0.42, 0.3))):
            x0 = cx + s * dx
            cristal = [(z, x0 + s * (z - 4.12) * 0.55, cy, w, d, r)
                       for z, _, _, w, d, r in B.punta(4.12, 4.12 + alto, 0, 0, 0.16, 0.16, final=0.08)]
            out.append(pieza(f"cristal{lado}{j}", cristal, hueso, "gema"))
    return out


def extremidades():
    out = []
    for s, lado in ((1, "Izq"), (-1, "Der")):
        aleta = lambda x0, z0, z1: [(z0, x0, 0.04, 0.06, 0.50, 0.02), (z0 + (z1 - z0) * 0.6, x0 + s * 0.02, 0.18, 0.05, 0.40, 0.02),
                                    (z1, x0 + s * 0.04, 0.34, 0.04, 0.12, 0.015)]
        px = s * 0.5
        out += [pieza(f"aleta_brazal{lado}", aleta(s * 2.05, 2.46, 2.98), "Codo" + lado, "mar_claro"),
                pieza(f"aleta_greba{lado}", aleta(s * 0.99, 0.44, 0.95), "Rodilla" + lado, "mar_claro"),
                pieza(f"filo_rodillera{lado}", placa(0.84, 1.18, px, -0.50, 0.66, 0.12, w1=0.58), "Rodilla" + lado, "oro"),
                pieza(f"rodillera{lado}", placa(0.87, 1.15, px, -0.53, 0.58, 0.10, w1=0.50), "Rodilla" + lado, "mar_claro"),
                pieza(f"greba{lado}", placa(0.46, 0.66, px, -0.51, 0.68, 0.08), "Rodilla" + lado,
                      frente_o(ARMADURA, ("paleta", "oro"))),
                pieza(f"puntera{lado}", placa(0.03, 0.24, px, -0.60, 0.86, 0.16, w1=0.76, cy1=-0.58), "Pie" + lado, "oro")]
        out.append(rombo(f"gema_rodilla{lado}", 1.01, -0.59, 0.1, 0.08, "Rodilla" + lado, 0.06, px))
    return out


def corona():
    out = [rombo("gema_corona", 5.25, -0.64, 0.14, 0.1, "Cabeza", 0.08)]
    puntas = [(0.40, -0.60, 0.50, "f"), (-0.40, -0.60, 0.50, "f"), (0.64, -0.15, 0.42, "l"),
              (-0.64, -0.15, 0.42, "l"), (0.64, 0.25, 0.36, "l"), (-0.64, 0.25, 0.36, "l"), (0, 0.60, 0.40, "f"),
              (0.2, -0.61, 0.28, "f"), (-0.2, -0.61, 0.28, "f")]
    for i, (x, y, alto, cara) in enumerate(puntas):
        w, d = (0.20, 0.08) if cara == "f" else (0.08, 0.20)
        tope = 5.28 + alto
        out.append(pieza(f"corona{i}", B.punta(5.28, tope, x, y, w, d), "Cabeza", B.con_punta(tope - 0.11, "oro", "gema")))
    # Aguja central: más alta, con una gema tallada a media altura.
    out.append(pieza("aguja", B.punta(5.28, 6.05, 0, -0.60, 0.26, 0.09, 5, 0.1), "Cabeza", B.con_punta(5.92, "oro", "gema")))
    out.append(rombo("gema_aguja", 5.58, -0.66, 0.13, 0.11, "Cabeza", 0.07))
    out.append(pieza("cresta", [(5.52, 0, 0.0, 0.10, 0.95, 0.04), (5.70, 0, 0.05, 0.12, 0.93, 0.045),
                                (5.86, 0, 0.12, 0.09, 0.84, 0.04), (6.00, 0, 0.22, 0.11, 0.66, 0.04),
                                (6.12, 0, 0.32, 0.07, 0.46, 0.03), (6.22, 0, 0.46, 0.04, 0.14, 0.015)], "Cabeza", "coral"))
    for s in (1, -1):
        out.append(pieza(f"aleta{s}", [(4.78, s * 0.64, 0.10, 0.08, 0.50, 0.03), (5.00, s * 0.66, 0.18, 0.08, 0.56, 0.03),
                                       (5.25, s * 0.70, 0.34, 0.07, 0.42, 0.03), (5.45, s * 0.75, 0.50, 0.05, 0.18, 0.02)],
                         "Cabeza", lambda c, n: ("paleta", "oro" if c.z < 4.84 else "mar_claro")))
    return out


def accesorios():
    return torso() + hombreras() + extremidades() + corona() + CARA.piezas()
