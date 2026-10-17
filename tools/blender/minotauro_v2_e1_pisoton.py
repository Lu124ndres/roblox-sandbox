r"""
Pisotón y caminata del Minotauro v2 E1 contra el faldón (opción a, aprobada el 2026-10-16):
FaldonFrente tiene hueso propio con la bisagra en el borde de adelante del cinturón y se
levanta lo justo para que el muslo no lo atraviese.

Mueve las piezas rígidas como lo haría el rig (Muslo > Pierna > Pie y los brazos desde el
hombro), busca con choques BVH (piernas contra las tres piezas del faldón) cuánto tiene que
levantarse el faldón y renderiza:
    pisoton_57.png      el pisotón del juego (Minotauro/Trucos.luau: muslo 1.0 rad, rodilla
                        1.2 rad, brazos abiertos 0.5 rad)
    pisoton_perfil.png  el mismo de perfil, cerca de la cadera y sin el brazo derecho (lo tapa)
    caminata.png        el momento de la caminata (Minotauro/Pose.luau, Pose.walk) que más pide
                        levantar el faldón
También mide la pose extrema de la guía (muslo y rodilla a 90°), la curva del faldón según el
muslo del pisotón (de 40° a 70°) y, para comparar, el cinturón en su lugar anterior
(ADELANTE = 0). No guarda el .blend.

Uso (desde la raíz del repo, después de minotauro_v2_e1_bloques.py):
    blender -b --factory-startup --python tools/blender/minotauro_v2_e1_pisoton.py
"""
import bpy, json, math, os
from mathutils import Matrix, Vector as V
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
_src = open(os.path.join(HERE, "minotauro_v2_e1_bloques.py"), encoding="utf-8").read()
exec(_src[:_src.index("objetos = armar()")], globals())  # armar(), estudio(), CELDA, ADELANTE
SALIDA = os.path.join(RAIZ, "renders", "minotauro_v2_e1")
APROBADO = ADELANTE

C = CELDA
CADERA = V((3, 0, 10)) * C  # muslo izquierdo (x = +3 celdas); el derecho, espejado
RODILLA = V((3, 0, 6)) * C
HOMBRO = V((8, -0.5, 17)) * C  # borde de adentro de la tapa de la hombrera
BISAGRA = V((0, -5, 10)) * C  # sin ADELANTE: borde de adelante y arriba de las tiras
JUEGO = (math.degrees(1.0), math.degrees(1.2))  # pisotón del juego: muslo y rodilla
EXTREMO = (90.0, 90.0)
ABRIR = math.degrees(0.5)
PIERNAS = [p + l for p in ("Muslo", "Pierna", "Pie") for l in ("Izq", "Der")]
FALDON = ["FaldonFrente", "FaldonIzq", "FaldonDer"]
BRAZOS = [p + l for p in ("Brazo", "Antebrazo", "Mano") for l in ("Izq", "Der")]
ob = bpy.data.objects


def giro(pivote, grados, eje="X"):
    """Giro por el pivote. En x, negativo = la punta va hacia adelante (-y)."""
    return Matrix.Translation(pivote) @ Matrix.Rotation(math.radians(grados), 4, eje) @ Matrix.Translation(-pivote)


def lado(p, s):
    return V((p.x * s, p.y, p.z))


def posar(piernas, faldon, abrir=0.0, brazos=(0.0, 0.0)):
    """piernas: {"Izq": (muslo, rodilla), "Der": ...} en grados (muslo + = adelante, rodilla +
    = la pierna va atrás); brazos: cabeceo izquierdo y derecho (+ = adelante)."""
    for s, l, cabeceo in ((1, "Izq", brazos[0]), (-1, "Der", brazos[1])):
        muslo, rodilla = piernas.get(l, (0.0, 0.0))
        m = giro(lado(CADERA, s), -muslo)
        ob["Muslo" + l].matrix_world = m
        ob["Pierna" + l].matrix_world = ob["Pie" + l].matrix_world = m @ giro(lado(RODILLA, s), rodilla)
        h = lado(HOMBRO, s)
        b = giro(h, -cabeceo) @ giro(h, -abrir * s, "Y")
        for pieza in ("Brazo", "Antebrazo", "Mano"):
            ob[pieza + l].matrix_world = b
    ob["FaldonFrente"].matrix_world = giro(BISAGRA - V((0, ADELANTE * C, 0)), -faldon)


def arbol(o):
    m = o.matrix_world
    return BVHTree.FromPolygons([m @ v.co for v in o.data.vertices], [p.vertices[:] for p in o.data.polygons])


