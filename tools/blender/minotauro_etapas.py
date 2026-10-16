r"""
Minotauro etapas 2, 3 y 4 sobre la base del becerro (minotauro_e1.py), mismos huesos:
    E2 joven      más alto, cabeza menos grande, cuernos medianos, tirante de cuero
    E3 adulto     musculoso, hocico largo, cuernos grandes con punta de oro, cejas bravas,
                  hombrera de oro con púas, brazaletes dobles
    E4 final      enorme, pelaje negro con grietas de lava, ojos de fuego, cuernos enormes,
                  dos hombreras, collar de oro
Se arma con los bloques del becerro (más músculo, menos panza, hocico más largo, cuernos y
ojos por etapa) y después se DEFORMA todo el espacio (piernas y tronco más largos, hombros
más anchos, brazos más largos): malla, piezas y articulaciones con la misma función, así el
esqueleto sigue calzando. Las articulaciones se guardan en la escena (scene["puntos"]).
Requiere criaturas.py y minotauro_e1.py (exec antes). construir_minotauro_etapa(n).
"""
import json

ETAPAS = {
    2: dict(K=1.0, piernas=1.3, tronco=1.2, ancho=1.06, hombros=1.18, musculo=1.12, panza=0.9,
            hocico=1.12, cuerno=1.6, ojo=0.86, ceja=0.4, pelo=(0.2, 0.062, 0.024),
            osc=(0.06, 0.02, 0.01), crema=(0.68, 0.4, 0.2), hocico_col=(0.75, 0.42, 0.3),
            extras={"tirante"}, ojos="ambar"),
    3: dict(K=0.9, piernas=1.42, tronco=1.3, ancho=1.14, hombros=1.36, musculo=1.32, panza=0.82,
            hocico=1.22, cuerno=2.1, ojo=0.72, ceja=0.8, pelo=(0.11, 0.035, 0.015),
            osc=(0.035, 0.012, 0.007), crema=(0.5, 0.27, 0.13), hocico_col=(0.55, 0.3, 0.2),
            extras={"tirante", "hombrera", "bracera", "punta_oro"}, ojos="ambar"),
    4: dict(K=0.84, piernas=1.5, tronco=1.36, ancho=1.2, hombros=1.5, musculo=1.48, panza=0.78,
            hocico=1.28, cuerno=2.6, ojo=0.64, ceja=1.0, pelo=(0.04, 0.014, 0.01),
            osc=(0.014, 0.006, 0.005), crema=(0.16, 0.06, 0.035), hocico_col=(0.2, 0.08, 0.06),
            extras={"hombrera", "hombrera2", "collar", "bracera", "punta_oro", "lava"}, ojos="lava"),
}
E = {}
ZH, ZS, ZN = 0.98, 1.76, 1.9  # cadera, hombro y cuello (coordenadas del becerro)
LAVA = (1.0, 0.32, 0.04)


def dy_hocico():
    return -(E["hocico"] - 1) * 0.42


def preparar(n):
    global K_CABEZA, PELO, PELO_OSC, CREMA, HOCICO
    E.clear()
    E.update(ETAPAS[n])
    E["n"] = n
    K_CABEZA = E["K"]
    PELO, PELO_OSC, CREMA, HOCICO = E["pelo"], E["osc"], E["crema"], E["hocico_col"]
    for k in PUNTOS:
        p = P_ORIG[k].copy()
        if k in ("menton", "boca"):
            p.y += dy_hocico()
        PUNTOS[k] = H(p) if k in ("cabeza", "coronilla", "bisagra", "menton", "boca", "oreja", "oreja_punta") else p


