"""
Datos del Marinero v2 (el traje que llevan todos los jugadores), compartidos por el armador
de Blender (marinero_v2.py) y el dibujo de la textura (marinero_v2_textura.py, Python normal).

Medidas en studs (1 unidad de Blender = 1 stud), proporciones de avatar de bloques R15:
piernas 2, torso 2, brazos 2, cabeza 1.2. Z arriba, frente hacia -Y y la izquierda del
personaje en +X (lado "Izq"), como el resto de los trajes (rig_traje.py).

Cada parte es un tubo de anillos (rectángulos de esquinas redondeadas). FX y FY son las líneas
de la malla sobre los lados rectos, en fracciones de medio lado recto (-1 a 1): las tapas son
una cuadrícula con esas líneas, y los puentes que unen las partes se cortan sobre ellas.
"""

# Colores (sRGB 0-255). La piel es fija para todos (decidido con el usuario).
COLORES = {
    "piel": (241, 194, 156),
    "barba": (101, 62, 38),
    "blanco": (244, 244, 239),
    "raya": (52, 104, 168),
    "marino": (31, 43, 77),
    "rojo": (205, 48, 45),
    "pantalon": (74, 118, 166),
    "cinturon": (78, 50, 32),
    "hebilla": (232, 186, 74),
    "bota": (110, 66, 40),
    "suela": (58, 38, 27),
    "gorra": (247, 247, 243),
    "ojo": (24, 24, 30),
    "boca": (70, 28, 30),
}
# Celda de cada color en la paleta (cuadrante inferior derecho de la textura, 8 x 8).
PALETA = {nombre: i for i, nombre in enumerate(COLORES)}

TAM_TEXTURA = 1024
MARGEN = 10 / 1024  # el dibujo sigue más allá de lo que se ve (filtrado y mipmaps)
# Regiones dibujadas (u0, v0, u1, v1) y lo que cubren del cuerpo (x0, z0, x1, z1) en studs.
# La espalda se dibuja vista desde atrás (x invertida) para que no quede en espejo.
REGIONES = {
    "cara": ((0.0, 0.5, 0.5, 1.0), (-0.62, 4.08, 0.62, 5.14)),
    "pecho": ((0.5, 0.5, 1.0, 1.0), (-1.0, 2.0, 1.0, 4.0)),
    "espalda": ((0.0, 0.0, 0.5, 0.5), (1.0, 2.0, -1.0, 4.0)),
}


def uv_region(nombre, x, z):
    (u0, v0, u1, v1), (x0, z0, x1, z1) = REGIONES[nombre]
    u0, v0, u1, v1 = u0 + MARGEN, v0 + MARGEN, u1 - MARGEN, v1 - MARGEN
    return (u0 + (x - x0) / (x1 - x0) * (u1 - u0), v0 + (z - z0) / (z1 - z0) * (v1 - v0))


