r"""
Forma de la versión 4 del volcán (volcan_cueva.py): una montaña volcánica cerrada, más grande
que la v3, con una copa de lava en la cumbre y, adentro, la cueva del gigante. La única
entrada es el arco. Lo carga volcan_cueva.py con exec (usa L, height, material, lava_vein,
smooth y lo de volcan_cono_forma.py: ISLA, PUERTA_DEG, desvio).

Por fuera (exterior):
    copa        lago de lava a LAVA_Y en la cumbre (radio COPA_R), con borde irregular
                (ALTO_CIMA más picos) y muescas por donde la lava DESBORDA y baja
    ladera      cóncava hasta el mar, con barrancos radiales; base de R_BASE de radio
    frente      hacia la isla, una fachada que se corta en FRENTE (el centro del arco) y se
                abre en V a los costados; lejos de la playa de la isla (ISLA_PLAYA) y del
                corredor del puente
Adentro (cueva): el lago, su fondo, el acantilado y el paseo a 30 salen de height(), igual
que ahora; encima, una bóveda de roca en escalones (techo()) que sobre el centro del lago
queda a TECHO_CENTRO (el gigante final mide 198) y baja hasta TECHO_BORDE sobre el paseo,
con pocas estalactitas sobre el paseo y vetas de lava.
El arco: un hueco de 2 x ARCO_MEDIO de ancho y de 30 a ARCO_ALTO para el modelo, y detrás un
túnel plano a 30 de 2 x TUNEL_MEDIO de ancho y techo a TUNEL_ALTO hasta el paseo.
"""

FONDO = L["craterFloor"] - 12  # todo lo sólido empieza acá abajo (no se ve)
MAR = L["seaFloorHeight"]
PASEO = L["craterRimHeight"]
WALK_END = L["craterCliffRadius"] + L["craterWalkWidth"]
R_BASE = 580  # radio de la base (con un vaivén de ±30)
R_MAX = R_BASE + 34
COPA_R, COPA_BORDE = 92, 128  # el lago de lava y el ancho del borde de la copa
LAVA_Y, ALTO_CIMA = 318, 346  # el lago de lava y el alto medio del borde
FRENTE = L["craterRimOuter"] - 3  # 262: el centro del arco, desde el cráter hacia la isla
ARCO_MEDIO, ARCO_ALTO, ARCO_HONDO = 36, PASEO + 74, 10  # hueco del modelo (69.35 x 72.84 x 18)
TUNEL_MEDIO, TUNEL_ALTO = 23, PASEO + 60  # el vano del arco mide 37
CORREDOR = 42  # medio ancho libre para el puente delante del arco
FACHADA = 24  # roca sobre el arco
ISLA_PLAYA = L["beachEndRadius"] + 40  # la montaña no se acerca más a la isla
TECHO_CENTRO, TECHO_BORDE = 252, 102  # la bóveda: sobre el centro del lago y sobre el paseo
# Por dónde desborda la copa: (grados alrededor del cráter, hasta qué parte de la ladera baja).
DESBORDES = ((38, 0.8), (112, 0.62), (163, 0.85), (214, 0.58), (332, 0.72))


def eje_puerta(dx, dz):
    """(cuánto avanza hacia la isla, distancia al eje del puente)."""
    g = math.radians(PUERTA_DEG)
    return dx * math.cos(g) + dz * math.sin(g), abs(-dx * math.sin(g) + dz * math.cos(g))


def alto_cima(a):
    return ALTO_CIMA + 14 * max(0.0, math.sin(7 * a + 0.5)) ** 2 + 8 * abs(math.sin(19 * a + 1.2))


def radio_base(a):
    return R_BASE + 30 * math.sin(3 * a + 0.7)


def desborde(grados, rho):
    """(0..1 dentro de un canal de lava que baja de la copa, hasta qué parte de la ladera)."""
    mejor, largo = 0.0, 0.0
    for g, hasta in DESBORDES:
        centro = g + math.degrees(7 * math.sin(rho * 0.04 + g) / max(rho, 1))
        lateral = math.radians(desvio(grados, centro)) * rho
        cerca = 1 - smooth((lateral - (8 + rho * 0.012)) / 6)
        if cerca > mejor:
            mejor, largo = cerca, hasta
    return mejor, largo


def ladera(rho, a):
    """El cono natural, sin nada del frente: (alto, H, canal, largo, u) o None más allá de la
    base. u = -1 en la copa y su borde (ya tienen su material)."""
    R = radio_base(a)
    if rho >= R:
        return None
    grados = math.degrees(a)
    H = alto_cima(a)
    canal, largo = desborde(grados, rho)
    if rho < COPA_R:
        return LAVA_Y, H, 1.0, 1.0, -1.0
    if rho < COPA_BORDE:  # el borde de la copa, con muescas donde desborda
        return H - (H - LAVA_Y + 2) * canal, H, canal, 1.0, -1.0
    u = (rho - COPA_BORDE) / (R - COPA_BORDE)
    h = MAR + (H - MAR) * (1 - u) ** 1.45
    surco = 1 - abs(math.sin(a * 34 + 0.6 * math.sin(a * 7)))
    h -= 12 * surco ** 3 * math.sin(math.pi * min(u, 1.0))
    return h, H, canal, largo, u