def cuerpo_bloques():
    m, pz = E["musculo"], E["panza"]
    b = [
        masa("Pelvis", (0, 0.03, 1.02), (0.44, 0.38, 0.3)),
        masa("Panza", (0, -0.07, 1.27), (0.5 * pz, 0.46 * pz, 0.42)),
        masa("Pecho", (0, -0.02, 1.6), (0.46 * m ** 0.5, 0.36 * m ** 0.6, 0.3)),
        masa("Hombros", (0, 0.03, 1.75), (0.5 * m ** 0.5, 0.3, 0.17 * m ** 0.5)),
        masa("Cuello", (0, -0.02, 1.9), (0.26 * m ** 0.7, 0.24 * m ** 0.6, 0.16)),
        masa("Trapecio", (0, 0.1, 1.84), (0.32 * m ** 0.6, 0.2, 0.12 * m)),
    ]
    b += simetrico(lambda s: [
        masa(f"Deltoide{s}", (s * 0.44, 0.0, 1.73), (0.17 * m, 0.17 * m, 0.17 * m)),
        masa(f"Pectoral{s}", (s * 0.19, -0.28, 1.6), (0.2 * m ** 0.7, 0.1 * m, 0.15 * m ** 0.6)),
        masa(f"Gluteo{s}", (s * 0.2, 0.18, 1.0), (0.24, 0.2, 0.22)),
        masa(f"Muslo{s}", (s * 0.28, -0.04, 0.78), (0.2 * m ** 0.7, 0.21 * m ** 0.7, 0.27)),
        masa(f"Pantorrilla{s}", (s * 0.29, 0.03, 0.38), (0.14 * m ** 0.7, 0.15 * m ** 0.7, 0.19)),
        masa(f"Biceps{s}", (s * 0.55, 0.0, 1.55), (0.16 * m, 0.16 * m, 0.21), (0, s * -22, 0)),
        masa(f"Antebrazo{s}", (s * 0.66, -0.01, 1.24), (0.17 * m ** 0.8, 0.17 * m ** 0.8, 0.2), (0, s * -10, 0)),
        masa(f"Mano{s}", (s * 0.71, -0.07, 0.95), (0.17, 0.16, 0.16)),
    ])
    b += simetrico(lambda s: [
        piel(f"Brazo{s}", [(s * P_ORIG["hombro"].x, 0.0, P_ORIG["hombro"].z, 0.13), (s * 0.63, 0.03, 1.4, 0.11),
                           (s * 0.69, -0.04, 1.1, 0.1)]),
        piel(f"Pierna{s}", [(s * 0.27, 0.0, 0.96, 0.19), (s * 0.29, -0.06, 0.54, 0.14),
                            (s * 0.29, 0.02, 0.2, 0.12), (s * 0.29, -0.02, 0.1, 0.13)]),
    ])
    for s in (1, -1):
        for i, dx in enumerate((-0.07, 0.0, 0.07)):
            x = s * (0.72 + dx * 0.4)
            y = -0.13 + abs(dx) * 0.4
            b.append(piel(f"Dedo{s}{i}", [(x + s * dx * 0.3, y, 0.92, 0.055), (x + s * dx * 0.5, y - 0.06, 0.84, 0.05),
                                          (x + s * dx * 0.55, y - 0.04, 0.77, 0.042)], subdiv=1))
        b.append(piel(f"Pulgar{s}", [(s * 0.62, -0.13, 1.0, 0.05), (s * 0.6, -0.2, 0.95, 0.042)], subdiv=1))
    b.append(piel("Cola", [(0, 0.3, 1.04, 0.07), (0, 0.5, 0.92, 0.05), (0, 0.62, 0.74, 0.04),
                           (0, 0.68, 0.56, 0.035), (0, 0.7, 0.48, 0.03)], subdiv=1))
    for o in cabeza_bloques():
        o.location = H(o.location)
        o.scale = o.scale * K_CABEZA
        b.append(o)
    return b


def cabeza_bloques():
    dy, c = dy_hocico(), E["ceja"]
    b = [
        masa("Craneo", (0, -0.04, 2.38), (0.5, 0.45, 0.42)),
        masa("Frente", (0, -0.2, 2.47 - 0.03 * c), (0.4, 0.3, 0.28)),
        masa("Carrillos", (0, -0.22 + dy * 0.4, 2.18), (0.47, 0.34 + abs(dy) * 0.3, 0.26)),
        masa("Hocico", (0, -0.42 + dy, 2.12), (0.36, 0.27 + abs(dy) * 0.4, 0.22), (-6, 0, 0)),
        masa("Morro", (0, -0.6 + dy, 2.13), (0.31, 0.13, 0.18)),
        masa("Nuca", (0, 0.12, 2.22), (0.38, 0.32, 0.3)),
    ]
    b += simetrico(lambda s: [
        # Cejas: con la etapa bajan hacia el centro (cara brava) y tapan un poco el ojo.
        masa(f"Ceja{s}", (s * (0.24 - 0.03 * c), -0.42, 2.6 - 0.07 * c), (0.16 + 0.03 * c, 0.1, 0.06 + 0.02 * c),
             (0, s * (-12 - 14 * c), s * (-18 + 30 * c))),
        masa(f"Mejilla{s}", (s * 0.3, -0.34 + dy * 0.5, 2.22), (0.16, 0.14, 0.13)),
    ])
    return b


