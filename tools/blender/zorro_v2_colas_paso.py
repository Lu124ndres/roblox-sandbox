r"""
Las colas del Zorro de agua v2 con la misma cuenta que el juego (src/shared/Zorro/Colas), parte 2:
Mezcla, Cadena, Limites y Colas.step, más simular() (como Colas/Prueba: 60 cuadros por segundo,
sin escribir huesos) y las escenas de Colas/Prueba. Necesita la parte 1 (zorro_v2_colas_sim.py)
cargada antes. Siempre corre "de cerca" (detail = true: pasos de 1/120 s y la onda con ruido).

    simular(med, etapa, plan, segundos) -> [cuadro]   plan(u) da (Intent, BodyInfo) a los u s
    cuadro: {"u", "angulos": {hueso: (fan, fold)}, "maxJoint", "minGap", "minTip", "room"}
    giro_tramo(med, hueso, fan, fold) -> matriz 3x3 del tramo en los ejes del cuerpo
"""

INICIO = 1000.0  # hora ficticia (Colas/Prueba)
MAX_JOINT = math.radians(45)


def resorte(s, objetivo, dt, hz, amort):
    """Resorte.step (s = [x, v]), en pasos de 1/120 s."""
    w = TAU * hz
    pasos = max(1, math.ceil(dt / (1 / 120)))
    h = dt / pasos
    for _ in range(pasos):
        s[1] += (w * w * (objetivo - s[0]) - 2 * amort * w * s[1]) * h
        s[0] += s[1] * h
    return s[0]


def mezcla_paso(st, intent, body, dt):
    """Mezcla.step: cada valor sigue al pedido con un resorte sin rebote."""
    def seguir(k, obj):
        return resorte(st["springs"].setdefault(k, [obj, 0.0]), obj, dt,
                       1.9 if k in ("sacudida", "meneo") else 0.9, 1)
    g = lambda k, d=0.0: intent.get(k, d)
    m = st["mix"]
    m["calma"] = max(0.0, seguir("calma", clamp(g("calma", 1.0), 0, 2.5)))
    m["alto"] = seguir("alto", clamp(g("alto"), -1, 1))
    m["alerta"] = clamp(seguir("alerta", clamp(g("alerta"), 0, 1)), 0, 1)
    m["meneo"] = max(0.0, seguir("meneo", clamp(g("meneo"), 0, 1.6)))
    m["gusto"] = clamp(seguir("gusto", g("gusto")), 0, 1)
    m["envolver"] = clamp(seguir("envolver", g("envolver")), 0, 1)
    m["enroscar"] = clamp(seguir("enroscar", g("enroscar")), 0, 1)
    m["lado"] = clamp(seguir("lado", -1.0 if g("lado", 1.0) < 0 else 1.0), -1, 1)
    m["correr"] = clamp(seguir("correr", clamp(body["avance"] / 1.2, 0, 1)), 0, 1)
    m["sacudida"] = clamp(seguir("sacudida", clamp(body["sacudida"], 0, 1)), 0, 1)
    m["latigazo"] = intent.get("latigazo")
    antes = st["rise"]
    st["rise"] += (body["subida"] - st["rise"]) * (1 - math.exp(-dt * 12))
    acel = clamp((st["rise"] - antes) / dt, -8, 8)
    st["accel"] += (acel - st["accel"]) * (1 - math.exp(-dt * 10))
    return m


def _limitar(ch, j):
    a, b = ch["fanX"][j], ch["foldX"][j]
    size = math.hypot(a, b)
    if size <= MAX_JOINT:
        return
    na, nb = a / size, b / size
    ch["fanX"][j], ch["foldX"][j] = a * MAX_JOINT / size, b * MAX_JOINT / size
    sale = ch["fanV"][j] * na + ch["foldV"][j] * nb
    if sale > 0:
        ch["fanV"][j] -= sale * na
        ch["foldV"][j] -= sale * nb


