"""Piezas que distinguen a un estanque: rana, muelle, cascada, rocas flotantes, cristales y el
islote del pez dorado del sagrado."""
import math

import generar_isla as gi
from estanques.forma import AGUA, SUELO, cilindro, elipsoide, orientar

GRIS = ((130, 126, 118), (114, 110, 104), (146, 142, 134))  # gris cálido: el frío se veía violeta
MUSGO = ((84, 140, 70), (70, 124, 62))
AGUA_CAE = (170, 225, 240)
ESPUMA = (240, 250, 255)


def rana(nombre, pos, tono=(96, 178, 70)):
    """Ranita sentada sobre una hoja: cuerpo, dos ojos saltones y pupilas."""
    y = AGUA + 0.12
    hijos = [elipsoide("Cuerpo", (pos[0], y + 0.35, pos[2]), (0.9, 0.65, 1.1), tono, **gi.FANTASMA)]
    for lado in (-1, 1):
        ojo = (pos[0] + 0.25 * lado, y + 0.75, pos[2] - 0.3)
        hijos.append(gi.pieza(f"Ojo{lado}", (0.34, 0.34, 0.34), ojo, (250, 250, 245), forma="Ball", **gi.FANTASMA))
        hijos.append(gi.pieza(f"Pupila{lado}", (0.16, 0.16, 0.16), gi.add(ojo, (0, 0.02, -0.14)), (20, 20, 24), forma="Ball",
                              **gi.FANTASMA))
    return gi.grupo(nombre, hijos)


def muelle(nombre, orilla, direccion, largo=6):
    """Muellecito de tablones que entra al agua desde la orilla, con dos postes."""
    d = gi.norm(direccion)
    r = gi.columnas(gi.cross((0, 1, 0), d), (0, 1, 0), d)
    hijos = []
    for k in range(int(largo / 0.9)):
        p = gi.add(orilla, d, -1 + k * 0.9)
        hijos.append(gi.pieza(f"Tablon{k}", (2.6, 0.25, 0.8), (p[0], SUELO + 0.15, p[2]), gi.MADERA_MEDIA if k % 2 else gi.MADERA_CLARA,
                              "WoodPlanks", r, **gi.DECORADO))
    fin = gi.add(orilla, d, largo - 1.4)
    for lado in (-1, 1):
        p = gi.add(fin, gi.aplicar(r, (1.15 * lado, 0, 0)))
        hijos.append(cilindro(f"Poste{lado}", (p[0], AGUA - 1.5, p[2]), 3, 0.35, gi.MADERA_OSCURA, "Wood", **gi.DECORADO))
    return gi.grupo(nombre, hijos)


def cascada(nombre, pie, hacia, rng):
    """Montículo de rocas en la orilla con un chorro de agua que cae al estanque. El cliente
    (Training/PondLife) le pone la bruma a la pieza "Cascada"."""
    d = gi.norm(hacia)  # del montículo hacia el agua
    atras = gi.add(pie, d, -4)
    hijos = []
    for k, (dx, dy, s) in enumerate(((0, 1.4, 6.6), (-3.4, 1, 5.2), (3.4, 1.1, 5.4), (-0.8, 5.4, 5.4), (0.6, 8.6, 4.2))):
        lado = gi.cross((0, 1, 0), d)
        p = gi.add(gi.add(atras, lado, dx), (0, dy, 0))
        hijos.append(elipsoide(f"Roca{k}", p, (s * 1.15, s * 0.8, s), GRIS[k % 3], "Slate",
                               gi.ry(rng.uniform(0, 360)), **gi.DECORADO))
        hijos.append(elipsoide(f"Musgo{k}", gi.add(p, (0, s * 0.33, 0)), (s * 0.7, s * 0.25, s * 0.6), MUSGO[k % 2], "Grass",
                               **gi.FANTASMA))
    tope = gi.add(atras, (0, 10, 0))
    tope = gi.add(tope, d, 2)
    caida = gi.add(pie, d, 1.2)
    caida = (caida[0], AGUA, caida[2])
    u = gi.norm(tuple(caida[n] - tope[n] for n in range(3)))
    largo = math.dist(tope, caida)
    ancho = gi.norm(gi.cross((0, 1, 0), u))  # horizontal: el ancho del chorro
    chorro = gi.pieza("Cascada", (3.2, 0.4, largo), gi.add(tope, u, largo / 2), AGUA_CAE, "Glass",
                      gi.columnas(ancho, gi.cross(u, ancho), u), Transparency=0.25, **gi.FANTASMA)
    hijos.append(chorro)
    for k in range(4):
        p = gi.add(caida, (rng.uniform(-1.2, 1.2), 0.1, rng.uniform(-1.2, 1.2)))
        s = rng.uniform(1.2, 2)
        hijos.append(elipsoide(f"Espuma{k}", p, (s, 0.5, s), ESPUMA, "SmoothPlastic", Transparency=0.3, **gi.FANTASMA))
    return gi.grupo(nombre, hijos)


