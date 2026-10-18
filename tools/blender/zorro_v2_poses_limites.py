r"""
Límites limpios del Zorro de agua v2, cualquier etapa. Lo carga zorro_v2_poses.py con exec (usa
posar(), revisar() y MED):
    limites_cuerpo(reposo)  hasta dónde se puede llevar cada clave de Pose.luau, sola, sin que nada
                            atraviese, se meta en su junta ni se separe (bisección con revisar());
                            si la clave llega a su tope limpia, devuelve el tope
    tolerancia_colas(reposo)  por cada par de colas vecinas (en el orden de Zorro/Colas): cuánto
                            pueden doblarse una hacia la otra (el giro del abanico repartido parejo
                            entre los tramos) antes de atravesarse, contra el gap que deja
                            Limites.gaps (min(gap de reposo / 3, 0.15)): si el gap de Limites es
                            más chico que (gap de reposo - tolerancia), la separación del juego
                            deja que se crucen
Sirve para elegir topes en Pose.luau y valores de Limites.luau/Estados.luau con números medidos.
"""
CLAVES = [  # (nombre, entrada(x), tope que se prueba)
    ("mirar_arriba", lambda x: {"lookPitch": x}, 1.2),
    ("mirar_abajo", lambda x: {"lookPitch": -x}, 1.2),
    ("mirar_a_un_lado", lambda x: {"lookYaw": x}, 1.6),
    ("ladear", lambda x: {"tilt": x}, 1.0),
    ("boca", lambda x: {"jaw": x}, 1.1),
    ("orejas_adelante", lambda x: {"earL": x, "earR": x}, 1.5),
    ("orejas_atras", lambda x: {"earL": -x, "earR": -x}, 1.5),
    ("reverencia", lambda x: {"bow": x}, 1.2),
    ("agacharse", lambda x: {"crouch": x}, 1.2),
    ("estirarse", lambda x: {"crouch": -x}, 1.0),
    ("levantar_pata_delantera", lambda x: {"stepFL": x}, 1.5),
    ("levantar_pata_trasera", lambda x: {"stepHL": x}, 1.5),
    ("inclinarse_atras", lambda x: {"lean": x}, 1.0),
    ("inclinarse_adelante", lambda x: {"lean": -x}, 1.0),
    ("sacudida", lambda x: {"shake": x, "t": math.pi / 76}, 1.0),
    # Huesos que el juego todavía no mueve solos (sentarse, echarse, rascarse, lamerse).
    ("brazo_adelante", lambda x: {"huesos": lados(["Brazo"], (x, 0, 0))}, 1.8),
    ("brazo_atras", lambda x: {"huesos": lados(["Brazo"], (-x, 0, 0))}, 1.8),
    ("muslo_adelante", lambda x: {"huesos": lados(["Muslo"], (x, 0, 0))}, 2.4),
    ("muslo_afuera", lambda x: {"huesos": {"MusloIzq": (0, 0, x)}}, 1.6),
    ("columna_de_lado", lambda x: {"huesos": {"Columna": (0, x, 0), "Pecho": (0, x, 0)}}, 1.0),
    ("parpado_abajo", lambda x: {"huesos": lados(["Parpado"], (-x, 0, 0))}, math.pi / 2),
    ("punta_de_oreja", lambda x: {"huesos": lados(["OrejaPunta"], (x, 0, 0))}, 1.0),
]


def _limpia(entrada, reposo):
    posar(entrada)
    return not any(revisar(reposo))


def _biseccion(f, tope, reposo):
    if _limpia(f(tope), reposo):
        return tope
    lo, hi = 0.0, tope
    for _ in range(8):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if _limpia(f(mid), reposo) else (lo, mid)
    return round(lo, 3)


def limites_cuerpo(reposo):
    return {n: {"tope_probado": tope, "limpio_hasta": _biseccion(f, tope, reposo)} for n, f, tope in CLAVES}


def tolerancia_colas(reposo):
    out = []
    cols = MED["colas"]
    for a, b in zip(cols, cols[1:]):
        par = {a["huesos"][0][:-2], b["huesos"][0][:-2]}

        def cruzan(x):
            posar({"colas": {**{h: (x / 2 / a["n"], 0) for h in a["huesos"]},
                             **{h: (-x / 2 / b["n"], 0) for h in b["huesos"]}}})
            return any({p.rsplit("_", 1)[0] for p in c["piezas"]} == par for c in revisar(reposo)[0])

        gap = b["angle"] - a["angle"]
        lo, hi = 0.0, gap
        for _ in range(8):
            mid = (lo + hi) / 2
            lo, hi = (lo, mid) if cruzan(mid) else (mid, hi)
        out.append({"par": sorted(par), "gap_reposo_rad": round(gap, 3), "se_acercan_sin_cruzar_rad": round(lo, 3),
                    "gap_de_limites_rad": round(min(gap / 3, 0.15), 3),
                    "gap_que_haria_falta_rad": round(gap - lo, 3)})
    return out