def uv_paleta(color):
    i = PALETA[color]
    return (0.5 + (i % 8 + 0.5) / 16, (i // 8 + 0.5) / 16)


# Articulaciones: (z del pivote, medio ancho de la transición de pesos).
# Codo y rodilla doblan mucho (hasta 90 grados): el pivote se corre hacia el lado de adentro
# del doblez (y) y la transición es ancha, con anillos cada 0.08. Si no, el lado de adentro se
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
PUENTE_HOMBRO = (3.71, 3.86)  # anillos del torso; el brazo usa sus rayas más cercanas
HOMBRO_Z = sum(PUENTE_HOMBRO) / 2
CUELLO_Z = 4.04

TORSO = dict(cx=0.0, w=2.0, d=1.0, r=0.12, k=2,
             fx=[-1, -0.65 / 0.88, -0.35 / 0.88, -0.25 / 0.88, 0.25 / 0.88, 0.35 / 0.88, 0.65 / 0.88, 1],
             fy=[-1, -0.25 / 0.38, -0.15 / 0.38, 0, 0.15 / 0.38, 0.25 / 0.38, 1],
             # (z, inset): inset achica el anillo sin mover las líneas rectas (chaflán)
             anillos=[(2.0, 0.04), (2.04, 0), (2.18, 0), (2.30, 0), (2.40, 0), (2.50, 0), (3.0, 0),
                      (3.71, 0), (3.86, 0), (3.96, 0), (4.0, 0.04)])
FRANJAS_MANGA = [3.15 + i * 0.85 / 6 for i in range(7)]  # 6 rayas, blanca abajo
BRAZO = dict(cx=1.5, w=0.94, d=0.94, r=0.10, k=2, x_dentro=1.03,
             fx=[-1, 1], fy=[-1, -0.15 / 0.37, 0, 0.15 / 0.37, 1],
             anillos=[(2.0, 0.04), (2.04, 0), (2.33, 0), (2.38, 0), (2.43, 0)]
             + [(2.74 + 0.09 * i, 0) for i in range(5)]
             + [(z, 0) for z in FRANJAS_MANGA[:-1]] + [(3.96, 0), (4.0, 0.04)])
PIERNA = dict(cx=0.5, w=0.94, d=0.94, r=0.10, k=2,
              fx=[-1, -0.15 / 0.37, 0.15 / 0.37, 1], fy=[-1, -0.15 / 0.37, 0, 0.15 / 0.37, 1],
              anillos=[(0.0, 0.03, "suela"), (0.03, 0, "suela"), (0.08, 0, "suela"), (0.08, 0, "pie"),
                       (0.26, 0, "pie"), (0.30, 0, "pie"), (0.40, 0, "cana"), (0.55, 0, "cana"),
                       (0.55, 0, "pierna")]
              + [(0.78 + 0.08 * i, 0, "pierna") for i in range(6)]
              + [(1.70, 0, "pierna"), (1.85, 0, "pierna"), (1.98, 0, "pierna")])
# Forma de la pierna por tramo: (ancho, fondo, centro en y, radio). La bota es más ancha y el
# pie sale hacia adelante (el empeine sube en rampa del pie a la caña); la suela asoma un poco.
# Las suelas no se tocan entre sí (0.98 de ancho con la pierna centrada en 0.5).
TRAMOS_PIERNA = {
    "suela": (0.98, 1.16, -0.07, 0.12),
    "pie": (0.96, 1.12, -0.07, 0.12),
    "cana": (0.96, 0.98, 0.0, 0.11),
    "pierna": (0.94, 0.94, 0.0, 0.10),
}
CABEZA = dict(cx=0.0, w=1.24, d=1.16, r=0.22, k=4,
              fx=[-1, -0.25 / 0.40, 0.25 / 0.40, 1],
              fy=[-1, -0.25 / 0.36, -0.15 / 0.36, 0, 0.15 / 0.36, 0.25 / 0.36, 1],
              anillos=[(4.08, 0.05), (4.13, 0), (4.30, 0), (4.62, 0), (4.95, 0), (5.11, 0), (5.14, 0.03)])
# Gorra de marinero: banda marino, ala blanca doblada hacia arriba y copa blanca.
# (z, ancho, fondo, radio, color de la banda que empieza en ese anillo)
GORRA = dict(cx=0.0, k=4, fx=[-1, -0.25 / 0.41, 0.25 / 0.41, 1],
             fy=[-1, -0.25 / 0.37, -0.15 / 0.37, 0, 0.15 / 0.37, 0.25 / 0.37, 1],
             anillos=[(5.15, 1.30, 1.22, 0.24), (5.31, 1.30, 1.22, 0.24), (5.31, 1.46, 1.38, 0.30),
                      (5.45, 1.46, 1.38, 0.30), (5.45, 1.02, 0.96, 0.21), (5.60, 1.02, 0.96, 0.21),
                      (5.68, 0.94, 0.88, 0.17), (5.71, 0.80, 0.74, 0.10)])
