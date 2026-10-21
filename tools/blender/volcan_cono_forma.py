r"""
Forma de la versión 3 del volcán (volcan_bloques.py -- --forma cono): un estratovolcán grande
que sube desde el mar y se cierra hacia la boca, en lugar del anillo bajo de montañas sueltas.
Lo carga volcan_bloques.py con exec y redefine forma(), bloque(), R_MAX, referencias() y fotos().

Lo que NO se mueve (es donde se juega): el lago, su fondo, el acantilado y el paseo a 30
(craterCliffRadius + craterWalkWidth) salen de height() igual que ahora. Afuera del paseo:
    pared interior   sube del paseo a la boca, empinada (se ve como estar dentro del volcán)
    boca             el borde, ALTO_BOCA de alto medio con picos irregulares
    ladera           cóncava como la de un estratovolcán: empinada arriba, tendida abajo,
                     con barrancos radiales, coladas de lava y un cono secundario en la falda
    garganta         hacia la isla (la puerta del puente): un cañón plano a 30 hasta
                     craterRimOuter, de 2 x CANON de ancho, con paredes que enmarcan el arco
La base llega a R_ATRAS hacia los lados y atrás, y a R_PUERTA hacia la isla; cerca de la isla
(dentro de ISLA_LIBRE de su centro) queda la forma de ahora, así no se mete en la isla ni
en el puente. Lejos (BLOQUE_MEDIO, BLOQUE_LEJOS) las columnas se juntan en bloques de 2 x 2 y
3 x 3: menos detalle donde no se camina.
"""

WALK_END = L["craterCliffRadius"] + L["craterWalkWidth"]  # el paseo: no se toca
BOCA = WALK_END + 38  # radio del borde de la boca
ALTO_BOCA = 140  # alto medio del borde (los picos suben más)
R_ATRAS, R_PUERTA = 480, L["craterBaseRadius"]  # radio de la base: atrás / hacia la isla
R_MAX = R_ATRAS + 8
ISLA = (-L["craterCenter"][0], -L["craterCenter"][1])  # centro de la isla, desde el cráter
ISLA_LIBRE = L["shelfRadius"] + 8  # más cerca de la isla queda la forma de ahora
CANON, CANON_PARED = 46, 26  # medio ancho de la garganta y lo que tarda en subir su pared
PUERTA_DEG = (L["bridgeAngle"] + 180) % 360
BLOQUE_MEDIO, BLOQUE_LEJOS = 300, 400  # desde estos radios, bloques de 2 x 2 y 3 x 3
# Coladas de lava: (grados alrededor del cráter, hasta qué parte de la ladera bajan).
COLADAS = ((22, 0.78), (58, 0.62), (96, 0.86), (134, 0.7), (168, 0.58), (204, 0.74),
           (322, 0.66), (350, 0.8))
CONO2 = (38, 420, 72, 84)  # cono secundario: grados, distancia, radio, alto

COLORES["falda"] = ((126, 108, 98), (86, 74, 70))  # ceniza tibia de la parte baja
NOMBRES[:] = [f"{c}_{l}" for c in COLORES for l in CARAS]


def desvio(grados, centro):
    """Grados (0..180) entre una dirección y otra."""
    return abs((grados - centro + 180) % 360 - 180)


def radio_base(grados):
    return R_PUERTA + (R_ATRAS - R_PUERTA) * smooth((desvio(grados, PUERTA_DEG) - 35) / 70)


def alto_boca(a):
    """Alto del borde: más bajo junto a la garganta (el volcán se abre hacia la isla),
    con picos filosos alrededor."""
    lejos = smooth((desvio(math.degrees(a), PUERTA_DEG) - 18) / 75)
    picos = 22 * max(0.0, math.sin(9 * a + 1.0)) ** 2 + 10 * abs(math.sin(23 * a + 0.5))
    return ALTO_BOCA * (0.8 + 0.2 * lejos) + picos * (0.4 + 0.6 * lejos)


