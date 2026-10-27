r"""
Hábitat completo del Minotauro (pedido del usuario, 2026-10-23; contrato en
docs/contrato_habitat_completo.md): un laberinto minoico en ruinas, épico, medio enterrado en
la arena del desierto del cráter. Reemplaza a los props sueltos de
Config.Habitats.byGiant.Minotauro. Una sola escena en tamaño real (1 unidad = 1 stud), con el
origen en el centro del cráter a la altura Y = 0 del mundo. Segunda pasada: escala de
laberinto de verdad, masas que se leen desde el paseo y un suelo propio que une el anillo.
    laberinto   tres anillos de muros de sillares grandes (radio 130, 150 y 170; de 18, 22 y
                28 de alto; 5 de grueso) con remates, contrafuertes y tramos caídos grandes,
                muros radiales entre ellos; el de afuera lleva la franja roja con greca de oro;
    arco        la gran puerta (unos 60 de alto) al otro lado del cráter (ángulo 90), de frente
                al centro y a la puerta del volcán, sobre un podio con escalinata;
    zigurat     en el acantilado al este (ángulo 0): cuatro escalones de sillares hasta Y = 30
                como mucho, santuario arriba y una escalinata que baja hacia el centro;
    estatuas    dos minotauros y dos toros de piedra rotos (de 25 a 35) entre los anillos;
    obeliscos   seis, en pares: en la puerta, en la escalinata del zigurat y en la vía del arco;
    columnatas  columnas minoicas de 30 a 37 al pie de la ladera, con dinteles y tambores caídos;
    monumentos  un cráneo de toro gigante semienterrado (ángulo 180), un labrys enorme clavado
                en la arena, braseros (el fuego lo pone el juego: `fuegos` del JSON) y
                estandartes con el labrys;
    suelo       losas del laberinto que asoman en la arena, dunas acumuladas contra los muros y
                sillares caídos por todo el anillo;
    centro      r < 95 libre para el gigante: solo un mosaico del laberinto (losas rojas y de
                oro a ras de la arena, con el patrón de un laberinto) que se lee desde arriba.
La vista desde la puerta del volcán (ángulos 255 a 285, +Y de Blender) queda libre: nada más
alto que una losa entre los jugadores y el gigante.

El cráter del Minotauro es un desierto (Config.Giants: sand = true): todo se apoya en la
superficie de la ARENA (src/client/Ambient/SandShape.luau, portada en
habitat_minotauro_piezas.arena), no en el fondo de roca. Cada pieza se hunde SINK studs en el
punto más bajo de su base y su primera hilada sigue bajo la arena.

Mallas (todas con la MISMA caja: un cubito mínimo en cada esquina de la caja común, simétrica
en X e Y alrededor del eje del cráter; ninguna pasa de 9.800 triángulos):
    MinotauroHabitat1        anillos interiores (130 y 150), sus radiales, la vía del arco y
                             sus sillares caídos
    MinotauroHabitat2        anillo exterior (170) con la greca y sus radiales
    MinotauroHabitat3        columnatas y obeliscos
    MinotauroHabitat4        arco, cráneo, labrys, braseros y estandartes
    MinotauroHabitat5        zigurat y su escalinata
    MinotauroHabitat6        estatuas, dunas y sillares caídos del anillo exterior
    MinotauroHabitat7        losas del suelo, vías procesionales y mosaico del centro
    MinotauroHabitatBrillo1  llamas de los braseros (en el juego, Neon naranja)
Exporta assets/blender/habitat_minotauro/MinotauroHabitat.fbx (textura embebida),
assets/textures/MinotauroHabitat_color.png, assets/blender/habitat_minotauro/
MinotauroHabitat.json y renders en renders/habitat_minotauro/ (con el fondo del cuenco en
gris y la arena, que son solo del render).

Uso sin abrir Blender:
    blender -b --factory-startup --python tools/blender/habitat_minotauro.py -- exportar render
"""
import bpy, bmesh, json, math, os, random, sys
from mathutils import Matrix, Vector

