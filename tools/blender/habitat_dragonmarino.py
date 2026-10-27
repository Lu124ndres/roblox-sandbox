r"""
Hábitat completo del DragonMarino (contrato: docs/contrato_habitat_completo.md, 2026-10-23):
el cráter lleno de lava (Dragon/Guarida.lava = -25) con peñascos de basalto en columnas, una
sola escena. Estilo de bloques, como el arco y el santuario:
    peñones    las 4 rocas donde se posa el dragón (src/shared/Dragon/Guarida.luau), de columnas
               hexagonales: dentro del radio de la cima todas cortadas a la altura exacta del
               contrato; afuera un muro con tajos, salientes, espolones, grietas verticales de
               lava y columnas sueltas que salen del lago (torres, no discos). Sobre la central,
               el nido con tres huevos y uno abierto (habitat_dragonmarino_penones.py);
    orilla     seis peñascos que salen del mar de lava, costra encendida en la playa, columnas
               caídas, cascajo, tres fumarolas, el esqueleto de un dragón antiguo con escamas
               mudadas, los cristales de la repisa y tres agujas de basalto con cristales en la
               punta; las cascadas de LairFalls con su mismo recorrido (habitat_dragonmarino_orilla.py);
    acantilado columnas por grupos de alturas muy distintas, huecos y derrumbes (nunca sobre
               Y = 29), un cráneo de dragón colosal tallado en la roca frente a la puerta y un
               arco de basalto en la repisa (habitat_dragonmarino_borde.py).

Mallas (todas con LA MISMA caja: un cubito mínimo en cada esquina de la caja común, simétrica
en X e Y alrededor del eje del cráter; ninguna pasa de 9.800 triángulos):
    DragonMarinoHabitat1        orilla y repisa (fija)
    DragonMarinoHabitat2        acantilado, cráneo y arco (fija)
    DragonMarinoHabitat3        peñón central con el nido y el de 155° (SUBEN con la lava, como LairLift)
    DragonMarinoHabitat4        los peñones de 35° y 265° (SUBEN)
    DragonMarinoHabitatBrillo1  lava fija: cascadas, ríos, costra y fumarolas. Neon (255, 98, 22);
                                se oculta cuando no hay lava, como hoy las cascadas
    DragonMarinoHabitatBrillo2  cristales fijos. Neon (255, 176, 64)
    DragonMarinoHabitatBrillo3  lava de los peñones y del nido. Neon (255, 98, 22) (SUBE)
Las que suben están en su lugar final (lava arriba); el juego las hunde y las sube junto con la
lava. Ninguna choca (el informe propone cómo pisar los peñones).

Coordenadas: 1 unidad = 1 stud; origen = centro del cráter a Y = 0 del mundo; Z de Blender =
Y del mundo (absoluta). Un punto del mundo (dx, y, dz) es (dx, -dz, y) aquí; un ángulo `a` de
Config/Guarida (x = cos, z = sin) es (r cos a, -r sin a). La puerta (270) queda en +Y.
Exporta assets/blender/habitat_dragonmarino/DragonMarinoHabitat.fbx (textura embebida),
assets/textures/DragonMarinoHabitat_color.png, assets/blender/habitat_dragonmarino/
DragonMarinoHabitat.json y renders en renders/habitat_dragonmarino/ (con el fondo del lago en
gris y la lava insinuada, solo para el render).

Uso sin abrir Blender:
    blender -b --factory-startup --python tools/blender/habitat_dragonmarino.py -- exportar render
"""
import bpy, json, math, os, random, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from habitat_dragonmarino_malla import (ARGS, CAJA_JSON, DIR, FBX, ID, LAVA, MAX_TRIS, PASEO_Y, PERCHES, RENDERS, Malla,
                                        V, en, hacer_paleta, perch_top, piso, radio_de)
import habitat_dragonmarino_borde as borde
import habitat_dragonmarino_orilla as orilla
import habitat_dragonmarino_penones as penones

MALLAS = (  # nombre, brillo (color Neon o None), sube con la lava, solo con lava arriba
    (f"{ID}Habitat1", None, False, False),
    (f"{ID}Habitat2", None, False, False),
    (f"{ID}Habitat3", None, True, False),
    (f"{ID}Habitat4", None, True, False),
    (f"{ID}HabitatBrillo1", (255, 98, 22), False, True),
    (f"{ID}HabitatBrillo2", (255, 176, 64), False, False),
    (f"{ID}HabitatBrillo3", (255, 98, 22), True, False),
)


