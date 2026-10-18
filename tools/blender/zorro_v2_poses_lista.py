r"""
Lista de poses extremas del Zorro de agua v2 (cualquier etapa). La carga zorro_v2_poses.py con exec;
armar_poses() llena, después de armar las piezas:
    POSES     {nombre: (entrada, ángulo de la cámara, elevación[, piezas que encuadra])}
    BARRIDOS  {nombre: [(etiqueta, entrada)]}: el ciclo de paso entero y cada escena de colas,
              muestreada, para buscar lo peor
    INFO      lo que mide el juego en cada escena de colas (maxJoint, minGap, minTip, minRoom) y la
              distancia que queda en las poses de contacto (rascarse, lamerse)
Las poses de cola salen de simular Zorro/Colas con los pedidos de Colas/Prueba (y el máximo que
acepta cada clave cuando se pide "al máximo"): nada inventado. Las del cuerpo que el juego ya hace
(mirar, aullido, reverencia, salto, sacudida, comer, paso) salen de Zorro/Trucos y Pose; las que
todavía no existen (sentado, echado, rascarse, lamerse, párpados) llevan `huesos` y se buscan con
resolver() cuando hay un contacto.
"""
Q = math.radians(45)
# Cuánto pesan los choques en resolver() (sobre la distancia al contacto), medido: 1.0 en el echado
# esquiva las patas plegadas bajo la grupa; en rascarse, más peso hace que la pata no llegue.
K_CHOQUE = globals().get("K_CHOQUE") or {"sentado": 0.3, "dormir": 1.0, "rascarse": 0.05, "lamerse": 0.6}
CARA = ["Cabeza", "Mandibula", "OrejaIzq", "OrejaDer", "OrejaPuntaIzq", "OrejaPuntaDer", "ParpadoIzq", "ParpadoDer"]


BAJADA = {"sentado": 0.0, "dormir": 0.0}  # fracción del alto: la llena armar_poses()


def entre(u, a, b):
    return 1.0 if a <= u <= b else 0.0


# Escenas de colas: (plan(u) -> (Intent, BodyInfo), segundos, qué cuadro se muestra).
ESCENAS = {
    "colas_abanico_max": (lambda u: ({"abanico": 1.5 * entre(u, 0.5, 9), "alto": 0.5 * entre(u, 0.5, 9)}, {}), 4, "abanico"),
    "colas_plegadas_correr": (lambda u: ({}, {"avance": 3 * entre(u, 0.5, 9)}), 3, "final"),
    # Sentado y echado: la base baja lo que baja en la pose del cuerpo (BodyInfo.bajada).
    "colas_dormir": (lambda u: ({"enroscar": entre(u, 0.5, 9), "calma": 0.3},
                                {"bajada": BAJADA["dormir"] * entre(u, 0.5, 9)}), 6, "final"),
    "colas_sentado": (lambda u: ({"envolver": entre(u, 0.5, 9)}, {"bajada": BAJADA["sentado"] * entre(u, 0.5, 9)}),
                      5, "final"),
    "colas_meneo_max": (lambda u: ({"meneo": 1.6, "gusto": 1}, {}), 3, "fan"),
    "colas_latigazo": (lambda u: ({"latigazo": INICIO + 0.5}, {}), 2, "fold"),
    "colas_salto": (lambda u: ({"alto": -0.15}, {"subida": entre(u, 0.5, 1.47) * 0.35 * math.pi / 0.97
                                                  * math.cos(math.pi * (u - 0.5) / 0.97)}), 1.0, "final"),
    "colas_sacudida": (lambda u: ({"meneo": 1.2}, {"sacudida": 1}), 1.5, "fan"),
    "colas_aullido": (lambda u: ({"abanico": 0.9, "alto": 0.6, "calma": 0}, {}), 3, "final"),
    "colas_reverencia": (lambda u: ({"meneo": 1.4, "alto": 0.4}, {}), 3, "fan"),
    "colas_comer": (lambda u: ({"meneo": 0.8, "gusto": 0.25, "alto": 0.15}, {}), 3, "fan"),
}


