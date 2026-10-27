"""Luz y línea de tiempo del previo de la cutscene (intro_previo.py): un tono de color por plano,
como una intro de jefe (todo de un color, contraste y bruma), que tiñe la luna (toda la escena,
la bruma incluida), la clave y el borde (solo los gigantes), el cielo y las brasas. También
muestra cada gigante en su plano y pone los relámpagos. Cuadros clave por código, constantes
salvo los del amanecer."""
import bpy

import intro_planos as IP

# luna: color y fuerza (tiñe la cueva y la bruma); clave: fuerza y color (de frente, solo los
# gigantes); borde: color (desde atrás, solo los gigantes); cielo; brasa: color de las brasas.
TONOS = {
    "noche": dict(luna=((0.55, 0.65, 1.0), 0.12), clave=(0.0, (1, 1, 1)), borde=(0.35, 0.5, 1.0),
                  cielo=(0.002, 0.004, 0.012), brasa=(0.5, 0.65, 1.0)),
    "orca": dict(luna=((0.15, 0.4, 1.0), 0.7), clave=(6.0, (0.75, 0.88, 1.0)), borde=(0.25, 0.7, 1.0),
                 cielo=(0.001, 0.005, 0.02), brasa=(0.45, 0.8, 1.0)),
    "minotauro": dict(luna=((1.0, 0.35, 0.08), 0.9), clave=(6.0, (1.0, 0.62, 0.3)), borde=(1.0, 0.6, 0.15),
                      cielo=(0.02, 0.006, 0.001), brasa=(1.0, 0.45, 0.1)),
    "dragon": dict(luna=((1.0, 0.12, 0.03), 0.9), clave=(8.0, (1.0, 0.45, 0.25)), borde=(1.0, 0.3, 0.05),
                   cielo=(0.025, 0.003, 0.001), brasa=(1.0, 0.28, 0.05)),
    "zorro": dict(luna=((0.2, 0.85, 1.0), 0.8), clave=(5.0, (0.8, 0.95, 1.0)), borde=(0.6, 1.0, 1.0),
                  cielo=(0.002, 0.012, 0.02), brasa=(0.7, 0.95, 1.0)),
    "amanecer": dict(luna=((0.15, 0.4, 1.0), 0.7), clave=(6.0, (1.0, 0.85, 0.7)), borde=(1.0, 0.7, 0.45),
                     cielo=(0.001, 0.005, 0.02), brasa=(1.0, 0.6, 0.3)),
}
DIA = dict(luna=((1.0, 0.85, 0.65), 3.5), cielo=(0.32, 0.5, 0.8))  # adonde llega el amanecer
SUAVES = set()  # (nombre del dato, ruta, cuadro) de los cuadros clave que no son constantes
CIELO = 'nodes["Background"].inputs[0].default_value'
EMISION = 'nodes["Principled BSDF"].inputs["Emission Color"].default_value'


def clave(dato, ruta, cuadro, valor, suave=False):
    obj, _, prop = ruta.rpartition(".")
    destino = dato.path_resolve(obj) if obj else dato
    setattr(destino, prop, valor)
    dato.keyframe_insert(ruta, frame=cuadro)
    if suave:
        SUAVES.add((dato.name, ruta, cuadro))


def curvas(dato):
    ad = dato.animation_data
    if not ad or not ad.action:
        return []
    salida = list(getattr(ad.action, "fcurves", None) or [])
    for capa in getattr(ad.action, "layers", []):
        for tira in capa.strips:
            for canal in tira.channelbags:
                salida += list(canal.fcurves)
    return salida


def interpolaciones(datos, modo=None):
    for dato in datos:
        for fc in curvas(dato):
            for k in fc.keyframe_points:
                suave = (dato.name, fc.data_path, round(k.co.x)) in SUAVES
                k.interpolation = modo or ("BEZIER" if suave else "CONSTANT")


def _tono(luces, brasa, cuadro, tono, suave=False):
    luna, frente, borde, _ = luces
    t = TONOS[tono]
    clave(luna.data, "color", cuadro, t["luna"][0], suave)
    clave(luna.data, "energy", cuadro, t["luna"][1], suave)
    clave(frente.data, "energy", cuadro, t["clave"][0])
    clave(frente.data, "color", cuadro, t["clave"][1])
    clave(borde.data, "color", cuadro, t["borde"])
    clave(borde.data, "energy", cuadro, 2.0 if tono == "amanecer" else 9.0)
    clave(bpy.context.scene.world.node_tree, CIELO, cuadro, (*t["cielo"], 1), suave)
    clave(brasa.node_tree, EMISION, cuadro, (*t["brasa"], 1))


def linea_de_tiempo(gigantes, luces, brasa, fps):
    """Tono, gigante visible y relámpagos de cada plano. luces: (luna, clave, borde, rayo)."""
    luna, frente, borde, rayo = luces
    mundo = bpy.context.scene.world.node_tree
    animados = [luna.data, frente.data, borde.data, rayo.data, mundo, brasa.node_tree]
    for _, partes in gigantes.values():
        animados += partes
    t0 = 0.0
    for plano in IP.PLANOS:
        f0 = round(t0 * fps) + 1
        _tono(luces, brasa, f0, plano["tono"])
        for nombre, (_, partes) in gigantes.items():
            for o in partes:
                clave(o, "hide_render", f0, plano["gigante"] != nombre)
        if "adentro" in plano:  # cruza la puerta del túnel: el tono de la cueva
            t, tono = plano["adentro"]
            _tono(luces, brasa, f0 + round(t * fps), tono)
        if "amanece" in plano:  # al salir por el arco se hace de día
            f1 = f0 + round(plano["amanece"] * fps)
            fin = f0 + round(plano["segundos"] * fps)
            _tono(luces, brasa, f1, plano["tono"], suave=True)
            clave(luna.data, "color", fin, DIA["luna"][0])
            clave(luna.data, "energy", fin, DIA["luna"][1])
            clave(mundo, CIELO, fin, (*DIA["cielo"], 1))
        clave(rayo.data, "energy", f0, 0.0)
        for r in plano["relampagos"]:
            fr = f0 + round(r * fps)
            for d, e in ((0, 14.0), (2, 0.0), (4, 9.0), (7, 0.0)):
                clave(rayo.data, "energy", fr + d, e)
        t0 += plano["segundos"]
    interpolaciones(animados)
