r"""
La cuenta del juego y la lista de poses de la Orca v2 (cualquier etapa). La carga orca_v2_poses.py con
exec. Una entrada de pose es {"huesos": {hueso: (pitch, yaw, roll)}} con los ángulos que escribe
OrcaMotion/Rig.turnBone (orca_ref/CONTRATO_RIG_NADO.md, 2), en radianes:
    pitch  alrededor de la derecha del modelo (+X de Roblox = -x de Blender): + sube lo de adelante
           del pivote y baja lo de atrás (la punta de la Cola y de la AletaCola BAJA; la nariz sube;
           la Mandibula se abre con pitch -)
    yaw    alrededor de arriba (+Y = z): + lleva lo de adelante a la izquierda (+x) y lo de atrás a
           la derecha
    roll   alrededor del eje largo (+Z de Roblox = atrás = +y): + lleva lo de arriba a la izquierda
           y lo de la izquierda abajo
Las pectorales se piden con el ángulo del contrato (+ = punta abajo, pegada) y aquí se pasan a roll
con el lado: roll = -side x ángulo (side = -1 a la izquierda, +1 a la derecha, como Rig.bind).
Los números del nado y del giro son los de Rig.apply de hoy (4 tramos) repartidos en 5.
"""
LAG = 0.75 * 3 / 4  # retraso de la onda entre tramos (Rig.TAIL_LAG en 4 tramos, en 5)
AMPLITUD = (0.05, 0.08, 0.115, 0.1575, 0.21)  # Rig.TAIL_AMPLITUDE (0.05..0.21) en 5 tramos
CURVA = (0.07, 0.0925, 0.115, 0.135, 0.15)  # Rig.TAIL_BEND (0.07..0.15) en 5 tramos
ESFUERZO_MAX = 2.0  # Rig.Pose.effort: 0..2
GIRO_MAX = 1.2  # Rig.apply: math.clamp(pose.turn, -1.2, 1.2)
PALETA, PALETA_MAX = 0.32, 0.4  # Rig.FLUKE_PADDLE y FLUKE_MAX
ARCO = (0.16, 0.22, 0.24, 0.22, 0.16)  # reparto de `arch` en Cola1..Cola5 (OrcaMotion/Rig, agente de cuerpo)
COLA = [f"Cola{i}" for i in range(1, 6)]
LADOS = (("Izq", -1), ("Der", 1))  # (lado, side de Rig.bind)

# Lo que el juego pide hoy al máximo (Tricks, Comer, Rig.apply), lo que tiene que dar limpio.
OBJETIVO = {
    "arco_zambullida": 0.8,  # arch +: lomo arriba, cabeza y cola caen
    "arco_salto": -1.2,  # arch -: Jumps pide tail 0.9 (x 0.55 x 1..4/4: 1.24 rad de cola arriba)
    "mandibula": -(-0.06 + (0.5 + 0.06) * 1.2),  # Rig: JAW_CLOSED, JAW_OPEN y jaw 1.2
    "cabeza_arriba": 0.37, "cabeza_abajo": -0.2, "cabeza_lado": 0.15,  # head 0.25 + 0.12; look x 0.12
    "aletas_abiertas": -0.75, "aletas_pegadas": 0.7,  # fins -0.6 / 0.5 + aleteo 0.11 + timón
    "dorsal": 0.4,  # bend x 0.18 + rollSpeed 3 x 0.06
    "aleta_cola": 0.6,  # paleta 0.4 + flukes
}


def sumar(*partes):
    """Une varias entradas; los ángulos del mismo hueso se suman."""
    h = {}
    for p in partes:
        for n, (a, g, b) in p.get("huesos", {}).items():
            a0, g0, b0 = h.get(n, (0, 0, 0))
            h[n] = (a0 + a, g0 + g, b0 + b)
    return {"huesos": h}


def pose_de(**angulos):
    return {"huesos": angulos}