def _abierto(cuadro):
    at = [c["angle"] + sum(cuadro["angulos"][h][0] for h in c["huesos"]) for c in MED["colas"]]
    return max(at) - min(at)


def _elegir(cuadros, como):
    if como == "final":
        return cuadros[-1]
    medida = {"abanico": _abierto,
              "fan": lambda q: sum(abs(a) for a, _ in q["angulos"].values()),
              "fold": lambda q: sum(abs(b) for _, b in q["angulos"].values())}[como]
    return max(cuadros, key=medida)


def _juntas(caso):
    """Cada junta de _2 a _5 a 45° (la raíz quieta), con los ejes de Zorro/Colas."""
    out = {}
    for c in MED["colas"]:
        s = signo(c["out"]) or 1
        for h in c["huesos"][1:]:
            out[h] = {"afuera": (s * Q, 0), "adentro": (-s * Q, 0), "atras": (0, Q), "adelante": (0, -Q)}[caso]
    return out


def espejar(e):
    """Copia los huesos Izq de `huesos` a los Der (cabeceo igual, giro y alabeo al revés)."""
    for h, (p, g, b) in list(e["huesos"].items()):
        if h.endswith("Izq"):
            e["huesos"][h[:-3] + "Der"] = (p, -g, -b)
    return e


def _z(m, h, p, z=0.0):
    return abs(punto(m, h, p).z - z * C)


