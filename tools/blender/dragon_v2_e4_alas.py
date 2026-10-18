r"""
Alas del anciano del dragón marino v2 (la carga dragon_v2_e4_geometria.py): descomunales, de
murciélago, con el festón muy hondo en ESCALONES (la membrana está hecha de celdas: el borde de
atrás baja en escalones de una celda, como desgarrado, y sigue sólida), el borde de lava y
ganchos marfil grandes en las puntas de los dedos y en el pulgar.

Vista de arriba del ala izquierda, en celdas (x hacia afuera, -y hacia el hocico):
  - Brazo (Ala1): el borde de adelante sube del hombro (x 4, y -4) a la muñeca (x 9) 2:1 hacia
    adelante. Grueso: una celda por debajo y otra por encima de la membrana.
  - Muñeca (Ala2): nudo de x 9..12, y -7..-3 (detrás de la cabeza: al subir el ala no llega a
    las mejillas) con el pulgar en gancho hacia adelante.
  - Dedo 1, el borde de adelante: hacia afuera y un poco atrás (2:1) hasta la punta del ala, que termina
    en un gancho hacia atrás con la cara plana en x 18 (la envergadura exacta).
  - Dedo 2: hacia atrás y afuera (1:2) hasta su gancho. Dedo 3: derecho hacia atrás, en relieve
    sobre la membrana, hasta su gancho largo.
  - Festones entre la punta y el dedo 2, entre el 2 y el 3 (el más hondo) y entre el 3 y la
    cadera. El borde de atrás es de lava (una celda), en escalones.
Tejas (docs/plan_dragon_v2.md, "Juntas"): Ala1 va de x 4 a 10 (membrana en z 10), Ala2 de 9 a 14
(z 11) y Ala3 de 13 a 18 (z 12); cada uno empieza una celda adentro del anterior y una más arriba.
Los huesos de cada segmento (brazo, nudo, dedos) no pasan del borde donde empieza el siguiente.
Alturas de cada segmento (z0 = abajo de la membrana): membrana z0..z0+1; el borde de adelante
(brazo, nudo, dedo 1) z0-1..z0+2; los dedos 2 y 3 y los ganchos, en relieve z0+1..z0+2.
La membrana no entra en los huesos del borde: de los del mismo segmento se quitan
las celdas que quedan tapadas del todo y las que tocan por dentro una cara recta del hueso (así
nunca quedan dos caras en el mismo plano; las que solo asoman bajo un borde en diagonal, como el del
brazo, quedan y tapan la rendija); de los huesos del segmento vecino que cruzan su altura, todas
las que se meten aunque sea un poco.
"""
# Contorno de la membrana del ala izquierda (celdas), con los tres festones. El borde de adelante va
# por el medio del brazo y del dedo 1 (en diagonal): así ninguna celda asoma por delante de ellos.
MEMBRANA_ALA = [(4, -3), (8, -5), (9, -7), (13, -7), (13, -6), (17, -4), (17, -1), (15, -1), (15, 1), (16, 3),
                (16, 5), (14, 3), (13, 1), (12, 3), (11, 7), (11, 10), (10, 7), (9, 5), (7, 3), (5, 4), (4, 7)]
# Segmentos: (hueso, x desde, x hasta, z0).
SEGMENTOS_ALA = [("Ala{lado}1", 4, 10, 10), ("Ala{lado}2", 9, 14, 11), ("Ala{lado}3", 13, 18, 12)]
# Huesos del ala izquierda: (hueso, color, polígono xy, z, tipo). "borde": envuelve la membrana
# (z0-1..z0+2); "relieve": encima de la membrana (z0+1..z0+2), como los dedos y los ganchos (placas
# de una celda: de arriba se leen grandes y de costado no tapan el cuerpo).
HUESOS_ALA = [
    ("Ala{lado}1", "cuerpo", [(4, -4), (8, -6), (9, -6), (9, -4), (5, -2), (4, -2)], (9, 12), "borde"),  # brazo
    ("Ala{lado}2", "cuerpo", [(9, -7), (12, -7), (12, -3), (9, -3)], (10, 14), "borde"),  # nudo
    ("Ala{lado}2", "marfil", [(9, -7), (11, -7), (10, -9)], (12, 13), "relieve"),  # pulgar
    ("Ala{lado}2", "cuerpo", [(12, -7), (13, -7), (13, -5), (12, -5)], (10, 13), "borde"),  # dedo 1
    ("Ala{lado}2", "cuerpo", [(12, -4), (13, -4), (13, -2)], (12, 13), "relieve"),  # dedo 2
    ("Ala{lado}2", "cuerpo", [(10, -3), (11, -3), (11, 8), (10, 8)], (12, 13), "relieve"),  # dedo 3
    ("Ala{lado}2", "marfil", [(10, 8), (11, 8), (11, 10), (10, 12)], (12, 13), "relieve"),  # su gancho
    ("Ala{lado}3", "cuerpo", [(13, -7), (17, -5), (17, -3), (13, -5)], (11, 14), "borde"),  # dedo 1
    ("Ala{lado}3", "marfil", [(17, -5), (18, -4), (18, 0), (17, -2)], (13, 14), "relieve"),  # punta del ala
    ("Ala{lado}3", "cuerpo", [(13, -4), (16, 2), (15, 2), (13, -2)], (13, 14), "relieve"),  # dedo 2
    ("Ala{lado}3", "marfil", [(15, 2), (16, 2), (17, 4), (17, 6), (15, 4)], (13, 14), "relieve"),  # su gancho
]


