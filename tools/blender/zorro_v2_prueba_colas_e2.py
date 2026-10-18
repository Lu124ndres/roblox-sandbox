r"""
Prueba de las juntas de las colas del Zorro de agua v2, etapa 2 (joven): la de
zorro_v2_prueba_colas.py (E3) para las tres colas de la E2 (zorro_v2_e2_colas.py, colas_locales),
con la celda de 0.3 y la central simétrica. Cada cola se mide en sus coordenadas (u, r, z) (u hacia
afuera, r a lo largo de la extrusión; también acepta colas en el plano y-z) y se gira en las del
zorro.

Dobla cada junta entre tramos (Cola<n>_2 a Cola<n>_5) 45° alrededor de su pivote, en cadena como
lo haría el rig (cada tramo suma el giro de los anteriores). Casos:
    afuera / adentro    en el plano de la cola: la punta hacia +u (afuera; en la central, hacia
                        +x) o al revés;
    atras / adelante    fuera del plano: la punta hacia +y o -y.
Medida, por junta: la cara donde nace el tramo k está metida en el tramo k-1 (la parte que queda
adentro en reposo). Al doblar se informa qué fracción sale y cuánto se despega como máximo
(celdas). Es rendija si se despega más de 1 celda (umbral "junta" de docs/guia_crear_monstruo.md, 4).

Uso (desde la raíz del repo; el .blend lo deja minotauro_v2_bloques.py --criatura zorro --etapa 2):
    blender -b --factory-startup --python tools/blender/zorro_v2_prueba_colas_e2.py -- --etapa 2
Salida: renders/zorro_v2_e2/prueba_colas/<caso>_<vista>.png y prueba_colas.json
"""
import bpy, json, math, os
from mathutils import Matrix, Vector as V

HERE = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(HERE, "..", ".."))
CELDA = 0.3
ANGULO = math.radians(45)
# El estudio y la cámara de las vistas (sin correr su main) y las colas (sin construir).
exec(open(os.path.join(HERE, "zorro_v2_vistas.py"), encoding="utf-8").read().replace("\nmain()\n", "\n"))
exec(open(os.path.join(HERE, "zorro_v2_e2_colas.py"), encoding="utf-8").read())
SALIDA = os.path.join(RAIZ, "renders", "zorro_v2_e2", "prueba_colas")
CASOS = ("afuera", "adentro", "atras", "adelante")
Z = V((0, 0, 1))


def ejes(eje, lado):
    """Los ejes u y r de una cola en las coordenadas del zorro (lado 0: la central, hacia +x)."""
    return (V((0, 1, 0)), V((1, 0, 0))) if eje == "x" else (V((lado or 1, 0, 0)), V((0, 1, 0)))


def a_zorro(eje, lado, p):
    u, r = ejes(eje, lado)
    return u * p[0] + r * p[1] + Z * p[2]


def a_cola(eje, lado, q):
    u, r = ejes(eje, lado)
    return V((q.dot(u), q.dot(r), q.z))


def giro(caso, eje, lado, direccion, pivote):
    """Matriz (en celdas, coordenadas del zorro) que dobla un tramo 45° alrededor de su pivote."""
    u, r = ejes(eje, lado)
    d = (u * direccion[0] + Z * direccion[1]).normalized()
    if caso in ("afuera", "adentro"):  # Z x u lleva z hacia u: la punta hacia +u
        k, a = Z.cross(u), ANGULO * (1 if caso == "afuera" else -1)
    else:  # d x r lleva d hacia r: la punta hacia +r
        k, a = d.cross(r).normalized(), ANGULO * (1 if caso == "atras" else -1)
    p = a_zorro(eje, lado, pivote)
    return Matrix.Translation(p) @ Matrix.Rotation(a, 4, k) @ Matrix.Translation(-p)


def dentro(pol, rango, q, margen=1e-6):
    """Cuánto queda q (celdas, (u, r, z)) fuera del prisma convexo (polígono u-z, rango en r)."""
    peor = max(rango[0] - q.y, q.y - rango[1])
    area = sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pol, pol[1:] + pol[:1]))
    s = 1 if area > 0 else -1
    for a, b in zip(pol, pol[1:] + pol[:1]):
        eu, ez = b[0] - a[0], b[1] - a[1]
        peor = max(peor, -s * (eu * (q.z - a[1]) - ez * (q.x - a[0])) / math.hypot(eu, ez))
    return peor - margen


def medir(caso, cola):
    nombre, eje, lado, t = cola
    juntas = []
    for k in range(1, 5):
        pol_ant, r_ant = t[k - 1][0], t[k - 1][1]
        pol, rango, piv, _, direccion, _ = t[k]
        m = giro(caso, eje, lado, direccion, piv)
        a, b = pol[0], pol[1]  # el borde donde nace
        adentro = afuera = 0
        despegue = 0.0
        for i in range(21):
            for j in range(31):
                f, w = i / 20, j / 30
                q = V((a[0] + (b[0] - a[0]) * f, rango[0] + (rango[1] - rango[0]) * w, a[1] + (b[1] - a[1]) * f))
                if dentro(pol_ant, r_ant, q) > 0:
                    continue  # en reposo ya se ve (el tramo es más ancho o va más atrás)
                adentro += 1
                h = dentro(pol_ant, r_ant, a_cola(eje, lado, m @ a_zorro(eje, lado, q)))
                if h > 0:
                    afuera += 1
                    despegue = max(despegue, h)
        juntas.append({"junta": f"{nombre}_{k}>{k + 1}", "sale": round(afuera / max(adentro, 1), 2),
                       "despegue_celdas": round(despegue, 2)})
    return juntas


def doblar(caso, colas):
    escala = Matrix.Scale(CELDA, 4)
    for nombre, eje, lado, t in colas:
        total = Matrix.Identity(4)
        for k, (_, _, piv, _, direccion, _) in enumerate(t):
            if k > 0:
                total = total @ giro(caso, eje, lado, direccion, piv)
            bpy.data.objects[f"{nombre}_{k + 1}"].matrix_world = escala @ total @ escala.inverted()


def main():
    bpy.ops.wm.open_mainfile(filepath=BLEND)
    os.makedirs(SALIDA, exist_ok=True)
    colas = colas_locales()
    informe = {}
    for caso in CASOS:
        juntas = [j for c in colas for j in medir(caso, c)]
        peor = max(juntas, key=lambda j: j["despegue_celdas"])
        informe[caso] = {"rendijas": [j for j in juntas if j["despegue_celdas"] > 1.0], "peor": peor,
                         "juntas": juntas}
        print("PRUEBA", caso, "peor", peor, "rendijas", len(informe[caso]["rendijas"]))
    with open(os.path.join(SALIDA, "prueba_colas.json"), "w", encoding="utf-8") as f:
        json.dump(informe, f, indent=2, ensure_ascii=False)
    # Renders: cada caso desde atrás, en tres cuartos desde atrás y de perfil.
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
