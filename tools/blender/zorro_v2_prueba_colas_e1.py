r"""
Prueba de las juntas de la cola del Zorro de agua v2, etapa 1 (cría): la copia de
zorro_v2_prueba_colas.py para la cola única de la cría, que está en el plano y-z y se extruye en x
(zorro_v2_e1_colas.py). Dobla cada junta entre tramos (Cola1_2 a Cola1_5) 45° alrededor de su
pivote, en cadena como lo haría el rig (cada tramo suma el giro de los anteriores), y mira si se
abre una rendija.

Casos: hacia adelante y hacia atrás en el plano de la cola (eje x) y hacia la izquierda y la
derecha (eje perpendicular a la cola dentro del plano y-z: la cola se menea de lado).
Medida, por junta: la cara donde nace el tramo k está metida en el tramo k-1 (la parte que queda
adentro en reposo). Al doblar, la parte que sale de k-1 deja ver su cara de abajo y una V entre los
dos tramos: se informa qué fracción sale y cuánto se despega como máximo (celdas). Se cuenta como
rendija si se despega más de 1 celda (el umbral "junta" de docs/guia_crear_monstruo.md, 4).

Uso (desde la raíz del repo; el .blend lo deja minotauro_v2_bloques.py --criatura zorro --etapa 1):
    blender -b --factory-startup --python tools/blender/zorro_v2_prueba_colas_e1.py
Salida: renders/zorro_v2_e1/prueba_colas/<caso>_<vista>.png y prueba_colas.json
"""
import bpy, json, math, os, sys
from mathutils import Matrix, Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
CELDA = 0.1
ANGULO = math.radians(45)
# El estudio y la cámara de las vistas (sin correr su main, en la E1) y la cola (tramos, sin construir).
sys.argv += ["--", "--etapa", "1"] if "--" not in sys.argv else ["--etapa", "1"]
exec(open(os.path.join(HERE, "zorro_v2_vistas.py"), encoding="utf-8").read().replace("\nmain()\n", "\n"))
exec(open(os.path.join(HERE, "zorro_v2_e1_colas.py"), encoding="utf-8").read())
SALIDA = os.path.join(RAIZ, "renders", "zorro_v2_e1", "prueba_colas")
CASOS = ("adelante", "atras", "izquierda", "derecha")


def giro(caso, direccion, pivote):
    """Matriz (en celdas) que dobla un tramo 45° alrededor de su pivote. Sobre +x, el ángulo
    positivo lleva la punta hacia -y (adelante); sobre d × x, hacia +x (la izquierda del zorro)."""
    d = V((0, direccion[0], direccion[1])).normalized()
    if caso in ("adelante", "atras"):
        eje, a = V((1, 0, 0)), ANGULO * (1 if caso == "adelante" else -1)
    else:
        eje, a = d.cross(V((1, 0, 0))).normalized(), ANGULO * (1 if caso == "izquierda" else -1)
    p = V(pivote)
    return Matrix.Translation(p) @ Matrix.Rotation(a, 4, eje) @ Matrix.Translation(-p)


def dentro(pol, x, q, margen=1e-6):
    """Cuánto queda q (celdas) fuera del prisma convexo (polígono y-z, x): <= 0 es adentro."""
    peor = max(x[0] - q.x, q.x - x[1])
    area = sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pol, pol[1:] + pol[:1]))
    s = 1 if area > 0 else -1
    for a, b in zip(pol, pol[1:] + pol[:1]):
        ey, ez = b[0] - a[0], b[1] - a[1]
        largo = math.hypot(ey, ez)
        peor = max(peor, -s * (ey * (q.z - a[1]) - ez * (q.y - a[0])) / largo)
    return peor - margen


def medir(caso, t):
    juntas = []
    for k in range(1, 5):
        pol_ant, x_ant = t[k - 1][0], t[k - 1][1]
        pol, x, piv, _, direccion, _ = t[k]
        m = giro(caso, direccion, piv)
        a, b = pol[0], pol[1]  # el borde donde nace
        adentro = afuera = 0
        despegue = 0.0
        for i in range(21):
            for j in range(31):
                u, w = i / 20, j / 30
                q = V((x[0] + (x[1] - x[0]) * w, a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u))
                if dentro(pol_ant, x_ant, q) > 0:
                    continue  # en reposo ya se ve (el tramo es más ancho o más grueso)
                adentro += 1
                h = dentro(pol_ant, x_ant, m @ q)
                if h > 0:
                    afuera += 1
                    despegue = max(despegue, h)
        juntas.append({"junta": f"Cola1_{k}>{k + 1}", "sale": round(afuera / max(adentro, 1), 2),
                       "despegue_celdas": round(despegue, 2)})
    return juntas


def doblar(caso, t):
    total = Matrix.Identity(4)
    escala = Matrix.Scale(CELDA, 4)
    for k, (_, _, piv, _, direccion, _) in enumerate(t):
        if k > 0:
            total = total @ giro(caso, direccion, piv)
        bpy.data.objects[f"Cola1_{k + 1}"].matrix_world = escala @ total @ escala.inverted()


def main():
    bpy.ops.wm.open_mainfile(filepath=BLEND)
    os.makedirs(SALIDA, exist_ok=True)
    t = tramos()
    informe = {}
    for caso in CASOS:
        juntas = medir(caso, t)
        peor = max(juntas, key=lambda j: j["despegue_celdas"])
        informe[caso] = {"rendijas": [j for j in juntas if j["despegue_celdas"] > 1.0], "peor": peor,
                         "juntas": juntas}
        print("PRUEBA", caso, "peor", peor, "rendijas", len(informe[caso]["rendijas"]))
    with open(os.path.join(SALIDA, "prueba_colas.json"), "w", encoding="utf-8") as f:
        json.dump(informe, f, indent=2, ensure_ascii=False)
    # Renders: cada caso de perfil, desde atrás y en tres cuartos desde atrás.
    lo, hi = caja()
    sc, cam, sol, piso = estudio(lo, hi)
    sc.cycles.samples = 24
    piso.hide_render = True  # cuatro juntas a 45° enroscan la cola: puede bajar del piso
    for caso in CASOS:
        doblar(caso, t)
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
