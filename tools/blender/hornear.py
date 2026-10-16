"""
Prepara un modelo de Meshy para Roblox sin perder la textura:
  - una malla, origen en la base y centrada, mirando a -Y;
  - una copia reducida (triángulos), con UVs nuevas de islas grandes;
  - las texturas (color, normales, rugosidad, metal) se HORNEAN desde el modelo
    original de alta resolución a la copia reducida, a 1024 con margen, así no
    hay costuras con colores corridos (el atlas de Meshy tiene cientos de islas
    chicas que se rompen al reducir la malla o la textura).
Uso: python3 -I hornear.py -- <fbx de Meshy> <salida.blend> <Nombre> <triangulos> [tamaño]
"""
import bpy, bmesh, sys, os, json, math, mathutils
SRC, OUT, NAME, TRIS = sys.argv[-5], sys.argv[-4], sys.argv[-3], int(sys.argv[-2])
SIZE = int(sys.argv[-1])
TEX = os.path.join(os.path.dirname(os.path.abspath(OUT)), "tex")
os.makedirs(TEX, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=SRC)
meshes = [x for x in bpy.data.objects if x.type == 'MESH']
for x in list(bpy.data.objects):
    if x not in meshes:
        bpy.data.objects.remove(x)
bpy.ops.object.select_all(action='DESELECT')
for m in meshes:
    m.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
hi = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bb = [mathutils.Vector(c) for c in hi.bound_box]
mn = mathutils.Vector([min(v[i] for v in bb) for i in range(3)]); mx = mathutils.Vector([max(v[i] for v in bb) for i in range(3)])
hi.data.transform(mathutils.Matrix.Translation(-mathutils.Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))))
height = mx.z - mn.z

# Copia reducida.
lo = hi.copy(); lo.data = hi.data.copy(); lo.name = NAME; lo.data.name = NAME
bpy.context.scene.collection.objects.link(lo)
bpy.ops.object.select_all(action='DESELECT'); lo.select_set(True); bpy.context.view_layer.objects.active = lo
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.0005)
bpy.ops.object.mode_set(mode='OBJECT')
for uv in list(lo.data.uv_layers):
    lo.data.uv_layers.remove(uv)
tris0 = sum(len(p.vertices) - 2 for p in lo.data.polygons)
if tris0 > TRIS:
    dec = lo.modifiers.new("Reducir", "DECIMATE"); dec.ratio = TRIS / tris0 * 0.98
    bpy.ops.object.modifier_apply(modifier=dec.name)
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.quads_convert_to_tris()
lo.data.uv_layers.new(name="UVMap")
bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.004, area_weight=0.0, scale_to_bounds=True)
try:
    bpy.ops.uv.pack_islands(margin=0.004, rotate=True)
except Exception as e:
    print("pack", e)
bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.shade_smooth()
tris = sum(len(p.vertices) - 2 for p in lo.data.polygons)

# Material del original: texturas por canal.
hmat = hi.active_material
nodes, links = hmat.node_tree.nodes, hmat.node_tree.links
bsdf = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
out = next(n for n in nodes if n.type == 'OUTPUT_MATERIAL')
def source(socket):
    if not socket.is_linked: return None
    n = socket.links[0].from_node
    if n.type == 'NORMAL_MAP':
        return source(n.inputs['Color'])
    return n if n.type == 'TEX_IMAGE' else None
srcs = {"color": source(bsdf.inputs['Base Color']), "roughness": source(bsdf.inputs['Roughness']),
        "metalness": source(bsdf.inputs['Metallic'])}
print("SOURCES", {k: (v.image.name if v else None) for k, v in srcs.items()})
surface_link = out.inputs['Surface'].links[0]
emit = nodes.new('ShaderNodeEmission')

# Material nuevo de la copia.
lmat = bpy.data.materials.new(NAME + "_Mat"); lmat.use_nodes = True
lo.data.materials.clear(); lo.data.materials.append(lmat)
ln, ll = lmat.node_tree.nodes, lmat.node_tree.links
lbsdf = next(n for n in ln if n.type == 'BSDF_PRINCIPLED')
target = ln.new('ShaderNodeTexImage')

scene = bpy.context.scene
scene.render.engine = 'CYCLES'; scene.cycles.device = 'CPU'; scene.cycles.samples = 1
bk = scene.render.bake
bk.use_selected_to_active = True; bk.cage_extrusion = 0.012 * height; bk.max_ray_distance = 0.05 * height
bk.margin = 12; bk.margin_type = 'EXTEND'
bpy.ops.object.select_all(action='DESELECT'); hi.select_set(True); lo.select_set(True)
bpy.context.view_layer.objects.active = lo

images = {}
def bake(kind, colorspace, mode):
    img = bpy.data.images.new(f"{NAME}_{kind}", SIZE, SIZE, alpha=False, float_buffer=False)
    img.colorspace_settings.name = colorspace
    target.image = img; ln.active = target
    for n in ln: n.select = False
    target.select = True
    if mode == 'EMIT':
        src = srcs[kind]
        if src is None:
            img.generate_type = 'BLANK'
            val = 0.0 if kind == "metalness" else 0.6
            img.pixels[:] = [val, val, val, 1.0] * (SIZE * SIZE)
        else:
            links.new(src.outputs['Color'], emit.inputs['Color'])
            links.new(emit.outputs['Emission'], out.inputs['Surface'])
            bpy.ops.object.bake(type='EMIT')
    else:
        links.new(bsdf.outputs[0], out.inputs['Surface'])
        bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT')
    path = os.path.join(TEX, f"{NAME}_{kind}.png")
    img.filepath_raw = path; img.file_format = 'PNG'; img.save()
    images[kind] = img
    print("BAKED", kind)

bake("color", "sRGB", 'EMIT')
bake("roughness", "Non-Color", 'EMIT')
bake("metalness", "Non-Color", 'EMIT')
bake("normal", "Non-Color", 'NORMAL')

# El material final: Principled con las 4 texturas (el importador de Roblox las lee).
ln.remove(target)
def tex(kind):
    n = ln.new('ShaderNodeTexImage'); n.image = images[kind]; return n
ll.new(tex("color").outputs['Color'], lbsdf.inputs['Base Color'])
ll.new(tex("roughness").outputs['Color'], lbsdf.inputs['Roughness'])
ll.new(tex("metalness").outputs['Color'], lbsdf.inputs['Metallic'])
nm = ln.new('ShaderNodeNormalMap')
ll.new(tex("normal").outputs['Color'], nm.inputs['Color'])
ll.new(nm.outputs['Normal'], lbsdf.inputs['Normal'])
bpy.data.objects.remove(hi)
for img in list(bpy.data.images):
    if img.name not in [i.name for i in images.values()]:
        bpy.data.images.remove(img)
bpy.ops.wm.save_as_mainfile(filepath=OUT)
print("RESULT", json.dumps({"name": NAME, "tris_before": tris0, "tris": tris, "dims": list(lo.dimensions)}))
