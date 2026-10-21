r"""
Forma de la versión 5 del volcán (volcan_pie.py): la montaña entera, sin cortes, y el arco al
pie del lado de la isla; la isla se aleja para que el puente mida lo mismo. Lo carga
volcan_pie.py con exec después de volcan_cueva.py (usa ladera(), material_ladera(), techo(),
la cueva de la v4 y las referencias).

    R_A         radio del arco desde el centro del cráter: el primer punto del eje hacia la
                isla donde la ladera natural baja de ALTO_PIE (el pie de la montaña)
    espolón     una saliente de roca que cubre el arco (ARCO_ALTO + 24 encima) y sube como
                cresta sobre el túnel hasta fundirse con la ladera
    salientes   rocas a los costados del arco, de alturas distintas
    rellano     plataforma a 30 delante del arco, a los costados del puente (el puente baja
                desde el arco: debajo de él el suelo baja en escalones bajo el tablero);
                en sus bordes, vetas de lava que enmarcan la puerta
    túnel       plano a 30 desde el arco hasta el paseo de la cueva, con paredes y techo
                irregulares y ríos de lava en las paredes cada tanto
    isla        en (0, -(R_A + 258)) desde el cráter: el ancla del arco sigue en z = 258 de la
                isla y el puente sale de su radio 142 igual que hoy. Dentro de ISLA_AGUA de su
                centro la falda queda bajo el agua (salvo el espolón y el rellano)
"""

ALTO_PIE = 45  # la ladera natural a esta altura marca el pie de la montaña
ARCO_Z_ISLA = 258  # el centro del ancla del arco, desde el centro de la isla (Roblox)
ISLA_AGUA = 270  # dentro de este radio de la isla la falda no sale del agua
ESPOLON_ANCHO, ESPOLON_LARGO = 62, 150  # medio ancho y largo de la saliente sobre el túnel
RELLANO, RELLANO_MEDIO = 18, 50  # fondo y medio ancho de la plataforma delante del arco
PUENTE_LARGO = ARCO_Z_ISLA - L["bridgeStartRadius"]  # 116: igual que hoy


def _pie():
    g = math.radians(PUERTA_DEG)
    for r in range(260, 620, 2):
        natural = ladera(r, g)
        if natural is None or natural[0] <= ALTO_PIE:
            return float(r)
    return 600.0


R_A = _pie()
ISLA = (0.0, -(R_A + ARCO_Z_ISLA))  # el centro de la isla, desde el cráter
CRATER_Z_ROBLOX = R_A + ARCO_Z_ISLA  # el nuevo craterCenter = (0, CRATER_Z_ROBLOX)


def zona_entrada(avance, lateral):
    """El espolón, las salientes y el rellano: lo único que sale del agua cerca de la isla."""
    return lateral <= ESPOLON_ANCHO + 30 and R_A - ESPOLON_LARGO <= avance <= R_A + ARCO_HONDO + RELLANO


def bloque_columna(dx, dz):
    """En la entrada, columnas sueltas: un bloque grande taparía el arco con el espolón."""
    avance, lateral = eje_puerta(dx, dz)
    if lateral <= ESPOLON_ANCHO + 50 and avance >= R_A - ESPOLON_LARGO - 20:
        return 1
    return bloque_exterior(math.hypot(dx, dz))


