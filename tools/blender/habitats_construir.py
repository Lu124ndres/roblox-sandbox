r"""
Construye los props de un hábitat, los exporta y (opcional) hace una vista previa.
    blender -b -P tools/blender/habitats_construir.py -- OrcaFantasma [render]
    (o python con bpy: python habitats_construir.py OrcaFantasma render)
Salida:
    assets/blender/habitats/<Habitat>.fbx   todos los props en fila + "Ancla" (cubo de 1 stud)
    assets/blender/habitats/<Habitat>.json  por prop: origen, efecto, llama, colores y tris
    assets/blender/habitats/<Habitat>.png   vista previa (con render)
El cubo Ancla permite ubicar el origen de cada prop en Studio aunque el importador centre
las mallas: origen_roblox = ancla_roblox + (x, z, -y) de (origen - centro del ancla).
"""
import bpy, sys, os, json, math, importlib
from mathutils import Vector as V

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import habitats as H

MODULOS = {"OrcaFantasma": "habitats_orcafantasma", "Minotauro": "habitats_minotauro",
           "Orca": "habitats_orca", "DragonMarino": "habitats_dragon"}
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
HABITAT = args[0]
RENDER = "render" in args
SALIDA = os.path.join(H.RAIZ, "assets", "blender", "habitats")
ANCLA = V((-30.0, 0.0, 0.5))


def limpiar():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    for me in list(bpy.data.meshes):
        bpy.data.meshes.remove(me)


def construir():
    limpiar()
    mod = importlib.import_module(MODULOS[HABITAT])
    datos = {"habitat": HABITAT, "ancla": list(ANCLA), "props": [], "sugerido": mod.SUGERIDO}
    x = 0.0
    objetos = []
    for nombre, fabrica in mod.PROPS:
        info = fabrica()
        o = info["malla"].objeto(nombre)
        ancho = o.dimensions.x
        minx = min((v.co.x for v in o.data.vertices), default=0)
        maxx = max((v.co.x for v in o.data.vertices), default=0)
        x += -minx
        o.location.x = x
        p = {"nombre": nombre, "origen": [x, 0, 0], "tris": H.tris(o),
             "alto": round(max(v.co.z for v in o.data.vertices), 2),
             "ancho": round(o.dimensions.x, 2), "fondo": round(o.dimensions.y, 2)}
        objetos.append(o)
        if info.get("brillo"):
            ob = info["brillo"].objeto(nombre + "_Brillo", piso=False)
            ob.location.x = x
            p["brillo"] = nombre + "_Brillo"
            p["colorBrillo"] = list(info.get("colorBrillo", (255, 255, 255)))
            p["trisBrillo"] = H.tris(ob)
            objetos.append(ob)
        for k in ("efecto", "colorLuz", "llama", "colision"):
            if info.get(k) is not None:
                p[k] = list(info[k]) if isinstance(info[k], (tuple, list, V)) else info[k]
        datos["props"].append(p)
        print("PROP", nombre, "tris", p["tris"], "alto", p["alto"], "ancho", p["ancho"], "fondo", p["fondo"])
        x += maxx + 10
    m = H.Malla()
    m.caja(H.T(*ANCLA), (1, 1, 1), "hierro")
    objetos.append(m.objeto("Ancla", piso=False))
    return datos, objetos


def exportar(datos, objetos):
    os.makedirs(SALIDA, exist_ok=True)
    for o in bpy.data.objects:
        o.select_set(o in objetos)
    fbx = os.path.join(SALIDA, HABITAT + ".fbx")
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
        path_mode="COPY", embed_textures=False, axis_forward="-Z", axis_up="Y", bake_space_transform=True,
        mesh_smooth_type="OFF", object_types={"MESH"})
    with open(os.path.join(SALIDA, HABITAT + ".json"), "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=1)
    print("EXPORTADO", fbx)


def vista(datos, objetos):
    try:
        bpy.ops.preferences.addon_enable(module="cycles")
    except Exception as e:
        print("cycles?", e)
    for o in objetos:
        if o.name.endswith("_Brillo"):
            p = next(p for p in datos["props"] if p.get("brillo") == o.name)
            mat = bpy.data.materials.new(o.name)
            mat.use_nodes = True
            bsdf = mat.node_tree.nodes["Principled BSDF"]
            c = [v / 255 for v in p["colorBrillo"]] + [1]
            bsdf.inputs["Base Color"].default_value = c
            bsdf.inputs["Emission Color"].default_value = c
            bsdf.inputs["Emission Strength"].default_value = 1.6
            o.data.materials.clear()
            o.data.materials.append(mat)
        if o.name == "Ancla":
            o.hide_render = True
    xs = [p["origen"][0] for p in datos["props"]]
    cx = (min(xs) + max(xs)) / 2
    largo = max(xs) - min(xs) + 40
    scn = bpy.context.scene
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    scn.collection.objects.link(cam)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = largo
    cam.location = V((cx + largo * 0.12, largo * 0.9, largo * 0.42))
    objetivo = V((cx, 0, 10))
    cam.rotation_euler = (objetivo - cam.location).to_track_quat("-Z", "Y").to_euler()
    scn.camera = cam
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy = 3.2
    sol.rotation_euler = (math.radians(50), math.radians(10), math.radians(200))
    scn.collection.objects.link(sol)
    piso = H.Malla()
    piso.caja(H.T(cx, 0, -0.5), (largo * 1.5, largo, 1), "arena")
    piso.objeto("Piso", piso=False)
    world = scn.world or bpy.data.worlds.new("Mundo")
    scn.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.42, 0.6, 0.78, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    scn.view_settings.view_transform = "Standard"
    scn.render.engine = "CYCLES"
    scn.cycles.samples = 24
    scn.cycles.use_denoising = True
    scn.render.resolution_x, scn.render.resolution_y = 1800, 760
    scn.render.filepath = os.path.join(SALIDA, HABITAT + ".png")
    bpy.ops.render.render(write_still=True)
    print("VISTA", scn.render.filepath)


datos, objetos = construir()
exportar(datos, objetos)
if RENDER:
    vista(datos, objetos)
