r"""
Poses del cuerpo del Zorro de agua v2 con la cuenta de src/shared/Zorro/Pose.luau (Pose.apply, con
los resortes de la cabeza y las orejas ya asentados) y un buscador de poses de contacto. Lo carga
zorro_v2_poses.py con exec (usa HUESOS, matrices(), V y C de minotauro_v2_poses.py).

Una entrada de pose es una tabla con las claves de Pose.luau (lean, lookYaw, jaw, bow, crouch,
stepFL...) y, además:
    huesos  {hueso: (cabeceo, giro, alabeo)} que reemplazan lo de Pose.apply: lo que el juego todavía
            no pide (sentarse, echarse, rascarse, lamerse, párpados, punta de la oreja)
    dy      cuánto sube (+) o baja la base, en fracción del alto (como pose.dy en Zorro/init)
    t       la hora, solo para el temblor de la sacudida (sin(t * 38))
    colas   {hueso: (fan, fold)}: lo que escribe Zorro/Colas en cada tramo (zorro_v2_colas_paso.py)
resolver() busca los ángulos que llevan un punto de una pieza a otro (la pata a la oreja): descenso
por coordenadas sobre matrices(), sin mirar choques (eso lo revisa después revisar()).
"""
import copy


BOW_BEND = 1.5  # Pose.luau: cuánto doblan las delanteras en la reverencia (por bow)
CROUCH_DROP = 0.035  # Zorro/init: cuánto baja la base al agacharse (fracción del alto, por crouch)


def _pata(r, delantera, s, lift, bend):
    """leg() de Pose.luau (swing siempre 0 en Pose.apply)."""
    if delantera:
        r[f"Hombro{s}"] = (0, 0, 0)
        r[f"Brazo{s}"] = (0.35 * lift - bend * 0.5, 0, 0)
        r[f"Antebrazo{s}"] = (-1.1 * lift + bend * 0.9, 0, 0)
        r[f"Mano{s}"] = (-0.8 * lift - bend * 0.4, 0, 0)
    else:
        r[f"Muslo{s}"] = (0.3 * lift + bend * 0.5, 0, 0)
        r[f"Pierna{s}"] = (-0.4 * lift - bend * 0.9, 0, 0)
        r[f"Tobillo{s}"] = (0.7 * lift + bend * 0.8, 0, 0)
        r[f"Pie{s}"] = (-0.5 * lift - bend * 0.4, 0, 0)


def locales(e):
    """Pose.apply: hueso -> (cabeceo, giro, alabeo) en radianes (sin las colas)."""
    if not e:
        return {}
    v = lambda k: e.get(k, 0.0)
    temblor = math.sin(v("t") * 38) * 0.22 * v("shake")
    lean, breathe, bow, crouch, sway = v("lean"), v("breathe"), v("bow"), v("crouch"), v("sway")
    yaw, pitch, tilt = v("lookYaw"), v("lookPitch") + bow * 0.5, v("tilt")
    r = {
        "Cadera": (-bow * 0.2 + crouch * 0.05, 0, sway + temblor),
        "Columna": (lean * 0.4 + breathe - bow * 0.25, 0, -sway * 0.4 - temblor * 0.8),
        "Pecho": (lean * 0.4 + breathe * 0.7 - bow * 0.2, yaw * 0.1, temblor * 0.6),
        "Cuello1": (pitch * 0.35, yaw * 0.3, tilt * 0.2 - temblor * 0.5),
        "Cuello2": (pitch * 0.3, yaw * 0.3, tilt * 0.3),
        "Cabeza": (pitch * 0.35 - breathe * 0.4, yaw * 0.4, tilt * 0.5 + temblor * 0.4),
        "Mandibula": (-0.6 * max(-0.1, min(1.1, v("jaw"))), 0, 0),
    }
    for s, k in (("Izq", "earL"), ("Der", "earR")):
        lado = 1 if s == "Izq" else -1  # -(rig.side): la Izq está a la izquierda (side -1)
        r[f"Oreja{s}"] = (-v(k) * 0.6, 0, v(k) * 0.3 * lado + temblor * lado)
    _pata(r, True, "Izq", v("stepFL"), bow * BOW_BEND + crouch)
    _pata(r, True, "Der", v("stepFR"), bow * BOW_BEND + crouch)
    _pata(r, False, "Izq", v("stepHL"), crouch - bow * 0.15)
    _pata(r, False, "Der", v("stepHR"), crouch - bow * 0.15)
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