def exterior(dx, dz):
    rho, a = math.hypot(dx, dz), math.atan2(dz, dx)
    avance, lateral = eje_puerta(dx, dz)
    natural = ladera(rho, a)
    h, H, canal, largo, u = natural if natural else (MAR, ALTO_CIMA, 0.0, 0.0, 1.0)
    # Cerca de la isla la falda baja suave hasta quedar bajo el agua.
    isla = math.hypot(dx - ISLA[0], dz - ISLA[1])
    h = min(h, MAR + 16 + (isla - ISLA_AGUA) * 1.0)
    mat = None
    frente_arco = R_A + ARCO_HONDO
    if zona_entrada(avance, lateral):
        # El espolón: una nariz redondeada que cubre el arco (y su túnel) y baja a los costados.
        nariz = frente_arco - (max(0.0, lateral - ARCO_MEDIO) / ESPOLON_ANCHO) ** 2 * 46
        if avance <= nariz:
            alto = ARCO_ALTO + 24 + (R_A - avance) * 0.35 - max(0.0, lateral - 30) * 0.9
            alto += 6 * math.sin(avance * 0.13 + lateral * 0.2) + 5 * math.sin(lateral * 0.31)
            w = 1 - smooth((lateral - ESPOLON_ANCHO) / 30)
            w *= 1 - smooth((R_A - ESPOLON_LARGO + 40 - avance) / 40)  # se funde atrás
            h = max(h, alto * w + h * (1 - w))
        if 38 <= lateral <= 74 and R_A - 8 <= avance <= frente_arco + RELLANO:  # salientes
            k = (int(lateral // 8) * 7919 + int(avance // 8) * 104729) % 7
            if k < 4:
                h = max(h, PASEO + 26 + k * 13)
                mat = "lava" if k == 0 else None
        if lateral <= RELLANO_MEDIO and frente_arco < avance <= frente_arco + RELLANO:
            h = PASEO  # el rellano
            mat = "lava" if lateral >= RELLANO_MEDIO - 6 else "basalto"
            if lateral <= L["bridgeWidth"] / 2 + 2:  # bajo el puente, que baja desde el arco
                tablero = L["craterDeckHeight"] - (L["craterDeckHeight"] - L["deckHeight"]) * (avance - R_A) / PUENTE_LARGO
                h = ESCALON * math.floor((tablero - 1) / ESCALON)
    if rho < WALK_END + 36:
        h = max(h, TECHO_BORDE + 34)
    if h <= MAR + 0.5:
        return None
    return h, mat or material_ladera(h, H, canal, largo, u)


def cueva(dx, dz):
    rho, a = math.hypot(dx, dz), math.atan2(dz, dx)
    if rho < WALK_END:
        piso = height(rho, a)
        return piso, material(rho, a, piso), None
    avance, lateral = eje_puerta(dx, dz)
    if lateral <= ARCO_MEDIO and R_A - ARCO_HONDO <= avance <= R_A + ARCO_HONDO:
        return PASEO, "basalto", ARCO_ALTO
    ancho = TUNEL_MEDIO + 3 * math.sin(avance * 0.09) + 2 * math.sin(avance * 0.23 + 1)
    if lateral <= ancho and WALK_END - 6 <= avance < R_A - ARCO_HONDO:
        return PASEO, "basalto", TUNEL_ALTO + 2 * round(2 * math.sin(avance * 0.07))
    return None


def vena_pared(i, j):
    dx, dz = (i + 0.5) * CELDA, (j + 0.5) * CELDA
    if math.hypot(dx, dz) < WALK_END + 8:
        return math.sin(math.atan2(dz, dx) * 23 + 1.7) > 0.93
    avance, _ = eje_puerta(dx, dz)
    return int(avance // CELDA) % 11 == 0  # en el túnel, un río de lava cada 44 studs


# --- Referencias y fotos -------------------------------------------------------------------
def arco_referencia():
    me = bpy.data.meshes.new("Arco")
    bm = bmesh.new()
    for x, ancho, alto in ((-26, 17, 60), (26, 17, 60), (0, 69, 13)):
        pieza = bmesh.new()
        bmesh.ops.create_cube(pieza, size=1)
        z = alto / 2 if alto == 60 else 60 + alto / 2
        bmesh.ops.scale(pieza, vec=V((ancho, 18, alto)), verts=pieza.verts)
        bmesh.ops.translate(pieza, vec=punto(x, -R_A, PASEO + z), verts=pieza.verts)
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
    inicio = -(R_A + ARCO_Z_ISLA - L["bridgeStartRadius"])
    fin = -(R_A + 1)
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


def luces_cueva():
    for k in range(8):
        a = math.radians(k * 45 + 10)
        luz(f"LavaCueva{k}", punto(170 * math.cos(a), 170 * math.sin(a), 90), 6e5)
    luz("LavaTecho", punto(0, 0, 200), 1.5e6, (1.0, 0.6, 0.3), 30)
    for k, d in enumerate(range(int(WALK_END) + 10, int(R_A), 45)):
        luz(f"Tunel{k}", punto(0, -d, PASEO + 40), 6e4)


def fotos_cueva(cam, grilla):
    isla_x, isla_z = ISLA
    foto(cam, "1_desde_la_plaza", punto(isla_x + 30, isla_z + 40, L["plateauHeight"] + 5),
         punto(0, -R_A * 0.45, 170), 22)
    foto(cam, "2_aerea", punto(1700, -(R_A + 1000), 1300), punto(0, -R_A * 0.6, 60), 28)
    foto(cam, "3_arco_de_cerca", punto(0, -(R_A + 110), 46), punto(0, -R_A, 70), 26)
    foto(cam, "4_tunel", punto(4, -(R_A - 22), PASEO + 8), punto(0, -(WALK_END - 20), PASEO + 14), 22)
    paseo = L["craterCliffRadius"] + 12
    foto(cam, "5_cueva", punto(25, -paseo, PASEO + 6), punto(-20, 150, 150), 16)
    foto(cam, "6_cenital", V((0, (R_A + ARCO_Z_ISLA) / 2, 3300)), V((0, (R_A + ARCO_Z_ISLA) / 2 + 0.01, 0)), 40)


BLEND = os.path.join(RAIZ, "assets", "blender", "volcan_v2", "volcan_bloques_4d.blend")
RENDERS = os.path.join(RAIZ, "renders", "volcan_v2e")