def cadena_paso(ch, fan_t, fold_t, zeta, dt, sub=1 / 120):
    """Cadena.step: resortes casi críticos, más blandos hacia la punta, con el látigo."""
    pasos = max(1, math.ceil(dt / sub))
    h = dt / pasos
    for _ in range(pasos):
        empuje_f = empuje_g = 0.0
        for j in range(len(ch["hz"])):
            w = TAU * ch["hz"][j]
            k, c = w * w, 2 * zeta * w
            af = k * (fan_t[j] - ch["fanX"][j]) - c * ch["fanV"][j] - 0.45 * empuje_f
            ag = k * (fold_t[j] - ch["foldX"][j]) - c * ch["foldV"][j] - 0.45 * empuje_g
            ch["fanV"][j] += af * h
            ch["foldV"][j] += ag * h
            ch["fanX"][j] += ch["fanV"][j] * h
            ch["foldX"][j] += ch["foldV"][j] * h
            _limitar(ch, j)
            empuje_f, empuje_g = af, ag


def separar(colas, fan, gaps):
    """Limites.separate: dos vecinas no se acercan más que su gap en el abanico."""
    at = [c["angle"] + sum(fan[i]) for i, c in enumerate(colas)]
    shift = [0.0] * len(colas)
    for _ in range(3):
        for i in range(len(colas) - 1):
            falta = gaps[i] - ((at[i + 1] + shift[i + 1]) - (at[i] + shift[i]))
            if falta > 0:
                shift[i] -= falta / 2
                shift[i + 1] += falta / 2
    for i, c in enumerate(colas):
        if shift[i] != 0:
            fan[i][0] += shift[i] * (0.6 if c["n"] > 1 else 1)
            if c["n"] > 1:
                fan[i][1] += shift[i] * 0.4


def punta(c, fan, fold, k=1.0):
    """Limites.tip: el último hueso y la punta con los ángulos por k."""
    giro, p = np.eye(3), c["root"]
    antes = p
    for j in range(c["n"]):
        giro = giro @ rot(ADE, fan[j] * k) @ rot(c["fold_axis"], fold[j] * k)
        antes, p = p, p + giro @ c["segs"][j]
    return antes, p


def _adentro(med, p):
    ab = med["b"] - med["a"]
    u = clamp((p - med["a"]) @ ab / (ab @ ab), 0, 1)
    return np.linalg.norm(p - (med["a"] + ab * u)) < med["radius"]


def _cabe(c, med, fan, fold, k, min_z):
    ultimo, tip = punta(c, fan, fold, k)
    return tip[2] >= min_z and ultimo[2] >= min_z and not _adentro(med, tip) and not _adentro(med, ultimo)


def lugar(c, med, fan, fold, min_z):
    """Limites.room: qué fracción de la pose cabe (búsqueda binaria, 4 pasos)."""
    if _cabe(c, med, fan, fold, 1, min_z):
        return 1.0
    lo, hi = 0.0, 1.0
    for _ in range(4):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if _cabe(c, med, fan, fold, mid, min_z) else (lo, mid)
    return lo


