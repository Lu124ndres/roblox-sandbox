r"""
Hábitat completo del zorro de agua (contrato: docs/contrato_habitat_completo.md, 2026-10-23;
segunda pasada: un reino de hielo). El cráter es agua con hielo (GiantDef.ice):
    - un glaciar enorme casi frente a la puerta (90 grados de ancho contra el paseo), con un muro
      de séracs que cae del borde del paseo al agua, grietas azules hondas y una cueva grande;
    - del otro lado, un arco natural de hielo (200) y una aguja de hielo gigante (345), a los
      costados de la vista desde la puerta;
    - toda la repisa cubierta: banquisa a ras del agua, crestas de hielo, nieve amontonada contra
      la pared; el acantilado entero con nieve, escarcha, carámbanos y cascadas congeladas;
    - peñones grandes con nieve, una cueva de hielo, icebergs de 15 a 25 y racimos de cristales
      de 17 a 20 de alto que brillan.
Estilo low-poly con textura de paleta (cada cara, un cuadrito de color), como habitats.py, con
los mismos colores que las primitivas de hielo del juego (IceParts: ICE, ICE_EDGE, ICE_DEEP,
SNOW, FROST, ROCKS).

Las piezas están en:
    habitat_zorrodeagua_base.py        paleta, Malla, fondo del cráter y zonas prohibidas
    habitat_zorrodeagua_glaciar.py     el glaciar: meseta, muro de séracs, trozos y su cueva
    habitat_zorrodeagua_masas.py       el arco y la aguja
    habitat_zorrodeagua_rocas.py       peñones, cuevas y racimos de cristales
    habitat_zorrodeagua_acantilado.py  franjas de nieve y escarcha, carámbanos y cascadas
    habitat_zorrodeagua_lago.py        banquisa, crestas, ventisqueros e icebergs

Mallas (todas con la MISMA caja, simétrica en X e Y alrededor del eje del cráter, con un
cubito mínimo en cada esquina; ninguna pasa de 9.800 triángulos; ninguna choca):
    ZorroDeAguaHabitat1        el glaciar y su cueva
    ZorroDeAguaHabitat2        peñones, arco, aguja, la cueva de la orilla y el pie de los cristales
    ZorroDeAguaHabitat3        lo que flota: la banquisa de adentro (r < 160) y los icebergs (el
                               juego lo sube y hunde con el lago, como IceLift: si no, queda en
                               el aire al vaciarse)
    ZorroDeAguaHabitat4        la repisa varada: banquisa de afuera, crestas y ventisqueros
    ZorroDeAguaHabitat5        el acantilado
    ZorroDeAguaHabitatBrillo1  los cristales (en el juego, Neon celeste suave)
Los lugares del zorro (src/shared/Zorro/Guarida.luau: los témpanos grandes y la roca de vigía)
siguen siendo de primitivas (IceFloes, IceRocks) y quedan libres alrededor, con agua.

Coordenadas: 1 unidad = 1 stud, origen en el centro del cráter a Y = 0 del mundo, Z = Y del
mundo. Exporta assets/blender/habitat_zorrodeagua/ZorroDeAguaHabitat.fbx (textura embebida),
assets/textures/ZorroDeAguaHabitat_color.png, assets/blender/habitat_zorrodeagua/
ZorroDeAguaHabitat.json y renders en renders/habitat_zorrodeagua/.

Uso sin abrir Blender:
    blender -b --factory-startup --python tools/blender/habitat_zorrodeagua.py -- exportar render
"""
import bpy, bmesh, json, math, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import habitat_zorrodeagua_acantilado as acantilado  # noqa: E402
import habitat_zorrodeagua_base as base  # noqa: E402
import habitat_zorrodeagua_glaciar as glaciar  # noqa: E402
import habitat_zorrodeagua_lago as lago  # noqa: E402
import habitat_zorrodeagua_masas as masas  # noqa: E402
import habitat_zorrodeagua_rocas as rocas  # noqa: E402
from habitat_zorrodeagua_base import (AGUA, BRILLO, COLORES, LADO, CELDA, NOMBRES, RAIZ, SPOTS, SPOT_TOP, V,
                                      Malla, polar, suelo)  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
NOMBRE = "ZorroDeAguaHabitat"
CARPETA = os.path.join(RAIZ, "assets", "blender", "habitat_zorrodeagua")
FBX = os.path.join(CARPETA, NOMBRE + ".fbx")
CAJA_JSON = os.path.join(CARPETA, NOMBRE + ".json")
TEX = os.path.join(RAIZ, "assets", "textures", NOMBRE + "_color.png")
RENDERS = os.path.join(RAIZ, "renders", "habitat_zorrodeagua")
MAX_TRIS = 9800
FLOTA = NOMBRE + "3"


