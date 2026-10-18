"""
Lo que comparten todos los trajes de bloques v2 (Marinero, Rey del Mar, Dios del Volcán): el
esqueleto, las articulaciones y las líneas de malla donde se cortan los puentes. Cada traje
(su ficha, traje_v2_<clave>.py) define la forma de sus partes con estas líneas y suma sus
accesorios; así el cuerpo dobla igual en los tres y el juego los mueve con el mismo rig.

Medidas en studs (1 unidad de Blender = 1 stud), proporciones de avatar de bloques R15:
piernas 2, torso 2, brazos 2, cabeza 1.2. Z arriba, frente hacia -Y y la izquierda del
personaje en +X (lado "Izq").
"""

# Articulaciones: (z del pivote, medio ancho de la transición de pesos).
# Codo y rodilla doblan mucho (hasta 90 grados): el pivote se corre hacia el lado de adentro
# del doblez (y) y la transición es ancha, con anillos cada ~0.08. Si no, el lado de adentro se
# comprime más de lo que mide la franja, los anillos se cruzan y las caras se dan vuelta.
CINTURA = (2.40, 0.10)
CODO = (2.92, 0.18)
CODO_Y = -0.28  # el antebrazo dobla hacia adelante (-y)
MUNECA = (2.38, 0.05)
RODILLA = (0.98, 0.20)
RODILLA_Y = 0.26  # la pierna dobla hacia atrás (+y)
TOBILLO = (0.32, 0.06)
CADERA_Z = 1.95  # pivote de las piernas (arriba de cada pierna)
# Pivote de los brazos: centro del puente con el torso, alto en el hombro para que al levantar
# el brazo asome poco de lo que queda encima (en R15 asoma un pedazo junto al torso).
PUENTE_HOMBRO = (3.71, 3.86)  # el torso y los brazos tienen anillos en estas dos alturas
HOMBRO_Z = sum(PUENTE_HOMBRO) / 2
HOMBRO_X = 1.015  # entre el costado del torso (1.0) y el del brazo (1.03)
CUELLO_Z = 4.04
BRAZO_CX = 1.5
PIERNA_CX = 0.5

# Anillos estándar de las articulaciones (cada traje los incluye en sus brazos y piernas).
ANILLOS_CODO = [2.74 + 0.09 * i for i in range(5)]
ANILLOS_MUNECA = [2.33, 2.38, 2.43]
ANILLOS_RODILLA = [0.78 + 0.08 * i for i in range(6)]

# Líneas de malla (fracciones de medio lado recto). Los puentes se cortan sobre ellas:
#   cuello   torso arriba celdas x 3..4, y 1..5  <->  cabeza abajo x 1..2, y 1..5
#   sombrero cabeza arriba x 1..2, y 1..5          <->  sombrero abajo x 1..2, y 1..5
#   hombro   torso costado y 2..4 entre PUENTE_HOMBRO <-> brazo costado y 1..3
#   cadera   torso abajo x 5..6 (Izq) o 1..2 (Der), y 2..4 <-> pierna arriba x 1..2, y 1..3
# Con otro ancho las líneas se mueven en proporción y los puentes siguen calzando.
TORSO_FX = [-1, -0.65 / 0.88, -0.35 / 0.88, -0.25 / 0.88, 0.25 / 0.88, 0.35 / 0.88, 0.65 / 0.88, 1]
TORSO_FY = [-1, -0.25 / 0.38, -0.15 / 0.38, 0, 0.15 / 0.38, 0.25 / 0.38, 1]
CABEZA_FX = [-1, -0.25 / 0.40, 0.25 / 0.40, 1]
CABEZA_FY = [-1, -0.25 / 0.36, -0.15 / 0.36, 0, 0.15 / 0.36, 0.25 / 0.36, 1]
SOMBRERO_FX = [-1, -0.25 / 0.41, 0.25 / 0.41, 1]
SOMBRERO_FY = [-1, -0.25 / 0.37, -0.15 / 0.37, 0, 0.15 / 0.37, 0.25 / 0.37, 1]
BRAZO_FX = [-1, 1]
BRAZO_FY = [-1, -0.15 / 0.37, 0, 0.15 / 0.37, 1]
PIERNA_FX = [-1, -0.15 / 0.37, 0.15 / 0.37, 1]
PIERNA_FY = [-1, -0.15 / 0.37, 0, 0.15 / 0.37, 1]

