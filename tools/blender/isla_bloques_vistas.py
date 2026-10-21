r"""
Solo para revisar la isla de bloques (no va al juego): el mar de mentira a waterLevel, cielo,
sol de tarde, la cámara y los renders.
    escena(F) -> cámara
    renders(cam, F, M, alto, base, carpeta)
"""
import bpy, math, os
from mathutils import Vector as V


def _mar(nivel):
    mat = bpy.data.materials.new("Mar")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.05, 0.42, 0.6, 1)
    bsdf.inputs["Alpha"].default_value = 0.62
    bsdf.inputs["Roughness"].default_value = 0.15
    if hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "BLENDED"
    verts = [V((math.cos(a) * 900, math.sin(a) * 900, nivel)) for a in (math.tau * k / 8 for k in range(8))]
    me = bpy.data.meshes.new("Mar")
    me.from_pydata(verts, [], [list(range(8))])
    o = bpy.data.objects.new("Mar", me)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    o["solo_render"] = True


def escena(F):
    sc = bpy.context.scene
    motores = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in motores else "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    sc.view_settings.view_transform = "Standard"
    mundo = bpy.data.worlds.new("Cielo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.42, 0.64, 0.9, 1)
    mundo.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    sc.world = mundo
    for nombre, energia, color, giro in (("Sol", 3.0, (1.0, 0.94, 0.84), (48, 30)),
                                         ("Relleno", 1.0, (1.0, 1.0, 1.0), (60, -150))):
        luz = bpy.data.objects.new(nombre, bpy.data.lights.new(nombre, "SUN"))
        luz.data.energy, luz.data.color = energia, color
        luz.rotation_euler = (math.radians(giro[0]), 0, math.radians(giro[1]))
        sc.collection.objects.link(luz)
    _mar(F.L["waterLevel"])
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    return cam


def mirar(cam, ojo, objetivo, lente=35, orto=None):
    """ojo y objetivo en ejes de Roblox (X, Y, Z)."""
    a = V((ojo[0], -ojo[2], ojo[1]))
    b = V((objetivo[0], -objetivo[2], objetivo[1]))
    cam.location = a
    cam.rotation_euler = (b - a).to_track_quat("-Z", "Y").to_euler()
    cam.data.type = "ORTHO" if orto else "PERSP"
    if orto:
        cam.data.ortho_scale = orto
    cam.data.lens = lente
    cam.data.clip_end = 5000


def renders(cam, F, M, alto, carpeta):
    os.makedirs(carpeta, exist_ok=True)
    suelo = lambda x, z: alto.get((math.floor(x / M.CELDA), math.floor(z / M.CELDA)), F.L["waterLevel"])
    import isla_bloques_monticulos as MO
    indice, (px, pz), radio = F.ESTANQUES[0]
    abre = MO.APERTURAS[indice][0]
    lejos = radio * 1.3 + 22
    costado = abre + 1.9  # de costado, para ver los montículos
    cx, cz = px + math.cos(costado) * (lejos + 6), pz + math.sin(costado) * (lejos + 6)
    for nombre, ojo, objetivo, lente in (
        ("plaza_arriba", (0, 190, -150), (0, 0, 8), 30),
        ("estanque", (cx, suelo(cx, cz) + 6, cz), (px, 6, pz), 26),
        ("sagrado", (16, 13, -40), (0, 5, 0), 26),
    ):
        mirar(cam, ojo, objetivo, lente)
        bpy.context.scene.render.filepath = os.path.join(carpeta, f"{nombre}.png")
        bpy.ops.render.render(write_still=True)