def hacer_paleta():
    img = bpy.data.images.get(NOMBRE + "_color") or bpy.data.images.new(NOMBRE + "_color", 128, 128)
    px = [0.0] * (128 * 128 * 4)
    for i, n in enumerate(NOMBRES):
        cx, cy = (i % LADO) * CELDA, (i // LADO) * CELDA
        r, g, b = (c / 255 for c in COLORES[n])
        for y in range(cy, cy + CELDA):
            for x in range(cx, cx + CELDA):
                k = (y * 128 + x) * 4
                px[k:k + 4] = [r, g, b, 1.0]
    img.pixels = px
    img.filepath_raw = TEX
    img.file_format = "PNG"
    os.makedirs(os.path.dirname(TEX), exist_ok=True)
    img.save()
    return img


def material(nombre, img=None, color=None, alfa=1.0, emision=0.0):
    mat = bpy.data.materials.new(nombre)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    if img is not None:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        tex.interpolation = "Closest"
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if color is not None:
        bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = 0.8
    if emision:
        bsdf.inputs["Emission Color"].default_value = (*(c / 255 for c in BRILLO), 1)
        bsdf.inputs["Emission Strength"].default_value = emision
    if alfa < 1:
        bsdf.inputs["Alpha"].default_value = alfa
        if hasattr(mat, "surface_render_method"):
            mat.surface_render_method = "BLENDED"
    return mat


def objeto(nombre, bm, mat):
    me = bpy.data.meshes.new(nombre)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nombre, me)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return o


def revisar(mallas):
    """Cuenta los vértices que caen en una zona prohibida del contrato."""
    malos = {}
    for nombre, m in mallas.items():
        n = {"paseo": 0, "techo": 0, "santuario": 0, "enterrado_flota": 0, "lugares": 0}
        for v in m.bm.verts:
            r, z = v.co.xy.length, v.co.z
            if z > AGUA - 4:  # el borde de cada témpano grande y el pie de la roca de vigía
                n["lugares"] += any((v.co.xy - polar(a, rs, 0).xy).length < (1.6 * size if tipo == "tempano" else size + 20)
                                    for _, a, rs, size, tipo in SPOTS)
            n["paseo"] += r > base.PASEO + 0.01
            n["techo"] += r >= base.LAGO - 0.5 and z > base.BORDE_Y  # el acantilado no pasa del paseo
            n["santuario"] += (r < 124 and z > -84) or (r < 100 and z > -136)
            if nombre == FLOTA:
                n["enterrado_flota"] += z < suelo(r) + 0.1
        malos[nombre] = {k: v for k, v in n.items() if v}
    return malos


def construir():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    img = hacer_paleta()
    m1, m2, m3 = Malla(NOMBRE + "1"), Malla(NOMBRE + "2"), Malla(FLOTA)
    m4, m5, b1 = Malla(NOMBRE + "4"), Malla(NOMBRE + "5"), Malla(NOMBRE + "Brillo1")
    rocas.construir(m2, b1)  # primero lo que ocupa lugar fijo
    masas.construir(m2, rocas.LUCES)
    glaciar.construir(m1, b1, rocas.cueva)
    acantilado.construir(m5)
    lago.construir(m4, m3)
    mallas = {m.nombre: m for m in (m1, m2, m3, m4, m5, b1)}
    malos = revisar(mallas)
    lims = [m.limites() for m in mallas.values()]
    a = max(max(-lo.x, -lo.y, hi.x, hi.y) for lo, hi in lims)
    lo = V((-a, -a, min(lo.z for lo, _ in lims)))
    hi = V((a, a, max(hi.z for _, hi in lims)))
    for nombre, m in mallas.items():
        for esquina in (lo, hi):
            m.bloque(esquina - V((0.02, 0.02, 0.02)) * (1 if esquina is hi else -1), (0.04, 0.04, 0.04),
                     "cristal" if nombre.endswith("Brillo1") else "hielo3")
    tris = {n: m.tris() for n, m in mallas.items()}
    assert all(t <= MAX_TRIS for t in tris.values()), f"una malla pasa de {MAX_TRIS} triángulos: {tris}"
    objs = []
    for nombre, m in mallas.items():
        brillo = nombre.endswith("Brillo1")
        objs.append(objeto(nombre, m.bm, material(nombre, img, emision=2.5 if brillo else 0.0)))
    return objs, lo, hi, tris, malos


# --- Renders (el fondo, el agua y los lugares del zorro son solo para mirar) ---------------------

def fondo_render():
    bm = bmesh.new()
    radios = [0, 74.9] + [75 + 75 * k / 14 for k in range(15)] + [150 + 5 * k for k in range(1, 9)]
    radios += [190 + 15 * (k / 10) ** 1.6 for k in range(1, 11)] + [215, 240]
    lados = 120
    filas = []
    for r in radios:
        filas.append([bm.verts.new(polar(360 * k / lados, max(r, 0.01), suelo(r))) for k in range(lados)])
    for i in range(len(filas) - 1):
        for k in range(lados):
            j = (k + 1) % lados
            bm.faces.new((filas[i][k], filas[i][j], filas[i + 1][j], filas[i + 1][k]))
    o = objeto("FondoRender", bm, material("FondoRender", color=(0.36, 0.36, 0.38)))
    return [o]


