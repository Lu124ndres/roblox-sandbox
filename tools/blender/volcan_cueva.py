r"""
Versión 4 del volcán en bloques: la montaña cerrada con la cueva del gigante adentro y el arco
como única entrada (la forma está en volcan_cueva_forma.py). Mismo estilo que las versiones
anteriores (volcan_bloques.py): celda de 4 x 4, escalones de 2, bisel de 0.4 en el borde de
arriba, la paleta y la lava en mallas aparte (en Roblox, Neon).

Con techo ya no alcanza una altura por columna: cada columna es una lista de tramos sólidos
(por ejemplo [fondo, piso del lago] y [techo de la cueva, cima]). Las caras que se ven salen de
restar a cada columna los tramos de su vecina; donde no hay vecina está el fondo del mar.
    tapas      la cara de arriba de cada tramo, juntadas en rectángulos (greedy), con bisel
    techos     la cara de abajo de los tramos que tienen aire debajo (la bóveda), en rectángulos
    lados      lo que queda al aire entre vecinas, en tiras
Lejos y en la bóveda las alturas se toman en bloques de 2 x 2 o 3 x 3 columnas.

Mallas por sector (SECTOR x SECTOR columnas, menos de 20,000 triángulos cada una):
    Volcan_<f>_<c>        la montaña por fuera
    VolcanCueva_<f>_<c>   el piso, las paredes y el techo de la cueva y del túnel
    VolcanLava / VolcanCuevaLava   la lava de afuera (copa y desbordes) y la de adentro

Uso (desde la raíz del repo):
    blender -b --factory-startup --python tools/blender/volcan_cueva.py
Salidas: assets/blender/volcan_v2/volcan_bloques_4c.blend y renders en renders/volcan_v2d/.
El agua, el puente, la isla, la caja del arco y las luces de la cueva van en la colección
Referencia (no se exportan).
"""
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SOLO_FUNCIONES = True
sys.argv = [a for a in sys.argv if a != "--"]  # volcan_bloques.py no tiene que ver --forma
exec(open(os.path.join(HERE, "volcan_bloques.py"), encoding="utf-8").read(), globals())
exec(open(os.path.join(HERE, "volcan_cono_forma.py"), encoding="utf-8").read(), globals())
exec(open(os.path.join(HERE, "volcan_cueva_forma.py"), encoding="utf-8").read(), globals())

BLEND = os.path.join(RAIZ, "assets", "blender", "volcan_v2", "volcan_bloques_4c.blend")
RENDERS = os.path.join(RAIZ, "renders", "volcan_v2d")
COLORES["techo"] = ((74, 62, 68), (52, 44, 50))
NOMBRES[:] = [f"{c}_{l}" for c in COLORES for l in CARAS]
N = int(math.ceil(R_MAX / CELDA))
DIRECCIONES = ((0, -1), (1, 0), (0, 1), (-1, 0))
SUELO_MAR = [(FONDO, MAR)]  # lo que hay donde no hay columna


class Tramo:
    def __init__(self, lo, hi, arriba, lado, capa, abajo=None):
        self.lo, self.hi, self.arriba, self.lado, self.capa, self.abajo = lo, hi, arriba, lado, capa, abajo


class Columna:
    def __init__(self, tramos, cueva=False, piso=None, techo=None):
        self.tramos, self.cueva, self.piso, self.techo = tramos, cueva, piso, techo


def q(h):
    return round(h / ESCALON) * ESCALON


def bloque_columna(dx, dz):
    """Columnas por lado que comparten altura en (dx, dz) (volcan_pie_forma.py la cambia)."""
    return bloque_exterior(math.hypot(dx, dz))


