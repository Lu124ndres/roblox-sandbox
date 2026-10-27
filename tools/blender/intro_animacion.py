"""Animación de los gigantes en el previo de la cutscene (intro_previo.py), por código: cada
cuadro se calcula con senos y envolventes y se escribe en los huesos del rig E4. En el juego
los mueve su rutina; esto es para ver el ritmo de cada plano.

Ángulos (rad) en los ejes del modelo, como el contrato de los rigs: el modelo mira a -Y de
Blender, arriba +Z, su izquierda +X.
    cabeceo  + = la punta del hueso sube (en los verticales, que van hacia adelante o atrás)
    giro     + = la punta va a la izquierda del modelo
    alabeo   alrededor del eje largo del hueso
    abrir    + = la punta se aleja del cuerpo (giro con el signo del lado: Izq +, Der -)
Cada hueso gira sobre su cabeza y lleva a sus hijos: los ángulos de una cadena se suman."""
import math
from mathutils import Quaternion, Vector as V

import intro_planos as IP

TAU = 2 * math.pi
X, Z = V((1, 0, 0)), V((0, 0, 1))


def _eje(a, b, reserva):
    e = a.cross(b)
    return e.normalized() if e.length > 0.3 else reserva


def _rotacion(hueso, cabeceo=0.0, giro=0.0, alabeo=0.0, abrir=0.0):
    d = (hueso.tail_local - hueso.head_local).normalized()
    lado = 1 if "Izq" in hueso.name else -1 if "Der" in hueso.name else 0
    r = Quaternion(d, alabeo) @ Quaternion(_eje(d, X, Z), giro + abrir * lado) @ Quaternion(_eje(d, Z, -X), cabeceo)
    m = hueso.matrix_local.to_3x3()
    return (m.inverted() @ r.to_matrix() @ m).to_quaternion()


def suave(t, a, b):
    """0 antes de a, 1 después de b, curva suave entre medio."""
    u = min(max((t - a) / (b - a), 0.0), 1.0)
    return u * u * (3 - 2 * u)


def campana(t, a, b, c, d):
    return suave(t, a, b) * (1 - suave(t, c, d))


# --- Una función por gigante: (t, segundos, plano) -> ({hueso: ángulos}, ancla); alto: studs
# sobre su base (None: no se mueve) --------------
ALTO_E4 = 19.5 * 5.5  # Config.Giants: stageHeightsInPlayers[4] x playerHeightStuds
CUMBRE = 35  # studs entre el agua y la panza en lo más alto del salto


def salto(t, a, b, c):
    """(alto, inclinación) del salto: tiro parabólico con la cumbre en b; antes de a, hundida."""
    hondo = -1.2 * ALTO_E4
    if t < a:
        return hondo, math.radians(60)
    k = (CUMBRE - hondo) / (b - a) ** 2
    u = min((t - a) / (c - a), 1.0)
    return max(CUMBRE - k * (t - b) ** 2, hondo), math.radians(60 - 110 * u)


def orca(t, total, plano):
    salta = plano["nombre"] == "entrada"
    nado = 1.1 if salta else 0.45
    amp = 0.16 if salta else 0.09
    p = {f"Cola{i}": {"cabeceo": amp * math.sin(TAU * nado * t - 0.6 * i)} for i in range(1, 6)}
    aleta = 0.35 * math.sin(TAU * nado * t - 3.6)
    p["AletaColaIzq"] = p["AletaColaDer"] = {"cabeceo": aleta}
    pecho = 0.3 * math.sin(TAU * 0.9 * t)
    p["AletaIzq"] = p["AletaDer"] = {"cabeceo": pecho}
    p["AletaIzq2"] = p["AletaDer2"] = {"cabeceo": 0.5 * pecho}
    if salta:  # brinca: boca abierta en el aire
        a, b, c = plano["salto"]
        alto, inclina = salto(t, a, b, c)
        boca = campana(t, a + 0.3, b - 0.2, b + 0.5, c)
    else:  # revelación: flota y cierra la boca mientras la cámara se va
        alto, inclina = 0.0, 0.0
        boca = 0.5 * (1 - suave(t, 0.0, 1.2))
    p["Cabeza"] = {"cabeceo": 0.3 * boca}
    p["Mandibula"] = {"cabeceo": -0.9 * boca}
    return p, {"inclina": inclina, "alto": alto}