V = Vector
AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = globals().get("RAIZ") or os.path.dirname(os.path.dirname(AQUI))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if AQUI not in sys.path:
    sys.path.insert(0, AQUI)
import habitats as H  # noqa: E402
import habitats_minotauro as HM  # noqa: E402
import habitat_minotauro_piezas as P  # noqa: E402
from habitats import T, girar  # noqa: E402
from habitat_minotauro_piezas import pb, ejes, suelo, pegar, radio_de, angulo_de  # noqa: E402

ID = "MinotauroHabitat"
CARPETA = os.path.join(RAIZ, "assets", "blender", "habitat_minotauro")
FBX = os.path.join(CARPETA, ID + ".fbx")
JSON = os.path.join(CARPETA, ID + ".json")
TEX = os.path.join(RAIZ, "assets", "textures", ID + "_color.png")
RENDERS = os.path.join(RAIZ, "renders", "habitat_minotauro")
MAX_TRIS = 9800
BRILLO = {ID + "Brillo1": (255, 140, 40)}  # llamas de los braseros (como colorBrillo del Brasero)

# ---- distribución ------------------------------------------------------------------------
# Anillos (radio, alto, tramos en grados, lado de los contrafuertes). Huecos: la vista de la
# puerta (250-290), la vía del arco (81-99 en el de 130; 70-110 afuera), la escalinata del
# zigurat (345-15), el cráneo (166-196), el costillar de SandDecor (110-136 en el de 130), el
# fémur (222-243 en el de 150) y la meseta de 128° en el de 170.
ANILLO_A = (130, 18.0, [(15, 40), (50, 81), (99, 110), (136, 166), (176, 212), (222, 250), (290, 318), (326, 345)], 1)
ANILLO_B = (150, 22.0, [(15, 30), (40, 70), (110, 150), (156, 166), (196, 222), (290, 300), (308, 345)], -1)
ANILLO_C = (170, 28.0, [(15, 40), (48, 70), (110, 120), (136, 166), (196, 214), (222, 250), (290, 318), (326, 345)], -1)
RADIALES_AB = [60, 160, 200, 300]  # de 130 a 150
RADIALES_BC = [20, 145, 210, 325]  # de 150 a 170
VIA = (81, 99)  # muros a los lados de la vía del arco, de 130 a 150

ESTATUAS = [(45, "toro"), (135, "minotauro"), (225, "toro_roto"), (315, "minotauro_roto")]
ESTATUA_R = 160.0
OBELISCOS = [(250, 140, False), (290, 140, True), (353, 136, False), (7, 136, False), (84, 140, False), (96, 140, False)]
COLUMNAS_R = 180.0
COLUMNAS = [[30, 36, 42], [64], [116], [140, 146, 152], [202], [224, 230, 236, 242], [296, 302, 308, 314], [342]]
COLUMNA_ALTO = 34.0
ARCO_ANG, ARCO_R = 90, 176.0
CRANEO_ANG, CRANEO_R, CRANEO_ESC = 180, 172.0, 4.2
LABRYS = (304, 157)
ZIGURAT_ANG, ZIGURAT_R = 0, 182.0
BRASEROS = [(248, 160), (292, 160), (72, 158), (108, 158)]  # más dos en el zigurat
BRASERO_ESC = 2.2
ESTANDARTES = [(247, 184), (293, 184), (77, 184), (103, 184), (160, 184), (12, 184), (348, 184)]
PUERTA = (250, 290)  # vista libre desde la puerta: aquí no va nada alto
MOSAICO_R = list(range(18, 91, 9))  # anillos del mosaico del centro

# Puntos que los contrafuertes y escombros dejan libres (estatuas y cráneo).
LIBRES = [pb(a, ESTATUA_R) for a, _ in ESTATUAS] + [pb(CRANEO_ANG, CRANEO_R - 14)]


def evitar(p):
    return P.cerca_de(p, LIBRES, 16.0)