def _dentro_convexo(p, pol, estricto):
    """p dentro del polígono convexo (cualquier sentido); estricto: no vale el borde."""
    signos = set()
    for a, b in zip(pol, pol[1:] + pol[:1]):
        c = (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
        if abs(c) < 1e-9:
            if estricto:
                return False
            continue
        signos.add(c > 0)
    return len(signos) <= 1


def _choca(celda, pol, cualquiera=False):
    """La celda entra en el hueso: lo tapa del todo, o se mete en él y apoya un lado en una cara
    recta del hueso (por dentro). Con `cualquiera`, basta con que se meta un poco."""
    x, y = celda
    muestras = [(x + (i + 0.5) / 6, y + (j + 0.5) / 6) for i in range(6) for j in range(6)]
    dentro = [_dentro_convexo(p, pol, True) for p in muestras]
    if not any(dentro):
        return False
    if cualquiera:
        return True
    if all(_dentro_convexo(p, pol, False) for p in ((x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1))):
        return True
    lados = [((x, y), (x + 1, y)), ((x, y + 1), (x + 1, y + 1)), ((x, y), (x, y + 1)), ((x + 1, y), (x + 1, y + 1))]
    for a, b in zip(pol, pol[1:] + pol[:1]):
        if a[0] != b[0] and a[1] != b[1]:
            continue  # cara en diagonal: no puede quedar en el plano de un lado de la celda
        for p, q in lados:
            if a[0] == b[0] == p[0] == q[0] and min(max(a[1], b[1]), q[1]) - max(min(a[1], b[1]), p[1]) > 0:
                return True
            if a[1] == b[1] == p[1] == q[1] and min(max(a[0], b[0]), q[0]) - max(min(a[0], b[0]), p[0]) > 0:
                return True
    return False


def _celdas_membrana():
    ala = rasterizar(MEMBRANA_ALA)
    dentro = lambda c: c in ala or c[0] < 4  # el cuerpo cuenta como membrana (no hay borde ahí)
    color = {}
    for x, y in ala:
        atras = not dentro((x, y + 1))
        costado = (not dentro((x + 1, y)) or not dentro((x - 1, y))) and dentro((x, y - 1))
        color[(x, y)] = "lava" if atras or costado else "membrana"
    return color


def alas():
    a = "Alas"
    color = _celdas_membrana()
    for h, x0, x1, z0 in SEGMENTOS_ALA:
        # Los huesos del borde de este segmento envuelven la membrana (z0-1..z0+2); los del vecino
        # empiezan en su plano: con esos no se puede tocar nada.
        propios = [pol for hh, _, pol, _, tipo in HUESOS_ALA if tipo == "borde" and hh == h]
        ajenos = [pol for hh, _, pol, (za, zb), tipo in HUESOS_ALA
                  if tipo == "borde" and hh != h and za < z0 + 1 and zb > z0]
        celdas = {c: v for c, v in color.items()
                  if x0 <= c[0] < x1 and not any(_choca(c, pol) for pol in propios)
                  and not any(_choca(c, pol, True) for pol in ajenos)}
        lamina_celdas(h, a, celdas, (z0, z0 + 1))
    for h, col, pol, z, _ in HUESOS_ALA:
        par_prisma(h, a, col, pol, z)
