r"""
Las colas del Zorro de agua v2 con la misma cuenta que el juego (src/shared/Zorro/Colas), parte 1:
Azar (Minotauro/Azar), Onda, Medidas y Estados, pasados línea por línea a Python. La parte 2
(zorro_v2_colas_paso.py) tiene Mezcla, Cadena, Limites y el paso de Colas.step.
No usa Blender: solo numpy, así se puede probar con cualquier Python. Lo cargan con exec
zorro_v2_poses.py y rig_zorro_v2.py.

Espacio: el de Blender (x = izquierda del zorro, -y = frente, z arriba). Los ejes del cuerpo son los
de Zorro/Rig.bind: derecha de HombroIzq a HombroDer (-x), arriba z y adelante = arriba x derecha
(-y). Las cuentas de Medidas son productos punto y cruz, que no cambian con el giro (propio) que
hace el FBX al pasar a Roblox, así que dan lo mismo que en el juego.
Si cambia algo en src/shared/Zorro/Colas, hay que cambiarlo aquí también.
"""
import math
import numpy as np

TAU = 2 * math.pi
T32 = 2 ** 32
DER, ARR, ADE = np.array((-1.0, 0, 0)), np.array((0, 0, 1.0)), np.array((0, -1.0, 0))
# Zorro/Etapas: cómo mueve las colas cada etapa.
PERFILES = {
    1: dict(ritmo=1.45, fuerza=1.25, peso=1.3, rebote=0.78, abanico=0.35, latigo=1.25),
    2: dict(ritmo=1.2, fuerza=1.1, peso=1.12, rebote=0.82, abanico=0.45, latigo=1.1),
    3: dict(ritmo=0.95, fuerza=1, peso=0.95, rebote=0.86, abanico=0.5, latigo=1),
    4: dict(ritmo=0.72, fuerza=0.9, peso=0.78, rebote=0.9, abanico=0.5, latigo=0.85),
}


def clamp(x, a, b):
    return max(a, min(b, x))


def signo(x):
    return 0 if x == 0 else math.copysign(1, x)


def unidad(v):
    return v / np.linalg.norm(v)


def rot(eje, ang):
    """Matriz 3x3 de giro (regla de la mano derecha), como CFrame.fromAxisAngle."""
    x, y, z = unidad(np.asarray(eje, float))
    c, s = math.cos(ang), math.sin(ang)
    k = 1 - c
    return np.array([[c + x * x * k, x * y * k - z * s, x * z * k + y * s],
                     [y * x * k + z * s, c + y * y * k, y * z * k - x * s],
                     [z * x * k - y * s, z * y * k + x * s, c + z * z * k]])


# --- Minotauro/Azar ---------------------------------------------------------------------
def _mezclar(h):
    h ^= h >> 16
    h = (h * 0x7FEB352D) % T32
    h ^= h >> 15
    h = (h * 0x846CA68B) % T32
    return h ^ (h >> 16)


def azar(a, b=0):
    h = _mezclar(math.floor(a) % T32)
    return _mezclar(h ^ ((math.floor(b) % T32 + 0x9E3779B9) % T32)) / T32