def _contactos():
    """Sentado, echado, rascarse y lamerse: resolver() con los puntos de contacto. Los puntos salen
    de la caja de cada pieza (ref), así sirven en cualquier etapa."""
    r, piv = {}, lambda h: HUESOS[h][1]
    mano_abajo, mano_arriba = ref("ManoIzq", 0.5, 0.5, 0), ref("ManoIzq", 0.5, 0.5, 1, dz=0.2)
    talon, punta_pie = ref("PieIzq", 0.5, 1, 0), ref("PieIzq", 0.5, 0, 0)
    libres = {"Cadera.0": (0, 1.2, 0.6), "dy": (-0.4, 0, -0.15), "lookPitch": (-1.2, 0.3, -0.5),
              "HombroIzq.0": (-1.2, 0.3, -0.6), "MusloIzq.0": (-0.5, 2.5, 1.0), "PiernaIzq.0": (-2.6, 0.5, -1.5),
              "TobilloIzq.0": (-0.5, 2.6, 1.5), "PieIzq.0": (-1.5, 1.5, -0.5)}
    def sentado(m):
        recta = abs(punto(m, "AntebrazoIzq", piv("AntebrazoIzq")).y - punto(m, "ManoIzq", piv("ManoIzq")).y)
        adelante = (m["Cabeza"].to_3x3() @ V((0, -1, 0))).z
        return (_z(m, "ManoIzq", mano_abajo) + _z(m, "PieIzq", talon) + _z(m, "PieIzq", punta_pie)
                + _z(m, "Cadera", ref("Cadera", 0.5, 1, 0), 0.5) + recta + abs(adelante) * C)
    r["sentado"] = resolver({}, libres, sentado, k_choque=K_CHOQUE["sentado"])
    libres = {"dy": (-0.45, 0, -0.25), "Cadera.0": (-0.3, 0.3, 0), "BrazoIzq.0": (-1.6, 1.8, 1.2),
              "AntebrazoIzq.0": (-2.0, 1.6, 0.3), "ManoIzq.0": (-1.5, 1.5, 0), "MusloIzq.0": (-0.5, 2.6, 1.6),
              "PiernaIzq.0": (-2.2, 0.5, -1.8), "TobilloIzq.0": (-0.5, 1.2, 1.0), "PieIzq.0": (-1.5, 1.5, 0)}
    # El lomo se dobla de lado hasta su límite limpio (columna_de_lado, ~0.25 rad por hueso).
    echado = {"lookYaw": -1.0, "lookPitch": -0.4, "huesos": {"Columna": (0, -0.25, 0), "Pecho": (0, -0.25, 0)}}
    panza = [("Pecho", ref("Pecho", 0.5, 0.5, 0)), ("Cadera", ref("Cadera", 0.5, 0.5, 0))]
    r["dormir"] = resolver(echado, libres, k_choque=K_CHOQUE["dormir"], costo=lambda m: (
        sum(_z(m, h, p, 0.5) for h, p in panza) + _z(m, "ManoIzq", mano_abajo)
        + _z(m, "AntebrazoIzq", ref("AntebrazoIzq", 0.5, 0.5, 0)) + _z(m, "PieIzq", talon) + _z(m, "PieIzq", punta_pie)))
    libres = {"lookYaw": (0, 1.3, 0.8), "lookPitch": (-1.0, 0.4, -0.4), "tilt": (-0.8, 0.8, 0.3),
              "Columna.1": (0, 0.6, 0.3), "Pecho.1": (0, 0.6, 0.3), "MusloIzq.0": (-0.5, 2.4, 1.2),
              "MusloIzq.2": (-0.3, 1.6, 0.3), "Cadera.2": (-0.4, 0.4, 0), "PiernaIzq.0": (-2.4, 1.0, -0.5),
              "TobilloIzq.0": (-1.0, 2.4, 0.8), "PieIzq.0": (-1.2, 1.2, 0)}
    garra, oreja = ref("PieIzq", 0.5, 0.1, 0.5), ref("OrejaIzq", 0.5, 1, 0.5, dy=0.5)  # detrás de la oreja
    rascar = lambda m: (punto(m, "PieIzq", garra) - punto(m, "OrejaIzq", oreja)).length
    llega = resolver({"earL": 0.3, "jaw": 0.1}, libres, rascar, k_choque=0)  # primero, que llegue
    r["rascarse_oreja"] = resolver({"earL": 0.3, "jaw": 0.1}, libres, rascar, k_choque=K_CHOQUE["rascarse"],
                                   inicio=llega[2])
    r["rascarse_sin_esquivar_choques"] = llega
    libres = {"lookPitch": (-1.2, 0.3, -0.6), "lookYaw": (-0.2, 1.0, 0.3), "tilt": (-0.6, 0.6, 0),
              "HombroIzq.0": (-0.5, 0.8, 0.2), "BrazoIzq.0": (0, 1.8, 1.0), "BrazoIzq.2": (-0.6, 0.6, 0),
              "AntebrazoIzq.0": (-2.2, 0.5, -1.0), "ManoIzq.0": (-1.2, 1.2, 0)}
    menton = ref("Mandibula", 0.5, 0.25, 0, dz=-0.7)  # debajo del mentón, donde lame
    lamer = lambda m: (punto(m, "ManoIzq", mano_arriba) - punto(m, "Mandibula", menton)).length
    r["lamerse_pata"] = resolver({"jaw": 0.35, "earL": 0.2, "earR": 0.2}, libres, lamer, k_choque=K_CHOQUE["lamerse"])
    espejar(r["sentado"][0])
    espejar(r["dormir"][0])
    return r