# ---- grupos de la escena -------------------------------------------------------------------
def laberinto(m_in, m_out, esc_in, esc_out):
    for k, (radio, alto, tramos, contra) in enumerate((ANILLO_A, ANILLO_B, ANILLO_C)):
        m, esc = (m_out, esc_out) if k == 2 else (m_in, esc_in)
        for j, (a0, a1) in enumerate(tramos):
            corto = (a1 - a0) % 360 < 22
            P.anillo(m, radio, a0, a1, alto, banda=k == 2, semilla=100 * k + j, caidas=1 if corto else 2,
                     contra=contra, evitar=evitar, escombro=esc)
    for j, ang in enumerate(RADIALES_AB):
        P.radial(m_in, ang, 130, 150, 16.0, semilla=300 + j, caidas=1, contra=1, evitar=evitar, escombro=esc_in)
    for j, ang in enumerate(RADIALES_BC):
        P.radial(m_out, ang, 150, 170, 20.0, semilla=400 + j, caidas=1, contra=-1, evitar=evitar, escombro=esc_out)
    for j, ang in enumerate(VIA):
        P.radial(m_in, ang, 130, 150, 10.0, semilla=500 + j, caidas=0, escombro=esc_in)


def columnatas(m):
    r = random.Random(9)
    for g, grupo in enumerate(COLUMNAS):
        tops = []
        for j, ang in enumerate(grupo):
            rota = r.random() < 0.35
            alto = COLUMNA_ALTO + r.uniform(-3.0, 3.0)
            src, top = P.columna(600 + 10 * g + j, alto, rota)
            p = pb(ang, COLUMNAS_R)
            z = suelo(p, 5.0) - P.SINK
            pegar(m, src, T(p.x, p.y, z) @ ejes(ang + r.uniform(-8, 8)))
            tops.append((ang, z + top, rota))
        for (a0, z0, r0), (a1, z1, r1) in zip(tops, tops[1:]):  # dinteles entre columnas sanas
            if r0 or r1 or r.random() < 0.25:
                continue
            p0, p1 = pb(a0, COLUMNAS_R), pb(a1, COLUMNAS_R)
            c = (p0 + p1) / 2
            M = T(c.x, c.y, min(z0, z1) + 1.3) @ ejes((a0 + a1) / 2)
            largo = (p1 - p0).length + 9.0
            m.caja(M, (6.0, largo, 2.6), {"+z": "piedra3", "resto": "piedra"}, bisel=0.08)
            m.caja(M @ T(3.1, 0, -0.2), (0.24, largo - 1.0, 1.4), "rojo2")
    for k, (ang, rr, roto) in enumerate(OBELISCOS):
        p = pb(ang, rr)
        z = suelo(p, 4.0) - P.SINK
        pegar(m, P.obelisco(700 + k, 31.0 + (k % 3) * 2.0, roto), T(p.x, p.y, z) @ ejes(ang + 90))


def monumentos(m, b):
    """Arco, cráneo, labrys, braseros y estandartes. Devuelve los puntos de los braseros."""
    src, medio = P.arco_grande()
    p = pb(ARCO_ANG, ARCO_R)
    pies = [pb(ARCO_ANG + s * math.degrees(medio * 0.6 / ARCO_R), ARCO_R) for s in (-1, 1)] + [p]
    z = min(suelo(q, 8.0) for q in pies) - P.SINK
    pegar(m, src, T(p.x, p.y, z) @ ejes(ARCO_ANG - 90))
    src = HM.craneo(51)["malla"]
    p = pb(CRANEO_ANG, CRANEO_R)
    z = suelo(p, 12.0) - 8.0
    pegar(m, src, T(p.x, p.y, z) @ ejes(CRANEO_ANG - 90) @ Matrix.Scale(CRANEO_ESC, 4))
    p = pb(*LABRYS)
    z = suelo(p, 2.0) - 0.5
    pegar(m, P.labrys_gigante(), T(p.x, p.y, z) @ ejes(LABRYS[0] + 90) @ girar("X", 0.22) @ girar("Y", 0.18))
    for k, (ang, rr) in enumerate(ESTANDARTES):
        p = pb(ang, rr)
        z = suelo(p, 2.4) - 0.8
        pegar(m, HM.estandarte(70 + k, alto=34.0)["malla"], T(p.x, p.y, z) @ ejes(ang + 90))
    return [pb(a, rr) for a, rr in BRASEROS]


