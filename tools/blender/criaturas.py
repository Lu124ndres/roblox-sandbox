"""
Herramientas para modelar los monstruos de Gigantes en Blender con código.

Método (parecido a esculpir):
  1. Bloques: cadenas de piel (Skin modifier) para huesos y extremidades, y
     masas elipsoidales para músculos, cráneo, hocico, etc.
  2. fusionar(): une todos los bloques en una sola superficie (remallado por
     vóxeles) y la suaviza, así las uniones se ven orgánicas.
  3. detalle(): relieve fino de piel/pelaje con ruido.
  4. pintar(): color por vértice con reglas (hocico claro, lomo oscuro...).
  5. Las piezas de otro material (cuernos, pezuñas, ojos, armadura) quedan
     como objetos aparte.
La exportación a Roblox (≤10k triángulos, texturas horneadas) está en exportar.py.

Uso en Blender:
    exec(open(r"...\\tools\\blender\\criaturas.py", encoding="utf-8").read())
"""
import bpy
import math
import random
from mathutils import Vector, Euler, noise


# ---------------------------------------------------------------- escena

def limpiar_escena():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.curves, bpy.data.images,
                  bpy.data.textures):
        for item in list(block):
            if item.users == 0:
                block.remove(item)


def estudio(alto, distancia=None, angulo=28, fondo=(0.42, 0.55, 0.68)):
    """Cámara 3/4, tres luces de área y fondo: para revisar el modelo."""
    distancia = distancia or alto * 2.3
    for obj in [o for o in bpy.data.objects if o.type in ("CAMERA", "LIGHT")]:
        bpy.data.objects.remove(obj)
    rad = math.radians(angulo)
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    bpy.context.collection.objects.link(cam)
    cam.location = (math.sin(rad) * distancia, -math.cos(rad) * distancia, alto * 0.52)
    objetivo = Vector((0, 0, alto * 0.5))
    cam.rotation_euler = (objetivo - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = 50
    bpy.context.scene.camera = cam
    for nombre, pos, energia, tam in (("Clave", (2.5, -3.5, 4.5), 1000, 2.5),
                                       ("Relleno", (-4, -2.5, 2.5), 300, 4),
                                       ("Contra", (-1, 4, 4), 900, 2)):
        luz = bpy.data.objects.new(nombre, bpy.data.lights.new(nombre, "AREA"))
        luz.data.energy = energia * (alto / 2.5) ** 2
        luz.data.size = tam * alto / 2.5
        luz.location = Vector(pos) * (alto / 2.5)
        luz.rotation_euler = (objetivo - luz.location).to_track_quat("-Z", "Y").to_euler()
        bpy.context.collection.objects.link(luz)
    scn = bpy.context.scene
    scn.view_settings.view_transform = "AgX"
    scn.view_settings.look = "AgX - Medium High Contrast"
    world = scn.world or bpy.data.worlds.new("Mundo")
    scn.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (*fondo, 1)
    bg.inputs["Strength"].default_value = 0.35


def renderizar(ruta, ancho=900, alto=900, muestras=48, motor="EEVEE"):
    scn = bpy.context.scene
    if motor == "CYCLES":
        scn.render.engine = "CYCLES"
        scn.cycles.samples = muestras
        scn.cycles.use_denoising = True
    else:
        scn.render.engine = "BLENDER_EEVEE"
        scn.eevee.taa_render_samples = muestras
        scn.eevee.use_raytracing = True
    scn.render.resolution_x, scn.render.resolution_y = ancho, alto
    scn.render.filepath = ruta
    bpy.ops.render.render(write_still=True)


# ---------------------------------------------------------------- bloques

def piel(nombre, puntos, aristas=None, subdiv=2, raiz=0):
    """Cadena orgánica: puntos = [(x, y, z, radio)]; sin aristas, en fila."""
    aristas = aristas or [(i, i + 1) for i in range(len(puntos) - 1)]
    mesh = bpy.data.meshes.new(nombre)
    mesh.from_pydata([p[:3] for p in puntos], aristas, [])
    obj = bpy.data.objects.new(nombre, mesh)
    bpy.context.collection.objects.link(obj)
    skin = obj.modifiers.new("Piel", "SKIN")
    skin.branch_smoothing = 0.5
    skin.use_smooth_shade = True
    for i, p in enumerate(puntos):
        r = p[3]
        mesh.skin_vertices[0].data[i].radius = r if isinstance(r, tuple) else (r, r)
    mesh.skin_vertices[0].data[raiz].use_root = True
    sub = obj.modifiers.new("Suave", "SUBSURF")
    sub.levels = sub.render_levels = subdiv
    return obj


def masa(nombre, centro, radios, rot=(0, 0, 0), segmentos=32):
    """Elipsoide (músculo, cráneo, hocico); rot en grados."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segmentos, ring_count=segmentos // 2,
                                         location=centro)
    obj = bpy.context.active_object
    obj.name = nombre
    obj.scale = radios
    obj.rotation_euler = Euler([math.radians(a) for a in rot])
    bpy.ops.object.shade_smooth()
    return obj


def simetrico(fn, *args, **kwargs):
    """Llama fn(lado) para lado = 1 y -1 y junta lo que devuelve."""
    out = []
    for lado in (1, -1):
        r = fn(lado, *args, **kwargs)
        out += r if isinstance(r, list) else [r]
    return out


# ---------------------------------------------------------------- superficie

def aplicar(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target="MESH")
    return obj


def unir(nombre, objetos):
    for obj in objetos:
        aplicar(obj)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objetos:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objetos[0]
    bpy.ops.object.join()
    final = bpy.context.active_object
    final.name = nombre
    final.data.name = nombre
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return final


def fusionar(nombre, objetos, voxel=0.025, suavizado=30, factor=1.0):
    """Une los bloques en una sola superficie orgánica: remallado por vóxeles y
    suavizado laplaciano (funde las uniones entre músculos sin perder volumen)."""
    obj = unir(nombre, objetos)
    rem = obj.modifiers.new("Fusion", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = voxel
    rem.adaptivity = 0
    rem.use_smooth_shade = True
    suave = obj.modifiers.new("Suavizado", "LAPLACIANSMOOTH")
    suave.iterations = suavizado
    suave.lambda_factor = factor
    suave.lambda_border = 0
    suave.use_volume_preserve = True
    suave.use_normalized = True
    aplicar(obj)
    bpy.ops.object.shade_smooth()
    return obj


def detalle(obj, fuerza=0.006, escala=0.05, tipo="CLOUDS"):
    tex = bpy.data.textures.new(f"{obj.name}_Relieve", tipo)
    if tipo == "CLOUDS":
        tex.noise_scale = escala
        tex.noise_depth = 4
    elif tipo == "VORONOI":
        tex.noise_scale = escala
    mod = obj.modifiers.new("Relieve", "DISPLACE")
    mod.texture = tex
    mod.strength = fuerza
    mod.mid_level = 0.5
    aplicar(obj)
    return obj


def pintar(obj, regla, capa="Color"):
    """regla(pos: Vector, normal: Vector) -> (r, g, b). Color por esquina."""
    mesh = obj.data
    attr = mesh.color_attributes.get(capa) or mesh.color_attributes.new(capa, "FLOAT_COLOR", "POINT")
    for i, v in enumerate(mesh.vertices):
        r, g, b = regla(v.co, v.normal)
        attr.data[i].color = (r, g, b, 1.0)
    mesh.color_attributes.active_color = attr
    return obj


def mezcla(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def cerca(pos, centro, radio, borde=0.6):
    """1 dentro de la esfera, 0 lejos; transición suave en el borde."""
    d = (Vector(pos) - Vector(centro)).length
    if d <= radio * borde:
        return 1.0
    if d >= radio:
        return 0.0
    t = (d - radio * borde) / (radio * (1 - borde))
    return 1 - t * t * (3 - 2 * t)


def ruido(pos, escala=6.0):
    return noise.noise(Vector(pos) * escala) * 0.5 + 0.5


# ---------------------------------------------------------------- materiales

def _nodos(nombre):
    mat = bpy.data.materials.get(nombre) or bpy.data.materials.new(nombre)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat, nt, bsdf


def mat_pelaje(nombre, capa="Color", rugosidad=0.85, bulto=0.45, escala_pelo=380.0, brillo_pelo=0.15,
               capa_brillo=None):
    """Pelaje: color por vértice, variación fina y relieve de pelo."""
    mat, nt, bsdf = _nodos(nombre)
    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = capa
    fino = nt.nodes.new("ShaderNodeTexNoise")
    fino.inputs["Scale"].default_value = escala_pelo
    fino.inputs["Detail"].default_value = 6
    hebra = nt.nodes.new("ShaderNodeTexWave")
    hebra.inputs["Scale"].default_value = escala_pelo * 0.35
    hebra.inputs["Distortion"].default_value = 12
    hebra.inputs["Detail"].default_value = 4
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 0.35
    nt.links.new(col.outputs["Color"], mix.inputs["A"])
    nt.links.new(fino.outputs["Color"], mix.inputs["B"])
    nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    suma = nt.nodes.new("ShaderNodeMath")
    suma.operation = "ADD"
    nt.links.new(fino.outputs["Fac"], suma.inputs[0])
    nt.links.new(hebra.outputs["Fac"], suma.inputs[1])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = bulto
    bump.inputs["Distance"].default_value = 0.01
    nt.links.new(suma.outputs["Value"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Roughness"].default_value = rugosidad
    bsdf.inputs["Sheen Weight"].default_value = brillo_pelo
    bsdf.inputs["Sheen Roughness"].default_value = 0.5
    nt.links.new(col.outputs["Color"], bsdf.inputs["Sheen Tint"])
    # Grietas que brillan (lava): segunda capa de color, si existe.
    if capa_brillo:
        brillo = nt.nodes.new("ShaderNodeVertexColor")
        brillo.layer_name = capa_brillo
        nt.links.new(brillo.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 6.0
    return mat


def mat_escamas(nombre, capa="Color", rugosidad=0.35, escala=55.0, bulto=0.5, capa_brillo=None, capa_brillo_fuerza=8.0):
    """Escamas: color por vértice, celdas de Voronoi en relieve y un poco de brillo."""
    mat, nt, bsdf = _nodos(nombre)
    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = capa
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.feature = "DISTANCE_TO_EDGE"
    vor.inputs["Scale"].default_value = escala
    borde = nt.nodes.new("ShaderNodeMapRange")
    borde.inputs["From Max"].default_value = 0.12
    nt.links.new(vor.outputs["Distance"], borde.inputs["Value"])
    oscuro = nt.nodes.new("ShaderNodeMix")
    oscuro.data_type = "RGBA"
    oscuro.blend_type = "MULTIPLY"
    nt.links.new(col.outputs["Color"], oscuro.inputs["A"])
    nt.links.new(borde.outputs["Result"], oscuro.inputs["B"])
    oscuro.inputs["Factor"].default_value = 0.45
    nt.links.new(oscuro.outputs["Result"], bsdf.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = bulto
    bump.inputs["Distance"].default_value = 0.02
    nt.links.new(borde.outputs["Result"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Roughness"].default_value = rugosidad
    bsdf.inputs["Coat Weight"].default_value = 0.3
    if capa_brillo:
        brillo = nt.nodes.new("ShaderNodeVertexColor")
        brillo.layer_name = capa_brillo
        nt.links.new(brillo.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = capa_brillo_fuerza
    return mat


def curva_puntos(control, n, radio):
    """Puntos a lo largo de una curva suave (Catmull-Rom) por los puntos de control.
    radio(t) da el grosor en cada tramo (t de 0 a 1)."""
    pts = []
    total = len(control) - 1
    for i in range(n):
        t = i / (n - 1)
        f = t * total
        k = min(int(f), total - 1)
        u = f - k
        p0 = Vector(control[max(k - 1, 0)])
        p1 = Vector(control[k])
        p2 = Vector(control[k + 1])
        p3 = Vector(control[min(k + 2, total)])
        q = 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u +
                   (-p0 + 3 * p1 - 3 * p2 + p3) * u * u * u)
        pts.append((q.x, q.y, q.z, radio(t)))
    return pts


def mat_cuerno(nombre, base=(0.75, 0.66, 0.5), punta=(0.18, 0.13, 0.1), anillos=40.0, eje="X"):
    """Cuerno/hueso: degradado hacia la punta oscura y anillos en relieve."""
    mat, nt, bsdf = _nodos(nombre)
    coord = nt.nodes.new("ShaderNodeTexCoord")
    onda = nt.nodes.new("ShaderNodeTexWave")
    onda.inputs["Scale"].default_value = anillos
    onda.inputs["Distortion"].default_value = 3
    onda.bands_direction = eje
    nt.links.new(coord.outputs["Object"], onda.inputs["Vector"])
    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = "Color"
    nt.links.new(col.outputs["Color"], bsdf.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.35
    nt.links.new(onda.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Roughness"].default_value = 0.45
    bsdf.inputs["Coat Weight"].default_value = 0.2
    return mat


def mat_simple(nombre, color, rugosidad=0.5, metal=0.0, emision=None, fuerza=0.0, rayones=0.0):
    mat, nt, bsdf = _nodos(nombre)
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = rugosidad
    bsdf.inputs["Metallic"].default_value = metal
    if rayones > 0:
        n = nt.nodes.new("ShaderNodeTexNoise")
        n.inputs["Scale"].default_value = 60
        n.inputs["Detail"].default_value = 10
        ramp = nt.nodes.new("ShaderNodeMapRange")
        ramp.inputs["To Min"].default_value = rugosidad - rayones
        ramp.inputs["To Max"].default_value = rugosidad + rayones
        nt.links.new(n.outputs["Fac"], ramp.inputs["Value"])
        nt.links.new(ramp.outputs["Result"], bsdf.inputs["Roughness"])
        bump = nt.nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.15
        nt.links.new(n.outputs["Fac"], bump.inputs["Height"])
        nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    if emision:
        bsdf.inputs["Emission Color"].default_value = (*emision, 1)
        bsdf.inputs["Emission Strength"].default_value = fuerza
    return mat


def asignar(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return obj


def triangulos(objs):
    total = 0
    deps = bpy.context.evaluated_depsgraph_get()
    for obj in objs:
        mesh = obj.evaluated_get(deps).to_mesh()
        total += sum(len(p.vertices) - 2 for p in mesh.polygons)
        obj.evaluated_get(deps).to_mesh_clear()
    return total