def armar_poses():
    global MED, POSES, BARRIDOS, INFO
    MED = medidas({n: np.array(tuple(p)) for n, (_, p) in HUESOS.items()}, ALTO_BU)
    BARRIDOS, INFO, colas = {}, {"escenas_colas": {}, "contacto_celdas": {}}, {}
    cont = _contactos()
    BAJADA.update({n: max(0.0, -cont[n][0].get("dy", 0.0)) for n in BAJADA})
    INFO["bajada"] = {n: round(b, 3) for n, b in BAJADA.items()}
    for nombre, (plan, seg, como) in ESCENAS.items():
        cuadros = simular(MED, ETAPA, plan, seg)
        colas[nombre] = _elegir(cuadros, como)["angulos"]
        vivos = [q for q in cuadros if q["u"] >= min(0.5, seg / 2)]
        INFO["escenas_colas"][nombre] = {
            "maxJoint_rad": round(max(q["maxJoint"] for q in cuadros), 3),
            "minGap_rad": round(min(q["minGap"] for q in cuadros), 3),
            "minTip_altos_cadera": round(min(q["minTip"] for q in cuadros), 3),
            "minRoom": round(min(min(q["room"]) for q in cuadros), 3)}
        BARRIDOS[nombre] = [(f"{q['u']:.2f}", {"colas": q["angulos"]}) for q in vivos[::max(1, len(vivos) // 8)]]
    BARRIDOS["paso"] = [(f"{f:.2f}", pasos(f)) for f in (2 * math.pi * i / 24 for i in range(24))]
    INFO["contacto_celdas"] = {n: round(c[1] / C, 2) for n, c in cont.items()}
    ear = lambda k: {"earL": k, "earR": k}
    POSES = {
        "mirar_arriba_45": ({"lookPitch": Q}, 90, 0), "mirar_abajo_45": ({"lookPitch": -Q}, 90, 0),
        "mirar_izq_60": ({"lookYaw": math.radians(60)}, 0, 20), "mirar_der_60": ({"lookYaw": -math.radians(60)}, 0, 20),
        "aullido_boca_max": ({"crouch": 0.25, "lean": 0.18, "lookPitch": 0.75, "lookYaw": -0.3, "jaw": 1.1,
                              **ear(-0.5), "colas": colas["colas_aullido"]}, 60, 10),
        "parpados_cerrados": ({"huesos": lados(["Parpado"], (-math.pi / 2, 0, 0))}, 20, 10, CARA),
        "orejas_planas": ({**ear(-1.0), "huesos": lados(["OrejaPunta"], (0.5, 0, 0))}, 60, 10, CARA),
        "orejas_adelante": ({**ear(1.0), "huesos": lados(["OrejaPunta"], (-0.5, 0, 0))}, 60, 10, CARA),
        "reverencia": ({"bow": 0.9, "lookPitch": 0.35, "jaw": 0.35, **ear(0.5), "colas": colas["colas_reverencia"]}, 90, 0),
        "sentado": (dict(cont["sentado"][0], colas=colas["colas_sentado"]), 60, 10),
        "dormir_echado": (dict(cont["dormir"][0], colas=colas["colas_dormir"]), 150, 45),
        "salto_agachado": ({"crouch": 0.6, "lean": -0.12}, 90, 0),
        "salto_estirado": ({"dy": 0.35, "crouch": -0.35, "stepFL": 0.7, "stepFR": 0.7, "stepHL": 0.5, "stepHR": 0.5,
                            **ear(-0.4), "jaw": 0.3, "colas": colas["colas_salto"]}, 90, 0),
        "paso_FL_HR": (pasos(math.pi / 2), 90, 0), "paso_FR_HL": (pasos(3 * math.pi / 2), -90, 0),
        "rascarse_oreja": (cont["rascarse_oreja"][0], 60, 10),
        "lamerse_pata": (cont["lamerse_pata"][0], 40, 10),
        "sacudida": ({"shake": 1, "t": math.pi / 76, "crouch": 0.1, "lookPitch": -0.1, **ear(-0.3),
                      "colas": colas["colas_sacudida"]}, 0, 20),
        "comer": ({"bow": 0.35, "lean": -0.12, "lookPitch": -0.28, "jaw": 0.8, **ear(0.35), "colas": colas["colas_comer"]}, 60, 10),
    }
    for nombre in ("colas_abanico_max", "colas_plegadas_correr", "colas_dormir", "colas_sentado",
                   "colas_meneo_max", "colas_latigazo"):
        POSES[nombre] = ({"colas": colas[nombre]}, 150, 25)
    for caso in ("afuera", "adentro", "atras", "adelante"):
        POSES[f"colas_juntas_45_{caso}"] = ({"colas": _juntas(caso)}, 150, 25)
