r"""
Renders del hábitat completo de la Orca fantasma (los pide habitat_orcafantasma.py con
"render"). Se hacen DESPUÉS de exportar: cambian el material de las mallas de brillo por uno
que emite su color y agregan, solo para la foto, el fondo del lago (malla gris con la fórmula
del contrato), el borde de los jugadores y el agua (Y = 2).
    paseo_puerta.png   desde la puerta (ángulo 270, r 220, Y 34) mirando al centro
    paseo_<a>.png      desde el paseo en otros ángulos, mirando al centro
    barco.png, ballena.png  desde el paseo, mirando a cada pieza grande
    aerea.png          vista aérea oblicua de todo el cráter
    agua.png           la vista de la puerta con el agua insinuada
    agua_aerea.png     la aérea con el agua
"""
import bpy, bmesh, math, os
from mathutils import Vector as V
import habitat_orcafantasma_piezas as Z


def mat_color(nombre, rgb, emision=0.0, alfa=1.0):
    mat = bpy.data.materials.new(nombre)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    c = [v / 255 for v in rgb] + [1]
    bsdf.inputs["Base Color"].default_value = c
    bsdf.inputs["Roughness"].default_value = 0.9
    if emision:
        bsdf.inputs["Emission Color"].default_value = c
        bsdf.inputs["Emission Strength"].default_value = emision
    if alfa < 1:
        bsdf.inputs["Alpha"].default_value = alfa
        if hasattr(mat, "surface_render_method"):
            mat.surface_render_method = "BLENDED"
    return mat


def revolucion(nombre, perfil, lados, mat):
    """Malla de revolución con el perfil [(r, z)] (el fondo del lago y el paseo)."""
    bm = bmesh.new()
    anillos = []
    for r, z in perfil:
        anillos.append([bm.verts.new((r * math.cos(2 * math.pi * k / lados), r * math.sin(2 * math.pi * k / lados), z))
                        for k in range(lados)])
    for a, b in zip(anillos, anillos[1:]):
        for k in range(lados):
            k2 = (k + 1) % lados
            bm.faces.new((a[k], a[k2], b[k2], b[k]))
    me = bpy.data.meshes.new(nombre)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(nombre, me)
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)
    return o


def escena(objs, brillos):
    for o in objs:
        for k, rgb in brillos.items():
            if o.name.endswith(k):
                o.data.materials.clear()
                o.data.materials.append(mat_color(o.name + "_render", rgb, 1.4))
    radios = [0.5, 40, 75] + [75 + 5 * k for k in range(1, 16)] + [150 + 5 * k for k in range(1, 8)] + \
             [190 + 1.5 * k for k in range(1, 11)] + [235, 270]
    revolucion("FondoLago", [(r, Z.piso(r)) for r in radios], 120, mat_color("Fondo", (120, 118, 124)))
    agua = revolucion("Agua", [(0.5, 2), (191, 2)], 96, mat_color("Agua", (14, 70, 86), 0.0, 0.55))
    esc = bpy.context.scene
    for motor in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            esc.render.engine = motor
            break
        except TypeError:
            continue
    esc.render.resolution_x, esc.render.resolution_y = 1600, 900
    esc.view_settings.view_transform = "Standard"
    mundo = bpy.data.worlds.new("Cielo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = (0.16, 0.14, 0.24, 1)
    mundo.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    esc.world = mundo
    sol = bpy.data.objects.new("Sol", bpy.data.lights.new("Sol", "SUN"))
    sol.data.energy = 2.6
    sol.rotation_euler = (math.radians(50), 0, math.radians(-30))
    esc.collection.objects.link(sol)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    cam.data.clip_end = 3000
    esc.collection.objects.link(cam)
    esc.camera = cam
    return cam, agua


def foto(cam, ruta, pos, mira, lente=22):
    cam.location = V(pos)
    cam.rotation_euler = (V(mira) - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lente
    bpy.context.scene.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
    print("RENDER", ruta)


def renders(objs, brillos, luces, carpeta):
    os.makedirs(carpeta, exist_ok=True)
    cam, agua = escena(objs, brillos)
    for k, (p, c, rango) in enumerate(luces):
        luz = bpy.data.objects.new(f"Luz{k}", bpy.data.lights.new(f"Luz{k}", "POINT"))
        luz.data.color = [v / 255 for v in c]
        luz.data.energy = 60000
        luz.data.shadow_soft_size = 1
        luz.location = p
        bpy.context.scene.collection.objects.link(luz)
    ruta = lambda n: os.path.join(carpeta, n + ".png")
    agua.hide_render = True
    foto(cam, ruta("paseo_puerta"), Z.polar(270, 220, 34), (0, 0, 2))
    for a in (0, 90, 160):
        foto(cam, ruta(f"paseo_{a}"), Z.polar(a, 220, 34), (0, 0, 2))
    foto(cam, ruta("barco"), Z.polar(250, 215, 70), Z.polar(205, 172, 0), 30)
    foto(cam, ruta("ballena"), Z.polar(90, 215, 70), Z.polar(45, 158, -5), 30)
    foto(cam, ruta("aerea"), (0, 330, 420), (0, 0, -40), 30)
    agua.hide_render = False
    foto(cam, ruta("agua"), Z.polar(270, 220, 34), (0, 0, 2))
    foto(cam, ruta("agua_aerea"), (0, 330, 420), (0, 0, -40), 30)