def cadena(total, eje, pesos=ARCO, nombres=COLA):
    """`total` rad repartidos en la cadena según `pesos` (eje 0 pitch, 1 yaw)."""
    s = sum(pesos)
    return {"huesos": {n: tuple(total * w / s if k == eje else 0 for k in range(3)) for n, w in zip(nombres, pesos)}}


def aletas_pecho(angulo, angulo2=None, solo=None):
    """Las dos pectorales (o una) con el ángulo del contrato; el codo, la mitad (Rig.apply)."""
    a2 = angulo * 0.5 if angulo2 is None else angulo2
    h = {}
    for l, side in LADOS:
        if solo in (None, l):
            h[f"Aleta{l}"] = (0, 0, -side * angulo)
            h[f"Aleta{l}2"] = (0, 0, -side * a2)
    return {"huesos": h}


def aletas_cola(pitch, roll=0.0):
    return {"huesos": {f"AletaCola{l}": (pitch, 0, side * roll) for l, side in LADOS}}


def nado(fase, esfuerzo=ESFUERZO_MAX):
    """La onda de Rig.apply: crece hacia la punta y la paleta de la cola va por detrás."""
    h = {n: (math.sin(fase - i * LAG) * AMPLITUD[i - 1] * esfuerzo, 0, 0) for i, n in enumerate(COLA, 1)}
    paleta = max(-PALETA_MAX, min(PALETA_MAX, -PALETA * esfuerzo * math.cos(fase - 6 * LAG)))
    return sumar({"huesos": h}, aletas_cola(paleta))


def giro(bend):
    """La curva de Rig.apply en una vuelta cerrada: la columna, el Pecho y la Cabeza miran a la curva,
    las aletas de la cola se ladean, la dorsal se mece y las pectorales hacen de timón."""
    h = {n: (0, -bend * CURVA[i], 0) for i, n in enumerate(COLA)}
    h["Pecho"], h["Cabeza"], h["Dorsal"] = (0, bend * 0.08, 0), (0, bend * 0.12, 0), (0, 0, bend * 0.18)
    timon = {"huesos": {}}
    for l, side in LADOS:
        timon = sumar(timon, aletas_pecho(-side * bend * 0.12, solo=l))
    return sumar({"huesos": h}, aletas_cola(0, bend * 0.06), timon)


def fase_cola(signo):
    """Fase del nado con la punta de la cola más abajo (signo 1) o más arriba (-1): suma de pitch."""
    return max((2 * math.pi * i / 360 for i in range(360)),
               key=lambda f: signo * sum(a for a, _, _ in nado(f)["huesos"].values() if a))


