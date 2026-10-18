r"""
Prueba de las juntas de las colas del Zorro de agua v2: dobla cada junta entre tramos (Cola<n>_2 a
Cola<n>_5) 45° alrededor de su pivote, en cadena como lo haría el rig (cada tramo suma el giro de
los anteriores), y mira si se abre una rendija.

Casos: hacia afuera y hacia adentro en el plano del abanico (eje y; espejado en las colas de la
derecha) y hacia atrás y adelante (eje perpendicular a la cola dentro del plano x-z).
Medida, por junta: la cara donde nace el tramo k está metida en el tramo k-1 (la parte que queda
adentro en reposo). Al doblar, la parte que sale de k-1 deja ver su cara de abajo y una V entre los
dos tramos: se informa qué fracción sale y cuánto se despega como máximo (celdas). Se cuenta como
rendija si se despega más de 1 celda (el umbral "junta" de docs/guia_crear_monstruo.md, 4).

Uso (desde la raíz del repo; el .blend lo deja minotauro_v2_bloques.py --criatura zorro --etapa 3):
    blender -b --factory-startup --python tools/blender/zorro_v2_prueba_colas.py
Salida: renders/zorro_v2_e3/prueba_colas/<caso>_<vista>.png y prueba_colas.json
"""
import bpy, json, math, os
from mathutils import Matrix, Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
CELDA = 0.5
ANGULO = math.radians(45)
# El estudio y la cámara de las vistas (sin correr su main) y las colas (tramos, sin construir).
exec(open(os.path.join(HERE, "zorro_v2_vistas.py"), encoding="utf-8").read().replace("\nmain()\n", "\n"))
exec(open(os.path.join(HERE, "zorro_v2_e3_colas.py"), encoding="utf-8").read())
SALIDA = os.path.join(RAIZ, "renders", "zorro_v2_e3", "prueba_colas")
CASOS = ("afuera", "adentro", "atras", "adelante")


def colas_izq_der():
    """[(nombre, lado, tramos)] de las seis colas, en celdas (las de la derecha espejadas en x)."""
    salida = []
    for izq, der, raiz, y_raiz, paso_y, hondo, lista in COLAS_ABANICO:
        t = tramos(raiz, y_raiz, paso_y, hondo, lista)
        salida.append((izq, 1, t))
        salida.append((der, -1, [([(-x, z) for x, z in pol], y, (-p[0], p[1], p[2]), (-q[0], q[1], q[2]), d, b)
                                 for pol, y, p, q, d, b in t]))
    return salida


def giro(caso, lado, direccion, pivote):
    """Matriz (en celdas) que dobla un tramo 45° alrededor de su pivote (la dirección es la del
    tramo, en la cola izquierda)."""
    d = V((lado * direccion[0], 0, direccion[1])).normalized()
    if caso in ("afuera", "adentro"):
        eje, a = V((0, 1, 0)), lado * ANGULO * (1 if caso == "afuera" else -1)
    else:  # d x y: con ángulo positivo la punta va hacia +y (atrás)
        eje, a = d.cross(V((0, 1, 0))).normalized(), ANGULO * (1 if caso == "atras" else -1)
    p = V(pivote)
    return Matrix.Translation(p) @ Matrix.Rotation(a, 4, eje) @ Matrix.Translation(-p)


def dentro(pol, y, q, margen=1e-6):
    """Cuánto queda q (celdas) fuera del prisma convexo (polígono x-z, y): <= 0 es adentro."""
    peor = max(y[0] - q.y, q.y - y[1])
    area = sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pol, pol[1:] + pol[:1]))
    s = 1 if area > 0 else -1
    for a, b in zip(pol, pol[1:] + pol[:1]):
        ex, ez = b[0] - a[0], b[1] - a[1]
        largo = math.hypot(ex, ez)
        peor = max(peor, -s * (ex * (q.z - a[1]) - ez * (q.x - a[0])) / largo)
    return peor - margen


def medir(caso, cola):
    nombre, lado, t = cola
    juntas = []
    for k in range(1, 5):
        pol_ant, y_ant = t[k - 1][0], t[k - 1][1]
        pol, y, piv, _, direccion, _ = t[k]
        m = giro(caso, lado, direccion, (piv[0], piv[1], piv[2]))
        a, b = pol[0], pol[1]  # el borde donde nace
        adentro = afuera = 0
        despegue = 0.0
        for i in range(21):
            for j in range(31):
                u, w = i / 20, j / 30
                q = V((a[0] + (b[0] - a[0]) * u, y[0] + (y[1] - y[0]) * w, a[1] + (b[1] - a[1]) * u))
                if dentro(pol_ant, y_ant, q) > 0:
                    continue  # en reposo ya se ve (el tramo es más ancho o va más atrás)
                adentro += 1
                h = dentro(pol_ant, y_ant, m @ q)
                if h > 0:
                    afuera += 1
                    despegue = max(despegue, h)
        juntas.append({"junta": f"{nombre}_{k}>{k + 1}", "sale": round(afuera / max(adentro, 1), 2),
                       "despegue_celdas": round(despegue, 2)})
    return juntas


def doblar(caso, colas):
    for nombre, lado, t in colas:
        total = Matrix.Identity(4)
        for k, (_, _, piv, _, direccion, _) in enumerate(t):
            if k > 0:
                total = total @ giro(caso, lado, direccion, piv)
            o = bpy.data.objects[f"{nombre}_{k + 1}"]
            escala = Matrix.Scale(CELDA, 4)
            o.matrix_world = escala @ total @ escala.inverted()


def main():
    bpy.ops.wm.open_mainfile(filepath=BLEND)
    os.makedirs(SALIDA, exist_ok=True)
    colas = colas_izq_der()
    informe = {}
    for caso in CASOS:
        juntas = [j for c in colas for j in medir(caso, c)]
        peor = max(juntas, key=lambda j: j["despegue_celdas"])
        informe[caso] = {"rendijas": [j for j in juntas if j["despegue_celdas"] > 1.0], "peor": peor,
                         "juntas": juntas}
        print("PRUEBA", caso, "peor", peor, "rendijas", len(informe[caso]["rendijas"]))
    with open(os.path.join(SALIDA, "prueba_colas.json"), "w", encoding="utf-8") as f:
        json.dump(informe, f, indent=2, ensure_ascii=False)
    # Renders: cada caso desde atrás y en tres cuartos desde atrás.
    lo, hi = caja()
    sc, cam, sol, piso = estudio(lo, hi)
    sc.cycles.samples = 24
    piso.hide_render = True  # cuatro juntas a 45° enroscan la cola media vuelta: baja del piso
    for caso in CASOS:
        doblar(caso, colas)
        bpy.context.view_layer.update()
        lo, hi = caja()
        centro, tam = (lo + hi) / 2, hi - lo
        for vista, angulo, elev in (("atras", 180, 10), ("tres_cuartos", 145, 25), ("perfil", 90, 0)):
            a, e = math.radians(angulo), math.radians(elev)
            d = V((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e)))
            cam.data.type, cam.data.ortho_scale = "ORTHO", max(tam) * 1.15
            mirar(cam, centro + d * tam.length * 2, centro)
            sol.rotation_euler = (math.radians(50), 0, a + math.radians(-35))
            sc.render.filepath = os.path.join(SALIDA, f"{caso}_{vista}.png")
            bpy.ops.render.render(write_still=True)


main()
