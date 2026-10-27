"""Previo (animatic) de la cutscene de entrada: el mapa de bloques de noche, los gigantes E4 en
el centro del cráter de a uno por plano y la cámara de intro_camara.py. Sirve para aprobar
encuadres y ritmo antes de pasarlo al juego. Los gigantes se animan con intro_animacion.py (en
el juego los mueve su rutina), la luz va en intro_luz.py y las partículas en intro_efectos.py.
Sin keyframes a mano: los cuadros clave los ponen estos scripts.

Uso (desde la raíz del repo; mapa_completo.blend sale de mapa_bloques_render.py):
  blender -b <mapa_completo.blend> --python tools/blender/intro_previo.py -- <raiz_repo> <carpeta_cuadros> [prueba]
  prueba: un cuadro a mitad de cada plano, en chico, para revisar encuadres.
Las barras de cine, el acabado de imagen y los carteles se ponen al armar el video
(intro_video.py)."""
import bpy, math, os, sys

ARGS = sys.argv[sys.argv.index("--") + 1:]
RAIZ, SALIDA = ARGS[:2]
PRUEBA = len(ARGS) > 2 and ARGS[2] == "prueba"
sys.path.insert(0, os.path.join(RAIZ, "tools", "blender"))
import intro_animacion as A  # noqa: E402
import intro_camara as CAM  # noqa: E402
import intro_efectos as FX  # noqa: E402
import intro_escena as E  # noqa: E402
import intro_luz as L  # noqa: E402
import intro_planos as IP  # noqa: E402

FPS = IP.MUESTRAS_POR_SEGUNDO


def camara(sc):
    cam = sc.camera
    cam.data.sensor_fit, cam.data.sensor_height = "VERTICAL", 24
    cam.data.clip_start, cam.data.clip_end = 0.5, 6000
    cuadro, t0 = 1, 0.0
    for plano in IP.PLANOS:
        for i in range(round(plano["segundos"] * FPS)):
            pos, mira, fov = CAM.camara_en(plano, i / FPS)
            cam.location = E.bl(pos)
            cam.rotation_euler = (E.bl(mira) - E.bl(pos)).to_track_quat("-Z", "Y").to_euler()
            cam.data.lens = 12 / math.tan(math.radians(fov) / 2)
            cam.keyframe_insert("location", frame=cuadro)
            cam.keyframe_insert("rotation_euler", frame=cuadro)
            cam.data.keyframe_insert("lens", frame=cuadro)
            cuadro += 1
        t0 += plano["segundos"]
    L.interpolaciones((cam, cam.data), "LINEAR")
    return cam, cuadro - 1


def render(sc, total):
    motores = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in motores else "BLENDER_EEVEE"
    sc.eevee.taa_render_samples = 8
    sc.eevee.shadow_pool_size = "1024"  # el mapa tiene muchas luces de lava
    sc.eevee.volumetric_start, sc.eevee.volumetric_end = 1, 1500  # la bruma de la cueva
    sc.render.fps = FPS
    sc.render.resolution_x, sc.render.resolution_y = (800, 450) if PRUEBA else (960, 540)
    sc.render.image_settings.file_format = "PNG"
    sc.frame_start, sc.frame_end = 1, total
    os.makedirs(SALIDA, exist_ok=True)
    if PRUEBA:
        t0 = 0.0
        for plano in IP.PLANOS:
            partes = (0.1, 0.3, 0.5, 0.65, 0.78, 0.9) if plano["segundos"] > 4 else (0.2, 0.8)
            for parte in partes:
                sc.frame_set(round((t0 + plano["segundos"] * parte) * FPS) + 1)
                vistos = [o.name for o in sc.objects if o.type == "MESH" and "E4" in o.name and not o.hide_render]
                print("VISIBLES", plano["nombre"], parte, vistos)
                sc.render.filepath = os.path.join(SALIDA, f"{plano['nombre']}_{int(parte * 100)}.png")
                bpy.ops.render.render(write_still=True)
            t0 += plano["segundos"]
        return
    sc.render.filepath = os.path.join(SALIDA, "")
    bpy.ops.render.render(animation=True)


def main():
    sc = bpy.context.scene
    gigantes = {nombre: E.gigante(RAIZ, nombre) for nombre in E.RIGS}
    gigantes["DragonMarino"][0].location.z += next(p["vuela"] for p in IP.PLANOS if "vuela" in p)
    luces = E.luces(gigantes)
    E.jugador()
    cam, total = camara(sc)
    FX.bruma()
    brasa = FX.brasas(total)
    L.linea_de_tiempo(gigantes, luces, brasa, FPS)
    A.animar(gigantes, FPS)  # después: sus cuadros clave no pasan a constantes
    FX.efectos(gigantes, FPS)
    render(sc, total)
    if not PRUEBA:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SALIDA, "intro_previo.blend"))


main()
