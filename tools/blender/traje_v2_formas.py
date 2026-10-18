"""
Formas de accesorios para los trajes v2, todas como anillos de traje_v2_tubos.Tubo:
  placa    caja de cantos biselados (peto, rodillera, placa de roca), que puede cambiar de
           ancho, fondo o centro de abajo a arriba (afinarse, inclinarse);
  pua      púa o cuerno que apunta en cualquier dirección (devuelve anillos y matriz);
  pieza    el diccionario de un accesorio (nombre, anillos, hueso o pesos, color, matriz).
Las que usan mathutils (pua) solo se llaman desde Blender.
"""
from traje_v2_base import punta


def pieza(nombre, anillos, hueso=None, color=None, **extra):
    acc = dict(nombre=nombre, anillos=anillos, **extra)
    if hueso:
        acc["hueso"] = hueso
    if color:
        acc["color"] = color
    return acc


def placa(z0, z1, cx, cy, w, d, bisel=0.025, w1=None, d1=None, cx1=None, cy1=None):
    """Placa de z0 a z1 con chaflán arriba y abajo; arriba mide (w1, d1) y está en (cx1, cy1)."""
    w1, d1 = (w if w1 is None else w1), (d if d1 is None else d1)
    cx1, cy1 = (cx if cx1 is None else cx1), (cy if cy1 is None else cy1)
    b = min(bisel, min(w, d, w1, d1) * 0.3)

    def anillo(z, x, y, ww, dd, e):
        r = min(ww, dd) * 0.45
        return (z, x, y, ww - 2 * e, dd - 2 * e, r - e)

    return [anillo(z0, cx, cy, w, d, b), anillo(z0 + b, cx, cy, w, d, 0),
            anillo(z1 - b, cx1, cy1, w1, d1, 0), anillo(z1, cx1, cy1, w1, d1, b)]


def pua(base, direccion, largo, grueso, final=0.08, pasos=4, aplanada=1.0):
    """Púa desde `base` hacia `direccion` (no hace falta que sea unitaria): (anillos, matriz)."""
    from mathutils import Matrix, Vector

    d = Vector(direccion).normalized()
    giro = Vector((0, 0, 1)).rotation_difference(d).to_matrix().to_4x4()
    anillos = punta(0, largo, 0, 0, grueso, grueso * aplanada, pasos, final)
    return anillos, Matrix.Translation(Vector(base)) @ giro