# --- Zorro/Colas/Medidas ----------------------------------------------------------------
def _cola(pos, num, n, centro, unit):
    pts = [pos[f"Cola{num}_{j}"] for j in range(1, n + 1)]
    pts.append(pts[-1] + (pts[-1] - pts[-2]))  # la punta: un tramo más, como el anterior
    segs = [pts[j + 1] - pts[j] for j in range(n)]
    d = unidad(pts[-1] - pts[0])
    angle = math.atan2(d @ DER, d @ ARR)
    plano = DER * math.sin(angle) + ARR * math.cos(angle)
    eje_fold = unidad(np.cross(plano, -ADE))
    g_fan, g_fold = np.cross(ADE, d), np.cross(eje_fold, d)
    mid = (pts[0] + pts[-1]) / 2 - centro
    drag = -np.cross(ARR, np.array((mid[0], mid[1], 0.0))) / unit
    seed = num * 7919 + 17
    return dict(huesos=[f"Cola{num}_{j}" for j in range(1, n + 1)], n=n, angle=angle, out=0.0,
                root=pts[0], segs=segs, fold_axis=eje_fold,
                turnFan=drag @ g_fan, turnFold=drag @ g_fold, upFan=ARR @ g_fan, upFold=ARR @ g_fold,
                backFan=-ADE @ g_fan, backFold=-ADE @ g_fold, seed=seed,
                rate=0.85 + 0.3 * azar(seed, 1), delta=0.3 + 0.2 * azar(seed, 2),
                phases=[0.0] + [TAU * azar(seed, 10 + k) for k in range(1, 9)])


def medidas(pos):
    """Medidas.bind. pos: {hueso: np.array} posición de reposo de cada hueso."""
    hip, neck = pos["Cadera"], pos["Cuello1"]
    floor = min(pos[n][2] for n in ("PieIzq", "PieDer", "ManoIzq", "ManoDer") if n in pos)
    unit = max(hip[2] - floor, 1e-3)
    centro = np.array((0.0, 0.0, hip[2]))
    colas = []
    for num in range(1, 13):
        n = 0
        while f"Cola{num}_{n + 1}" in pos:
            n += 1
        if n >= 2:
            colas.append(_cola(pos, num, n, centro, unit))
    widest = max(abs(c["angle"]) for c in colas)
    for c in colas:
        c["out"] = c["angle"] / widest if widest > 1e-3 else 0.0
    colas.sort(key=lambda c: c["angle"])
    return dict(colas=colas, a=hip, b=neck, floor=floor, unit=unit,
                radius=np.linalg.norm(pos["HombroIzq"] - pos["HombroDer"]) * 0.8)


# --- Zorro/Colas/Onda -------------------------------------------------------------------
RATIOS, PESOS_ONDA = (1, 1.6180339887, 2.4142135624), (0.62, 0.28, 0.14)


def _ruido(seed, x):
    k = math.floor(x)
    a, b = azar(seed, k), azar(seed, k + 1)
    s = x - k
    return (a + (b - a) * s * s * (3 - 2 * s)) * 2 - 1


def _suma(c, t, j, ritmo, fino, first, slow):
    hz = 0.3 * ritmo * c["rate"] * slow
    at = t - (j - 1) * c["delta"] / (TAU * hz)
    total = sum(PESOS_ONDA[k] * math.sin(TAU * hz * RATIOS[k] * at + c["phases"][first + k + 1])
                for k in range(3))
    return total + 0.25 * _ruido(c["seed"] + first, at * 0.35 * ritmo) if fino else total


def onda_wag(c, t, j, ritmo, gusto):
    at, p, g = t - (j - 1) * 0.06, c["phases"][7], clamp(gusto, 0, 1)
    return math.sin(TAU * 1.3 * ritmo * at + p) * (1 - g) + math.sin(TAU * 2.6 * ritmo * at + p) * g


def onda_shake(c, t, j, ritmo):
    return math.sin(TAU * 4.2 * math.sqrt(ritmo) * (t - (j - 1) * 0.05) + c["phases"][8])


def onda_pulse(tau):
    if tau < 0 or tau > 0.75:
        return 0.0
    carga = math.sin(math.pi * clamp(tau / 0.18, 0, 1))
    golpe = math.sin(math.pi * clamp((tau - 0.18) / 0.3, 0, 1))
    asienta = math.sin(math.pi * clamp((tau - 0.48) / 0.27, 0, 1))
    return -0.35 * carga + golpe - 0.25 * asienta


# --- Zorro/Colas/Estados ----------------------------------------------------------------
WRAP = dict(side=1.75, spread=0.55, root=0.0, curl=-0.6)  # sentado
CURL = dict(side=1.95, spread=0.6, root=-0.2, curl=-0.85)  # dormido


