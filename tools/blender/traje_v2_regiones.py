"""
Dónde cae cada cara de un traje v2 en su textura (Python puro: lo usan el armador de Blender
y el dibujo con PIL). Tres maneras, que decide la ficha del traje cara por cara:
  paleta  un color plano: el centro de su celda (8 x 8 celdas en ficha.PALETA_RECT);
  region  dibujo plano visto de frente (x, z) dentro de un rectángulo de la textura;
  caja    dibujo que envuelve todo el cuerpo (grietas de lava, escamas): cada cara se proyecta
          por su eje dominante, así un mismo dibujo cubre frente, costados y tapas.
Una región es ((u0, v0, u1, v1), (a0, b0, a1, b1)): rectángulo de la textura y lo que cubre
del cuerpo, en studs. En "region" a es x y b es z; en "caja", a y b son el par proyectado.
"""

TAM_TEXTURA = 1024
MARGEN = 10 / 1024  # el dibujo sigue más allá de lo que se ve (filtrado y mipmaps)
PALETA_RECT = (0.5, 0.0, 1.0, 0.5)


def interior(rect):
    u0, v0, u1, v1 = rect
    return u0 + MARGEN, v0 + MARGEN, u1 - MARGEN, v1 - MARGEN


def uv_region(ficha, nombre, a, b):
    rect, (a0, b0, a1, b1) = ficha.REGIONES[nombre]
    u0, v0, u1, v1 = interior(rect)
    return (u0 + (a - a0) / (a1 - a0) * (u1 - u0), v0 + (b - b0) / (b1 - b0) * (v1 - v0))


def proyeccion_caja(co, n):
    """Par (a, b) de un punto según el eje dominante de la normal de su cara. Cada lado usa
    otro tramo del dibujo para que frente, espalda y costados no se repitan igual."""
    ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
    if ay >= ax and ay >= az:
        return (co.x, co.z) if n.y < 0 else (-co.x + 0.9, co.z + 0.45)
    if ax >= az:
        return (co.y + 1.7, co.z + 0.2) if n.x > 0 else (-co.y - 1.7, co.z + 0.65)
    return (co.x + 0.4, co.y + 3.2) if n.z > 0 else (co.x - 0.4, co.y + 1.6)


def uv_caja(ficha, nombre, co, n):
    return uv_region(ficha, nombre, *proyeccion_caja(co, n))


def celda(ficha, color):
    i = list(ficha.COLORES).index(color)
    return i % 8, i // 8


def uv_paleta(ficha, color):
    u0, v0, u1, v1 = getattr(ficha, "PALETA_RECT", PALETA_RECT)
    col, fila = celda(ficha, color)
    return (u0 + (col + 0.5) / 8 * (u1 - u0), v0 + (fila + 0.5) / 8 * (v1 - v0))
