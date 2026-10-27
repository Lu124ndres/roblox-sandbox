"""Piezas de la escena del previo de la cutscene (intro_previo.py): gigantes E4 traídos de sus
rigs v2, luces de noche (luna, clave y borde sobre los gigantes, relámpago) y un muñeco
en la playa del novato. Ejes: Blender (x, y, z) = Roblox (x, -z, y)."""
import bmesh, bpy, math, os
from mathutils import Vector as V

import intro_planos as IP

ALTO_E4 = 19.5 * 5.5  # Config.Giants: stageHeightsInPlayers[4] x playerHeightStuds
NIVEL_AGUA = 2.0  # WorldLayoutData.waterLevel
# carpeta del rig, alto (el dragón se mide a lo largo: vuela) y giro para mirar a -Z de Roblox
# (los rigs miran a -Y de Blender = +Z de Roblox: hay que darlos vuelta).
RIGS = {
    "Orca": ("orca_v2", ALTO_E4, 180),
    "Minotauro": ("minotauro_v2", ALTO_E4, 180),
    "DragonMarino": ("dragon_v2", ALTO_E4 * 1.6, 180),
    "ZorroDeAgua": ("zorro_v2", ALTO_E4, 180),
}


def bl(p):
    return V((p[0], -p[2], p[1]))


def _traer_rig(raiz, carpeta):
    ruta = os.path.join(raiz, "assets", "blender", carpeta, "e4_rig.blend")
    with bpy.data.libraries.load(ruta) as (origen, destino):
        destino.objects = list(origen.objects)
    rig = next(o for o in destino.objects if o and o.type == "ARMATURE")
    partes = [o for o in destino.objects if o and (o is rig or o.parent is rig)]
    for o in partes:
        bpy.context.scene.collection.objects.link(o)
    return rig, partes


def gigante(raiz, nombre):
    """Ancla vacía en el centro del cráter con el rig adentro, escalado al alto del juego."""
    carpeta, alto, giro = RIGS[nombre]
    rig, partes = _traer_rig(raiz, carpeta)
    bpy.context.view_layer.update()
    puntos = [m.matrix_world @ V(c) for m in partes if m.type == "MESH" for c in m.bound_box]
    if nombre == "DragonMarino":
        medida = max(max(p.x for p in puntos) - min(p.x for p in puntos),
                      max(p.y for p in puntos) - min(p.y for p in puntos))
    else:
        medida = max(p.z for p in puntos) - min(p.z for p in puntos)
    ancla = bpy.data.objects.new("Gigante_" + nombre, None)
    bpy.context.scene.collection.objects.link(ancla)
    rig.parent = ancla
    ancla.location = bl(IP.C(0, NIVEL_AGUA, 0))
    ancla.rotation_euler = (0, 0, math.radians(giro))
    ancla.scale = (alto / medida,) * 3
    return ancla, partes


def _sol(nombre, color, direccion):
    o = bpy.data.objects.get(nombre)
    if not o:
        o = bpy.data.objects.new(nombre, bpy.data.lights.new(nombre, "SUN"))
        bpy.context.scene.collection.objects.link(o)
    o.data.color = color
    o.data.use_shadow = False  # el cráter es una cueva: sin sombra, la luz entra igual
    o.rotation_euler = V(direccion).to_track_quat("-Z", "Y").to_euler()
    return o


def luces(gigantes):
    """Luna (del lado de la cámara: los gigantes la miran), relámpago y, solo sobre los gigantes
    (light linking: la cueva sigue oscura), la clave de frente y el borde desde atrás."""
    luna = _sol("Sol", (0.6, 0.7, 1.0), (-0.3, -0.8, -0.55))  # hacia -Y: de frente al gigante
    clave = _sol("Clave", (0.85, 0.9, 1.0), (-0.35, -0.8, -0.45))
    borde = _sol("Borde", (1, 1, 1), (0.3, 1.0, -0.55))
    rayo = _sol("Relampago", (0.75, 0.82, 1.0), (-0.3, 0.5, -0.8))
    coleccion = bpy.data.collections.new("Gigantes")
    for _, partes in gigantes.values():
        for o in partes:
            if o.type == "MESH":
                coleccion.objects.link(o)
    for luz in (clave, borde):
        luz.light_linking.receiver_collection = coleccion
    return luna, clave, borde, rayo


def jugador():
    m = bpy.data.materials.new("Jugador")
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.9, 0.5, 0.2, 1)
    x, y, z = IP.JUGADOR
    for nombre, alto, tam in (("Piernas", -1.5, (2, 1, 2)), ("Torso", 0.5, (2, 1, 2)), ("Cabeza", 2.1, (1.2, 1.2, 1.2))):
        o = bpy.data.objects.new("Jugador" + nombre, bpy.data.meshes.new("Jugador" + nombre))
        bpy.context.scene.collection.objects.link(o)
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        bm.to_mesh(o.data)
        bm.free()
        o.location, o.scale = bl((x, y + alto, z)), tam
        o.data.materials.append(m)
