"""Efectos del previo de la cutscene (intro_previo.py), por código y con partículas de Blender:
brasas que flotan en toda la cueva (su color lo cambia intro_luz.py con el tono del plano),
bruma en la cueva, y en cada gigante su estallido: agua al salir y al caer la orca, polvo en el
rugido del minotauro, fuego por la boca del dragón y esquirlas de hielo en el aullido del zorro.
En el juego cada uno es un ParticleEmitter; acá sirven para ver el ritmo y el color."""
import bmesh, bpy, math

import intro_planos as IP

NIVEL_AGUA = 2.0  # WorldLayoutData.waterLevel


def bl(p):
    return (p[0], -p[2], p[1])


def material(nombre, color, emision, alfa=1.0):
    m = bpy.data.materials.new(nombre)
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Emission Color"].default_value = (*color, 1)
    b.inputs["Emission Strength"].default_value = emision
    b.inputs["Alpha"].default_value = alfa
    return m


def _cubito(nombre, mat):
    malla = bpy.data.meshes.new(nombre)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bm.to_mesh(malla)
    bm.free()
    malla.materials.append(mat)
    o = bpy.data.objects.new(nombre, malla)
    bpy.context.scene.collection.objects.link(o)
    o.location = (0, 0, -5000)  # la plantilla queda lejos, bajo el mar
    return o


def _disco(nombre, centro, radio):
    malla = bpy.data.meshes.new(nombre)
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=True, segments=24, radius=radio)
    bm.to_mesh(malla)
    bm.free()
    o = bpy.data.objects.new(nombre, malla)
    bpy.context.scene.collection.objects.link(o)
    o.location = centro
    return o


def emisor(o, plantilla, cuadros, cantidad, vida, velocidad, azar, gravedad, tam, giro=True):
    """Partículas que salen de las caras de `o` (hacia su normal) con copias de `plantilla`."""
    o.modifiers.new("Particulas", "PARTICLE_SYSTEM")
    s = o.particle_systems[-1].settings
    s.count, s.lifetime, s.lifetime_random = cantidad, vida, 0.4
    s.frame_start, s.frame_end = cuadros
    s.emit_from = "FACE"
    s.normal_factor, s.factor_random = velocidad, azar
    s.effector_weights.gravity = gravedad
    s.render_type, s.instance_object = "OBJECT", plantilla
    s.particle_size, s.size_random = tam, 0.6
    s.use_rotations, s.rotation_factor_random = giro, 1.0
    s.angular_velocity_mode, s.angular_velocity_factor = "RAND", 6.0
    o.show_instancer_for_render = False
    return s


def brasas(total):
    """Brasas en toda la cueva, desde antes del primer cuadro (ya está llena al empezar)."""
    mat = material("Brasa", (1.0, 0.45, 0.1), 4.0)  # con más brillo se queman a blanco
    plantilla = _cubito("BrasaPlantilla", mat)
    disco = _disco("Brasas", bl(IP.C(0, NIVEL_AGUA + 1, 0)), 230)
    s = emisor(disco, plantilla, (-300, total), 3000, 300, 4.0, 3.0, 0.0, 0.3)
    s.brownian_factor = 2.5
    return mat


def bruma():
    """Bruma de la cueva: un volumen con el color de la luna del plano (no tapa el mar)."""
    malla = bpy.data.meshes.new("Bruma")
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bm.to_mesh(malla)
    bm.free()
    o = bpy.data.objects.new("Bruma", malla)
    bpy.context.scene.collection.objects.link(o)
    o.location, o.scale = bl(IP.C(0, 70, 0)), (520, 520, 200)
    m = bpy.data.materials.new("Bruma")
    nodos = m.node_tree.nodes
    nodos.remove(nodos["Principled BSDF"])
    vol = nodos.new("ShaderNodeVolumePrincipled")
    vol.inputs["Density"].default_value = 0.0008
    m.node_tree.links.new(vol.outputs[0], nodos["Material Output"].inputs["Volume"])
    malla.materials.append(m)


def estallido(nombre, centro, radio, cuadro, cantidad, velocidad, gravedad, vida, tam, color, emision):
    plantilla = _cubito(nombre + "Plantilla", material(nombre, color, emision))
    emisor(_disco(nombre, bl(centro), radio), plantilla, (cuadro, cuadro + 3), cantidad, vida,
           velocidad, velocidad * 0.5, gravedad, tam)


def fuego(rig, cuadros):
    """Llamarada que sale de la boca del dragón (emisor colgado del hueso Boca)."""
    plantilla = _cubito("FuegoPlantilla", material("Fuego", (1.0, 0.5, 0.1), 25.0))
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=3.0)
    malla = bpy.data.meshes.new("Llamarada")
    bm.to_mesh(malla)
    bm.free()
    o = bpy.data.objects.new("Llamarada", malla)
    bpy.context.scene.collection.objects.link(o)
    o.parent, o.parent_type, o.parent_bone = rig, "BONE", "Boca"
    s = emisor(o, plantilla, cuadros, 1500, 24, 6.0, 4.0, -0.3, 4.0)
    s.object_align_factor = (0, 45, 0)  # a lo largo del hueso: hacia adelante de la boca


def efectos(gigantes, fps):
    """Pone el estallido de cada gigante en su momento del plano."""
    t0 = 0.0
    for p in IP.PLANOS:
        f0 = round(t0 * fps) + 1
        en = lambda t: f0 + round(t * fps)  # noqa: E731
        if "salto" in p:
            a, _, c = p["salto"]
            for nombre, t, n in (("Sale", a + 0.15, 700), ("Cae", c - 0.1, 1100)):
                estallido("Agua" + nombre, IP.C(0, NIVEL_AGUA, 0), 55, en(t), n, 75, 3.0, 70, 1.4,
                          (0.75, 0.9, 1.0), 1.5)
        if p["gigante"] == "Minotauro":
            estallido("Polvo", IP.C(0, NIVEL_AGUA, 0), 60, en(0.5), 600, 30, 0.4, 55, 1.2,
                      (0.6, 0.3, 0.12), 0.6)
        if p["gigante"] == "DragonMarino":
            rig = next(o for o in gigantes["DragonMarino"][1] if o.type == "ARMATURE")
            fuego(rig, (en(1.0), en(2.1)))
        if p["gigante"] == "ZorroDeAgua":
            estallido("Hielo", IP.C(0, NIVEL_AGUA, 0), 70, en(0.8), 700, 45, 2.0, 60, 1.6,
                      (0.7, 0.95, 1.0), 4.0)
        t0 += p["segundos"]