ABAJO_F, ARRIBA_F = fase_cola(1), fase_cola(-1)
O = OBJETIVO
POSES = {  # nombre -> (entrada, ángulo de la cámara (0 = de frente, 90 = perfil izquierdo), elevación)
    # Combinadas (contrato, 2 y 4).
    "nado_cola_arriba": (nado(ARRIBA_F), 90, 0),
    "nado_cola_abajo": (nado(ABAJO_F), 90, 0),
    "giro_cerrado_izq": (giro(GIRO_MAX), 180, 80),
    "giro_cerrado_der": (giro(-GIRO_MAX), 180, 80),
    "giro_con_nado": (sumar(giro(GIRO_MAX), nado(ARRIBA_F, 1.5)), 135, 40),
    "arco_zambullida": (cadena(O["arco_zambullida"], 0), 90, 0),
    "arco_salto": (cadena(O["arco_salto"], 0), 90, 0),
    "zambullida_cola_afuera": (sumar(cadena(O["arco_zambullida"], 0), aletas_cola(-0.5)), 90, 0),
    "boca_max": (pose_de(Mandibula=(O["mandibula"], 0, 0)), 60, 10),
    "comer": (sumar(pose_de(Mandibula=(O["mandibula"], 0, 0), Cabeza=(O["cabeza_arriba"], 0, 0)),
                    cadena(-0.3, 0)), 60, 10),
    "pectorales_abiertas": (aletas_pecho(O["aletas_abiertas"]), 0, 0),
    "pectorales_pegadas": (aletas_pecho(O["aletas_pegadas"]), 0, 0),
    "saludo": (sumar(aletas_pecho(-1.0, -0.5, "Izq"), aletas_pecho(0.5, 0.25, "Der")), 0, 10),
    # Extremos de cada hueso, solos.
    "cabeza_arriba": (pose_de(Cabeza=(O["cabeza_arriba"], 0, 0)), 90, 0),
    "cabeza_abajo": (pose_de(Cabeza=(O["cabeza_abajo"], 0, 0)), 90, 0),
    "cabeza_izq": (pose_de(Cabeza=(0, O["cabeza_lado"], 0)), 180, 80),
    "cabeza_der": (pose_de(Cabeza=(0, -O["cabeza_lado"], 0)), 180, 80),
    "aletas_cola_arriba": (aletas_cola(-O["aleta_cola"]), 90, 10),
    "aletas_cola_abajo": (aletas_cola(O["aleta_cola"]), 90, 10),
    "dorsal_izq": (pose_de(Dorsal=(0, 0, O["dorsal"])), 180, 10),
    "dorsal_der": (pose_de(Dorsal=(0, 0, -O["dorsal"])), 180, 10),
    # El pedúnculo con Cola3..Cola5 a la vez en el pico de la onda al máximo (sin el retraso).
    "pedunculo_arriba": (pose_de(**{n: (-AMPLITUD[i] * ESFUERZO_MAX, 0, 0) for i, n in enumerate(COLA) if i >= 2}), 90, 0),
    "pedunculo_abajo": (pose_de(**{n: (AMPLITUD[i] * ESFUERZO_MAX, 0, 0) for i, n in enumerate(COLA) if i >= 2}), 90, 0),
    "aletazo": (sumar(pose_de(Cola4=(0.3, 0, 0), Cola5=(0.3, 0, 0)), aletas_cola(-0.4)), 90, 0),
}

# Barridos por hueso: (nombre, entrada(x), tope que se prueba). x >= 0; el signo va en la entrada.
TOPES = []
for _n in COLA:
    TOPES += [(f"{_n}.pitch+", lambda x, n=_n: pose_de(**{n: (x, 0, 0)}), 1.0),
              (f"{_n}.pitch-", lambda x, n=_n: pose_de(**{n: (-x, 0, 0)}), 1.0),
              (f"{_n}.yaw+", lambda x, n=_n: pose_de(**{n: (0, x, 0)}), 1.0),
              (f"{_n}.yaw-", lambda x, n=_n: pose_de(**{n: (0, -x, 0)}), 1.0)]
TOPES += [
    ("AletaCola.pitch+", lambda x: aletas_cola(x), 1.2), ("AletaCola.pitch-", lambda x: aletas_cola(-x), 1.2),
    ("Cabeza.pitch+", lambda x: pose_de(Cabeza=(x, 0, 0)), 0.8), ("Cabeza.pitch-", lambda x: pose_de(Cabeza=(-x, 0, 0)), 0.8),
    ("Cabeza.yaw+", lambda x: pose_de(Cabeza=(0, x, 0)), 0.8), ("Cabeza.yaw-", lambda x: pose_de(Cabeza=(0, -x, 0)), 0.8),
    ("Mandibula.pitch-", lambda x: pose_de(Mandibula=(-x, 0, 0)), 1.2),
    ("Mandibula.pitch+", lambda x: pose_de(Mandibula=(x, 0, 0)), 0.5),
    # Aleta: el hombro con el codo a la mitad, como lo mueve Rig.apply; Aleta2: el codo solo.
    ("Aleta.abajo", lambda x: aletas_pecho(x), 1.6), ("Aleta.arriba", lambda x: aletas_pecho(-x), 1.6),
    ("Aleta2.abajo", lambda x: aletas_pecho(0, x), 1.6), ("Aleta2.arriba", lambda x: aletas_pecho(0, -x), 1.6),
    ("Dorsal.roll+", lambda x: pose_de(Dorsal=(0, 0, x)), 1.0), ("Dorsal.roll-", lambda x: pose_de(Dorsal=(0, 0, -x)), 1.0),
]
