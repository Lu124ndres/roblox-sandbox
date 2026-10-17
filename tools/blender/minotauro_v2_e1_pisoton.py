r"""
Pose de pisotón del Minotauro v2 E1 para comparar dos opciones del faldón:
    a) FaldonFrente con hueso propio (bisagra en el borde de adelante del cinturón): se
       levanta solo lo justo para que el muslo no lo atraviese.
    b) Faldón rígido en Cadera (sin huesos nuevos): el muslo sube hasta el límite sin choque.
Mide las dos con el modelo aprobado (ADELANTE = 0) y con la propuesta de cinturón y faldón
1 celda más adelante (ADELANTE = 1); los renders son de la propuesta. No guarda el .blend.
Mueve las piezas rígidas como lo haría el rig (Muslo > Pierna > Pie), busca los ángulos sin
choque (BVH entre la pierna derecha y el faldón) y renderiza cada opción. El pisotón del
juego (Minotauro/Trucos.luau) sube el muslo 1.0 rad y dobla la rodilla 1.2 rad; la guía pide
revisar además la pierna a 90°.

Uso (desde la raíz del repo, después de minotauro_v2_e1_bloques.py):
    blender -b --factory-startup --python tools/blender/minotauro_v2_e1_pisoton.py
"""
import bpy, json, math, os
from mathutils import Matrix, Vector as V
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
_src = open(os.path.join(HERE, "minotauro_v2_e1_bloques.py"), encoding="utf-8").read()
exec(_src[:_src.index("objetos = armar()")], globals())  # armar(), estudio(), CELDA
SALIDA = os.path.join(RAIZ, "renders", "minotauro_v2_e1")

C = CELDA
CADERA = V((-3, 0, 10)) * C  # muslo derecho: centro en x = -3 celdas, arriba en el cinturón
RODILLA = V((-3, 0, 6)) * C
HOMBRO = V((10.5, 0, 17.5)) * C  # brazo izquierdo; el derecho, espejado
ABRIR = math.degrees(0.5)  # el pisotón del juego abre los brazos (outL/outR = 0.5 rad)
BISAGRA = V((0, -5, 10)) * C  # borde de adelante y arriba de las tiras (se corre con ADELANTE)
JUEGO = (math.degrees(1.0), math.degrees(1.2))  # muslo y rodilla del pisotón del juego
EXTREMO = (90.0, 90.0)  # pose extrema de la guía
PIERNA = ["MusloDer", "PiernaDer", "PieDer"]
FALDON = ["FaldonFrente", "FaldonDer"]
ob = bpy.data.objects


def giro(pivote, grados):
    """Cabeceo alrededor del eje x por el pivote (negativo = la punta va hacia adelante)."""
    return Matrix.Translation(pivote) @ Matrix.Rotation(math.radians(grados), 4, "X") @ Matrix.Translation(-pivote)


def posar(muslo, rodilla, faldon):
    for o in ob:
        if o.type == "MESH" and o.name in PARTES_POSABLES:
            o.matrix_world = Matrix.Identity(4)
    for s, lado in ((1, "Izq"), (-1, "Der")):
        h = V((HOMBRO.x * s, HOMBRO.y, HOMBRO.z))
        m = Matrix.Translation(h) @ Matrix.Rotation(math.radians(-ABRIR * s), 4, "Y") @ Matrix.Translation(-h)
        for pieza in ("Brazo", "Antebrazo", "Mano"):
            ob[pieza + lado].matrix_world = m
    m = giro(CADERA, -muslo)
    ob["MusloDer"].matrix_world = m
    ob["PiernaDer"].matrix_world = ob["PieDer"].matrix_world = m @ giro(RODILLA, rodilla)
    ob["FaldonFrente"].matrix_world = giro(BISAGRA - V((0, ADELANTE * C, 0)), -faldon)


def arbol(o):
    m = o.matrix_world
    return BVHTree.FromPolygons([m @ v.co for v in o.data.vertices], [p.vertices[:] for p in o.data.polygons])


def chocan():
    return any(arbol(ob[a]).overlap(arbol(ob[b])) for a in PIERNA for b in FALDON)


def faldon_minimo(muslo, rodilla):
    """Opción a: el menor levantamiento del faldón (de 1 en 1 grado) sin choque."""
    for f in range(0, 181):
        posar(muslo, rodilla, f)
        if not chocan():
            return f
    return None


def muslo_maximo():
    """Opción b: el mayor cabeceo del muslo (rodilla en la proporción del juego) sin choque."""
    ultimo = 0.0
    for d in range(0, 91):
        posar(d, d * JUEGO[1] / JUEGO[0], 0)
        if chocan():
            return ultimo
        ultimo = float(d)
    return ultimo


def render(nombre, sc, cam, sol):
    centro = V((0, 0, 1.45))
    a = math.radians(-60)  # desde la derecha del personaje (la pierna que pisa) y desde arriba
    cam.location = centro + V((math.sin(a) * 10, -math.cos(a) * 10, 4.0))
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    sol.rotation_euler = (math.radians(50), 0, a + math.radians(-35))
    sc.render.filepath = os.path.join(SALIDA, nombre)
    bpy.ops.render.render(write_still=True)


def medir(adelante):
    global ADELANTE
    ADELANTE = adelante
    PARTES.clear()
    armar()
    posar(0, 0, 0)
    d = {"reposo_sin_choque": not chocan()}
    d["a_faldon_juego"] = faldon_minimo(*JUEGO)
    d["a_faldon_extremo"] = faldon_minimo(*EXTREMO)
    d["b_muslo_maximo"] = muslo_maximo()
    return d


PARTES_POSABLES = set(PIERNA + FALDON) | {p + l for p in ("Brazo", "Antebrazo", "Mano") for l in ("Izq", "Der")}
datos = {"juego_muslo_rodilla": [round(x, 1) for x in JUEGO], "modelo_aprobado": medir(0)}
datos["propuesta_adelante_1"] = d = medir(1)  # deja armada la propuesta para los renders

sc, cam, sol = estudio()
posar(*JUEGO, d["a_faldon_juego"])
render("pisoton_a.png", sc, cam, sol)
b = d["b_muslo_maximo"]
posar(b, b * JUEGO[1] / JUEGO[0], 0)
render("pisoton_b.png", sc, cam, sol)
posar(*JUEGO, 0)
render("pisoton_b_choque.png", sc, cam, sol)
with open(os.path.join(SALIDA, "pisoton.json"), "w", encoding="utf-8") as f:
    json.dump(datos, f, indent=2, ensure_ascii=False)
print("PISOTON", json.dumps(datos))
