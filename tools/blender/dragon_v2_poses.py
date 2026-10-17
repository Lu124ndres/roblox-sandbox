r"""
Poses extremas del Dragón marino v2, cualquier etapa (docs/plan_dragon_v2.md): posa las piezas
rígidas con la misma cuenta que el juego y revisa que no se separen ni se crucen.

La cuenta es la de src/shared/Dragon:
    Rig.bind    ejes del CUERPO medidos en los huesos: adelante (de Cadera a Cabeza), derecha
                (de AlaIzq1 a AlaDer1) y arriba; el lado de cada hueso y `neutral`, cuánto
                bajar cada ala para que quede en planeo (diedro de 0.1 rad).
    Rig.turn    cabeceo por la derecha, giro por arriba y alabeo por adelante, en ese orden.
    Pose.apply  alas (aletazo con látigo, plegado en picada, timón en las curvas), pecho, cadera,
                cola (onda y curva), cuello y cabeza, mandíbula y patas (colgando al quedarse
                quieto). Los resortes se toman ya asentados (su objetivo).
medir() y revisar() son las de minotauro_v2_poses.py (este archivo la carga hasta armar()):
    atraviesa  dos piezas sin articulación entre ellas que se meten una en otra más de PENETRA
               celdas más que en planeo (ala en el cuerpo, ala con ala, cola en una pata)
    junta      una pieza y su padre que se solapan más de JUNTA celdas más que en planeo
    hueco      una pieza que se separa de su padre más de HUECO celdas
Además barre una vuelta entera del aleteo al máximo del juego (AMPLITUD x 1.7: comiendo y
enojado) y anota lo peor de cada fase. Renderiza cada pose en renders/dragon_v2_e<n>/poses/ y
guarda poses.json. No guarda el .blend.

Uso (desde la raíz del repo; sin --etapa, la 1):
    blender -b --factory-startup --python tools/blender/dragon_v2_poses.py -- --etapa 1
"""
import bpy, json, math, os

CRIATURA = "dragon"
HERE = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(HERE, "minotauro_v2_poses.py"), encoding="utf-8").read()
exec(_src[:_src.index("\narmar()\n")], globals())  # bloques del dragón, HUESOS, medir(), revisar()

# Dragon/Etapas: amplitud del aleteo (rad) por etapa. El máximo del juego: comiendo y enojado
# (x 1.7); el rugido enojado llega a x 2.24 (se revisa aparte).
AMPLITUD = {1: 0.8, 2: 0.72, 3: 0.66, 4: 0.58}[ETAPA]
AMP_MAX = AMPLITUD * 1.7
AMP_RUGIDO = AMPLITUD * 1.6 * 1.4
DIEDRO = 0.1  # Dragon/Rig: al planear, las alas apenas arriba de la horizontal (rad)
FASES = 24  # muestras de una vuelta del aleteo


# --- Dragon/Rig.bind ---------------------------------------------------------------------
def _junta(n):
    return HUESOS[n][1]


ORIGEN = V(PUNTOS["Raiz"][1]) * C
ADELANTE = (_junta("Cabeza") - _junta("Cadera")).normalized()
DERECHA = (_junta("AlaDer1") - _junta("AlaIzq1")).normalized()
ARRIBA = DERECHA.cross(ADELANTE).normalized()
DERECHA = ADELANTE.cross(ARRIBA).normalized()
LADO = {}
for _n, (_, _p) in HUESOS.items():
    _d = (_p - ORIGEN).dot(DERECHA)
    LADO[_n] = 0 if abs(_d) < 1e-4 else math.copysign(1, _d)
NEUTRAL = {}
for _s in ("Izq", "Der"):
    _span = _junta(f"Ala{_s}3") - _junta(f"Ala{_s}1")
    NEUTRAL[_s] = math.asin(max(-1.0, min(1.0, _span.normalized().dot(ARRIBA)))) - DIEDRO


# --- Dragon/Pose.apply -------------------------------------------------------------------
def _golpe(fase):
    """Bajada rápida, subida lenta (stroke de Pose.luau)."""
    return math.sin(fase + 0.38 * math.sin(fase))