def braseros(m, b, puntos):
    """Braseros apoyados en cada punto (Blender; con z ya puesto o 0 = sobre la arena)."""
    luces, fuegos = [], []
    r = random.Random(5)
    for k, p in enumerate(puntos):
        d = HM.brasero(60 + k)
        z = p.z if p.z else suelo(p, 5.0) - P.SINK
        M = T(p.x, p.y, z) @ girar("Z", r.uniform(0, 2.1)) @ Matrix.Scale(BRASERO_ESC, 4)
        llama = M @ V(d["llama"])
        pegar(m, d["malla"], M)
        pegar(b, d["brillo"], M)
        mundo = [round(llama.x, 2), round(llama.z, 2), round(-llama.y, 2)]
        fuegos.append({"pos": mundo, "tam": 7})
        luces.append({"pos": [mundo[0], round(mundo[1] + 2, 2), mundo[2]], "color": list(HM.FUEGO), "rango": 32})
    return luces, fuegos


def estatuas(m):
    r = random.Random(13)
    for k, (ang, tipo) in enumerate(ESTATUAS):
        p = pb(ang, ESTATUA_R)
        if tipo.startswith("toro"):
            src = P.estatua_toro(800 + k, sin_cabeza=tipo.endswith("roto"))
        else:
            src = P.estatua_minotauro(800 + k, brazo_roto=tipo.endswith("roto"))
        z = suelo(p, 7.0) - P.SINK
        pegar(m, src, T(p.x, p.y, z) @ ejes(ang - 90 + r.uniform(-10, 10), r.uniform(-0.04, 0.04)))


def dunas(m):
    """Arena acumulada contra la cara de afuera de cada anillo y algunas sueltas en los huecos."""
    r = random.Random(21)
    for k, (radio, _, tramos, _) in enumerate((ANILLO_A, ANILLO_B, ANILLO_C)):
        for a0, a1 in tramos:
            a1 = a1 + 360 if a1 < a0 else a1
            a = a0 + r.uniform(2, 8)
            while a < a1 - 3:
                lado = 1 if r.random() < 0.7 else -1
                rr = radio + lado * r.uniform(5.0, 7.5)
                p = pb(a, rr)
                if 126 < radio_de(p) < 186 and not evitar(p):
                    P.duna(m, p, a, r.uniform(16, 26), r.uniform(8, 12), r.uniform(3.0, 6.5))
                a += math.degrees(r.uniform(26, 40) / radio)
    for k in range(14):
        a = r.uniform(0, 360)
        if PUERTA[0] - 5 < a < PUERTA[1] + 5:
            continue
        p = pb(a, r.uniform(132, 182))
        if not evitar(p):
            P.duna(m, p, a + r.uniform(-30, 30), r.uniform(14, 22), r.uniform(8, 12), r.uniform(2.5, 5.0))


def suelo_losas(m):
    """Losas del laberinto que asoman en la arena por todo el anillo (también en la vista de la
    puerta: son bajas) y las dos vías procesionales hacia el gigante."""
    r = random.Random(33)
    n = 0
    while n < 300:
        a = r.uniform(0, 360)
        rr = math.sqrt(r.uniform(97 ** 2, 186 ** 2))
        p = pb(a, rr)
        P.losa(m, r, p, a, tam=r.uniform(5.0, 8.0), asoma=r.uniform(0.2, 0.6))
        n += 1
    for eje, desde, hasta in ((270, 97, 188), (90, 97, 150), (0, 97, 146)):
        rr = desde
        while rr < hasta:
            for lado in (-1, 0, 1):
                if r.random() < 0.18:
                    continue
                ang = eje + lado * math.degrees(6.6 / rr) + r.uniform(-0.4, 0.4)
                P.losa(m, r, pb(ang, rr + r.uniform(-0.4, 0.4)), ang, tam=6.2, asoma=0.4)
            rr += 6.8


