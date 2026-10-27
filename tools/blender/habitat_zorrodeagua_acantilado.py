r"""
El acantilado del hábitat del zorro de agua, entero con nieve y hielo (menos donde lo tapa el
glaciar): cuatro franjas de losas pegadas a la pared, de la escarcha de abajo a la cornisa de
nieve del borde, con carámbanos colgando, y cascadas congeladas que bajan hasta el agua.
Nada pasa del paseo (r 205) ni de su altura (Y 30).
"""
import math
from mathutils import Matrix
import habitat_zorrodeagua_glaciar as glaciar
from habitat_zorrodeagua_base import (AGUA, LAGO, PASEO, PUERTA, PUERTA_HUECO, TECHO, V, afuera, contorno, dif,
                                      ocupar, polar, rnd, suelo, OCUPADO)

# Franjas: radio de la pared, alto de la losa a lo largo de la pared y colores posibles.
FRANJAS = (
    (190.9, 6.5, ("escarcha", "hielo2", "escarcha")),
    (193.2, 7.0, ("escarcha", "nieve", "hielo2")),
    (196.6, 7.4, ("nieve", "escarcha", "nieve")),
    (199.4, 6.0, ("nieve", "escarcha")),
    (201.6, 4.6, ("nieve",)),  # la cornisa del borde
)
LOSA = 9.5  # ancho de cada losa a lo largo de la orilla


def pared(a, r):
    """Punto de la pared del acantilado, su normal (hacia el lago y arriba) y la dirección a lo
    largo de la orilla."""
    sube = (suelo(r + 0.25) - suelo(r - 0.25)) / 0.5
    normal = (V((0, 0, 1)) - afuera(a) * sube).normalized()
    largo = V((0, 0, 1)).cross(afuera(a)).normalized()
    return polar(a, r, suelo(r)), normal, largo


def losa_pared(m, a, r, ancho, alto, grosor, arriba, lados, despega=0.3, giro=0.0):
    """Losa apoyada en la pared (ancho a lo largo de la orilla, alto pared arriba). No la pone si
    alguna esquina pasa del paseo o de su altura. Da el borde de abajo (centro) o None."""
    p, normal, largo = pared(a, r)
    subida = normal.cross(largo)
    if subida.z < 0:
        subida = -subida
    rot = Matrix.Rotation(giro, 3, normal)
    x, y = rot @ largo, rot @ subida
    centro = p + normal * (despega + grosor / 2 - 0.25)
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                q = centro + x * sx * ancho / 2 + y * sy * alto / 2 + normal * sz * grosor / 2
                if q.z > TECHO - 0.1 or q.xy.length > PASEO - 0.4:
                    return None
    m.bloque(centro, (ancho, alto, grosor), arriba, lados, Matrix((x, y, normal)).transposed())
    return centro - y * (alto / 2) + normal * (grosor / 2)


def radio_de(z):
    """Radio de la pared a la altura z (inversa de suelo() entre 190 y 205)."""
    return LAGO + (PASEO - LAGO) * (min(max((z + 1) / 31, 0), 1)) ** (1 / 0.6)


def _tapado(p, rad):
    return glaciar.toca(p, rad, 1.0) or any((p.xy - c).length < rad + rc - 2 for c, rc in OCUPADO)


def franjas(m):
    for i, (r0, alto, colores) in enumerate(FRANJAS):
        paso = math.degrees(LOSA * 0.92 / r0)
        a = rnd.uniform(0, paso)
        while a < 360:
            ang = a + rnd.uniform(-0.3, 0.3)
            if not glaciar.dentro(polar(ang, r0, 0), 4) and not (i < 2 and _tapado(polar(ang, r0, 0), 3)):
                color = rnd.choice(colores)
                for r in (r0, r0 - 0.6, r0 - 1.2):
                    borde = losa_pared(m, ang, r, LOSA * rnd.uniform(0.95, 1.08), alto * rnd.uniform(0.9, 1.1),
                                       rnd.uniform(1.0, 1.6), color, color if color == "nieve" else "hielo2", 0.2,
                                       rnd.uniform(-0.1, 0.1))
                    if borde is not None:
                        break
                if borde is not None and i < 3 and rnd.random() < 0.45:
                    for _ in range(rnd.randint(1, 2)):
                        _, _, largo = pared(ang, r)
                        q = borde + largo * rnd.uniform(-LOSA * 0.4, LOSA * 0.4)
                        m.cristal(q, V((0, 0, -1)), rnd.uniform(0.4, 0.8), rnd.uniform(2.5, 5.5), "hielo", 4)
            a += paso


def cascadas(m, cuantas=4):
    """Cascadas congeladas: cortinas de hielo escalonadas por la pared, con carámbanos en cada
    escalón y un montículo de hielo al pie, en el agua."""
    hechas = 0
    for a in rnd.sample(range(0, 360, 9), 40):
        if hechas >= cuantas:
            break
        if abs(dif(a, PUERTA)) < PUERTA_HUECO + 6 or _tapado(polar(a, 195, 0), 10):
            continue
        z = 25.0
        while z > AGUA + 1:
            r = radio_de(z)
            ancho = 7 + (26 - z) * 0.25 + rnd.uniform(-0.8, 0.8)
            borde = losa_pared(m, a + rnd.uniform(-0.6, 0.6), r, ancho, 5.4, 2.6, "hielo",
                               rnd.choice(("hielo", "hielo4")), 1.2, rnd.uniform(-0.1, 0.1))
            if borde is not None:
                _, _, largo = pared(a, r)
                for k in range(3):
                    q = borde + largo * ((k - 1) * ancho * 0.3 + rnd.uniform(-0.6, 0.6))
                    m.cristal(q, V((0, 0, -1)), rnd.uniform(0.5, 0.9), rnd.uniform(2.5, 4.5), "hielo", 4)
            z -= 4.2
        pie = polar(a, 186.5, 0)
        m.prisma(pie, contorno(7.5, 7, 0.4), suelo(178) - 0.5, AGUA + 2.2, "nieve", "hielo2")
        ocupar(pie, 8)
        hechas += 1


def construir(m):
    cascadas(m)
    franjas(m)