# Huesos: (cabeza, cola, padre). Los mismos 16 nombres que lee el juego (Shared/Trajes).
HUESOS = {
    "Raiz": ((0, 0, 0), (0, 0, 0.15), None),
    "Cadera": ((0, 0, 2.0), (0, 0, CINTURA[0]), "Raiz"),
    "Pecho": ((0, 0, CINTURA[0]), (0, 0, CUELLO_Z), "Cadera"),
    "Cabeza": ((0, 0, CUELLO_Z), (0, 0, CUELLO_Z + 0.3), "Pecho"),
}
for _lado, _s in (("Izq", 1), ("Der", -1)):
    _bx, _px = _s * BRAZO_CX, _s * PIERNA_CX
    HUESOS["Brazo" + _lado] = ((_s * HOMBRO_X, 0, HOMBRO_Z), (_bx, CODO_Y, CODO[0]), "Pecho")
    HUESOS["Codo" + _lado] = ((_bx, CODO_Y, CODO[0]), (_bx, 0, MUNECA[0]), "Brazo" + _lado)
    HUESOS["Mano" + _lado] = ((_bx, 0, MUNECA[0]), (_bx, 0, 2.0), "Codo" + _lado)
    HUESOS["Pierna" + _lado] = ((_px, 0, CADERA_Z), (_px, RODILLA_Y, RODILLA[0]), "Cadera")
    HUESOS["Rodilla" + _lado] = ((_px, RODILLA_Y, RODILLA[0]), (_px, 0, TOBILLO[0]), "Pierna" + _lado)
    HUESOS["Pie" + _lado] = ((_px, 0, TOBILLO[0]), (_px, -0.55, 0.02), "Rodilla" + _lado)


def suave(z, junta):
    """0 debajo de la articulación, 1 encima, con una transición corta."""
    centro, medio = junta
    t = max(0.0, min(1.0, (z - centro + medio) / (2 * medio)))
    return t * t * (3 - 2 * t)


def pesos_cuerpo(parte, co):
    """Pesos de una parte del cuerpo ('torso', 'cabeza', 'brazo_Izq', 'pierna_Der'...)."""
    z = co.z
    if parte == "torso":
        t = suave(z, CINTURA)
        return {"Pecho": t, "Cadera": 1 - t}
    if parte in ("cabeza", "sombrero"):
        return {"Cabeza": 1.0}
    lado = parte.split("_")[1]
    if parte.startswith("brazo"):
        te, tm = suave(z, CODO), suave(z, MUNECA)
        return {"Brazo" + lado: te, "Codo" + lado: (1 - te) * tm, "Mano" + lado: 1 - tm}
    # Arriba de la pierna, parte del peso queda en la cadera: así el borde de arriba casi no
    # se inclina y no se abre una cuña bajo el torso al caminar.
    cadera = max(0.0, min(0.5, (z - 1.70) / (1.98 - 1.70) * 0.5))
    tr, tt = suave(z, RODILLA), suave(z, TOBILLO)
    return {"Cadera": cadera, "Pierna" + lado: tr * (1 - cadera),
            "Rodilla" + lado: (1 - tr) * tt, "Pie" + lado: 1 - tt}


def anillos(parte, cx=0.0):
    """Anillos de Tubo de una parte: cada entrada (z, inset, tramo), donde tramo es el nombre
    de una forma de parte["tramos"] o la forma misma (ancho, fondo, centro y, radio). El inset
    achica el anillo sin mover las líneas rectas (chaflán)."""
    out = []
    for z, e, tramo in parte["anillos"]:
        w, d, cy, r = parte["tramos"][tramo] if isinstance(tramo, str) else tramo
        out.append((z, cx, cy, w - 2 * e, d - 2 * e, r - e))
    return out


def punta(z0, z1, cx, cy, w, d, pasos=4, final=0.12):
    """Anillos de una pieza que se afina hacia arriba (punta de corona, cristal, púa, cuerno):
    de (w, d) abajo a una fracción `final` arriba."""
    out = []
    for i in range(pasos + 1):
        t = i / pasos
        f = 1 - (1 - final) * t ** 1.3
        out.append((z0 + (z1 - z0) * t, cx, cy, w * f, d * f, min(w, d) * f * 0.3))
    return out


def con_punta(z_brillo, base, brillo):
    """Color de una pieza: `brillo` arriba de z_brillo (en el mundo) y `base` abajo."""
    return lambda c, n: ("paleta", brillo if c.z > z_brillo else base)