def mosaico(m):
    """El laberinto dibujado en el centro: anillos de losas rojas (uno de cada tres de oro) a ras
    de la arena con aberturas alternadas y travesaños, como un laberinto de Creta visto desde
    arriba, y un labrys de oro en el medio. Nada pasa de 1 stud sobre la arena."""
    r = random.Random(44)
    ancho, asoma = 2.8, 0.6
    for i, rr in enumerate(MOSAICO_R):
        color = "oro2" if i % 3 == 2 else "rojo2"
        abre = 270 if i % 2 == 0 else 90
        hueco = math.degrees(8.0 / rr)
        n = max(8, round(2 * math.pi * rr / 8.0))
        for k in range(n):
            a = 360 * (k + 0.5) / n
            if abs((a - abre + 180) % 360 - 180) < hueco:
                continue
            p = pb(a, rr)
            z = suelo(p, 2.0) + asoma - 1.5
            m.caja(T(p.x, p.y, z) @ ejes(a), (ancho, 2 * math.pi * rr / n - 0.25, 3.0), color)
        if i < len(MOSAICO_R) - 1:  # travesaño hacia el anillo siguiente (callejones sin salida)
            for a in ((0, 180) if i % 2 == 0 else (45, 225)):
                a += r.uniform(-8, 8)
                largo = MOSAICO_R[i + 1] - rr
                p = pb(a, rr + largo / 2)
                z = suelo(p, 2.0) + asoma - 1.5
                m.caja(T(p.x, p.y, z) @ ejes(a), (largo, ancho, 3.0), color)
    # Medallón del medio: disco de losas claras con un labrys de oro acostado.
    for k in range(10):
        a = 36 * (k + 0.5)
        p = pb(a, 6.0)
        z = suelo(p, 2.0) + 0.3 - 1.5
        m.caja(T(p.x, p.y, z) @ ejes(a), (6.0, 3.6, 3.0), "marmol")
    z = suelo(V((0, 0, 0)), 6.0) + 0.5
    m.placa(T(0, 0, z) @ girar("Z", math.radians(-270 + 90)) @ girar("X", math.pi / 2),
            [(x * 1.7, y * 1.7) for x, y in HM.LABRYS], 0.6, "oro")


# ---- escena, exportación y render ----------------------------------------------------------
def paleta():
    img = H.hacer_paleta(guardar=False)
    img.name = ID + "_color"
    img.filepath_raw = TEX
    img.file_format = "PNG"
    os.makedirs(os.path.dirname(TEX), exist_ok=True)
    img.save()
    return img


def material(nombre, img, emision=0.0):
    mat = bpy.data.materials.get(nombre) or bpy.data.materials.new(nombre)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.8
    if emision:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emision
    return mat


def limites(m):
    ps = [v.co for v in m.bm.verts]
    return (V((min(p.x for p in ps), min(p.y for p in ps), min(p.z for p in ps))),
            V((max(p.x for p in ps), max(p.y for p in ps), max(p.z for p in ps))))


def objeto(nombre, malla, mat):
    bm = malla.bm
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    lisos = [f[malla.liso] == 1 for f in bm.faces]
    me = bpy.data.meshes.new(nombre)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    for p, liso in zip(me.polygons, lisos):
        p.use_smooth = liso
    if hasattr(me, "set_sharp_from_angle"):
        me.set_sharp_from_angle(angle=math.radians(40))
    o = bpy.data.objects.new(nombre, me)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return o


