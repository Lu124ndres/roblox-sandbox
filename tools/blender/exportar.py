"""
Exporta un monstruo de Gigantes a Roblox (ver docs/blender-pipeline.md):
  - una sola malla de pocos polígonos (≤ 9,800 triángulos),
  - UVs automáticas,
  - texturas horneadas de 1024 desde el modelo detallado: color (con el
    brillo de lava/ojos sumado) y normales,
  - FBX con texturas embebidas en assets/blender/<Nombre>.fbx y PNG en
    assets/textures/<Nombre>_color.png / _normal.png.
Requiere criaturas.py cargado. exportar_monstruo(nombre, objetos, carpeta_proyecto).
"""
import os


def _duplicar_unido(nombre, objetos):
    bpy.ops.object.select_all(action="DESELECT")
    copias = []
    for obj in objetos:
        copia = obj.copy()
        copia.data = obj.data.copy()
        bpy.context.collection.objects.link(copia)
        copias.append(copia)
    return unir(nombre, copias)


def _imagen(nombre, color=True):
    img = bpy.data.images.get(nombre)
    if img:
        bpy.data.images.remove(img)
    img = bpy.data.images.new(nombre, 1024, 1024, alpha=False, float_buffer=False)
    img.colorspace_settings.name = "sRGB" if color else "Non-Color"
    return img


def _material_horneado(nombre, img_color, img_normal):
    mat, nt, bsdf = _nodos(nombre)
    tc = nt.nodes.new("ShaderNodeTexImage")
    tc.image = img_color
    tn = nt.nodes.new("ShaderNodeTexImage")
    tn.image = img_normal
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(tc.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tn.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Roughness"].default_value = 0.75
    return mat, nt, tc, tn


def _hornear(alto, bajo, tipo, img, nt_bajo, nodo):
    nt_bajo.nodes.active = nodo
    for o in bpy.context.selected_objects:
        o.select_set(False)
    alto.select_set(True)
    bajo.select_set(True)
    bpy.context.view_layer.objects.active = bajo
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.samples = 8
    scn.render.bake.use_selected_to_active = True
    scn.render.bake.cage_extrusion = 0.04
    scn.render.bake.margin = 8
    if tipo == "DIFFUSE":
        scn.render.bake.use_pass_direct = False
        scn.render.bake.use_pass_indirect = False
        scn.render.bake.use_pass_color = True
    bpy.ops.object.bake(type=tipo)


def exportar_monstruo(nombre, objetos, proyecto, triangulos_max=9800):
    texturas = os.path.join(proyecto, "assets", "textures")
    blender_dir = os.path.join(proyecto, "assets", "blender")
    os.makedirs(texturas, exist_ok=True)
    alto = _duplicar_unido(f"{nombre}_Alto", objetos)
    bajo = _duplicar_unido(nombre, objetos)
    # Reducir polígonos.
    tris = triangulos([bajo])
    if tris > triangulos_max:
        dec = bajo.modifiers.new("Reducir", "DECIMATE")
        dec.ratio = triangulos_max / tris * 0.97
        aplicar(bajo)
    bpy.ops.object.select_all(action="DESELECT")
    bajo.select_set(True)
    bpy.context.view_layer.objects.active = bajo
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.006)
    bpy.ops.object.mode_set(mode="OBJECT")
    # Texturas horneadas.
    img_color = _imagen(f"{nombre}_color")
    img_brillo = _imagen(f"{nombre}_brillo")
    img_normal = _imagen(f"{nombre}_normal", color=False)
    mat, nt, tc, tn = _material_horneado(f"{nombre}_Mat", img_color, img_normal)
    bajo.data.materials.clear()
    bajo.data.materials.append(mat)
    _hornear(alto, bajo, "DIFFUSE", img_color, nt, tc)
    tc.image = img_brillo
    _hornear(alto, bajo, "EMIT", img_brillo, nt, tc)
    tc.image = img_color
    _hornear(alto, bajo, "NORMAL", img_normal, nt, tn)
    # Color final = color + brillo (las grietas de lava y los ojos se ven encendidos).
    px_c = list(img_color.pixels)
    px_b = list(img_brillo.pixels)
    img_color.pixels = [min(1.0, c + b * 0.85) if (i % 4) != 3 else 1.0 for i, (c, b) in enumerate(zip(px_c, px_b))]
    for img, sufijo in ((img_color, "color"), (img_normal, "normal")):
        img.filepath_raw = os.path.join(texturas, f"{nombre}_{sufijo}.png")
        img.file_format = "PNG"
        img.save()
    bpy.data.objects.remove(alto)
    # FBX con texturas embebidas.
    bpy.ops.object.select_all(action="DESELECT")
    bajo.select_set(True)
    bpy.context.view_layer.objects.active = bajo
    bpy.ops.export_scene.fbx(filepath=os.path.join(blender_dir, f"{nombre}.fbx"), use_selection=True,
                             apply_scale_options="FBX_SCALE_UNITS", path_mode="COPY", embed_textures=True,
                             bake_space_transform=True, axis_forward="-Z", axis_up="Y",
                             mesh_smooth_type="FACE", add_leaf_bones=False)
    return {"triangulos": triangulos([bajo])}
