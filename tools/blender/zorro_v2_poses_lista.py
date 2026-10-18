r"""
Lista de poses extremas del Zorro de agua v2 (cualquier etapa). La carga zorro_v2_poses.py con exec;
armar_poses() llena, después de armar las piezas:
    POSES     {nombre: (entrada, ángulo de la cámara, elevación[, piezas que encuadra])}
    BARRIDOS  {nombre: [(etiqueta, entrada)]}: el ciclo de paso entero y cada escena de colas,
              muestreada, para buscar lo peor
    INFO      lo que mide el juego en cada escena de colas (maxJoint, minGap, minTip, minRoom) y la
              distancia que queda en las poses de contacto (rascarse, lamerse)
Las poses de cola salen de simular Zorro/Colas con los pedidos de Colas/Prueba (y el máximo que
acepta cada clave cuando se pide "al máximo"): nada inventado. Las del cuerpo usan las claves de
Zorro/Pose (sit, lie, curl, scratch, pawL, stretch, spine, walk, pounce...) con la cuenta de
zorro_v2_poses_cuerpo.py; solo los párpados y las puntas de las orejas llevan `huesos`. La base
baja Pose.drop (subida_zorro()) y las escenas de colas sentado y echado bajan lo mismo.
"""
Q = math.radians(45)
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


def _contactos():
    """Cuánto le falta (celdas) a la pata que rasca para llegar detrás de la cabeza (bajo la oreja) y a
    la mano que se lame para llegar bajo el mentón, con las poses de las claves."""
    garra, cuello = ref("PieIzq", 0.5, 0.1, 0.5), ref("Cabeza", 1.0, 1.0, 0.3)
    mano, menton = ref("ManoIzq", 0.5, 0.5, 1, dz=0.2), ref("Mandibula", 0.5, 0.25, 0, dz=-0.7)
    out = {}
    for nombre, entrada, (pa, a), (pb, b) in (
            ("rascarse", RASCAR, ("PieIzq", garra), ("Cabeza", cuello)),
            ("lamerse_sentado", {"sit": 1, "pawL": 1, "jaw": 0.2}, ("ManoIzq", mano), ("Mandibula", menton)),
            ("lamerse_parado", {"pawL": 1, "jaw": 0.2}, ("ManoIzq", mano), ("Mandibula", menton))):
        m = matrices(entrada)
        out[nombre] = round((punto(m, pa, a) - punto(m, pb, b)).length / C, 2)
    return out


RASCAR = {"sit": 1, "scratch": 1, "scratchSide": 1, "earL": 0.3, "jaw": 0.1}


def armar_poses():
    global MED, POSES, BARRIDOS, INFO, subida
    subida = subida_zorro  # la base baja Pose.drop, como en el juego
    MED = medidas({n: np.array(tuple(p)) for n, (_, p) in HUESOS.items()}, ALTO_BU)
    BARRIDOS, INFO, colas = {}, {"escenas_colas": {}, "contacto_celdas": {}}, {}
    BAJADA.update({"sentado": drop({"sit": 1}), "dormir": drop({"lie": 1})})
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
    BARRIDOS["caminar"] = [(f"{f:.2f}", {"walk": 1, "walkPhase": f}) for f in (2 * math.pi * i / 24 for i in range(24))]
    BARRIDOS["rascarse_latido"] = [(f"{b:.1f}", dict(RASCAR, scratchBeat=b)) for b in (-1, -0.5, 0, 0.5, 1)]
    BARRIDOS["rascarse_der_latido"] = [(f"{b:.1f}", dict(RASCAR, scratchSide=-1, earL=0, earR=0.3, scratchBeat=b))
                                       for b in (-1, -0.5, 0, 0.5, 1)]
    INFO["contacto_celdas"] = _contactos()
    INFO["drop"] = {"sentado": round(drop({"sit": 1}), 3), "echado": round(drop({"lie": 1}), 3),
                    "caminando": round(drop({"walk": 1}), 3), "quieto": round(drop({}), 3)}
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
        "sentado": ({"sit": 1, "tailWrap": 1, "colas": colas["colas_sentado"]}, 60, 10),
        "sentado_lado": ({"sit": 1, "colas": colas["colas_sentado"]}, 90, 0),
        "echado": ({"lie": 1, "colas": colas["colas_dormir"]}, 40, 25),
        "dormir_enroscado": ({"lie": 1, "curl": 1, "curlSide": 1, "colas": colas["colas_dormir"]}, 150, 45),
        "dormir_enroscado_der": ({"lie": 1, "curl": 1, "curlSide": -1}, -150, 45),
        "salto_agachado": ({"crouch": 0.6, "lean": -0.12}, 90, 0),
        "salto_estirado": ({"dy": 0.35, "crouch": -0.35, "stepFL": 0.7, "stepFR": 0.7, "stepHL": 0.5, "stepHR": 0.5,
                            **ear(-0.4), "jaw": 0.3, "colas": colas["colas_salto"]}, 90, 0),
        "paso_FL_HR": (pasos(math.pi / 2), 90, 0), "paso_FR_HL": (pasos(3 * math.pi / 2), -90, 0),
        "rascarse_izq": (RASCAR, 60, 10),
        "rascarse_der": (dict(RASCAR, scratchSide=-1, earL=0, earR=0.3, scratchBeat=1), -60, 10),
        "lamerse_sentado": ({"sit": 1, "pawL": 1, "jaw": 0.2}, 40, 10),
        "lamerse_parado": ({"pawR": 1, "jaw": 0.2}, -40, 10),
        "estirarse": ({"stretch": 1, "lookPitch": 0.2}, 90, 0),
        "columna_de_lado": ({"spine": 1, "lookYaw": 0.6}, 0, 70),
        "picada": ({"pounce": 1, "dy": 0.3, "colas": colas["colas_salto"]}, 90, 0),
        "picada_34": ({"pounce": 1, "dy": 0.3, "colas": colas["colas_salto"]}, 30, 10),
        **{f"caminar_{i}": ({"walk": 1, "walkPhase": math.pi * i / 2}, 90, 0) for i in range(4)},
        "sacudida": ({"shake": 1, "t": math.pi / 76, "crouch": 0.1, "lookPitch": -0.1, **ear(-0.3),
                      "colas": colas["colas_sacudida"]}, 0, 20),
        "comer": ({"bow": 0.35, "lean": -0.12, "lookPitch": -0.28, "jaw": 0.8, **ear(0.35), "colas": colas["colas_comer"]}, 60, 10),
    }
    for nombre in ("colas_abanico_max", "colas_plegadas_correr", "colas_dormir", "colas_sentado",
                   "colas_meneo_max", "colas_latigazo"):
        POSES[nombre] = ({"colas": colas[nombre]}, 150, 25)
    for caso in ("afuera", "adentro", "atras", "adelante"):
        POSES[f"colas_juntas_45_{caso}"] = ({"colas": _juntas(caso)}, 150, 25)