def construir():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    img = paleta()
    m = {k: H.Malla(k) for k in range(1, 8)}
    b1 = H.Malla(99)
    laberinto(m[1], m[2], m[1], m[6])
    columnatas(m[3])
    puntos = monumentos(m[4], b1)
    puntos += P.zigurat(m[5], m[5], ZIGURAT_ANG, ZIGURAT_R, random.Random(55))
    luces, fuegos = braseros(m[4], b1, puntos)
    estatuas(m[6])
    dunas(m[6])
    suelo_losas(m[7])
    mosaico(m[7])
    mallas = {ID + str(k): m[k] for k in range(1, 8)}
    mallas[ID + "Brillo1"] = b1
    lims = [limites(x) for x in mallas.values()]
    a = math.ceil(max(max(-lo.x, -lo.y, hi.x, hi.y) for lo, hi in lims)) + 0.5
    lo = V((-a, -a, math.floor(min(lo.z for lo, _ in lims)) - 0.5))
    hi = V((a, a, math.ceil(max(hi.z for _, hi in lims)) + 0.5))
    for nombre, x in mallas.items():
        color = "fuego" if nombre in BRILLO else "piedra"
        for esquina, s in ((lo, 1), (hi, -1)):
            x.caja(T(*(esquina + V((0.02, 0.02, 0.02)) * s)), (0.04, 0.04, 0.04), color)
    objs = [objeto(n, x, material(n, img, 1.5 if n in BRILLO else 0.0)) for n, x in mallas.items()]
    tris = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs}
    assert len(objs) <= 8
    return objs, lo, hi, tris, luces, fuegos


def revisar(objs, lo):
    """Zonas del contrato. Por malla: vértices fuera (r >= 205; Y > 30 en el acantilado), radio
    mínimo y máximo, lo más alto a r < 95 (sobre la arena de ahí) y vértices altos en la vista
    de la puerta (más de 2 studs sobre la arena entre 250 y 290)."""
    informe = {}
    for o in objs:
        fuera, rs, centro, puerta = 0, [], 0.0, 0
        for v in o.data.vertices:
            p = v.co
            if abs(abs(p.x) + lo.x) < 0.1 and abs(abs(p.y) + lo.y) < 0.1:
                continue  # cubitos de la caja
            r = math.hypot(p.x, p.y)
            rs.append(r)
            if r >= 205 or (r >= 190 and p.z > 30):
                fuera += 1
            sobre = p.z - P.arena(p.x, -p.y)
            if r < 95:
                centro = max(centro, sobre)
            if PUERTA[0] + 5 < angulo_de(p) < PUERTA[1] - 5 and r < 200 and sobre > 2.0:
                puerta += 1
        informe[o.name] = {"fuera": fuera, "r": (round(min(rs), 1), round(max(rs), 1)), "centro_alto": round(centro, 1),
                           "puerta_altos": puerta}
    return informe


def exportar(objs, lo, hi, luces, fuegos):
    for x in bpy.data.objects:
        x.select_set(x in objs)
    os.makedirs(CARPETA, exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=True, mesh_smooth_type="OFF", object_types={"MESH"})
    datos = {
        "ancho": round(hi.x - lo.x, 3),
        "alto": round(hi.z - lo.z, 3),
        "centroY": round((hi.z + lo.z) / 2, 3),
        "mallas": [{"nombre": o.name, "brillo": list(BRILLO[o.name]) if o.name in BRILLO else None} for o in objs],
        "luces": luces,
        "fuegos": fuegos,
    }
    with open(JSON, "w", encoding="utf-8") as f:
        json.dump(datos, f, indent=1, ensure_ascii=False)
        f.write("\n")


def malla_radial(nombre, altura, rmax, color, pasos_r=150, pasos_a=240, media=False):
    """Malla de rejilla polar (solo para el render): altura(dx, dz, r) en cada punto."""
    bm = bmesh.new()
    na = pasos_a // 2 if media else pasos_a
    filas = []
    for i in range(pasos_r + 1):
        r = rmax * (i / pasos_r) ** 0.9
        fila = []
        for k in range(na + (1 if media else 0)):
            a = math.pi + math.pi * k / na if media else 2 * math.pi * k / na
            x, y = r * math.cos(a), r * math.sin(a)
            fila.append(bm.verts.new((x, y, altura(x, -y, r))))
        filas.append(fila)
    for i in range(pasos_r):
        n = len(filas[i])
        for k in range(n - (1 if media else 0)):
            k2 = (k + 1) % n
            try:
                bm.faces.new((filas[i][k], filas[i][k2], filas[i + 1][k2], filas[i + 1][k]))
            except ValueError:
                pass
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nombre, me)
    mat = bpy.data.materials.new(nombre)
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = color
    mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.95
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return o


