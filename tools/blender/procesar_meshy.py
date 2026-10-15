"""Prepara un modelo de Meshy para el juego: una malla, triángulos limitados,
simetría en X, origen en la base, nariz hacia -Y, texturas de 1024 con el nombre
del modelo. Uso: blender -b --python procesar.py -- <fbx de Meshy> <salida.blend> <Nombre> <triangulos>"""
import bpy, sys, json, mathutils, os
SRC, OUT, NAME, TRIS = sys.argv[-4], sys.argv[-3], sys.argv[-2], int(sys.argv[-1])
TEX = os.path.join(os.path.dirname(OUT), "tex")
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
o = bpy.context.view_layer.objects.active
o.name = NAME; o.data.name = NAME
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
if hasattr(bpy.ops.mesh, 'customdata_custom_splitnormals_clear'):
    bpy.ops.mesh.customdata_custom_splitnormals_clear()
bpy.ops.mesh.remove_doubles(threshold=0.0005)
bpy.ops.object.mode_set(mode='OBJECT')
tris0 = sum(len(p.vertices) - 2 for p in o.data.polygons)
if tris0 > TRIS:
    dec = o.modifiers.new("Reducir", "DECIMATE"); dec.ratio = TRIS / tris0 * 0.98
    dec.use_symmetry = True; dec.symmetry_axis = 'X'
    bpy.ops.object.modifier_apply(modifier=dec.name)
tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
bpy.ops.object.shade_smooth()
bb = [o.matrix_world @ mathutils.Vector(c) for c in o.bound_box]
mn = mathutils.Vector([min(v[i] for v in bb) for i in range(3)]); mx = mathutils.Vector([max(v[i] for v in bb) for i in range(3)])
o.data.transform(mathutils.Matrix.Translation(-mathutils.Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))))
o.location = (0, 0, 0)
mat = o.active_material; mat.name = NAME + "_Mat"
names = {"Base Color": "color", "Color": "normal", "Roughness": "roughness", "Metallic": "metalness"}
for l in list(mat.node_tree.links):
    if l.from_node.type == 'TEX_IMAGE' and l.to_socket.name in names:
        img = l.from_node.image; suf = names[l.to_socket.name]
        img.scale(1024, 1024)
        path = os.path.join(TEX, f"{NAME}_{suf}.png")
        img.filepath_raw = path; img.file_format = 'PNG'; img.save()
        space = img.colorspace_settings.name
        new = bpy.data.images.load(path); new.colorspace_settings.name = space
        new.name = f"{NAME}_{suf}.png"; l.from_node.image = new
        bpy.data.images.remove(img)
bpy.ops.wm.save_as_mainfile(filepath=OUT)
print("RESULT", json.dumps({"name": NAME, "tris_before": tris0, "tris": tris, "dims": list(o.dimensions)}))
