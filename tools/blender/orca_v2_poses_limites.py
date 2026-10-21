r"""
Topes limpios de la Orca v2: por hueso y por eje, y la suma de la columna. La carga orca_v2_poses.py
con exec (usa posar(), revisar(), TOPES, COLA, ARCO, LADOS y cadena()):
    fallas(), limpia()  lo que falla en una pose y si queda limpia
    tope()              el ángulo más grande que queda limpio (pasos de PASO y bisección)
    medir_topes()       un tope por barrido de TOPES
    limites()           los topes en el formato de OrcaMotion/Limites.luau
    medir_cadenas()     cadenaPitch y cadenaYaw
"""

def fallas(entrada, reposo):
    posar(entrada)
    return resumen(*revisar(reposo))


def limpia(entrada, reposo):
    return not any(fallas(entrada, reposo).values())


def tope(f, maximo, reposo):
    """El x más grande de 0 a `maximo` con f(0..x) limpias (pasos de PASO y bisección al final) y
    lo que falla justo después."""
    x = 0.0
    while x < maximo - 1e-9:
        sig = min(maximo, x + PASO)
        if not limpia(f(sig), reposo):
            lo, hi = x, sig
            for _ in range(5):
                mid = (lo + hi) / 2
                lo, hi = (mid, hi) if limpia(f(mid), reposo) else (lo, mid)
            return round(lo, 3), fallas(f(hi), reposo)
        x = sig
    return round(maximo, 3), None


def medir_topes(reposo):
    out = {}
    for nombre, f, maximo in TOPES:
        t, falla = tope(f, maximo, reposo)
        out[nombre] = {"limpio_hasta": t, "probado": maximo, "falla": falla}
    return out


def _rango(t, hueso, eje, signo=1):
    """{min, max} del hueso en un eje; con signo -1, en la convención contraria a turnBone."""
    lo, hi = -t[f"{hueso}.{eje}-"]["limpio_hasta"], t[f"{hueso}.{eje}+"]["limpio_hasta"]
    return {"min": lo, "max": hi} if signo > 0 else {"min": -hi, "max": -lo}


def limites(t):
    """Los topes en el formato de OrcaMotion/Limites.luau (porHueso), en la convención del contrato:
    en Cola1..Cola5 y AletaCola, pitch + = la punta de atrás ARRIBA (el contrario de turnBone: lo
    convierte Huesos.set); las pectorales, con el ángulo del contrato (+ = abajo, el código lo pasa a
    roll con -side); el resto, como turnBone (Mandibula: abrir = -)."""
    por = {n: {"pitch": _rango(t, n, "pitch", -1), "yaw": _rango(t, n, "yaw")} for n in COLA}
    por["Cabeza"] = {"pitch": _rango(t, "Cabeza", "pitch"), "yaw": _rango(t, "Cabeza", "yaw")}
    por["Mandibula"] = {"pitch": _rango(t, "Mandibula", "pitch")}
    por["Dorsal"] = {"roll": _rango(t, "Dorsal", "roll")}
    for l, _ in LADOS:
        por[f"AletaCola{l}"] = {"pitch": _rango(t, "AletaCola", "pitch", -1)}
        for h, k in (("Aleta", ""), ("Aleta2", "2")):
            por[f"Aleta{l}{k}"] = {"roll": {"min": -t[f"{h}.arriba"]["limpio_hasta"], "max": t[f"{h}.abajo"]["limpio_hasta"]}}
    return por


def medir_cadenas(t, reposo):
    """cadenaPitch y cadenaYaw: la suma más grande que queda limpia, por signo, repartida como ARCO
    y como los topes de cada tramo (cada tramo, la misma fracción de su tope). Los signos son los de
    turnBone: pitch+ = la cola baja (arch +, zambullida), pitch- = la cola sube (arch -, salto)."""
    out = {}
    for eje, k in (("pitch", 0), ("yaw", 1)):
        for s, signo in (("+", 1), ("-", -1)):
            topes = [t[f"{n}.{eje}{s}"]["limpio_hasta"] for n in COLA]
            for reparto, pesos in (("arco", ARCO), ("topes", topes)):
                total, falla = tope(lambda x: cadena(signo * x, k, pesos), 3.0, reposo)
                out[f"{eje}{s}_{reparto}"] = {"limpio_hasta": total, "pesos": [round(w, 3) for w in pesos],
                                              "falla": falla}
    return out