def _pesos(n):
    us = [(j / (n - 1) if n > 1 else 0) for j in range(n)]
    spread, root = [1 - 0.35 * u for u in us], [(1 - u) ** 2 + 0.08 for u in us]
    return [x / sum(spread) for x in spread], [x / sum(root) for x in root]


def objetivos(c, m, abierto, drive_fan, drive_fold, perfil, t, fino=True):
    """Estados.targets: los ángulos objetivo (fan, fold) de cada tramo."""
    n = c["n"]
    sw, rw = _pesos(n)
    relax = (1 - m["alerta"]) * (1 - m["correr"])
    total = m["envolver"] + m["enroscar"]
    k = 1 / total if total > 1 else 1
    e, s = m["envolver"] * k, m["enroscar"] * k
    lado = signo(c["out"]) if abs(c["out"]) > 0.15 else m["lado"]
    hacia = lambda p: lado * (p["side"] - (1 - abs(c["out"])) * p["spread"]) - c["angle"]
    wa = e * hacia(WRAP) + s * hacia(CURL)
    free = 1 - e - s
    alpha = (-0.12 * relax + 0.15 * m["alerta"] - 0.45 * m["correr"]) * c["out"] * free + wa
    fold = 0.15 * relax - 0.25 * m["alerta"] + 0.9 * m["correr"] - 0.2 * abierto
    room = max(0.0, 1 - abs(c["angle"]) / 1.75)
    opening = abierto * perfil["abanico"] * c["out"] * room * free
    amp = (0.15 * perfil["fuerza"] * m["calma"] * (1 - 0.3 * min(abierto, 1)) * (1 - 0.6 * m["alerta"])
           * (1 - 0.8 * e) * (1 - 0.95 * s) * (1 + 0.3 * m["correr"]))
    ritmo, fuera = perfil["ritmo"], signo(c["out"])
    aliento = s * 0.03 * math.sin(TAU * t / 4.6)
    fans, folds = [], []
    for i in range(n):
        j, u = i + 1, (i / (n - 1) if n > 1 else 0)
        reach = j / n
        tipward, a = 0.5 + 0.5 * reach, amp * (0.55 + 0.45 * (j / n))
        f = (alpha - wa) * sw[i] + wa * (sw[i] + rw[i]) / 2 + opening * rw[i]
        g = fold * sw[i] - m["alto"] * (0.35 if j == 1 else 0.08) + aliento
        if j == n:
            f += 0.12 * abierto * fuera * math.sqrt(room)  # la punta rompe hacia afuera
        g += (e * WRAP["root"] + s * CURL["root"]) if j == 1 else (e * WRAP["curl"] + s * CURL["curl"]) * (0.4 + 0.6 * u)
        f += a * _suma(c, t, j, ritmo, fino, 0, 1)
        g += 0.5 * a * _suma(c, t, j, ritmo, fino, 3, 0.83)
        if m["alerta"] > 0:
            f += m["alerta"] * 0.02 * math.sin(TAU * 3.1 * t + c["phases"][6] - j * 0.4)
        if m["meneo"] > 0:
            f += m["meneo"] * 0.15 * perfil["fuerza"] * (0.6 + 0.4 * reach) * onda_wag(c, t, j, ritmo, m["gusto"])
        if m["sacudida"] > 0:
            f += m["sacudida"] * 0.3 * tipward * onda_shake(c, t, j, ritmo)
            g += m["sacudida"] * 0.1 * tipward * onda_shake(c, t + 0.07, j, ritmo)
        if m["latigazo"] is not None:
            g += perfil["latigo"] * 0.3 * (0.6 + 0.4 * reach) * onda_pulse(t - m["latigazo"] - i * 0.05)
        fans.append(f + drive_fan * tipward)
        folds.append(g + drive_fold * tipward)
    return fans, folds
