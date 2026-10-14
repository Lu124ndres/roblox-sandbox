"""Exporta en cola los monstruos que falten, uno por uno, sin congelar Blender
(cada uno en su propio temporizador). Escribe assets/blender/render/log_<Nombre>.json
y cola.json con el avance. Uso (desde la consola o el MCP):
    exec(open(".../exportar_todos.py").read()); exportar_cola([("Minotauro", 2), ...])
"""
import json
import os
import time

PROYECTO = r"C:\Users\luisa\Desktop\JuegoRoblox"
BASE = os.path.join(PROYECTO, "tools", "blender")
CONSTRUCTORES = {
    "Minotauro": ("minotauro.py", "construir_minotauro", 0.016),
    "DragonMarino": ("dragon.py", "construir_dragon", 0.02),
    "ZorroDeAgua": ("zorro.py", "construir_zorro", 0.016),
}


def _cargar(*archivos):
    g = globals()
    for f in ("criaturas.py", "exportar.py") + archivos:
        exec(open(os.path.join(BASE, f), encoding="utf-8").read(), g)


def exportar_cola(trabajos):
    render = os.path.join(PROYECTO, "assets", "blender", "render")
    pendientes = list(trabajos)
    hechos = []

    def paso():
        if not pendientes:
            return None
        base, etapa = pendientes.pop(0)
        archivo, funcion, voxel = CONSTRUCTORES[base]
        nombre = f"{base}E{etapa}"
        try:
            _cargar(archivo)
            limpiar_escena()
            t0 = time.time()
            objs = globals()[funcion](etapa, voxel=voxel)
            t1 = time.time()
            info = exportar_monstruo(nombre, objs, PROYECTO)
            info.update(build=round(t1 - t0), export=round(time.time() - t1))
        except Exception:
            import traceback
            info = {"error": traceback.format_exc()}
        with open(os.path.join(render, f"log_{nombre}.json"), "w") as f:
            json.dump(info, f)
        hechos.append(nombre)
        with open(os.path.join(render, "cola.json"), "w") as f:
            json.dump({"hechos": hechos, "faltan": [f"{b}E{e}" for b, e in pendientes]}, f)
        return 1.0 if pendientes else None

    bpy.app.timers.register(paso, first_interval=0.5)