def _aplicar(base, vals):
    e = copy.deepcopy(base)
    e.setdefault("huesos", {})
    for k, x in vals.items():
        if "." in k:  # "Hueso.eje": 0 cabeceo, 1 giro, 2 alabeo
            h, eje = k.split(".")
            t = list(e["huesos"].get(h, (0, 0, 0)))
            t[int(eje)] = x
            e["huesos"][h] = tuple(t)
        else:
            e[k] = x
    return e


def preparar_choques(cruces_reposo):
    """Para choque(): las muestras (vértices y centros de caras) y la caja de cada pieza del cuerpo
    en reposo, achicada PENETRA celdas. Se saltan los pares padre-hijo y los que ya se tocan en
    reposo (como revisar())."""
    global MUESTRAS, CAJAS, PARES
    MUESTRAS, CAJAS = {}, {}
    for n in HUESOS:
        if n.startswith("Cola"):
            continue
        me = bpy.data.objects[n].data
        vs = np.array([tuple(v.co) for v in me.vertices])
        pts = np.vstack([vs, [tuple(p.center) for p in me.polygons]])
        MUESTRAS[n] = np.hstack([pts, np.ones((len(pts), 1))]).T
        CAJAS[n] = (vs.min(axis=0) + PENETRA * C, vs.max(axis=0) - PENETRA * C)
    nombres = list(CAJAS)
    PARES = [(a, b) for i, a in enumerate(nombres) for b in nombres[i + 1:]
             if HUESOS[a][0] != b and HUESOS[b][0] != a and (a, b) not in cruces_reposo
             and (b, a) not in cruces_reposo]


def choque(m):
    """Cuánto se meten las piezas del cuerpo unas en otras (suma de hondos, BU), aproximando cada
    pieza por su caja: barato, para que resolver() esquive los choques."""
    total = 0.0
    mat = {n: np.array(m[n]) for n in CAJAS}
    inv = {n: np.linalg.inv(x) for n, x in mat.items()}
    for a, b in PARES:
        for x, y in ((a, b), (b, a)):
            p = (inv[y] @ mat[x] @ MUESTRAS[x])[:3]
            lo, hi = CAJAS[y]
            d = np.minimum(p - lo[:, None], hi[:, None] - p).min(axis=0)
            total += float(d[d > 0].sum())
    return total


def resolver(base, libres, costo, vueltas=60, k_choque=0.3, inicio=None):
    """libres {clave: (mín, máx, inicio)}; costo(m) -> número (BU), al que se suma choque(m) x
    k_choque. `inicio` reemplaza los valores de arranque. Devuelve (entrada, costo sin los
    choques, valores)."""
    vals = dict({k: ini for k, (_, _, ini) in libres.items()}, **(inicio or {}))
    paso = {k: (hi - lo) / 4 for k, (lo, hi, _) in libres.items()}
    total = lambda m: costo(m) + k_choque * choque(m)
    mejor = total(matrices(_aplicar(base, vals)))
    for _ in range(vueltas):
        mejoro = False
        for k, (lo, hi, _) in libres.items():
            for d in (paso[k], -paso[k]):
                prueba = dict(vals, **{k: max(lo, min(hi, vals[k] + d))})
                c = total(matrices(_aplicar(base, prueba)))
                if c < mejor - 1e-7:
                    vals, mejor, mejoro = prueba, c, True
                    break
        if not mejoro:
            paso = {k: p / 2 for k, p in paso.items()}
            if max(paso.values()) < 1e-3:
                break
    e = _aplicar(base, vals)
    return e, costo(matrices(e)), vals