def minotauro(t, total, plano):
    ruge = suave(t, 0.5, 1.1)
    temblor = 0.04 * math.sin(t * 38) * ruge
    agacha = campana(t, 0.0, 0.3, 0.4, 0.8)
    p = {
        "Cabeza": {"cabeceo": 0.3 * ruge - 0.15 * agacha, "giro": temblor},
        "Mandibula": {"cabeceo": -0.55 * ruge},
        "Pecho": {"cabeceo": 0.12 * ruge},
        "Columna": {"cabeceo": 0.06 * ruge - 0.08 * agacha},
        "BrazoIzq": {"abrir": 1.0 * ruge}, "BrazoDer": {"abrir": 1.0 * ruge},
        "AntebrazoIzq": {"cabeceo": 0.8 * ruge}, "AntebrazoDer": {"cabeceo": 0.8 * ruge},
        "OrejaIzq": {"abrir": 0.3 * ruge}, "OrejaDer": {"abrir": 0.3 * ruge},
    }
    for i in range(1, 4):
        p[f"Cola{i}"] = {"giro": 0.15 * math.sin(TAU * 0.8 * t - 0.7 * i)}
    return p, {"inclina": 0.0, "alto": None}


def dragon(t, total, plano):
    aleteo = TAU * 1.3 * t
    ruge = campana(t, 0.9, 1.4, 2.0, 2.4)
    p = {
        "AlaIzq1": {"cabeceo": 0.55 * math.sin(aleteo)}, "AlaDer1": {"cabeceo": 0.55 * math.sin(aleteo)},
        "AlaIzq2": {"cabeceo": 0.35 * math.sin(aleteo - 0.7)}, "AlaDer2": {"cabeceo": 0.35 * math.sin(aleteo - 0.7)},
        "AlaIzq3": {"cabeceo": 0.3 * math.sin(aleteo - 1.4)}, "AlaDer3": {"cabeceo": 0.3 * math.sin(aleteo - 1.4)},
        "Cuello1": {"cabeceo": 0.2 * ruge}, "Cuello2": {"cabeceo": 0.15 * ruge},
        "Cabeza": {"cabeceo": 0.15 * ruge}, "Mandibula": {"cabeceo": -0.7 * ruge},
    }
    for i in range(1, 7):
        p[f"Cola{i}"] = {"giro": 0.12 * math.sin(TAU * 0.8 * t - 0.5 * i)}
    return p, {"inclina": 0.0, "alto": -4 * math.sin(aleteo)}


def zorro(t, total, plano):
    aulla = suave(t, 0.8, 1.4)
    mira = campana(t, 0.2, 0.7, 1.6, 2.2)  # gira la cabeza hacia la cámara (a su derecha)
    p = {
        "Cuello1": {"cabeceo": 0.25 * aulla}, "Cabeza": {"cabeceo": 0.3 * aulla, "giro": -0.25 * mira},
        "Mandibula": {"cabeceo": -0.6 * aulla},
        "OrejaIzq": {"cabeceo": -0.3 * aulla}, "OrejaDer": {"cabeceo": -0.3 * aulla},
    }
    for k in range(1, 10):
        for i in range(1, 6):
            p[f"Cola{k}_{i}"] = {"giro": 0.16 * math.sin(TAU * 0.6 * t - 0.45 * i + k),
                                 "cabeceo": 0.06 * math.sin(TAU * 0.4 * t + k)}
    return p, {"inclina": 0.0, "alto": None}


ANIMA = {"Orca": orca, "Minotauro": minotauro, "DragonMarino": dragon, "ZorroDeAgua": zorro}


def animar(gigantes, fps):
    """Escribe un cuadro clave por cuadro en los huesos (y el ancla) de cada gigante visible."""
    t0 = 0.0
    for plano in IP.PLANOS:
        nombre = plano["gigante"]
        if nombre:
            ancla, partes = gigantes[nombre]
            rig = next(o for o in partes if o.type == "ARMATURE")
            base_z, giro_z = ancla.location.z, ancla.rotation_euler.z
            f0 = round(t0 * fps) + 1
            for i in range(round(plano["segundos"] * fps)):
                t = i / fps
                poses, a = ANIMA[nombre](t, plano["segundos"], plano)
                for hueso, angulos in poses.items():
                    pb = rig.pose.bones.get(hueso)
                    if pb:
                        pb.rotation_mode = "QUATERNION"
                        pb.rotation_quaternion = _rotacion(pb.bone, **angulos)
                        pb.keyframe_insert("rotation_quaternion", frame=f0 + i)
                ancla.rotation_euler = (-a["inclina"], 0, giro_z)
                ancla.keyframe_insert("rotation_euler", frame=f0 + i)
                if a["alto"] is not None:
                    ancla.location.z = base_z + a["alto"]
                    ancla.keyframe_insert("location", index=2, frame=f0 + i)
        t0 += plano["segundos"]