def construir():
    m = {nombre: Malla() for nombre, *_ in MALLAS}
    h1, h2, h3, h4, b1, b2, b3 = (m[n] for n, *_ in MALLAS)
    rnd = random.Random(29)
    for k, perch in enumerate(PERCHES):  # central y 155° en la 3; 35° y 265° en la 4 (por triángulos)
        penones.penon(h3 if k in (0, 2) else h4, b3, perch, 17 + k)
    revisar_cimas((h3, h4, b3))  # antes del nido: lo único que puede sobresalir de una cima
    penones.nido(h3, b3, penones.centro_nido(PERCHES[0]))
    luces, fuegos = orilla.orilla(h1, b1, b2, rnd)
    borde.acantilado(h2, b2, rnd)
    luces.append(borde.craneo(h2, b1, b2, rnd))
    borde.arco(h2, b1, rnd)
    orilla.cascadas(h2, b1)
    revisar_zonas(m)
    # Misma caja para todas: un cubito mínimo en cada esquina de la caja común.
    lims = [x.limites() for x in m.values()]
    a = max(max(-lo.x, -lo.y, hi.x, hi.y) for lo, hi in lims)
    lo = V((-a, -a, min(lo.z for lo, _ in lims)))
    hi = V((a, a, max(hi.z for _, hi in lims)))
    for nombre, brillo, *_ in MALLAS:
        color = "lava" if brillo else "basalto3"
        if nombre.endswith("Brillo2"):
            color = "lava2"
        for esquina, s in ((lo, 1), (hi, -1)):
            m[nombre].bloque(esquina + V((0.02, 0.02, 0.02)) * s, (0.04, 0.04, 0.04), color)
    tris = {n: x.tris() for n, x in m.items()}
    assert all(t <= MAX_TRIS for t in tris.values()), f"una malla pasa de {MAX_TRIS} triángulos: {tris}"
    assert len(luces) <= 12, f"{len(luces)} luces (máximo 12)"
    return m, lo, hi, tris, luces, fuegos


def revisar_cimas(mallas):
    """Nada por encima de la cima de un peñón dentro de su radio (ahí apoya las patas)."""
    for perch in PERCHES:
        cima, size = perch_top(perch)
        for x in mallas:
            for v in x.bm.verts:
                if math.hypot(v.co.x - cima.x, v.co.y - cima.y) < size and v.co.z > cima.z + 1e-4:
                    raise AssertionError(f"algo sobresale de la cima {perch}: {tuple(v.co)}")


def revisar_zonas(m):
    """Zonas prohibidas del contrato: el paseo, Y = 30 en el acantilado y el santuario (fijas)."""
    for nombre, _, sube, _ in MALLAS:
        for v in m[nombre].bm.verts:
            r, z = radio_de(v.co), v.co.z
            assert r < 205, f"{nombre}: {tuple(v.co)} en el paseo"
            assert r < 189 or z <= PASEO_Y, f"{nombre}: {tuple(v.co)} sobre Y = 30 en el acantilado"
            if not sube:
                assert not (r < 124 and z > -84), f"{nombre}: {tuple(v.co)} en las cadenas del santuario"
                assert not (r < 100 and z > -136), f"{nombre}: {tuple(v.co)} en el cono del santuario"


def material(nombre, img, brillo=None):
    mat = bpy.data.materials.get(nombre) or bpy.data.materials.new(nombre)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    if brillo:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 4.0
    return mat


def objetos(m):
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    img = hacer_paleta()
    piedra = material(f"{ID}Habitat", img)
    objs = []
    for nombre, brillo, *_ in MALLAS:
        me = bpy.data.meshes.new(nombre)
        m[nombre].bm.to_mesh(me)
        m[nombre].bm.free()
        o = bpy.data.objects.new(nombre, me)
        o.data.materials.append(material(f"{nombre}_Neon", img, brillo) if brillo else piedra)
        bpy.context.scene.collection.objects.link(o)
        objs.append(o)
    return objs


def exportar(objs, lo, hi, luces, fuegos):
    for x in bpy.data.objects:
        x.select_set(x in objs)
    os.makedirs(DIR, exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=FBX, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
                             path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
                             bake_space_transform=True, mesh_smooth_type="OFF", object_types={"MESH"})
    datos = {
        "ancho": round(hi.x - lo.x, 3), "alto": round(hi.z - lo.z, 3), "centroY": round((hi.z + lo.z) / 2, 3),
        "mallas": [{"nombre": n, "brillo": list(b) if b else None, "sube": s, "soloConLava": c} for n, b, s, c in MALLAS],
        "luces": luces, "fuegos": fuegos,
        "lava": LAVA,  # Dragon/Guarida.lava: las que suben están armadas con la lava aquí
    }
    with open(CAJA_JSON, "w", encoding="utf-8") as f:
        json.dump(datos, f, indent=1, ensure_ascii=False)
        f.write("\n")