def chocan():
    return any(arbol(ob[a]).overlap(arbol(ob[b])) for a in PIERNAS for b in FALDON)


def faldon_minimo(piernas, **brazos):
    """El menor levantamiento del faldón (de 1 en 1 grado) sin choque; None si no hay."""
    for f in range(0, 181):
        posar(piernas, f, **brazos)
        if not chocan():
            return f
    return None


def pisoton(muslo, rodilla):
    return {"Der": (muslo, rodilla)}


def caminata(fase):
    """Pose.walk: legL = 0.55 sen, legR = -0.55 sen, rodillas 0.75 max(0, ±cos), brazos ∓0.45 sen."""
    s, c = math.sin(fase), math.cos(fase)
    g = math.degrees
    piernas = {"Izq": (g(0.55 * s), g(0.75 * max(0, c))), "Der": (g(-0.55 * s), g(0.75 * max(0, -c)))}
    return piernas, (g(-0.45 * s), g(0.45 * s))


def medir_caminata():
    peor = (0, 0)
    for grados in range(0, 360, 5):
        piernas, brazos = caminata(math.radians(grados))
        f = faldon_minimo(piernas, brazos=brazos)
        if f is None:
            return {"faldon_maximo": None, "fase": grados}
        peor = max(peor, (f, grados))
    return {"faldon_maximo": peor[0], "fase": peor[1]}


def medir(adelante):
    global ADELANTE
    ADELANTE = adelante
    PARTES.clear()
    armar()
    posar({}, 0)
    return {
        "reposo_sin_choque": not chocan(),
        "pisoton_57": faldon_minimo(pisoton(*JUEGO), abrir=ABRIR),
        "extremo_90": faldon_minimo(pisoton(*EXTREMO), abrir=ABRIR),
        "caminata": medir_caminata(),
    }


def curva_muslo():
    """Faldón mínimo según el muslo del pisotón (rodilla en la proporción del juego), de 40° a
    70° cada medio grado. No baja con el muslo: tiene su pico en 52° (por eso no se bajó el
    pisotón a 55°, ver docs/decisiones.md)."""
    k = JUEGO[1] / JUEGO[0]
    return {f"{m / 2:g}": faldon_minimo(pisoton(m / 2, m / 2 * k), abrir=ABRIR) for m in range(80, 141)}


def render(nombre, sc, cam, sol, angulo=-60, alto=4.0, centro=V((0, 0, 1.45))):
    """angulo: desde dónde mira la cámara alrededor del eje z (-60 = derecha del personaje, la
    pierna que pisa, y adelante; -90 = perfil derecho)."""
    a = math.radians(angulo)
    cam.location = centro + V((math.sin(a) * 10, -math.cos(a) * 10, alto))
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    sol.rotation_euler = (math.radians(50), 0, a + math.radians(-35))
    sc.render.filepath = os.path.join(SALIDA, nombre)
    bpy.ops.render.render(write_still=True)


def render_perfil(nombre, sc, cam, sol):
    """Perfil derecho cerca de la cadera, sin el brazo derecho (tapa el muslo)."""
    brazo = [ob[p + "Der"] for p in ("Brazo", "Antebrazo", "Mano")]
    escala = cam.data.ortho_scale
    for o in brazo:
        o.hide_render = True
    cam.data.ortho_scale = 1.6
    render(nombre, sc, cam, sol, angulo=-90, alto=0.3, centro=V((0, -0.3, 0.85)))
    cam.data.ortho_scale = escala
    for o in brazo:
        o.hide_render = False


datos = {"grados_levantado_del_faldon": "None = no hay ángulo sin choque",
         "pisoton_juego_muslo_rodilla": [round(x, 1) for x in JUEGO],
         "cinturon_anterior_adelante_0": medir(0)}
datos[f"aprobado_adelante_{APROBADO}"] = d = medir(APROBADO)  # deja armado el aprobado
d["curva_muslo_faldon"] = curva_muslo()

sc, cam, sol = estudio()
posar(pisoton(*JUEGO), d["pisoton_57"], abrir=ABRIR)
render("pisoton_57.png", sc, cam, sol)
render_perfil("pisoton_perfil.png", sc, cam, sol)
piernas, brazos = caminata(math.radians(d["caminata"]["fase"]))
posar(piernas, d["caminata"]["faldon_maximo"], brazos=brazos)
render("caminata.png", sc, cam, sol)
with open(os.path.join(SALIDA, "pisoton.json"), "w", encoding="utf-8") as f:
    json.dump(datos, f, indent=2, ensure_ascii=False)
print("PISOTON", json.dumps(datos, ensure_ascii=False))