def cono(rho, a):
    """Altura del cono afuera del paseo, sin la garganta; None más allá de la base."""
    H = alto_boca(a)
    if rho <= BOCA:  # pared interior
        s = (rho - WALK_END) / (BOCA - WALK_END)
        return L["craterRimHeight"] + (H - L["craterRimHeight"]) * max(s, 0.0) ** 0.6
    R = radio_base(math.degrees(a))
    if rho >= R:
        return None
    u = (rho - BOCA) / (R - BOCA)
    h = L["seaFloorHeight"] + (H - L["seaFloorHeight"]) * (1 - u) ** 1.6
    # Barrancos radiales, más hondos a media ladera.
    surco = 1 - abs(math.sin(a * 30 + 0.6 * math.sin(a * 7)))
    h -= 10 * surco ** 3 * math.sin(math.pi * min(u, 1.0))
    return h


def canon(rho, a):
    """1 dentro de la garganta hacia la isla, 0 afuera (sube suave por las paredes)."""
    d = math.radians(desvio(math.degrees(a), PUERTA_DEG))
    if math.cos(d) <= 0:
        return 0.0
    lateral = rho * math.sin(d)
    return 1 - smooth((lateral - CANON) / CANON_PARED)


def cono_chico(dx, dz):
    g, r, radio, alto = CONO2
    cx, cz = r * math.cos(math.radians(g)), r * math.sin(math.radians(g))
    d = math.hypot(dx - cx, dz - cz)
    if d >= radio:
        return None, False
    h = L["seaFloorHeight"] + (alto - L["seaFloorHeight"]) * (1 - d / radio) ** 1.3
    boca = d < 12
    return (h - 6 if boca else h), boca


def forma(dx, dz):
    rho, a = math.hypot(dx, dz), math.atan2(dz, dx)
    grados = math.degrees(a)
    actual = height(rho, a)  # la forma de ahora (lago, acantilado, paseo, puerta)
    if rho < WALK_END:
        return None if actual is None else (actual, material(rho, a, actual))
    if math.hypot(dx - ISLA[0], dz - ISLA[1]) < ISLA_LIBRE:
        return None if actual is None else (actual, material(rho, a, actual))
    alto = cono(rho, a)
    c = canon(rho, a)
    if c > 0 and actual is not None:
        alto = actual * c + (alto if alto is not None else actual) * (1 - c)
    chico, boca_chica = cono_chico(dx, dz)
    if chico is not None and (alto is None or chico > alto):
        alto = chico
    if alto is None:
        return None
    return alto, material_cono(rho, a, grados, alto, c, boca_chica)


def material_cono(rho, a, grados, h, c, boca_chica):
    if c > 0.5 and h < L["craterRimHeight"] + 2:
        return "basalto"  # el piso de la garganta
    if h < L["waterLevel"] + 3:
        return "roca"
    if boca_chica:
        return "lava"
    if rho <= BOCA:
        return "lava" if lava_vein(a, rho) else "basalto"
    R = radio_base(grados)
    u = (rho - BOCA) / (R - BOCA)
    for g, largo in COLADAS:
        centro = g + math.degrees(6 * math.sin(rho * 0.045 + g) / rho)  # serpentea ~6 studs
        if 0.02 < u < largo and abs(math.radians(desvio(grados, centro)) * rho) < 7 + 5 * u:
            return "lava"
    if h > alto_boca(a) - 14:
        return "cumbre"
    if h < 24:
        return "falda"
    return "basalto"


def bloque(dx, dz):
    rho = math.hypot(dx, dz)
    return 1 if rho < BLOQUE_MEDIO else 2 if rho < BLOQUE_LEJOS else 3