def colores_cuerpo(pos, nrm):
    x, y, z = pos
    dy = dy_hocico()
    c = PELO
    c = mezcla(c, PELO_OSC, max(0.0, nrm.y) * 0.35 * (1 if z > 0.9 else 0.4))
    panza = cerca(pos, (0, -0.42, 1.36), 0.42, 0.55) * suave(-nrm.y * 1.6 + 0.2)
    c = mezcla(c, CREMA, panza * (0.8 if E["n"] < 4 else 0.5))
    if 1.45 < z < 1.95 and abs(x) > 0.28:
        d = (V((abs(x), y, z)) - V((0.46, 0.0, 1.76))).length
        marca = max(0.0, 1 - abs(d - 0.12) / 0.022) + max(0.0, 1 - abs(d - 0.2) / 0.018) * (1 if z > 1.68 else 0)
        brillo = LAVA if "lava" in E["extras"] else (1.0, 0.5, 0.08)
        c = mezcla(c, brillo, min(1.0, marca) * suave(nrm.z * 2 + abs(nrm.x)))
    c = mezcla(c, PELO_OSC, suave((0.36 - z) / 0.18))
    if abs(x) > 0.5 and z < 1.6:
        c = mezcla(c, PELO_OSC, suave((1.18 - z) / 0.2))
    if "lava" in E["extras"] and 0.15 < z < 1.85:
        v = abs(noise.noise(V(pos) * 3.2))
        c = mezcla(c, LAVA, max(0.0, 1 - v / 0.045))
    if z > 1.85:
        hocico = cerca(pos, H((0, -0.5 + dy, 2.12)), 0.5, 0.5) * suave(-nrm.y * 1.5 + 0.5)
        c = mezcla(c, HOCICO, hocico)
        c = mezcla(c, mezcla(ROSA, PELO_OSC, (E["n"] - 1) / 3), cerca(pos, H((0, -0.72 + dy, 2.15)), 0.23, 0.35))
        if E["n"] < 4:
            c = mezcla(c, CREMA, cerca(pos, H((0, -0.34, 2.62)), 0.2, 0.3) * suave(-nrm.y * 2))
        if z < H((0, 0, 2.03)).z and nrm.z < -0.35 and y < -0.3:
            c = mezcla(c, BOCA, suave((-nrm.z - 0.35) * 3))
    v = 0.9 + 0.2 * ruido(pos, 5.0)
    return tuple(min(1.0, k * v) for k in c)


def cuerno(s):
    c = E["cuerno"]
    base = V((s * 0.27, -0.06, 2.66))
    curva = [V((0, 0, 0)), V((s * 0.13, -0.02, 0.12)), V((s * 0.23, -0.06, 0.27)),
             V((s * 0.25, -0.12, 0.4)), V((s * 0.21, -0.16, 0.46))]
    radios = [0.1, 0.085, 0.065, 0.04, 0.008]
    g = c ** 0.5
    pts = [tuple(base + d * c) + (r * g,) for d, r in zip(curva, radios)]
    h = piel(f"Cuerno{s}", pts, subdiv=2)
    aplicar(h)
    largo = (curva[-1] * c).length
    oro = "punta_oro" in E["extras"]

    def color(p, n):
        t = (V(p) - base).length / max(largo, 1e-3)
        col = mezcla(MARFIL, (0.98, 0.93, 0.82), suave((t - 0.3) / 0.5))
        if E["n"] >= 3:
            col = mezcla((0.3, 0.22, 0.14), col, suave((t - 0.1) / 0.5))  # base oscura
        if oro and t > 0.78:
            col = ORO
        return col
    pintar(h, color)
    return h


