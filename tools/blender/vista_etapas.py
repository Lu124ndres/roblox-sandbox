"""Render de las 4 etapas de un monstruo lado a lado (para revisar el diseño).
vista_etapas(construir, alto, ruta, voxel)
Cada etapa se pone a la derecha de la anterior según su caja real y la cámara
(ortográfica, de frente con un poco de ángulo) encuadra a las cuatro."""

from mathutils import Vector


def _caja(objs):
    bpy.context.view_layer.update()
    puntos = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    minimo = Vector((min(p.x for p in puntos), min(p.y for p in puntos), min(p.z for p in puntos)))
    maximo = Vector((max(p.x for p in puntos), max(p.y for p in puntos), max(p.z for p in puntos)))
    return minimo, maximo


def vista_etapas(construir, alto, ruta, voxel=0.03, separacion=None, angulo=8):
    limpiar_escena()
    escalas = {1: 0.5, 2: 0.68, 3: 0.84, 4: 1.0}
    hueco = separacion or alto * 0.12
    todos = []
    cursor = 0.0
    for etapa in (1, 2, 3, 4):
        objs = construir(etapa, voxel=voxel)
        for o in objs:
            o.location = o.location * escalas[etapa]
            o.scale = o.scale * escalas[etapa]
        minimo, maximo = _caja(objs)
        for o in objs:
            o.location.x += cursor - minimo.x
            o.location.z -= minimo.z  # todos parados en el suelo
        cursor += (maximo.x - minimo.x) + hueco
        todos += objs
    minimo, maximo = _caja(todos)
    centro = (minimo + maximo) / 2
    for o in todos:
        o.location.x -= centro.x
    ancho, altura = maximo.x - minimo.x, maximo.z - minimo.z
    estudio(altura, distancia=altura * 4.0, angulo=angulo)
    cam = bpy.context.scene.camera
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = max(ancho, altura * 2.0) * 1.08
    cam.location.z = altura * 0.5
    cam.rotation_euler = (Vector((0, 0, altura * 0.5)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    renderizar(ruta, 1600, 800, 24)