# --- Renders (el fondo y la lava son solo para el render) ---------------------------------
def fondo_lago():
    import bmesh
    bm = bmesh.new()
    radios = [0, 74.9] + [75 + 2.5 * k for k in range(31)] + [152 + 4 * k for k in range(10)] + \
        [190 + 1.5 * k for k in range(11)] + [245]
    lados = 128
    anillos = []
    for r in radios:
        anillos.append([bm.verts.new((r * math.cos(math.tau * k / lados), r * math.sin(math.tau * k / lados), piso(r)))
                        for k in range(lados)])
    for a, b in zip(anillos, anillos[1:]):
        for k in range(lados):
            j = (k + 1) % lados
            bm.faces.new((a[k], a[j], b[j], b[k]))
    me = bpy.data.meshes.new("FondoLago")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("FondoLago", me)
    mat = bpy.data.materials.new("Fondo")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.2, 0.19, 0.19, 1)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return o


def disco_lava():
    lo, hi = 75.0, 150.0
    for _ in range(40):  # dónde el cuenco llega a la lava
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if piso(mid) < LAVA else (lo, mid)
    bpy.ops.mesh.primitive_circle_add(vertices=128, radius=lo + 0.6, fill_type="NGON", location=(0, 0, LAVA))
    o = bpy.context.active_object
    o.name = "LagoDeLava"
    mat = bpy.data.materials.new("Lava")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.35, 0.06, 0.02, 1)
    bsdf.inputs["Emission Color"].default_value = (1.0, 0.25, 0.04, 1)
    bsdf.inputs["Emission Strength"].default_value = 1.2
    o.data.materials.append(mat)
    return o


VISTAS = (  # nombre, cámara (ángulo, radio, Y), mira a, lente, con lava
    ("paseo_puerta_lava", (270, 220, 34), (0, 0, -18), 20, True),
    ("paseo_30_lava", (30, 220, 34), (0, 0, -18), 20, True),
    ("paseo_150_sin_lava", (150, 220, 34), (0, 0, -40), 20, False),
    ("aerea_lava", (270, 150, 430), (0, 0, -20), 30, True),
    ("aerea_sin_lava", (270, 150, 430), (0, 0, -20), 30, False),
    ("cerca_nido", (300, 80, 18), (0, -8, -6), 32, True),
    ("cerca_craneo", (105, 110, 22), (0, -185, 10), 30, True),
    ("paseo_225_lava", (225, 220, 34), (0, 0, -18), 20, True),
)


def renders(objs):
    """Sin lava, las mallas que suben no están (el juego las hunde y las saca con ella)."""
    escena = bpy.context.scene
    suben = [o for o, (_, _, sube, _) in zip(objs, MALLAS) if sube]
    solo_lava = [o for o, (*_, con) in zip(objs, MALLAS) if con]
    for motor in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            escena.render.engine = motor
            break
        except TypeError:
            continue
    escena.render.resolution_x, escena.render.resolution_y = 1600, 900
    escena.view_settings.view_transform = "Standard"
    mundo = bpy.data.worlds.new("Fondo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.09, 0.06, 0.07, 1)
    escena.world = mundo
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy = 3.2
    sol.rotation_euler = (math.radians(50), 0, math.radians(-30))
    escena.collection.objects.link(sol)
    fondo_lago()
    lava = disco_lava()
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    escena.collection.objects.link(cam)
    escena.camera = cam
    cam.data.clip_end = 3000
    os.makedirs(RENDERS, exist_ok=True)
    for nombre, (a, r, y), mira, lente, con_lava in VISTAS:
        for o in [lava] + suben + solo_lava:
            o.hide_render = not con_lava
        cam.location = en(a, r, y)
        cam.rotation_euler = (V(mira) - cam.location).to_track_quat("-Z", "Y").to_euler()
        cam.data.lens = lente
        escena.render.filepath = os.path.join(RENDERS, f"{nombre}.png")
        bpy.ops.render.render(write_still=True)
        print("RENDER", escena.render.filepath)


M, LO, HI, TRIS, LUCES, FUEGOS = construir()
OBJS = objetos(M)
print("HABITAT tris", TRIS, "caja", tuple(round(v, 2) for v in LO), tuple(round(v, 2) for v in HI))
if "exportar" in ARGS:
    exportar(OBJS, LO, HI, LUCES, FUEGOS)
    print("EXPORTADO", FBX)
if "render" in ARGS:
    renders(OBJS)