def ojo(s):
    k = E["ojo"]
    centro = V((s * 0.245, -0.4, 2.43 - 0.03 * E["ceja"]))
    frente = V((s * 0.38, -1.0, 0.04)).normalized()
    o = masa(f"Ojo{s}", tuple(centro), (0.15 * k, 0.13 * k, 0.165 * k), segmentos=48)
    aplicar(o)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    arriba = V((0, 0, 1))
    derecha = frente.cross(arriba).normalized()
    arriba = derecha.cross(frente).normalized()
    lava = E["ojos"] == "lava"

    def color(p, n):
        d = (V(p) - centro).normalized()
        ang = math.acos(max(-1.0, min(1.0, d.dot(frente))))
        lx, ly = d.dot(derecha), d.dot(arriba)
        if ang > 0.78:
            return (0.25, 0.03, 0.02) if lava else (0.92, 0.92, 0.95)
        if ang > 0.7:
            return (0.08, 0.03, 0.01)
        if lava:
            if abs(lx) < 0.07 and ang < 0.6:
                return (0.02, 0.0, 0.0)  # pupila de rendija
            return mezcla((1.0, 0.9, 0.3), (1.0, 0.3, 0.02), ang / 0.7)
        if ang < 0.3:
            c = (0.01, 0.006, 0.004)
        else:
            c = mezcla((1.0, 0.5, 0.05), (0.5, 0.15, 0.02), (ang - 0.3) / 0.4)
            c = mezcla(c, (0.3, 0.08, 0.01), suave(ly * 2.5))
        if (lx + s * 0.22) ** 2 + (ly - 0.28) ** 2 < 0.014:
            return (1.0, 1.0, 1.0)
        return c
    pintar(o, color)
    return o


def mandibula():
    dy = dy_hocico()
    m = masa("Mandibula", (0, -0.4 + dy, 1.97), (0.27, 0.22 + abs(dy) * 0.5, 0.09), (-4, 0, 0))
    aplicar(m)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    pintar(m, lambda p, n: LENGUA if n.z > 0.5 else mezcla(HOCICO, PELO, suave((p.y + 0.3 - dy) / 0.15)))
    return m


def hombrera(s):
    piezas = [masa(f"HombreraBase{s}", (s * 0.48, 0.0, 1.84), (0.27, 0.27, 0.16), (0, s * 28, 0), segmentos=32)]
    for i in range(3):
        x0, y0 = s * (0.4 + 0.1 * i), -0.12 + 0.12 * i
        piezas.append(piel(f"Pua{s}{i}", [(x0, y0, 1.94, 0.06), (x0 + s * 0.06, y0, 2.18, 0.008)], subdiv=1))
    o = unir(f"Hombrera{s}", piezas)
    pintar(o, lambda p, n: ORO if p.z < 1.97 else (0.85, 0.82, 0.78))
    return o


def extras():
    """Piezas que no tiene el becerro: (objeto, hueso, ¿dorado?)."""
    x = E["extras"]
    out = []
    if "tirante" in x:
        out.append((anillo("Tirante", (0, -0.01, 1.45), 0.56, 0.045, rot=(0, 50, 0), escala=(1, 0.82, 1), color=CUERO),
                    "Columna", False))
    if "hombrera" in x:
        out.append((hombrera(1), "BrazoIzq", True))
    if "hombrera2" in x:
        out.append((hombrera(-1), "BrazoDer", True))
    if "collar" in x:
        out.append((anillo("Collar", (0, -0.03, 1.86), 0.33, 0.06, escala=(1.05, 0.95, 1)), "Pecho", True))
    if "bracera" in x:
        for s, lado in ((1, "Izq"), (-1, "Der")):
            out.append((anillo(f"Bracera{s}", (s * 0.675, -0.02, 1.24), 0.15, 0.04, rot=(0, s * -8, 0)),
                        f"Antebrazo{lado}", True))
    return out