def armar():
    """{(i, j): Columna}."""
    grilla = {}
    for i in range(-N, N):
        for j in range(-N, N):
            dx, dz = (i + 0.5) * CELDA, (j + 0.5) * CELDA
            rho = math.hypot(dx, dz)
            k = bloque_columna(dx, dz)
            i0, j0 = (i // k) * k, (j // k) * k
            # El borde (si hay montaña) por columna; la altura, la del bloque.
            afuera = exterior(dx, dz)
            if afuera is not None:
                afuera = exterior((i0 + k / 2) * CELDA, (j0 + k / 2) * CELDA) or afuera
            adentro = cueva(dx, dz)
            if afuera is None and adentro is None:
                continue
            if afuera is not None:
                alto, mat = q(afuera[0]), afuera[1]
                if mat in VARIANTES and variante(i0, j0):
                    mat = VARIANTES[mat]
            if adentro is None:
                grilla[(i, j)] = Columna([Tramo(FONDO, alto, mat, mat, "cima")])
                continue
            piso, mat_piso, techo_fijo = adentro
            piso = q(piso)
            if techo_fijo is None:  # la bóveda, en bloques de 2 x 2
                b0, b1 = (i // 2) * 2, (j // 2) * 2
                techo_alto = q(techo((b0 + 1) * CELDA, (b1 + 1) * CELDA, b0, b1))
                mat_techo = material_techo((b0 + 1) * CELDA, (b1 + 1) * CELDA)
            else:
                techo_alto, mat_techo = techo_fijo, "techo"
            tramos = [Tramo(FONDO, piso, mat_piso, mat_piso, "piso")]
            if afuera is not None:
                alto = max(alto, techo_alto + 18)  # la roca del techo nunca es una cáscara
                tramos.append(Tramo(techo_alto, alto, mat, mat, "cima", mat_techo))
            grilla[(i, j)] = Columna(tramos, True, piso, techo_alto)
    return grilla


def solidos(grilla, celda):
    col = grilla.get(celda)
    return [(t.lo, t.hi) for t in col.tramos] if col else SUELO_MAR


def restar(propios, ajenos):
    """Los pedazos de `propios` que no tapa ningún tramo de `ajenos`."""
    libres = []
    for lo, hi in propios:
        partes = [(lo, hi)]
        for alo, ahi in ajenos:
            nuevas = []
            for plo, phi in partes:
                if ahi <= plo or alo >= phi:
                    nuevas.append((plo, phi))
                    continue
                if alo > plo:
                    nuevas.append((plo, alo))
                if ahi < phi:
                    nuevas.append((ahi, phi))
            partes = nuevas
        libres += [(a, b) for a, b in partes if b - a > 0.01]
    return libres


def cubre(grilla, celda, lo, hi):
    return any(a <= lo and b >= hi for a, b in solidos(grilla, celda))


def sector(i, j):
    return ((j + N) // SECTOR, (i + N) // SECTOR)


class Mallas:
    """Las mallas de cada sector y las dos de lava, con su conteo de triángulos."""

    def __init__(self):
        self.porsector, self.lava, self.cueva_lava = {}, Malla(), Malla()

    def de(self, clase, sec):
        if clase == "lava":
            return self.lava
        if clase == "cueva_lava":
            return self.cueva_lava
        return self.porsector.setdefault((clase, sec), Malla())


def greedy(celdas):
    """celdas: {(i, j): clave} -> [(i, j, ancho, largo, clave)]."""
    restantes = set(celdas)
    rects = []
    for i, j in sorted(celdas, key=lambda c: (c[1], c[0])):
        if (i, j) not in restantes:
            continue
        clave = celdas[(i, j)]
        ancho = 1
        while (i + ancho, j) in restantes and celdas[(i + ancho, j)] == clave:
            ancho += 1
        largo = 1
        while all((i + k, j + largo) in restantes and celdas[(i + k, j + largo)] == clave for k in range(ancho)):
            largo += 1
        for k in range(ancho):
            for m in range(largo):
                restantes.discard((i + k, j + m))
        rects.append((i, j, ancho, largo, clave))
    return rects


def vecinas_borde(i, j, ancho, largo):
    return (
        [(i + k, j - 1) for k in range(ancho)],
        [(i + ancho, j + m) for m in range(largo)],
        [(i + k, j + largo) for k in range(ancho)],
        [(i - 1, j + m) for m in range(largo)],
    )


def tapa(malla, grilla, i, j, ancho, largo, alto, color):
    x0, x1, z0, z1 = i * CELDA, (i + ancho) * CELDA, j * CELDA, (j + largo) * CELDA
    b, hb = BISEL, alto - BISEL
    bisel = [any(not cubre(grilla, c, hb, alto + ESCALON) for c in vs) for vs in vecinas_borde(i, j, ancho, largo)]
    sx0, sx1 = (b if bisel[3] else 0.0), (b if bisel[1] else 0.0)
    sz0, sz1 = (b if bisel[0] else 0.0), (b if bisel[2] else 0.0)
    t = [punto(x0 + sx0, z0 + sz0, alto), punto(x1 - sx1, z0 + sz0, alto),
         punto(x1 - sx1, z1 - sz1, alto), punto(x0 + sx0, z1 - sz1, alto)]
    malla.cara(t, color, (0, 0, 1))
    e = [punto(x0, z0, hb), punto(x1, z0, hb), punto(x1, z1, hb), punto(x0, z1, hb)]
    afuera = [punto(0, -1, 1), punto(1, 0, 1), punto(0, 1, 1), punto(-1, 0, 1)]
    for k in range(4):
        if bisel[k]:
            malla.cara([e[k], e[(k + 1) % 4], t[(k + 1) % 4], t[k]], color, afuera[k])


def caras(grilla):
    mallas = Mallas()
    porsector = {}
    for celda in grilla:
        porsector.setdefault(sector(*celda), []).append(celda)
    for sec, celdas in porsector.items():
        # Tapas: la de afuera (cima) y el piso de la cueva, cada una en rectángulos.
        for capa, clase in (("cima", "exterior"), ("piso", "cueva")):
            claves = {}
            for c in celdas:
                for t in grilla[c].tramos:
                    if t.capa == capa:
                        claves[c] = (t.hi, t.arriba)
            for i, j, ancho, largo, (alto, mat) in greedy(claves):
                destino = ("cueva_lava" if clase == "cueva" else "lava") if mat == "lava" else clase
                tapa(mallas.de(destino, sec), grilla, i, j, ancho, largo, alto, f"{mat}_arriba")
        # Techos: la cara de abajo de la roca sobre la cueva.
        claves = {c: (t.lo, t.abajo) for c in celdas for t in grilla[c].tramos if t.abajo}
        for i, j, ancho, largo, (alto, mat) in greedy(claves):
            x0, x1, z0, z1 = i * CELDA, (i + ancho) * CELDA, j * CELDA, (j + largo) * CELDA
            m = mallas.de("cueva_lava" if mat == "lava" else "cueva", sec)
            m.cara([punto(x0, z0, alto), punto(x1, z0, alto), punto(x1, z1, alto), punto(x0, z1, alto)],
                   f"{mat}_arriba", (0, 0, -1))
        # Lados, en tiras: se juntan los tramos seguidos con el mismo alto y color.
        tiras = {}
        for (i, j) in celdas:
            col = grilla[(i, j)]
            for d, (di, dj) in enumerate(DIRECCIONES):
                vecina = (i + di, j + dj)
                otra = grilla.get(vecina)
                topes_vecina = [b for _, b in solidos(grilla, vecina)]
                for t in col.tramos:
                    for lo, hi in restar([(t.lo, t.hi)], solidos(grilla, vecina)):
                        arriba = hi - BISEL if abs(hi - t.hi) < 0.01 else hi
                        if any(abs(lo - b) < 0.01 for b in topes_vecina):
                            lo -= BISEL  # baja hasta el bisel de la tapa vecina: sin ranura
                        if arriba <= lo:
                            continue
                        medio = (lo + arriba) / 2
                        adentro = (col.cueva and medio < col.techo) or (
                            otra is not None and otra.cueva and otra.piso < medio < otra.techo)
                        clase, color = ("cueva" if adentro else "exterior"), f"{t.lado}_lado"
                        if adentro and not col.cueva and vena_pared(i, j):
                            clase, color = "cueva_lava", "lava_arriba"
                        linea, pos = (j, i) if d in (0, 2) else (i, j)
                        tiras.setdefault((d, linea, lo, arriba, color, clase), []).append(pos)
        for (d, linea, lo, arriba, color, clase), posiciones in tiras.items():
            posiciones.sort()
            inicio = previo = posiciones[0]
            for p in posiciones[1:] + [None]:
                if p is not None and p == previo + 1:
                    previo = p
                    continue
                lado_tira(mallas.de(clase, sec), d, linea, inicio, previo, lo, arriba, color)
                if p is not None:
                    inicio = previo = p
    return mallas


def lado_tira(malla, d, linea, p0, p1, lo, hi, color):
    di, dj = DIRECCIONES[d]
    if d in (0, 2):  # cara en z fija, de x = p0 a p1 + 1
        z = (linea + (1 if dj > 0 else 0)) * CELDA
        a, b = (p0 * CELDA, z), ((p1 + 1) * CELDA, z)
    else:  # cara en x fija, de z = p0 a p1 + 1
        x = (linea + (1 if di > 0 else 0)) * CELDA
        a, b = (x, p0 * CELDA), (x, (p1 + 1) * CELDA)
    malla.cara([punto(a[0], a[1], lo), punto(b[0], b[1], lo), punto(b[0], b[1], hi), punto(a[0], a[1], hi)],
               color, punto(di, dj, 0))


def construir_cueva():
    img = paleta()
    roca = material_paleta(img, "VolcanBloques")
    lava = material_paleta(img, "VolcanLava", emision=3.0)  # en Roblox: Neon
    grilla = armar()
    mallas = caras(grilla)
    informe = {"exterior": 0, "cueva": 0, "lava": 0}
    for (clase, (f, c)), m in sorted(mallas.porsector.items()):
        nombre = f"{'Volcan' if clase == 'exterior' else 'VolcanCueva'}_{f}_{c}"
        tris = m.tris()
        assert tris < LIMITE_TRIS, f"{nombre}: {tris}"
        informe[clase] += tris
        informe[nombre] = tris
        objeto(nombre, m, roca)
    for nombre, m in (("VolcanLava", mallas.lava), ("VolcanCuevaLava", mallas.cueva_lava)):
        tris = m.tris()
        assert tris < LIMITE_TRIS, f"{nombre}: {tris}"
        informe["lava"] += tris
        informe[nombre] = tris
        objeto(nombre, m, lava)
    return informe, grilla


# --- Revisión -------------------------------------------------------------------------------
def luz(nombre, donde, energia, color=(1.0, 0.45, 0.15), radio=6.0):
    l = bpy.data.objects.new(nombre, bpy.data.lights.new(nombre, "POINT"))
    l.data.energy = energia
    l.data.color = color
    l.data.shadow_soft_size = radio
    l.location = donde
    referencia(l)


def luces_cueva():
    """Lo que en el juego darían la lava en Neon y unas PointLight: para que no salga negra."""
    for k in range(8):
        a = math.radians(k * 45 + 10)
        luz(f"LavaCueva{k}", punto(170 * math.cos(a), 170 * math.sin(a), 90), 6e5)
    luz("LavaTecho", punto(0, 0, 200), 1.5e6, (1.0, 0.6, 0.3), 30)
    luz("Tunel", punto(0, -(FRENTE - 20), PASEO + 30), 8e4)


def fotos_cueva(cam, grilla):
    puente_inicio = -(math.hypot(*ISLA) - L["bridgeStartRadius"])
    foto(cam, "1_desde_la_isla", punto(-60, puente_inicio - 60, L["plateauHeight"] + 6), punto(0, -120, 210), 15)
    foto(cam, "2_aerea", punto(1150, -1500, 1000), punto(0, -120, 120), 30)
    paseo = L["craterCliffRadius"] + 12
    foto(cam, "3_cueva_desde_el_paseo", punto(25, -paseo, PASEO + 6), punto(-20, 150, 150), 16)
    foto(cam, "4_tunel", punto(0, -(FRENTE + 30), PASEO + 8), punto(0, -150, PASEO + 14), 24)
    foto(cam, "5_cenital", V((0, 0, 2600)), V((0, 0.01, 0)), 40)


def main_cueva():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    informe, grilla = construir_cueva()
    plano_agua()
    puente_inclinado()
    isla_referencia()
    arco_referencia()
    luces_cueva()
    cam = escena()
    os.makedirs(RENDERS, exist_ok=True)
    fotos_cueva(cam, grilla)
    os.makedirs(os.path.dirname(BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    altos = [t.hi for c in grilla.values() for t in c.tramos]
    techos_centro = [c.techo for (i, j), c in grilla.items() if c.techo and math.hypot((i + 0.5) * CELDA, (j + 0.5) * CELDA) < 80]
    print("TRIS", json.dumps({k: v for k, v in informe.items() if k in ("exterior", "cueva", "lava")}))
    print("TOTAL_TRIS", informe["exterior"] + informe["cueva"] + informe["lava"],
          "MAX_SECTOR", max(v for k, v in informe.items() if k not in ("exterior", "cueva", "lava")),
          "ALTO_MAX", max(altos), "TECHO_MIN_CENTRO", min(techos_centro), "COLUMNAS", len(grilla))


if not globals().get("SOLO_FUNCIONES_CUEVA"):
    main_cueva()
