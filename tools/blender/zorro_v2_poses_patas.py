r"""
Las patas del Zorro de agua v2 con la cuenta de src/shared/Zorro/Patas (init.luau y Plano.luau): IK
en el plano del cuerpo con números complejos (f + u·i, en fracciones del alto, el piso en u = 0).
Lo carga zorro_v2_poses_cuerpo.py (usa HUESOS, ALTO_BU, ETAPA, drop() y los números de
zorro_v2_poses_ajustes.py).
"""
import cmath


# ---------------------------------------------------------------- Patas/Plano
_GEO = {}


def _p2(nombre):
    """Articulación de reposo en el plano del cuerpo: f (adelante, -y) + u (arriba, z) i, en altos."""
    piv = HUESOS[nombre][1]
    return complex(-piv.y, piv.z) / ALTO_BU


def geometria():
    if "alto" in _GEO and _GEO["alto"] == ALTO_BU:
        return _GEO
    _GEO.clear()
    _GEO["alto"] = ALTO_BU
    for n in ("Cadera", "Columna", "Pecho"):
        _GEO[n] = _p2(n)
    for s in ("Izq", "Der"):
        _GEO["F" + s] = [_p2(h + s) for h in ("Hombro", "Brazo", "Antebrazo", "Mano")]
        _GEO["H" + s] = [_p2(h + s) for h in ("Muslo", "Pierna", "Tobillo", "Pie")]
    return _GEO


def _rot(p, centro, a):
    return (p - centro) * cmath.exp(1j * a) + centro


def _ang(z):
    return cmath.phase(z)


def _envolver(a):
    return (a + math.pi) % (2 * math.pi) - math.pi


def _dos_huesos(a, objetivo, l1, l2, lado):
    """Plano.twoBone: ángulos (mundo) del primero y del segundo hueso. lado -1: la junta queda atrás
    de la línea a->objetivo cuando esta baja (codo y talón atrás)."""
    d = objetivo - a
    largo = max(abs(d), 1e-9)
    dist = min(max(largo, abs(l1 - l2) + 1e-6), (l1 + l2) * 0.9999)
    alfa = math.acos(max(-1.0, min(1.0, (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist))))
    f1 = _ang(d) + lado * alfa
    b = a + l1 * cmath.exp(1j * f1)
    return f1, _ang(a + d / largo * dist - b)


def paso(s, zancada):
    """Una pata en el ciclo (s 0..1, 0 = apoya): (adelante, alto 0..1)."""
    amp = DUTY * zancada / 2
    if s < DUTY:
        return amp * (1 - 2 * s / DUTY), 0.0
    q = (s - DUTY) / (1 - DUTY)
    return -amp + 2 * amp * q * q * (3 - 2 * q), math.sin(math.pi * q ** 1.35)


def ciclo(e, etapa=None):
    """Plano.cycle: {pata: (adelante, alto)} (fracciones del alto), ya por walk."""
    w = _u01(e, "walk")
    fase = _v(e, "walkPhase") / (2 * math.pi)
    out = {}
    for pata, off in GAIT.items():
        x, h = paso((fase - off) % 1.0, ZANCADA[etapa or ETAPA])
        out[pata] = (x * w, h * w)
    return out


# ---------------------------------------------------------------- Patas (init)
def _delantera(e, g, tr, A, piso, andar, s, lado_s, letra):
    hip, spine, chest = tr
    ho, br, an, ma = g["F" + s]
    l1, l2 = abs(an - br), abs(ma - an)
    largo = l1 + l2
    adelante, alto = andar["F" + s]
    lift = max(0.0, min(1.5, _v(e, "stepF" + letra) + alto * A["walkLift"][0]))
    sit, lie = _u01(e, "sit"), _u01(e, "lie")
    bow = min(_v(e, "bow"), A["bowMax"])
    suma = hip + spine + chest
    hombro = 0.6 * adelante / largo + SIT_SHOULDER * sit * suma
    a = _rot(_rot(_rot(_rot(br, ho, hombro), g["Pecho"], chest), g["Columna"], spine), g["Cadera"], hip)
    quieto = ma.real
    vertical = a.real + (ma.real - br.real) + A["sitFront"] * largo
    frente = a.real + A["lieReach"] * largo
    f = quieto + sit * (vertical - quieto) + lie * (frente - quieto) + adelante + bow * A["bowReach"] * largo
    objetivo = complex(f, piso + ma.imag + LIFT_U * largo * lift)
    a1, a2 = _dos_huesos(a, objetivo, l1, l2, -1)
    c1, c2 = _envolver(a1 - _ang(an - br)), _envolver(a2 - _ang(ma - an))
    c3 = (LIE_WRIST * lie + A["bowWrist"] * bow) * c2
    pitch = [hombro, c1 - suma - hombro, c2 - c1, c3 - c2 + LIFT_CURL * lift]
    roll = [0.0, 0.0, 0.0, 0.0]
    pw = min(_u01(e, "paw" + letra), 1 + (A["pawSitMax"] - 1) * sit)
    if pw > 0:
        k = min(sit, 1.0)
        for i in range(4):
            fk = A["pawStand"][i] + (A["pawSit"][i] - A["pawStand"][i]) * k
            pitch[i] += (fk - pitch[i]) * pw
        roll[1] = -lado_s * (A["pawStand"][4] + (A["pawSit"][4] - A["pawStand"][4]) * k) * pw
    pounce = _u01(e, "pounce")
    if pounce > 0:
        for i in range(4):
            pitch[i] += (POUNCE_F[i] - pitch[i]) * pounce
            roll[i] -= lado_s * POUNCE_IN * pounce
    return {h + s: (pitch[i], 0, roll[i]) for i, h in enumerate(("Hombro", "Brazo", "Antebrazo", "Mano"))}


