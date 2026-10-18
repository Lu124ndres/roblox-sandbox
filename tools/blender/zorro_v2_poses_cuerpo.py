r"""
Poses del cuerpo del Zorro de agua v2 con la cuenta de src/shared/Zorro/Pose (Pose.apply, Pose.drop y
Pose/Tronco, con los resortes de la cabeza y las orejas ya asentados) y de src/shared/Zorro/Patas (las
cuatro patas con IK en el plano del cuerpo, Patas/Plano, y los números de Patas/Ajustes), y un buscador
de poses de contacto. Lo carga zorro_v2_poses.py con exec (usa HUESOS, matrices(), V y C de
minotauro_v2_poses.py, y ETAPA).

Una entrada de pose es una tabla con las claves de Pose (lean, lookYaw, jaw, bow, crouch, sit, lie,
curl/curlSide, scratch/scratchSide/scratchBeat, pawL/pawR, stretch, spine, walk/walkPhase, pounce,
stepFL...) y, además:
    huesos  {hueso: (cabeceo, giro, alabeo)} que reemplazan lo de Pose.apply (párpados, punta de la
            oreja, o lo que busca resolver())
    dy      cuánto sube (+) o baja la base, en fracción del alto (como pose.dy); la base baja además
            Pose.drop (subida_zorro(), que zorro_v2_poses_lista.py pone en lugar de subida())
    t       la hora, solo para el temblor de la sacudida (sin(t * 38))
    colas   {hueso: (fan, fold)}: lo que escribe Zorro/Colas en cada tramo (zorro_v2_colas_paso.py)
Las patas se cuentan en el plano del cuerpo (adelante, arriba) con números complejos: f + u·i, en
fracciones del alto, el piso en u = 0 (Vector2 en Patas/Plano). resolver() (zorro_v2_poses_resolver.py)
busca los ángulos que llevan un punto de una pieza a otro.
"""
import copy
import cmath

for _f in ("zorro_v2_poses_ajustes.py", "zorro_v2_poses_patas.py", "zorro_v2_poses_resolver.py"):
    exec(open(os.path.join(HERE, _f), encoding="utf-8").read(), globals())


def _v(e, k):
    return e.get(k, 0.0)


def _u01(e, k):
    return max(0.0, min(1.0, e.get(k, 0.0)))


def drop(e, etapa=None):
    """Pose.drop: cuánto baja la base (fracción del alto)."""
    A = ETAPAS[etapa or ETAPA]
    walk = _u01(e, "walk")
    body = max(_u01(e, "sit") * A["sitDrop"], _u01(e, "lie") * A["lieDrop"])
    bob = BOB * walk * (0.5 + 0.5 * math.cos(2 * _v(e, "walkPhase") - math.pi))
    return SETTLE + _v(e, "crouch") * CROUCH_DROP + body + _u01(e, "stretch") * STRETCH_DROP + WALK_DROP * walk + bob


def subida_zorro(p):
    """Cuánto sube la base (BU): (pose.dy - Pose.drop) x alto."""
    p = p or {}
    return (p.get("dy", 0.0) - drop(p)) * (ALTO_BU or 0.0)