def renders():
    escena = bpy.context.scene
    for motor in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            escena.render.engine = motor
            break
        except TypeError:
            continue
    escena.render.resolution_x, escena.render.resolution_y = 1600, 1000
    escena.view_settings.view_transform = "Standard"
    mundo = bpy.data.worlds.new("Cielo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.62, 0.72, 0.86, 1)
    mundo.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    escena.world = mundo
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy = 3.2
    sol.data.color = (1.0, 0.93, 0.82)
    sol.rotation_euler = (math.radians(50), 0, math.radians(-30))
    escena.collection.objects.link(sol)
    roca = malla_radial("FondoRender", lambda x, z, r: P.fondo(r), 240, (0.42, 0.42, 0.44, 1))
    arena_color = (0.855, 0.617, 0.262, 1)  # Terrain Sand (238, 206, 140) en lineal
    arena_o = malla_radial("ArenaRender", lambda x, z, r: P.arena_con_rocas(x, z), P.REACH, arena_color, 200, 360)
    media = malla_radial("ArenaMediaRender", lambda x, z, r: P.arena_con_rocas(x, z), P.REACH, arena_color, 200, 360, True)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=40, depth=165, location=(0, 0, P.AGUA + 82.5))
    gigante = bpy.context.active_object  # marca de la E4 (~165 x 80), solo para la escala
    gigante.name = "GiganteE4Render"
    mg = bpy.data.materials.new("GiganteRender")
    mg.use_nodes = True
    mg.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.35, 0.18, 0.12, 1)
    gigante.data.materials.append(mg)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    escena.collection.objects.link(cam)
    escena.camera = cam
    cam.data.clip_end = 3000
    os.makedirs(RENDERS, exist_ok=True)
    vistas = [
        # nombre, posición, mira a, lente, relleno (toda / media), con la marca del gigante
        ("paseo_puerta", (0, 220, 34), (0, 0, 4), 18, "toda", False),
        ("borde_puerta_gigante", (0, 206, 34), (0, 0, 30), 18, "toda", True),
        ("paseo_este", pb(0, 220, 34), (0, 0, 4), 18, "toda", False),
        ("paseo_noreste", pb(45, 220, 34), (0, 0, 4), 18, "toda", False),
        ("paseo_oeste", pb(160, 220, 34), (0, 0, 4), 18, "toda", False),
        ("arco", pb(270, 40, 30), pb(90, 176, 28), 32, "toda", False),
        ("zigurat", pb(180, 60, 34), pb(0, 176, 14), 34, "toda", False),
        ("craneo", pb(192, 215, 34), pb(178, 160, 10), 28, "toda", False),
        ("aerea", (0, 140, 520), (0, 0, 0), 30, "toda", False),
        ("cenital", (0, 0, 640), (0, 0.01, 0), 30, "toda", False),
        ("corte_relleno", (0, 150, 95), (0, -60, -60), 20, "media", False),
    ]
    for nombre, pos, mira, lente, relleno, con_gigante in vistas:
        arena_o.hide_render = relleno != "toda"
        media.hide_render = relleno != "media"
        gigante.hide_render = not con_gigante
        roca.hide_render = False
        cam.location = V(pos)
        cam.rotation_euler = (V(mira) - cam.location).to_track_quat("-Z", "Y").to_euler()
        cam.data.lens = lente
        escena.render.filepath = os.path.join(RENDERS, nombre + ".png")
        bpy.ops.render.render(write_still=True)
        print("RENDER", escena.render.filepath)


OBJS, LO, HI, TRIS, LUCES, FUEGOS = construir()
print("HABITAT tris", TRIS, "total", sum(TRIS.values()))
print("HABITAT caja", tuple(round(v, 2) for v in LO), tuple(round(v, 2) for v in HI))
print("HABITAT zonas", revisar(OBJS, LO))
assert all(t <= MAX_TRIS for t in TRIS.values()), f"una malla pasa de {MAX_TRIS} triángulos: {TRIS}"
if "exportar" in ARGS:
    exportar(OBJS, LO, HI, LUCES, FUEGOS)
    print("EXPORTADO", FBX)
if "render" in ARGS:
    renders()