def locales(e):
    """Hueso -> (cabeceo, giro, alabeo) para la entrada `e` de Pose.apply (phase, amp, fold, turn,
    climb, jaw, headPitch, headYaw, hover, now). `huesos` reemplaza el giro de algunos huesos
    (poses de la guía que el juego no pide). Sin entrada, el reposo del modelo (todo en 0): el
    planeo del juego es {"amp": 0} (baja el ala `neutral` y la cola hace su onda)."""
    if not e:
        return {}
    g = lambda k: e.get(k, 0.0)
    fase, amp, fold = g("phase"), g("amp"), g("fold")
    abajo = _golpe(fase)
    subiendo = max(0.0, -math.cos(fase))
    turn = max(-1.5, min(1.5, g("turn")))
    r = {}
    for s in ("Izq", "Der"):
        lado = LADO[f"Ala{s}1"] or (1 if s == "Der" else -1)
        base = NEUTRAL[s] + amp * abajo - fold * 0.25
        r[f"Ala{s}1"] = (0, -lado * fold * 0.5, lado * (base + lado * turn * 0.06))
        lag2 = amp * 0.42 * _golpe(fase - 0.75) + 0.22 * amp * subiendo + fold * 0.9
        r[f"Ala{s}2"] = (0, -lado * (0.3 * amp * subiendo + fold * 0.6), lado * lag2)
        lag3 = amp * 0.34 * _golpe(fase - 1.4) + 0.15 * amp * subiendo + fold * 0.7
        r[f"Ala{s}3"] = (0, -lado * fold * 0.5, lado * lag3)
    r["Pecho"] = (0.05 * amp * math.sin(fase + math.pi), 0, 0)
    r["Cadera"] = (-0.04 * g("climb"), 0, 0)
    for i in range(1, 7):
        onda = 0.09 * math.sin(g("now") * 1.6 - i * 0.7) * (0.5 + i * 0.16)
        curva = turn * 0.07 * i ** 0.7
        caida = -g("climb") * 0.05 * i / 6
        r[f"Cola{i}"] = (caida + 0.035 * amp * math.sin(fase - i * 0.55), onda + curva, 0)
    contra = -0.07 * amp * math.sin(fase + 0.6)
    mira, cabecea = g("headYaw") - turn * 0.12, g("headPitch")
    r["Cuello1"] = (cabecea * 0.35 + contra, mira * 0.35, 0)
    r["Cuello2"] = (cabecea * 0.3 + contra * 0.6, mira * 0.3, 0)
    r["Cabeza"] = (cabecea * 0.35 - contra * 0.4, mira * 0.35, 0)
    r["Mandibula"] = (-0.75 * g("jaw"), 0, 0)
    quieto, cuelga = g("hover"), 0.06 * math.sin(fase - 1)
    for s in ("Izq", "Der"):
        r[f"Brazo{s}"] = (0.9 * quieto + cuelga, 0, 0)
        r[f"Antebrazo{s}"] = (-0.4 * quieto + cuelga * 0.5, 0, 0)
        r[f"Muslo{s}"] = (1.1 * quieto + cuelga * 0.7, 0, 0)
        r[f"Pierna{s}"] = (-0.3 * quieto, 0, 0)
    r.update(e.get("huesos", {}))
    return r


def giros(p, faldon=0.0):
    """Rig.turn en los ejes del cuerpo: hueso -> matriz de giro (sin trasladar). `faldon` no se
    usa (es del minotauro: matrices() y posar() lo pasan)."""
    rot = locales(p)
    r = {}
    for nombre in HUESOS:
        a, g, b = rot.get(nombre, (0, 0, 0))
        r[nombre] = (Matrix.Rotation(a, 4, DERECHA) @ Matrix.Rotation(g, 4, ARRIBA)
                     @ Matrix.Rotation(b, 4, ADELANTE))
    return r


def fase_extrema(signo):
    """Fase del aleteo con el ala más abajo (signo 1) o más arriba (-1)."""
    return max((2 * math.pi * i / 360 for i in range(360)), key=lambda f: signo * _golpe(f))


def _lados(huesos, valor):
    return {f"{h}{l}": valor for h in huesos for l in ("Izq", "Der")}


ABAJO, ARRIBA_F = fase_extrema(1), fase_extrema(-1)
COLA = [f"Cola{i}" for i in range(1, 7)]
POSES = {  # nombre -> (entrada de Pose.apply, ángulo de la cámara, altura de la cámara)
    # Guía (docs/plan_dragon_v2.md): extremos de cada parte.
    "planeo": ({"amp": 0.0}, 35, 0.35),
    "aletazo_abajo_max": ({"amp": AMP_MAX, "phase": ABAJO}, 0, 0.1),
    "aletazo_arriba_max": ({"amp": AMP_MAX, "phase": ARRIBA_F}, 0, 0.1),
    "aletazo_abajo_rugido": ({"amp": AMP_RUGIDO, "phase": ABAJO}, 0, 0.1),
    "aletazo_arriba_rugido": ({"amp": AMP_RUGIDO, "phase": ARRIBA_F}, 0, 0.1),
    "alas_plegadas_picada": ({"fold": 1, "amp": AMPLITUD * 0.15, "climb": -1}, 35, 0.6),
    "cola_enroscada": ({"huesos": {h: (0, 0.6, 0) for h in COLA}}, 0, 8),
    "cola_en_s": ({"huesos": {h: (0, v, 0) for h, v in zip(COLA, (0.45, 0.45, 0.45, -0.6, -0.6, -0.6))}}, 0, 8),
    "cola_arriba": ({"huesos": {h: (0.25, 0, 0) for h in COLA}}, 90, 0),
    "cola_abajo": ({"huesos": {h: (-0.25, 0, 0) for h in COLA}}, 90, 0),
    "cuello_izq_30": ({"headYaw": math.radians(30)}, 0, 8),
    "cuello_izq_60": ({"headYaw": math.radians(60)}, 0, 8),
    "cuello_der_60": ({"headYaw": -math.radians(60)}, 0, 8),
    "cuello_arriba_45": ({"headPitch": math.radians(45)}, 90, 0),
    "cuello_abajo_45": ({"headPitch": -math.radians(45)}, 90, 0),
    "boca_max": ({"jaw": 1}, 60, 0.1),
    "patas_colgando": ({"hover": 1}, 90, 0),
    "patas_apoyadas": ({"huesos": _lados(["Brazo"], (1.1, 0, 0)) | _lados(["Antebrazo"], (-0.3, 0, 0))
                        | _lados(["Muslo"], (1.3, 0, 0)) | _lados(["Pierna"], (-0.4, 0, 0))
                        | _lados(["Pie"], (0.3, 0, 0))}, 90, 0),
    "patas_recogidas_aleteo": ({"amp": AMPLITUD, "phase": ABAJO}, 90, 0),
    # Picos de los trucos del juego (Dragon/Trucos, con su pose en 1) y de comer.
    "truco_rugido": ({"amp": AMPLITUD * 1.6, "phase": ABAJO, "hover": 1, "headPitch": 0.45,
                      "jaw": 1}, 35, 0.2),
    "truco_fuego": ({"amp": AMPLITUD * 0.3, "headPitch": -0.45, "jaw": 1}, 60, 0.2),
    "truco_voltereta": ({"amp": AMPLITUD * 0.4, "fold": 0.35, "phase": ARRIBA_F}, 35, 0.35),
    "comer": ({"amp": AMPLITUD * 1.3, "phase": ABAJO, "hover": 1, "jaw": 1, "headPitch": -0.15},
              35, 0.2),
    "curva_cerrada": ({"amp": AMPLITUD, "turn": 1.5, "now": 1.0}, 0, 8),
}