def deformar(p):
    """Espacio del becerro -> espacio de la etapa: piernas y tronco más largos, hombros anchos."""
    L, T = E["piernas"], E["tronco"]
    a, hs = E["ancho"], E["hombros"]
    cuello = 1 + (hs - 1) * 0.45
    x, y, z = p.x, p.y, p.z

    def ancho(zz):
        if zz <= ZH:
            return 1 + (a - 1) * (0.7 + 0.3 * suave((zz - (ZH - 0.25)) / 0.25))
        if zz <= ZS:
            return a + (hs - a) * suave((zz - ZH) / (ZS - ZH))
        if zz <= ZN:
            return hs + (cuello - hs) * suave((zz - ZS) / (ZN - ZS))
        return cuello + (1 - cuello) * suave((zz - ZN) / 0.25)

    def alto(zz):
        if zz <= ZH:
            return zz * L
        if zz <= ZN:
            return ZH * L + (zz - ZH) * T
        return ZH * L + (ZN - ZH) * T + (zz - ZN)

    w = ancho(z)
    prof = 1 + (w - 1) * 0.55
    tronco = V((x * w, y * prof, alto(z)))
    # Brazos: se corren con el hombro y se alargan desde él.
    peso = suave((abs(x) - 0.44) / 0.12) * (1 if 0.6 < z < 2.0 else 0)
    if peso <= 0:
        return tronco
    s = 1 if x >= 0 else -1
    largo = T * 0.6 + L * 0.4
    brazo = V((s * (abs(x) + 0.45 * (ancho(ZS) - 1)), y, alto(ZS) - (ZS - z) * largo))
    return tronco.lerp(brazo, peso)


def construir_minotauro_etapa(n, voxel=0.014):
    preparar(n)
    nombre = f"MinoE{n}"
    cuerpo = fusionar(f"{nombre}_Cuerpo", cuerpo_bloques(), voxel=voxel, suavizado=24)
    detalle(cuerpo, fuerza=0.006 + 0.002 * n, escala=0.035)
    pintar(cuerpo, colores_cuerpo)
    pelaje = mat_pelaje(f"{nombre}_Pelaje", rugosidad=0.8, bulto=0.35, escala_pelo=260.0)
    asignar(cuerpo, pelaje)
    brillo = mat_simple(f"{nombre}_Brillo", (1, 1, 1), 0.2); _vc(brillo)
    metal = mat_simple(f"{nombre}_Oro", (1, 1, 1), 0.3, metal=1.0); _vc(metal)
    cuero = mat_simple(f"{nombre}_Cuero", (1, 1, 1), 0.75); _vc(cuero)
    partes = {cuerpo: None}
    cabeza = []
    for s, lado in ((1, "Izq"), (-1, "Der")):
        cabeza.append(asignar(oreja(s), pelaje)); partes[cabeza[-1]] = f"Oreja{lado}"
        cabeza.append(asignar(cuerno(s), brillo)); partes[cabeza[-1]] = "Cabeza"
        cabeza.append(asignar(ojo(s), brillo)); partes[cabeza[-1]] = "Cabeza"
        if "punta_oro" not in E["extras"]:
            g = E["cuerno"]
            cabeza.append(asignar(anillo(f"AnilloCuerno{s}", (s * (0.27 + 0.18 * g), -0.06 - 0.05 * g, 2.66 + 0.22 * g),
                                         0.075 * g ** 0.5, 0.025 * g ** 0.5, rot=(0, s * 30, 0)), metal))
            partes[cabeza[-1]] = "Cabeza"
        partes[asignar(pezuna(s), brillo)] = f"Pie{lado}"
    cabeza.append(asignar(mechon(), pelaje)); partes[cabeza[-1]] = "Cabeza"
    cabeza.append(asignar(mandibula(), pelaje)); partes[cabeza[-1]] = "Mandibula"
    partes[asignar(borla(), pelaje)] = "Cola3"
    for a in accesorios():
        hueso = "Cadera"
        if a.name.startswith("Brazalete"):
            hueso = "AntebrazoDer" if a.name.endswith("-1") else "AntebrazoIzq"
        elif a.name == "AroNariz":
            hueso = "Cabeza"
            for v in a.data.vertices:
                v.co.y += dy_hocico()
            cabeza.append(a)
        dorado = a.name == "Hebilla" or a.name.startswith(("Brazalete", "Aro", "Remache"))
        partes[asignar(a, metal if dorado else cuero)] = hueso
    agrandar(cabeza)
    for obj, hueso, dorado in extras():
        partes[asignar(obj, metal if dorado else cuero)] = hueso
    # Deformar todo (malla, piezas y articulaciones) con la misma función.
    for o in partes:
        for v in o.data.vertices:
            v.co = deformar(v.co)
        o.data.update()
    puntos = {k: list(deformar(v)) for k, v in PUNTOS.items()}
    bpy.context.scene["puntos"] = json.dumps(puntos)
    bpy.context.scene["nombre"] = f"MinotauroE{n}"
    for o, hueso in partes.items():
        o["hueso"] = hueso or ""
    return list(partes), puntos