def cristales(nombre, base, rng, tono, n=4, alto=(1.4, 3)):
    """Racimo de cristales que salen del suelo, inclinados hacia afuera."""
    hijos = []
    for k in range(n):
        a = math.radians(k * 360 / n + rng.uniform(-25, 25))
        u = (math.cos(a) * 0.35, 1, math.sin(a) * 0.35)
        h = rng.uniform(*alto)
        hijos.append(gi.pieza(f"Cristal{k}", (0.5 + h * 0.15, h, 0.5 + h * 0.15), gi.add(base, gi.norm(u), h * 0.4), tono, "Neon",
                              orientar((1, 0, 0), u), **gi.FANTASMA))
    return gi.grupo(nombre, hijos)


def roca_flotante(nombre, centro, altura, tono, rng):
    """Roca que flota sobre el agua con musgo y cristalitos. La mece Training/PondLife."""
    p = (centro[0], AGUA + altura, centro[2])
    s = rng.uniform(2.2, 3.2)
    hijos = [
        elipsoide("Roca", p, (s * 1.2, s * 0.75, s), GRIS[rng.randrange(3)], "Slate", gi.ry(rng.uniform(0, 360)), **gi.FANTASMA),
        elipsoide("Musgo", gi.add(p, (0, s * 0.3, 0)), (s * 0.95, s * 0.22, s * 0.8), MUSGO[0], "Grass", **gi.FANTASMA),
        elipsoide("Punta", gi.add(p, (0, -s * 0.45, 0)), (s * 0.5, s * 0.6, s * 0.5), GRIS[1], "Slate", **gi.FANTASMA),
    ]
    hijos.append(cristales("Cristales", gi.add(p, (0, s * 0.3, 0)), rng, tono, 3, (0.8, 1.6)))
    return gi.grupo(nombre, hijos)


def islote_sagrado(centro, rng):
    """Islote de rocas con musgo en el medio del sagrado y el pez dorado saltando de él."""
    hijos = []
    for k, (dx, dz, s, dy) in enumerate(((0, 0, 7, 0.4), (-3, 2, 5, 0.2), (3, -1.5, 5.4, 0.1), (1, 3, 4, 1.8), (-1, -2.5, 4.4, 2))):
        p = (centro[0] + dx, AGUA + dy, centro[2] + dz)
        hijos.append(elipsoide(f"Roca{k}", p, (s * 1.1, s * 0.6, s), GRIS[k % 3], "Slate", gi.ry(rng.uniform(0, 360)),
                               **gi.DECORADO))
        hijos.append(elipsoide(f"Musgo{k}", gi.add(p, (0, s * 0.22, 0)), (s * 0.8, s * 0.2, s * 0.7), MUSGO[k % 2], "Grass",
                               **gi.FANTASMA))
    giro = gi.mat(gi.ry(30), gi.rx(-35))
    pez = (centro[0], AGUA + 7.5, centro[2])
    hijos.append(elipsoide("PezDorado", pez, (4, 5.4, 12), gi.ORO, "Metal", giro))
    for lado in (-1, 1):  # aleta de la cola en V, como dos hojas abiertas
        aleta = gi.mat(giro, gi.rx(35 * lado))
        hijos.append(elipsoide(f"Cola{lado}", gi.add(pez, gi.aplicar(giro, (0, 1.4 * lado, 7))), (0.5, 2.2, 4.4), gi.ORO, "Metal",
                               aleta))
    for k in range(3):  # el chorro de agua de donde salta
        p = gi.add(pez, gi.aplicar(giro, (0, 0, -3 - k * 1.6)))
        hijos.append(elipsoide(f"Salpicon{k}", (p[0], AGUA + 2.2 + k * 0.4, p[2]), (2.4 - k * 0.5, 1, 2.4 - k * 0.5), ESPUMA,
                               Transparency=0.35, **gi.FANTASMA))
    brillo = gi.pieza("Brillo", (1, 1, 1), pez, gi.ORO, **gi.INVISIBLE, CanCollide=False)
    brillo["children"] = [gi.luz(30, 1, gi.ORO)]
    hijos.append(brillo)
    return gi.grupo("Islote", hijos)
