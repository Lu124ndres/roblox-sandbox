r"""
El buscador de poses de contacto del Zorro de agua v2: resolver() lleva un punto de una pieza a otro
(la pata a la oreja) con descenso por coordenadas sobre matrices(), y choque() aproxima cuánto se
meten las piezas (por cajas) para que lo esquive; lo exacto lo revisa revisar(). Lo carga
zorro_v2_poses_cuerpo.py.
"""
import copy


def _aplicar(base, vals):
    e = copy.deepcopy(base)
    e.setdefault("huesos", {})
    for k, x in vals.items():
        if "." in k:  # "Hueso.eje": 0 cabeceo, 1 giro, 2 alabeo
            h, eje = k.split(".")
            t = list(e["huesos"].get(h, locales({k2: v2 for k2, v2 in base.items() if k2 != "huesos"}).get(h, (0, 0, 0))))
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
    paso_ = {k: (hi - lo) / 4 for k, (lo, hi, _) in libres.items()}
    total = lambda m: costo(m) + k_choque * choque(m)
    mejor = total(matrices(_aplicar(base, vals)))
    for _ in range(vueltas):
        mejoro = False
        for k, (lo, hi, _) in libres.items():
            for d in (paso_[k], -paso_[k]):
                prueba = dict(vals, **{k: max(lo, min(hi, vals[k] + d))})
                c = total(matrices(_aplicar(base, prueba)))
                if c < mejor - 1e-7:
                    vals, mejor, mejoro = prueba, c, True
                    break
        if not mejoro:
            paso_ = {k: p / 2 for k, p in paso_.items()}
            if max(paso_.values()) < 1e-3:
                break
    e = _aplicar(base, vals)
    return e, costo(matrices(e)), vals