def _trasera(e, g, tr, A, piso, andar, s, lado_s, letra):
    hip = tr[0]
    mu, pi_, to, pie = g["H" + s]
    l1, l2, l3 = abs(pi_ - mu), abs(to - pi_), abs(pie - to)
    total = l1 + l2 + l3
    adelante, alto = andar["H" + s]
    lift = max(0.0, min(1.5, _v(e, "stepH" + letra) + alto * A["walkLift"][1]))
    sit, lie, stretch = _u01(e, "sit"), _u01(e, "lie"), _u01(e, "stretch")
    h_w = _rot(mu, g["Cadera"], hip)
    f = pie.real + (sit * A["sitPaw"] + lie * A["liePaw"] - stretch * STRETCH_BACK) * total + adelante
    suelo = complex(f, piso + pie.imag)
    objetivo = suelo + complex(0, LIFT_UH * total * lift)
    r0 = abs(pie - mu)
    beta0 = _envolver(_ang(pi_ - mu) - _ang(pie - mu))
    d = objetivo - h_w
    rr = max(abs(d), 1e-9)
    # lo plegada sale del pie en el suelo: levantar la pata no la pliega bajo la grupa
    plegado = max(0.0, min(1.0, (r0 - abs(suelo - h_w)) / (FOLD_RANGE * r0)))
    beta = beta0 + (FOLD_BETA - beta0) * plegado ** A["foldPow"] - stretch * STRETCH_BETA
    cmin = (l1 * l1 + rr * rr - (l2 + l3) ** 2 * 0.998) / (2 * l1 * rr)
    if cmin > -1:
        bmax = math.acos(cmin) if cmin < 1 else 0.0
        beta = max(-bmax, min(bmax, beta))
    a1 = _ang(d) + beta
    k = h_w + l1 * cmath.exp(1j * a1)
    a2, a3 = _dos_huesos(k, objetivo, l2, l3, -1)
    c1, c2, c3 = _envolver(a1 - _ang(pi_ - mu)), _envolver(a2 - _ang(to - pi_)), _envolver(a3 - _ang(pie - to))
    pitch = [c1 - hip, c2 - c1, c3 - c2, -c3 + LIFT_CURL_H * lift]
    roll = [0.0, 0.0, 0.0, 0.0]
    lado_rasca = 1 if e.get("scratchSide", 1) >= 0 else -1
    sc = _u01(e, "scratch") if lado_rasca == lado_s else 0.0
    if sc > 0:
        L, beat = A["scratchLeg"], _v(e, "scratchBeat")
        fk = (L[0], L[2] + SCRATCH_BEAT[0] * beat, L[3] + SCRATCH_BEAT[1] * beat, L[4])
        for i in range(4):
            pitch[i] += (fk[i] - pitch[i]) * sc
        roll[0] += lado_s * L[1] * sc
    pounce = _u01(e, "pounce")
    if pounce > 0:
        for i in range(4):
            pitch[i] += (POUNCE_H[i] - pitch[i]) * pounce
    return {h + s: (pitch[i], 0, roll[i]) for i, h in enumerate(("Muslo", "Pierna", "Tobillo", "Pie"))}


def patas_ik(e, tr, etapa=None):
    """Patas.apply: {hueso: (cabeceo, giro, alabeo)} de las cuatro patas. tr: cabeceo local de Cadera,
    Columna y Pecho (lo que puso Pose.apply)."""
    if not ALTO_BU:  # todavía sin medir el alto (armar_y_medir posa el reposo antes): patas quietas
        return {}
    etapa = etapa or ETAPA
    A, g, piso, andar = ETAPAS[etapa], geometria(), drop(e, etapa), ciclo(e, etapa)
    r = {}
    for s, lado_s, letra in (("Izq", 1, "L"), ("Der", -1, "R")):
        r.update(_delantera(e, g, tr, A, piso, andar, s, lado_s, letra))
        r.update(_trasera(e, g, tr, A, piso, andar, s, lado_s, letra))
    return r