# --- Referencias y fotos -------------------------------------------------------------------
def isla_referencia():
    """La isla en primitivas (meseta y playa) para ver el tamaño del volcán al lado."""
    for nombre, radio, alto, color in (("Playa", L["beachEndRadius"], 1.0, (0.86, 0.72, 0.46, 1)),
                                       ("Meseta", L["plateauRadius"], L["plateauHeight"], (0.3, 0.62, 0.22, 1))):
        me = bpy.data.meshes.new(nombre)
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=48, radius1=radio, radius2=radio, depth=alto + 20)
        bmesh.ops.translate(bm, vec=punto(ISLA[0], ISLA[1], alto - (alto + 20) / 2), verts=bm.verts)
        bm.to_mesh(me)
        bm.free()
        o = bpy.data.objects.new(f"Isla {nombre} (solo revisión)", me)
        mat = bpy.data.materials.new(nombre)
        mat.use_nodes = True
        mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = color
        o.data.materials.append(mat)
        referencia(o)


def arco_referencia():
    """La caja del arco del volcán (69 x 73 x 18, en craterRimOuter - 3) para ver si entra."""
    me = bpy.data.meshes.new("Arco")
    bm = bmesh.new()
    for x, ancho, alto in ((-26, 17, 60), (26, 17, 60), (0, 69, 13)):
        pieza = bmesh.new()
        bmesh.ops.create_cube(pieza, size=1)
        z = alto / 2 if alto == 60 else 60 + alto / 2
        bmesh.ops.scale(pieza, vec=V((ancho, 18, alto)), verts=pieza.verts)
        bmesh.ops.translate(pieza, vec=punto(x, -(L["craterRimOuter"] - 3), L["craterRimHeight"] + z), verts=pieza.verts)
        tmp = bpy.data.meshes.new("tmp")
        pieza.to_mesh(tmp)
        pieza.free()
        bm.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("Arco (solo revisión)", me)
    mat = bpy.data.materials.new("ArcoRef")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.12, 0.08, 0.1, 1)
    o.data.materials.append(mat)
    referencia(o)


def puente_inclinado():
    """El puente de verdad sube de la meseta (deckHeight) a la puerta (craterDeckHeight)."""
    inicio = -(math.hypot(*ISLA) - L["bridgeStartRadius"])
    fin = -(L["craterRimOuter"] - 2)
    w = L["bridgeWidth"] / 2
    me = bpy.data.meshes.new("Puente")
    bm = bmesh.new()
    vs = [bm.verts.new(punto(x, z, y)) for x, z, y in (
        (-w, inicio, L["deckHeight"]), (w, inicio, L["deckHeight"]),
        (w, fin, L["craterDeckHeight"]), (-w, fin, L["craterDeckHeight"]))]
    bm.faces.new(vs)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("Puente (solo revisión)", me)
    mat = bpy.data.materials.new("Madera")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.36, 0.2, 0.09, 1)
    o.data.materials.append(mat)
    referencia(o)


def referencias():
    plano_agua()
    puente_inclinado()
    isla_referencia()
    arco_referencia()


def fotos(cam, grilla):
    rim = L["craterRimHeight"]
    puente_inicio = -(math.hypot(*ISLA) - L["bridgeStartRadius"])  # dz del inicio del puente
    # 1. Desde la isla, a la altura de un jugador al empezar el puente.
    foto(cam, "1_desde_la_isla", punto(-40, puente_inicio - 20, L["plateauHeight"] + 6),
         punto(0, 0, 75), 20)
    # 2. Aérea 3/4 con la isla de referencia.
    foto(cam, "2_aerea", punto(760, -1050, 560), punto(0, -200, 10), 30)
    # 3. Desde el paseo, junto a la garganta, mirando la pared del cono del otro lado.
    paseo = L["craterCliffRadius"] + 10
    foto(cam, "3_desde_el_paseo", punto(-30, -paseo, rim + 6), punto(40, 260, 95), 20)
    # 4. Cenital.
    foto(cam, "4_cenital", V((0, 0, 2100)), V((0, 0.01, 0)), 40)