def material_ladera(h, H, canal, largo, u):
    if u < 0:  # la copa y su borde
        return "lava" if canal > 0.5 else "cumbre"
    if h < L["waterLevel"] + 3:
        return "roca"
    if canal > 0.5 and u < largo:
        return "lava"
    if h > H - 60:
        return "cumbre"
    if h < 26:
        return "falda"
    return "basalto"


def exterior(dx, dz):
    """(alto, material) de la superficie de afuera, o None (mar, frente o isla)."""
    rho, a = math.hypot(dx, dz), math.atan2(dz, dx)
    avance, lateral = eje_puerta(dx, dz)
    if math.hypot(dx - ISLA[0], dz - ISLA[1]) < ISLA_PLAYA:
        return None
    if avance > FRENTE + max(0.0, lateral - 60) * 0.9:
        return None  # la fachada: el arco queda incrustado y el puente llega por fuera
    natural = ladera(rho, a)
    if natural is None:
        return None
    h, H, canal, largo, u = natural
    if u >= 0:
        # Hacia la isla la montaña baja en escalones hasta el arco (que queda enmarcado por
        # FACHADA de roca encima), en vez de cortarse en una pared plana.
        tope = ARCO_ALTO + FACHADA + max(0.0, FRENTE - avance) * 1.4 + max(0.0, lateral - 45) * 0.6
        tope += 9 * math.sin(avance * 0.11 + lateral * 0.07) + 7 * math.sin(lateral * 0.19 + 1.3)
        h = min(h, tope)
        # Lejos del arco, la ladera baja al mar antes del corte del frente (sin paredes planas).
        hasta_corte = FRENTE + max(0.0, lateral - 60) * 0.9 - avance
        lado = smooth((lateral - 110) / 60)
        h = min(h, h * (1 - lado) + (MAR + hasta_corte * 1.3) * lado)
        if rho < WALK_END + 36:  # la pared de la cueva: nunca más baja que su techo
            h = max(h, TECHO_BORDE + 34)
    return h, material_ladera(h, H, canal, largo, u)


def techo(dx, dz, bloque_i, bloque_j):
    """Alto de la bóveda de la cueva (escalones irregulares y pocas estalactitas)."""
    rho, a = math.hypot(dx, dz), math.atan2(dz, dx)
    t = min(rho / WALK_END, 1.0)
    alto = TECHO_CENTRO - (TECHO_CENTRO - TECHO_BORDE) * t ** 2.6
    alto += 6 * math.sin(7 * a + rho * 0.05) + 5 * math.sin(13 * a - rho * 0.08)
    if rho < 90:  # (90: los bloques de 2 x 2 del borde también)
        alto = max(alto, 241.0)  # sobre el gigante (198 de alto, parado cerca de y = 2)
    sobre_paseo = WALK_END - 38 < rho < WALK_END - 4
    if sobre_paseo and (bloque_i * 92821 ^ bloque_j * 68917) % 19 == 0:
        alto = max(alto - 20, PASEO + 50)  # estalactita (solo sobre el paseo y el acantilado)
    return alto


def cueva(dx, dz):
    """(piso, material del piso, techo base) de una columna con aire adentro, o None. El techo
    base None quiere decir que lo pone techo() (la bóveda)."""
    rho, a = math.hypot(dx, dz), math.atan2(dz, dx)
    if rho < WALK_END:
        piso = height(rho, a)
        return piso, material(rho, a, piso), None
    avance, lateral = eje_puerta(dx, dz)
    if lateral <= ARCO_MEDIO and FRENTE - ARCO_HONDO <= avance <= FRENTE + ARCO_HONDO:
        return PASEO, "basalto", ARCO_ALTO  # el hueco del arco (el modelo va acá)
    if lateral <= TUNEL_MEDIO and WALK_END - 6 <= avance < FRENTE - ARCO_HONDO:
        return PASEO, "basalto", TUNEL_ALTO  # el túnel hasta el paseo
    return None


def material_techo(dx, dz):
    rho, a = math.hypot(dx, dz), math.atan2(dz, dx)
    return "lava" if lava_vein(a * 1.4, rho * 1.3) else "techo"


def vena_pared(i, j):
    """Ríos de lava que bajan por las paredes de la cueva (columnas enteras)."""
    a = math.atan2(j + 0.5, i + 0.5)
    return math.sin(a * 23 + 1.7) > 0.93


def bloque_exterior(rho):
    return 2 if rho < 300 else 3
