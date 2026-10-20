r"""
Render de comprobación de ojos_medir.py (lo carga con exec): la cabeza de frente a cada ojo, con
un marco magenta en el rectángulo medido y un punto en su centro, un poco por delante de la cara.
Si los dos ojos miran casi igual (de frente), una vista; si no (a los costados), una por ojo, lado
a lado en el mismo PNG.
"""
import bmesh
from mathutils import Matrix


def _caja(nombre, base, centro, ancho, alto, hondo, mat):
    """Caja en los ejes del ojo (base = columnas der, up, normal)."""
    me = bpy.data.meshes.new(nombre)
    b = bmesh.new()
    bmesh.ops.create_cube(b, size=1.0)
    b.to_mesh(me)
    b.free()
    o = bpy.data.objects.new(nombre, me)
    o.matrix_world = Matrix.Translation(centro) @ base @ Matrix.Diagonal((ancho, alto, hondo, 1))
    o.data.materials.append(mat)
    bpy.context.scene.collection.objects.link(o)


def _marcas(ojos, celda):
    mat = bpy.data.materials.new("OjosMarca")
    mat.diffuse_color = (1, 0, 1, 1)
    g = celda * 0.12
    for k, o in enumerate(ojos):
        n, up = o["normal"], o["up"]
        der = up.cross(n)
        base = Matrix((der, up, n)).transposed().to_4x4()
        c = o["center"] + n * celda * 0.25
        w, h = o["size"]
        _caja(f"Marca{k}a", base, c + up * (h / 2), w + g, g, g, mat)
        _caja(f"Marca{k}b", base, c - up * (h / 2), w + g, g, g, mat)
        _caja(f"Marca{k}c", base, c + der * (w / 2), g, h + g, g, mat)
        _caja(f"Marca{k}d", base, c - der * (w / 2), g, h + g, g, mat)
        _caja(f"Marca{k}e", base, c, g * 1.5, g * 1.5, g, mat)


def _foto(ruta, objetivo, mira, lado):
    """Ortográfica desde objetivo + mira (unitario), que cubre `lado` BU."""
    sc = bpy.context.scene
    datos = bpy.data.cameras.new("OjosCam")
    datos.type, datos.ortho_scale, datos.clip_end = "ORTHO", lado, lado * 100
    cam = bpy.data.objects.new("OjosCam", datos)
    sc.collection.objects.link(cam)
    cam.location = objetivo + mira * lado * 10
    cam.rotation_euler = (-mira).to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)


def vista(salida, ojos, celda):
    sc = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH" and o.name == "Plane":
            o.hide_render = True
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "TEXTURE"
    sc.render.resolution_x = sc.render.resolution_y = 600
    sc.render.resolution_percentage = 100
    for m in bpy.data.materials:  # las piezas sueltas (sin rig) no tienen textura: su color plano
        bsdf = m.node_tree.nodes.get("Principled BSDF") if m.node_tree else None
        if bsdf and not bsdf.inputs["Base Color"].is_linked:
            m.diffuse_color = bsdf.inputs["Base Color"].default_value
    _marcas(ojos, celda)
    os.makedirs(os.path.dirname(salida), exist_ok=True)
    a, b = ojos
    if a["normal"].dot(b["normal"]) > 0.5:
        tomas = [((a["center"] + b["center"]) / 2, (a["normal"] + b["normal"]).normalized(),
                  (a["center"] - b["center"]).length + celda * 12)]
    else:
        tomas = [(o["center"], o["normal"], celda * 14) for o in (a, b)]
    rutas = []
    for k, (objetivo, mira, lado) in enumerate(tomas):
        rutas.append(salida.replace(".png", f"_{k}.png"))
        _foto(rutas[-1], objetivo, mira, lado)
    imgs = [bpy.data.images.load(r) for r in rutas]
    w, h = imgs[0].size
    px = np.concatenate([np.array(i.pixels[:], dtype=np.float32).reshape(h, w, 4) for i in imgs], axis=1)
    out = bpy.data.images.new("OjosVista", w * len(imgs), h, alpha=False)
    out.pixels[:] = px.ravel()
    out.filepath_raw, out.file_format = salida, "PNG"
    out.save()
    for r in rutas:
        os.remove(r)