# ---------------------------------------------------------------- Pose/Tronco y Pose.apply
def tronco(e, etapa=None):
    """Tronco.compute: giros de Cadera, Columna y Pecho, objetivo de la cabeza y lo que suman las
    claves a la mandíbula y las orejas."""
    etapa = etapa or ETAPA
    A = ETAPAS[etapa]
    v = lambda k: e.get(k, 0.0)
    temblor = math.sin(v("t") * 38) * 0.22 * v("shake")
    lean, breathe, crouch, sway = v("lean"), v("breathe"), v("crouch"), v("sway")
    bow = min(v("bow"), A["bowMax"])
    sit, stretch, pounce, walk = _u01(e, "sit"), _u01(e, "stretch"), _u01(e, "pounce"), _u01(e, "walk")
    curl, scratch = _u01(e, "curl"), _u01(e, "scratch")
    tope = 1 + (A["pawSitMax"] - 1) * sit  # sentado, el antebrazo topa con el pecho
    pl, pr = min(_u01(e, "pawL"), tope), min(_u01(e, "pawR"), tope)
    paw = max(pl, pr)
    cside = 1 if v("curlSide") >= 0 else -1
    sside = 1 if v("scratchSide") >= 0 else -1
    andar = ciclo(e, etapa)
    zancada = ZANCADA[etapa]
    lateral = max(-1.0, min(1.0, v("spine"))) + cside * CURL_SPINE * curl
    yaw_lomo = max(-SPINE_MAX, min(SPINE_MAX, lateral * SPINE_MAX))
    rol_cadera = 0.06 * (andar["HDer"][1] - andar["HIzq"][1])
    rol_pecho = 0.05 * (andar["FDer"][1] - andar["FIzq"][1])
    yaw_paso = 0.04 * (andar["HIzq"][0] - andar["HDer"][0]) / max(zancada, 1e-6)
    encorva = A["pawHunch"] * sit * paw
    a_h = -bow * 0.2 + crouch * 0.05 + sit * SIT[0] + stretch * STRETCH_TRUNK[0] - pounce * 0.35
    a_s = (lean * 0.4 + breathe - bow * 0.25 + sit * SIT[1] + stretch * STRETCH_TRUNK[1] - pounce * 0.1
           - walk * 0.03 - encorva * 0.4)
    a_c = lean * 0.4 + breathe * 0.7 - bow * 0.2 + sit * SIT[2] + stretch * STRETCH_TRUNK[2] - encorva * 0.6
    endereza = HEAD_LEVEL * (sit * sum(SIT) - encorva + stretch * 0.06)
    k = min(sit, 1.0)
    ph = [x + (y - x) * k for x, y in zip(A["pawHeadStand"], A["pawHeadSit"])]
    cabeceo = 0.04 * walk * math.cos(2 * v("walkPhase") - math.pi)
    sh = A["scratchHead"]
    yaw = (v("lookYaw") + cside * curl * A["curlHead"][0] + sside * scratch * sh[0] + (pl - pr) * ph[0]
           - yaw_lomo * 0.5 * (1 - curl))
    pitch = (v("lookPitch") + bow * 0.5 - endereza + curl * A["curlHead"][1] + scratch * sh[1] + paw * ph[1]
             - pounce * 0.35 - 0.05 * walk - cabeceo)
    return {
        "Cadera": (a_h, -yaw_lomo * 0.3 + yaw_paso, sway + temblor + rol_cadera + sside * scratch * 0.04),
        "Columna": (a_s, yaw_lomo - yaw_paso, -sway * 0.4 - temblor * 0.8 - rol_cadera * 0.6),
        "Pecho": (a_c, max(-SPINE_MAX, min(SPINE_MAX, yaw_lomo + v("lookYaw") * 0.1)), temblor * 0.6 + rol_pecho),
        "yaw": yaw, "pitch": pitch, "tilt": v("tilt") - sside * scratch * (sh[2] + 0.06 * v("scratchBeat")),
        "jaw": 0.15 * paw, "ears": -0.4 * curl + 0.6 * pounce, "temblor": temblor,
    }


def locales(e):
    """Pose.apply: hueso -> (cabeceo, giro, alabeo) en radianes (sin las colas)."""
    e = e or {}
    t = tronco(e)
    yaw, pitch, tilt, temblor = t["yaw"], t["pitch"], t["tilt"], t["temblor"]
    breathe = e.get("breathe", 0.0)
    r = {n: t[n] for n in ("Cadera", "Columna", "Pecho")}
    r.update({
        "Cuello1": (pitch * 0.25, yaw * 0.2, tilt * 0.2 - temblor * 0.5),
        "Cuello2": (pitch * 0.25, yaw * 0.25, tilt * 0.3),
        "Cabeza": (pitch * 0.5 - breathe * 0.4, yaw * 0.55, tilt * 0.5 + temblor * 0.4),
        "Mandibula": (-0.6 * max(-0.1, min(1.1, e.get("jaw", 0.0) + t["jaw"])), 0, 0),
    })
    for s, k in (("Izq", "earL"), ("Der", "earR")):
        lado = 1 if s == "Izq" else -1  # -(rig.side): la Izq está a la izquierda (side -1)
        oreja = e.get(k, 0.0) + t["ears"]
        r[f"Oreja{s}"] = (-oreja * 0.6, 0, oreja * 0.3 * lado + temblor * lado)
    r.update(patas_ik(e, (t["Cadera"][0], t["Columna"][0], t["Pecho"][0])))
    r.update(e.get("huesos", {}))
    return r


def pasos(fase, cuanto=1.0):
    """Pose.steps: pares cruzados (delantera izquierda con trasera derecha)."""
    a, b = max(0.0, math.sin(fase)), max(0.0, -math.sin(fase))
    return {"stepFL": a * cuanto, "stepHR": a * cuanto, "stepFR": b * cuanto, "stepHL": b * cuanto,
            "sway": 0.04 * math.sin(fase) * cuanto}


def lados(huesos, valor, solo=None):
    """{Hueso{l}: valor} para los dos lados (o solo uno)."""
    return {f"{h}{l}": valor for h in huesos for l in (solo or ("Izq", "Der"))}


def punto(m, hueso, p):
    """Dónde queda el punto p (BU, en reposo) de la pieza `hueso` con las matrices m."""
    return m[hueso] @ p


def ref(pieza, fx, fy, fz, dy=0.0, dz=0.0):
    """Un punto de la caja de reposo de una pieza (fracciones 0..1 en x, y, z; y = 0 es el frente)
    corrido dy, dz celdas. Sale de la malla: sirve en cualquier etapa."""
    vs = np.array([tuple(v.co) for v in bpy.data.objects[pieza].data.vertices])
    lo, hi = vs.min(axis=0), vs.max(axis=0)
    return V(tuple(lo + (hi - lo) * (fx, fy, fz))) + V((0, dy * C, dz * C))