def simular(med, etapa, plan, segundos, fps=60):
    """Colas.new + Colas.step en cada cuadro (como Colas/Prueba.simular)."""
    p, colas = PERFILES[etapa], med["colas"]
    st = dict(mix=dict(calma=1.0, alto=0.0, alerta=0.0, meneo=0.0, gusto=0.0, envolver=0.0, enroscar=0.0,
                       lado=1.0, correr=0.0, sacudida=0.0, latigazo=None), springs={}, rise=0.0, accel=0.0)
    gaps = [min((b["angle"] - a["angle"]) / 3, 0.15) if b["angle"] > a["angle"] else 0.0
            for a, b in zip(colas, colas[1:])]
    cadenas, abre, abre_hz, room, rest_ok = [], [], [], [], []
    min_z0 = med["floor"] + med["unit"] * 0.3
    for c in colas:
        n = c["n"]
        hz = [(2.4 + (1.1 - 2.4) * ((j / (n - 1)) if n > 1 else 0)) * p["peso"] for j in range(n)]
        cadenas.append(dict(fanX=[0.0] * n, fanV=[0.0] * n, foldX=[0.0] * n, foldV=[0.0] * n, hz=hz))
        abre, room = abre + [[0.0, 0.0]], room + [1.0]
        abre_hz.append((1.5 + (0.75 - 1.5) * abs(c["out"])) * p["peso"])
        rest_ok.append(_cabe(c, med, [0.0] * n, [0.0] * n, 0, min_z0))
    dt, cuadros = 1 / fps, []
    for f in range(math.ceil(segundos * fps) + 1):
        u = f * dt
        intent, body = plan(u)
        body = dict(dict(giro=0.0, avance=0.0, subida=0.0, sacudida=0.0), **body)
        m = mezcla_paso(st, intent, body, dt)
        turn = 0.15 * clamp(body["giro"], -3, 3) * p["latigo"]
        run = 0.15 * clamp(body["avance"], 0, 3) * p["latigo"]
        vert = (0.09 * st["rise"] + 0.025 * st["accel"]) * p["latigo"]
        abierto_pedido = clamp(intent.get("abanico", 0.0), 0, 1.5)
        fans, folds = [], []
        for i, c in enumerate(colas):
            abierto = resorte(abre[i], abierto_pedido, dt, abre_hz[i], 0.5)
            df = turn * c["turnFan"] + run * c["backFan"] - vert * c["upFan"]
            dg = turn * c["turnFold"] + run * c["backFold"] - vert * c["upFold"]
            ft, gt = objetivos(c, m, abierto, df, dg, p, INICIO + u)
            ch = cadenas[i]
            if f > 0:
                cadena_paso(ch, ft, gt, p["rebote"], dt)
            else:  # Cadena.reset: arranca ya en su pose
                ch["fanX"], ch["foldX"] = list(ft), list(gt)
                for j in range(c["n"]):
                    _limitar(ch, j)
            fans, folds = fans + [list(ch["fanX"])], folds + [list(ch["foldX"])]
        separar(colas, fans, gaps)
        wrap = clamp(m["envolver"] + m["enroscar"], 0, 1)
        min_z = med["floor"] + med["unit"] * (0.3 + (0.04 - 0.3) * wrap)
        angulos, max_joint, at, min_tip = {}, 0.0, [], math.inf
        for i, c in enumerate(colas):
            if rest_ok[i]:
                room[i] = min(lugar(c, med, fans[i], folds[i], min_z), room[i] + dt * 2)
            fs, gs = [], []
            for j, hueso in enumerate(c["huesos"]):
                a, b = fans[i][j] * room[i], folds[i][j] * room[i]
                size = math.hypot(a, b)
                if size > MAX_JOINT:
                    a, b = a * MAX_JOINT / size, b * MAX_JOINT / size
                angulos[hueso] = (a, b)
                max_joint = max(max_joint, math.hypot(a, b))
                fs, gs = fs + [a], gs + [b]
            at.append(c["angle"] + sum(fs))
            min_tip = min(min_tip, (punta(c, fs, gs)[1][2] - med["floor"]) / med["unit"])
        cuadros.append(dict(u=u, angulos=angulos, maxJoint=max_joint, minTip=min_tip, room=list(room),
                            minGap=min([b - a for a, b in zip(at, at[1:])], default=math.inf)))
    return cuadros


def giro_tramo(med, hueso, fan, fold):
    """El Transform que escribe Colas (fan alrededor de adelante, fold alrededor del eje de la
    cola), en los ejes del cuerpo."""
    c = next(c for c in med["colas"] if hueso in c["huesos"])
    return rot(ADE, fan) @ rot(c["fold_axis"], fold)