def render_pose(nombre, sc, cam, sol, angulo, alto, carpeta=None):
    centro, k = ENCUADRE
    a = G(angulo)
    cam.location = centro + V((math.sin(a) * 10, -math.cos(a) * 10, alto * 10)) * k
    cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
    sol.rotation_euler = (G(50), 0, a + G(-35))
    sc.render.filepath = os.path.join(carpeta or SALIDA, nombre + ".png")
    bpy.ops.render.render(write_still=True)


def resumen(atraviesa, juntas, sueltas):
    return {"atraviesa": atraviesa, "junta": juntas, "hueco": sueltas}


def barrido(reposo):
    """Una vuelta del aleteo al máximo del juego: lo peor de cada fase."""
    peor = {}
    for i in range(FASES):
        f = 2 * math.pi * i / FASES
        posar({"amp": AMP_MAX, "phase": f})
        atraviesa, juntas, sueltas = revisar(reposo)
        if atraviesa or juntas or sueltas:
            peor[f"{f:.2f}"] = resumen(atraviesa, juntas, sueltas)
    return peor


# === PRINCIPAL (rig_dragon_v2.py carga este archivo hasta aquí) ===
armar()
os.makedirs(SALIDA, exist_ok=True)
posar({})
ENCUADRE = encuadre()
# Se compara contra el planeo del juego: en el reposo exacto las cuñas de la cola solo tocan las
# caras del segmento anterior y el BVH no cuenta ese cruce (aparecería en todas las poses).
posar(POSES["planeo"][0])
reposo = medir()
datos = {
    "umbral_celdas": {"atraviesa": PENETRA, "junta": JUNTA, "hueco": HUECO},
    "rig": {"adelante": [round(x, 4) for x in ADELANTE], "derecha": [round(x, 4) for x in DERECHA],
            "arriba": [round(x, 4) for x in ARRIBA],
            "neutral_rad": {s: round(v, 4) for s, v in NEUTRAL.items()},
            "diedro_modelado_rad": {s: round(v + DIEDRO, 4) for s, v in NEUTRAL.items()}},
    "amplitud": {"etapa": AMPLITUD, "maxima": round(AMP_MAX, 3), "rugido_enojado": round(AMP_RUGIDO, 3)},
    "planeo": {"cruces": {f"{a}/{b}": round(d, 2) for (a, b), d in sorted(reposo[0].items())},
               "huecos": {h: round(d, 2) for h, d in reposo[1].items() if d > 0}},
    "poses": {},
}
datos["aleteo_maximo_por_fase"] = barrido(reposo)
sc, cam, sol = estudio(ENCUADRE[1] * 3.1)
sc.cycles.samples = 24
for nombre, (entrada, angulo, alto) in POSES.items():
    posar(entrada)
    datos["poses"][nombre] = resumen(*revisar(reposo))
    bpy.data.objects["Plane"].hide_render = alto < 0
    render_pose(nombre, sc, cam, sol, angulo, alto)
with open(os.path.join(SALIDA, "poses.json"), "w", encoding="utf-8", newline="\n") as fh:
    json.dump(datos, fh, indent=2, ensure_ascii=False)
print("POSES", json.dumps({n: [len(d[k]) for k in ("atraviesa", "junta", "hueco")]
                           for n, d in datos["poses"].items()}))
print("BARRIDO", json.dumps({f: [len(d[k]) for k in ("atraviesa", "junta", "hueco")]
                             for f, d in datos["aleteo_maximo_por_fase"].items()}))