def agua_render():
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=True, segments=96, radius=base.LAGO + 0.5)
    for v in bm.verts:
        v.co.z = AGUA
    return objeto("AguaRender", bm, material("AguaRender", color=(0.12, 0.42, 0.62), alfa=0.62))


def lugares_render():
    objs = []
    for nombre, a, r, size, tipo in SPOTS:
        bm = bmesh.new()
        top = AGUA + SPOT_TOP[tipo]
        alto = 0.6 if tipo == "tempano" else top - suelo(r) + 1
        bmesh.ops.create_cone(bm, cap_ends=True, segments=24, radius1=size, radius2=size * (1 if tipo == "tempano" else 0.7),
                              depth=alto)
        c = polar(a, r, top - alto / 2)
        for v in bm.verts:
            v.co += c
        objs.append(objeto("Lugar" + nombre, bm, material("Lugar" + nombre, color=(1.0, 0.45, 0.1), alfa=0.75)))
    return objs


def vistas(lo, hi):
    escena = bpy.context.scene
    for motor in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            escena.render.engine = motor
            break
        except TypeError:
            continue
    escena.render.resolution_x, escena.render.resolution_y = 1400, 860
    escena.view_settings.view_transform = "Standard"
    mundo = bpy.data.worlds.new("Cielo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.62, 0.74, 0.86, 1)
    mundo.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    escena.world = mundo
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy = 3.2
    sol.rotation_euler = (math.radians(50), 0, math.radians(-30))
    escena.collection.objects.link(sol)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    escena.collection.objects.link(cam)
    escena.camera = cam
    cam.data.clip_end = 3000
    fondo = fondo_render()
    agua = agua_render()
    lugares = lugares_render()
    # (archivo, cámara, mira a, lente, con agua, con lugares del zorro)
    tomas = (
        ("paseo_puerta.png", polar(270, 220, 34), polar(90, 40, -10), 22, False, True),
        ("paseo_puerta_agua.png", polar(270, 220, 34), polar(90, 40, -10), 22, True, False),
        ("paseo_lado_agua.png", polar(200, 220, 34), polar(20, 30, -8), 22, True, False),
        ("aerea.png", polar(270, 260, 380), V((0, 0, -20)), 30, False, True),
        ("aerea_agua.png", polar(250, 200, 420), V((0, 0, -10)), 30, True, False),
        ("glaciar_agua.png", polar(140, 215, 34), polar(55, 175, 8), 24, True, False),
        ("glaciar_cerca_agua.png", polar(60, 105, 14), polar(60, 175, 12), 30, True, False),
        ("arco_agua.png", polar(240, 120, 14), polar(200, 177, 14), 30, True, False),
        ("aguja_agua.png", polar(300, 130, 14), polar(345, 180, 18), 30, True, False),
    )
    os.makedirs(RENDERS, exist_ok=True)
    for archivo, pos, mira, lente, con_agua, con_lugares in tomas:
        agua.hide_render = not con_agua
        for o in lugares:
            o.hide_render = not con_lugares
        cam.location = pos
        cam.rotation_euler = (V(mira) - V(pos)).to_track_quat("-Z", "Y").to_euler()
        cam.data.lens = lente
        escena.render.filepath = os.path.join(RENDERS, archivo)
        bpy.ops.render.render(write_still=True)
        print("RENDER", escena.render.filepath)
    for o in fondo + [agua] + lugares:
        bpy.data.objects.remove(o)


def mundo_rel(p):
    """Blender -> mundo relativo al centro del cráter (dx, y, dz)."""
    return [round(p.x, 2), round(p.z, 2), round(-p.y, 2)]


def exportar(objs, lo, hi):
    for x in bpy.data.objects:
        x.select_set(x in objs)
    os.makedirs(CARPETA, exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=True, mesh_smooth_type="OFF", object_types={"MESH"})
    datos = {
        "ancho": round(hi.x - lo.x, 3), "alto": round(hi.z - lo.z, 3), "centroY": round((hi.z + lo.z) / 2, 3),
        "mallas": [{"nombre": o.name, "brillo": list(BRILLO) if o.name.endswith("Brillo1") else None,
                    "flota": o.name == FLOTA} for o in objs],
        "luces": [{"pos": mundo_rel(p), "color": list(rocas.LUZ), "rango": rango} for p, rango in rocas.LUCES],
        "fuegos": [],
    }
    with open(CAJA_JSON, "w", encoding="utf-8") as f:
        json.dump(datos, f, indent=1, ensure_ascii=False)
        f.write("\n")


OBJS, LO, HI, TRIS, MALOS = construir()
print("HABITAT tris", TRIS, "caja", tuple(round(v, 2) for v in LO), tuple(round(v, 2) for v in HI))
print("HABITAT zonas", MALOS, "luces", len(rocas.LUCES))
if "exportar" in ARGS:
    exportar(OBJS, LO, HI)
    print("EXPORTADO", FBX)
if "render" in ARGS:
    vistas(LO, HI)
