r"""
Alas de murciélago del joven del dragón marino v2 (la carga dragon_v2_e2_geometria.py).

Vista de arriba del ala izquierda, en celdas (x hacia afuera, -y hacia el hocico):
  - Brazo (Ala1): el borde de adelante sube del hombro (x 3, y -2) a la muñeca (x 6), 1:1 hacia
    adelante. Color del cuerpo, grueso (toda la altura del segmento).
  - Muñeca (Ala2): un nudo más alto con la garra del pulgar en gancho hacia adelante, en y -6..-3:
    detrás de las aletitas de las mejillas (al subir el ala no entra en la cabeza).
  - Tres dedos larguísimos en abanico desde la muñeca: el 1 es el borde de adelante de la mano
    (2:1 hacia atrás) hasta la punta del ala (x 16, con la cara plana: la envergadura queda
    exacta); el 2 va hacia atrás y afuera (1:2) y el 3 derecho hacia atrás, los dos en relieve
    sobre la membrana.
  - Membrana llena y hondísima: nace del costado del cuerpo y llega hasta la cadera. El borde de
    atrás es un festón de arcos cóncavos hondos entre dedo y dedo, con las puntas en gancho, y
    lleva una franja de brasa de 1 celda (el brillo del borde de la referencia). La membrana de
    cada segmento es una lámina partida en piezas convexas: la parte oscura (trocear) y la franja,
    en paralelogramos que la siguen.
Tejas (docs/plan_dragon_v2.md, "Juntas"): Ala1 va de x 3 a 7 (membrana en z 9), Ala2 de 6 a 11
(z 10) y Ala3 de 10 a 16 (z 11); cada uno empieza una celda adentro del anterior y una más arriba.
Los huesos (brazo, nudo y dedos) de cada segmento no pasan del borde donde empieza el siguiente.
Alturas de cada segmento (z0 = abajo de la membrana): membrana z0..z0+1, dedos en relieve
z0+1..z0+2, borde de adelante z0..z0+2, nudo de la muñeca z0..z0+3.
"""


def _area(pol):
    return abs(sum(p[0] * q[1] - q[0] * p[1] for p, q in zip(pol, pol[1:] + pol[:1]))) / 2


def membrana(h, z, contorno, adentro, franja):
    """La membrana de un segmento: `adentro` (polígono o lista de polígonos, color membrana) y las
    piezas convexas de la `franja` del borde (color borde). Entre las dos llenan `contorno` justo
    (se comprueba el área)."""
    adentro = [adentro] if isinstance(adentro[0][0], int) else adentro
    total = sum(_area(p) for p in adentro) + sum(_area(p) for p in franja)
    assert abs(total - _area(contorno)) < 1e-9, f"{h}: la membrana no llena el contorno ({total})"
    for pol in adentro:
        par_lamina(h, "Alas", "membrana", pol, z)
    for pieza in franja:
        par_prisma(h, "Alas", "borde", pieza, z)


def feston(frente, atras):
    """Contorno, parte oscura y franja de un segmento cuyo borde de atrás `atras` es una función de
    x (de afuera hacia adentro; puede bajar en vertical): la franja es el borde corrido 1 celda
    hacia adelante, en un paralelogramo por tramo."""
    adentro = frente + [(x, y - 1) for x, y in atras]
    franja = [[p, q, (q[0], q[1] - 1), (p[0], p[1] - 1)] for p, q in zip(atras, atras[1:]) if p[0] != q[0]]
    return frente + atras, adentro, franja


def alas():
    a = "Alas"
    # Ala1: brazo y la membrana junto al cuerpo (del hombro a la cadera).
    h = "Ala{lado}1"
    par_prisma(h, a, "cuerpo", [(3, -2), (6, -5), (6, -3), (3, 0)], (9, 11))
    membrana(h, (9, 10), *feston([(3, 0), (6, -3), (7, -3)], [(7, 13), (6, 11), (6, 9), (5, 7), (4, 6), (3, 6)]))
    # Ala2: muñeca con el pulgar, el comienzo de los dedos 1 y 2 y el dedo 3 entero.
    h = "Ala{lado}2"
    par_prisma(h, a, "cuerpo", [(6, -6), (8, -6), (8, -3), (6, -3)], (10, 13))  # nudo
    par_prisma(h, a, "garra", [(6, -6), (8, -6), (7, -7)], (10, 12))  # pulgar
    par_prisma(h, a, "cuerpo", [(8, -6), (10, -5), (10, -3), (8, -4)], (10, 12))  # dedo 1
    par_prisma(h, a, "cuerpo_osc", [(7, -3), (8, -3), (10, 1), (10, 3)], (11, 12))  # dedo 2
    par_prisma(h, a, "cuerpo_osc", [(6, -3), (7, -3), (7, 12), (6, 11)], (11, 12))  # dedo 3
    membrana(h, (10, 11), *feston([(6, -3), (8, -3), (8, -4), (10, -3), (11, -3)],
                                  [(11, 7), (10, 6), (9, 6), (8, 8), (8, 13), (7, 13), (6, 11)]))
    # Ala3: la punta del dedo 1 (la del ala, en gancho) y la del dedo 2, con los festones a los dos
    # lados. El borde de afuera no es función de x: la franja va a mano y la punta del ala es toda
    # de brasa. La parte oscura va en dos piezas: trocear no corta por la prolongación de un lado.
    h = "Ala{lado}3"
    par_prisma(h, a, "cuerpo", [(10, -5), (16, -2), (16, 0), (10, -3)], (11, 13))  # dedo 1
    par_prisma(h, a, "cuerpo_osc", [(10, 1), (10, 3), (14, 11), (15, 11)], (12, 13))  # dedo 2
    membrana(h, (11, 12),
             [(10, -3), (12, -2), (14, -1), (16, 0), (16, 2), (12, 4), (12, 5), (15, 11), (15, 12), (13, 11),
              (11, 7), (10, 6)],
             [[(10, -3), (12, -2), (14, -1), (14, 2), (12, 3), (11, 4), (11, 5), (13, 9), (13, 10), (11, 6),
               (10, 5)],
              [(13, 9), (14, 11), (13, 11)]],
             [[(14, -1), (16, 0), (16, 2), (14, 3)], [(14, 3), (12, 4), (12, 3), (14, 2)],
              [(12, 3), (12, 5), (11, 5), (11, 4)], [(12, 5), (15, 11), (14, 11), (11, 5)],
              [(13, 11), (15, 11), (15, 12)], [(13, 11), (11, 7), (11, 6), (13, 10)],
              [(11, 7), (10, 6), (10, 5), (11, 6)]])
