"""
Simulación del recorrido de la Orca (OrcaMotion/Path y OrcaMotion/Steer).

Replica la cuenta de los módulos Luau (mismo hash entero, mismas constantes) y corre
10 minutos de nado por etapa, sin comer y con una comida de prueba, para medir:
  - qué parte del tiempo mira hacia la rampa (adelante · dirección a la puerta > 0.5),
    de costado o de espaldas (< -0.5), y el tramo más largo de espaldas;
  - si sale del lago (radio de nado de Path.radius y el acantilado);
  - que el recorrido no salte en el cambio de época ni al terminar de comer;
y dibuja una vista de arriba de la trayectoria en PNG.

Uso:  python tools/orca_recorrido_sim.py [salida.png] [hora_inicial]
Si se cambia una constante en OrcaMotion/Path/ o en Steer.luau, se cambia también aquí.
"""

import math
import sys

# --- Mundo (WorldLayoutData.json) -------------------------------------------------
LAKE_RADIUS = 190 + 4  # OrcaMotion/init: craterLakeRadius + 4


def _f32(x):
    """Redondea a float de 32 bits, como guarda Roblox los Vector3."""
    import struct

    return struct.unpack("f", struct.pack("f", x))[0]


# bridgeEnds() final menos el centro del cráter (x, z), con la cuenta en Vector3 de
# WorldZones (bridgeAngle 90, craterRimOuter - 2 = 263).
DOOR = (-_f32(_f32(math.cos(math.radians(90))) * 263.0), -263.0)
DOOR_ANGLE = math.atan2(DOOR[1], DOOR[0])
HEIGHTS = {"OrcaBebe": 16.5, "OrcaJoven": 44.0, "OrcaAdulta": 82.5, "OrcaAnciana": 165.0}
SWIM_SPEED = {"OrcaBebe": 1.05, "OrcaJoven": 1.15, "OrcaAdulta": 1.0, "OrcaAnciana": 0.6}
BREATH = {  # seconds, shallow, deep (Etapas/*.luau)
    "OrcaBebe": (10, -0.04, -0.12),
    "OrcaJoven": (13, -0.05, -0.13),
    "OrcaAdulta": (16, -0.05, -0.14),
    "OrcaAnciana": (22, -0.04, -0.1),
}

# --- Azar (Minotauro/Azar) ---------------------------------------------------------
TWO32 = 4294967296


def _mul(a, b):
    lo, hi = a % 65536, a // 65536
    return ((hi * b) % 65536 * 65536 + lo * b) % TWO32


def _mix(h):
    h ^= h >> 16
    h = _mul(h, 0x7FEB352D)
    h ^= h >> 15
    h = _mul(h, 0x846CA68B)
    return h ^ (h >> 16)


def unit(a, b=0):
    h = _mix(math.floor(a) % TWO32)
    h = _mix(h ^ ((math.floor(b) % TWO32 + 0x9E3779B9) % TWO32))
    return h / TWO32


# --- Vectores 2D (x, z) ------------------------------------------------------------
def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def mul(a, k):
    return (a[0] * k, a[1] * k)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]


def length(a):
    return math.sqrt(a[0] * a[0] + a[1] * a[1])


def unitv(a):
    m = length(a)
    return (a[0] / m, a[1] / m) if m > 1e-9 else (0.0, 0.0)


def smooth(t):
    t = min(max(t, 0.0), 1.0)
    return t * t * (3 - 2 * t)


def ang(v):
    return math.atan2(v[1], v[0])


def dirv(th):
    return (math.cos(th), math.sin(th))


def wrapa(a):
    return (a + math.pi) % (2 * math.pi) - math.pi


# --- Path/Tramo: arcos y descansos -------------------------------------------------
def seg_eval(seg, tau):
    """Posición, velocidad y rumbo del tramo a `tau` segundos de su comienzo.

    arc: gira a ritmo fijo (w rad/s) mientras la velocidad pasa de v0 a v1 en línea recta.
    rest: flota casi quieta; la posición es un Hermite y el rumbo gira suave en los
    primeros REST_TURN segundos.
    """
    D = seg["D"]
    tau = min(max(tau, 0.0), D)
    if seg["kind"] == "arc":
        a, b, w, th0 = seg["v0"], (seg["v1"] - seg["v0"]) / D, seg["w"], seg["th0"]
        speed = a + b * tau
        th = th0 + w * tau
        if abs(w) < 1e-5:
            s = a * tau + b * tau * tau / 2
            off = (s, 0.0)
        else:
            c, sn = math.cos(w * tau), math.sin(w * tau)
            off = (speed * sn / w + b * (c - 1) / (w * w), (a - speed * c) / w + b * sn / (w * w))
        rot = (off[0] * math.cos(th0) - off[1] * math.sin(th0), off[0] * math.sin(th0) + off[1] * math.cos(th0))
        return add(seg["p0"], rot), mul(dirv(th), speed), th
    u = tau / D
    u2, u3 = u * u, u * u * u
    p0, p1, m0 = seg["p0"], seg["p1"], mul(seg["V0"], D)
    a, b, c = 2 * u3 - 3 * u2 + 1, u3 - 2 * u2 + u, -2 * u3 + 3 * u2
    da, db, dc = 6 * u2 - 6 * u, 3 * u2 - 4 * u + 1, -6 * u2 + 6 * u
    pos = (a * p0[0] + b * m0[0] + c * p1[0], a * p0[1] + b * m0[1] + c * p1[1])
    vel = ((da * p0[0] + db * m0[0] + dc * p1[0]) / D, (da * p0[1] + db * m0[1] + dc * p1[1]) / D)
    return pos, vel, seg["th0"] + seg["dth"] * smooth(tau / min(D, REST_TURN))


# --- Path/Ruta: la cadena de tramos de cada época ---------------------------------
EPOCH = 300.0  # s: cada época empieza quieta en un punto fijo (sin estado entre épocas)
APPROACH = 90.0  # s: en los últimos de la época va al punto de la siguiente
FINAL_REST = 14.0  # s: como mínimo flota quieta ahí antes de que empiece la otra época
U = 0.065  # radios del lago por segundo: el crucero
# La puerta en radios del lago queda más cerca o más lejos según la etapa (el radio de nado
# cambia): el plan se cuida de las dos, la de la etapa más chica y la de la más grande.
DOOR_NEAR = (DOOR[0] / 175.0, DOOR[1] / 175.0)
DOOR_FAR = (DOOR[0] / 41.0, DOOR[1] / 41.0)
PHI_MAX = math.radians(112)  # rumbo: como mucho esto desde la dirección a la puerta
OMEGA = (0.28, 0.5)  # rad/s de las curvas (Steer gira al menos 0.85)
R_HARD = 0.9  # fracción del radio que un tramo no pasa
LOOK = 0.35  # radios: cuánto mira adelante para no ir contra la orilla
SOFT = (0.7, 0.12)  # radio cómodo: medio y cuánto crece hacia el lado opuesto a la rampa
MODES = [  # nombre, peso, velocidad (min, max) en U
    ("cruce", 3.0, 0.9, 1.3),
    ("orilla", 2.5, 0.75, 1.0),
    ("paseo", 2.0, 0.5, 0.8),
    ("descanso", 1.2, 0.0, 0.0),
]
MODE_INDEX = {m[0]: k for k, m in enumerate(MODES)}
INTENT_SECONDS = 45.0  # s: si no llegó en este tiempo, cambia de idea
NEAR = 0.15  # radios: llegó al lugar que buscaba
BEHIND = math.radians(160)  # el lugar queda casi justo detrás de la orca
TURN_SECONDS = 10.0  # s: una curva larga se parte en tramos de esto
SLOW = 0.3  # U: velocidad a la que da una vuelta cerrada
BIG = 1.5  # rad: desde esta vuelta frena y gira más rápido
FLIP = 0.9  # rad/s: vuelta rápida (pasa los ~120° de espaldas en menos de 3 s)
REST_TURN = 6.0  # s: al descansar se acomoda de costado en este tiempo
SIDE = 0.9  # al descansar: qué tan de costado queda (1 = justo de costado)


def rnd(epoch, i, salt, field):
    return unit(epoch * 32 + field, i * 16 + salt)


def door_frame(p):
    """Dirección a la puerta (entre las dos) y cuánto puede apartarse de ella el rumbo."""
    near, far = ang(sub(DOOR_NEAR, p)), ang(sub(DOOR_FAR, p))
    gap = wrapa(far - near) / 2
    return near + gap, PHI_MAX - abs(gap)


def door_dir(p):
    return dirv(door_frame(p)[0])


def soft(p):
    """Radio cómodo en esa dirección: del lado de la rampa deja lugar para dar la vuelta."""
    m = length(p)
    return SOFT[0] + SOFT[1] * (p[1] / m if m > 1e-6 else 0.0)


def inside(w):
    m = length(w)
    lim = soft(w) - 0.05
    return mul(w, lim / m) if m > lim else w


def facing(th, p):
    return wrapa(th - door_frame(p)[0])


def wanted(th_w, p, phi0):
    """Rumbo hacia `th_w` sin ir de espaldas a la rampa ni contra la orilla, en `facing`."""
    q = add(p, mul(dirv(th_w), LOOK))
    if length(q) > soft(q) and length(p) > 1e-3:
        n = unitv(p)
        d = dirv(th_w)
        out = dot(d, n)
        if out > -0.35:
            th_w = ang(sub(d, mul(n, out + 0.35)))
    phi, lim = facing(th_w, p), door_frame(p)[1]
    if abs(phi) > lim:  # justo detrás: se queda del lado por el que ya va
        phi = math.copysign(lim, phi if abs(phi) < BEHIND or phi0 == 0 else phi0)
    return phi


def anchor(epoch):
    a = DOOR_ANGLE + (rnd(epoch, 0, 15, 0) - 0.5) * 1.4
    r = 0.25 + 0.3 * rnd(epoch, 0, 15, 1)
    p = (r * math.cos(a), r * math.sin(a))
    side = SIDE * (math.pi / 2 if rnd(epoch, 0, 15, 2) < 0.5 else -math.pi / 2)
    return p, door_frame(p)[0] + side


def pick_mode(epoch, i, prev):
    total = sum(m[1] for m in MODES if not (m[0] == "descanso" and prev == "descanso"))
    x = rnd(epoch, i, 14, 0) * total
    for m in MODES:
        if m[0] == "descanso" and prev == "descanso":
            continue
        x -= m[1]
        if x <= 0:
            return m[0]
    return MODES[0][0]


def target(epoch, i, mode, p):
    h = lambda f: rnd(epoch, i, 13, f)
    if mode == "cruce":
        best, far = p, -1.0
        for k in range(4):
            a, r = 2 * math.pi * h(2 * k), math.sqrt(h(2 * k + 1))
            w = inside((r * math.cos(a), r * math.sin(a)))
            d = length(sub(w, p))
            if d >= 0.7:
                return w
            if d > far:
                best, far = w, d
        return best
    if mode == "orilla":
        a = ang(p) + (1 if h(8) < 0.5 else -1) * (0.7 + 0.4 * h(9))
        w = (math.cos(a), math.sin(a))
        return mul(w, soft(w) - 0.05)
    a, d = 2 * math.pi * h(10), 0.25 + 0.25 * h(11)
    return inside(add(p, (d * math.cos(a), d * math.sin(a))))


def arc_seg(t, p, th, v, v1, turn, D):
    return {"kind": "arc", "t0": t, "D": D, "p0": p, "th0": th, "v0": v, "v1": v1, "w": turn / D}


def max_r(seg):
    worst, n = 0.0, max(2, math.ceil(seg["D"]))
    for j in range(n + 1):
        worst = max(worst, length(seg_eval(seg, seg["D"] * j / n)[0]))
    return worst


def keep_front(seg):
    """Corrige un tramo para que al final no quede de espaldas a la rampa."""
    pos, _, th = seg_eval(seg, seg["D"])
    phi, lim = facing(th, pos), door_frame(pos)[1]
    if abs(phi) > lim:
        seg["w"] -= math.copysign(abs(phi) - lim + 0.03, phi) / seg["D"]
    return seg


def turn_seg(t, p, th, v, v1, delta, omega, room):
    D = abs(delta) / omega
    turn = delta if D <= TURN_SECONDS else delta * TURN_SECONDS / D
    return keep_front(arc_seg(t, p, th, v, v1, turn, min(max(D, 2.0), TURN_SECONDS, room)))


def travel(epoch, i, t, st, room):
    h = lambda f: rnd(epoch, i, 12, f)
    p, th, v = st["p"], st["th"], st["v"]
    _, _, lo, hi = MODES[MODE_INDEX[st["mode"]]]
    to_w = sub(st["w"], p)
    dist = length(to_w)
    burst = h(0) < 0.55  # aletazos o planeo
    v1 = U * (hi * (1 + 0.12 * h(1)) if burst else lo * (0.8 + 0.2 * h(1)))
    if dist < 0.35:
        v1 = min(v1, U * max(0.35, dist / 0.35))
    phi0 = facing(th, p)
    delta = wanted(ang(to_w), p, phi0) - phi0  # siempre por el lado de la rampa
    if abs(delta) <= 0.12:
        seg = keep_front(arc_seg(t, p, th, v, v1, delta + (h(4) - 0.5) * 0.3, min(3 + 6 * h(3), room)))
        if max_r(seg) <= R_HARD:
            return seg
        delta = wanted(ang(mul(p, -1)), p, phi0) - phi0  # se acerca a la orilla: hacia adentro
    big = abs(delta) > BIG  # vuelta grande: frena y gira más rápido, no da un círculo
    omega = OMEGA[0] + (OMEGA[1] - OMEGA[0]) * h(2)
    v_turn = v1 * (1 - 0.2 * omega / OMEGA[1])
    if big:
        omega, v_turn = OMEGA[1] + (FLIP - OMEGA[1]) * h(2), v1 * (0.45 + 0.25 * h(5))
    other = delta - math.copysign(2 * math.pi, delta)
    front = lambda: turn_seg(t, p, th, v, v_turn, delta, omega, room)
    back = lambda: turn_seg(t, p, th, v, SLOW * U, other, FLIP, room)  # da la vuelta rápido de espaldas
    small = max(-0.3, min(0.3, delta))
    tries = [back, front] if abs(delta) > math.pi else [front]
    tries += [
        lambda: turn_seg(t, p, th, v, SLOW * U, delta, FLIP, room),  # frena y la vuelta se cierra
        lambda: keep_front(arc_seg(t, p, th, v, 0.2 * U, small, min(3.5, room))),  # frena antes
    ]
    if math.pi / 2 < abs(delta) <= math.pi:
        tries.append(back)
    best, best_r = None, 9.0
    for make in tries:
        seg = make()
        r = max_r(seg)
        if r <= R_HARD:
            return seg
        if r < best_r:
            best, best_r = seg, r
    return best


def rest_seg(t, p, th, v, D, p1=None, th1=None, drift=0.0):
    if p1 is None:
        phi0 = facing(th, p)
        side = math.pi / 2 if abs(math.pi / 2 - phi0) <= abs(-math.pi / 2 - phi0) else -math.pi / 2
        th1 = door_frame(p)[0] + side * SIDE
        p1 = add(p, mul(dirv(th1), drift))
    dth = facing(th1, p) - facing(th, p)
    return {"kind": "rest", "t0": t, "D": D, "p0": p, "p1": p1, "V0": mul(dirv(th), v), "th0": th, "dth": dth}


def brake_seg(t, p, th, v, D):
    """Frena para descansar y de paso se acomoda hacia un costado de la rampa."""
    phi0 = facing(th, p)
    side = math.copysign(math.pi / 2 * SIDE, phi0 if phi0 != 0 else 1)
    turn = max(-0.4, min(0.4, side - phi0))
    return arc_seg(t, p, th, v, 0.08 * U, turn, D)


def advance(st, seg):
    pos, _, th = seg_eval(seg, seg["D"])
    st["p"], st["th"] = (seg["p1"] if seg["kind"] == "rest" else pos), th
    st["v"] = 0.0 if seg["kind"] == "rest" else seg["v1"]


_cache = {}


def build(epoch):
    if epoch in _cache:
        return _cache[epoch]
    t, t_end = epoch * EPOCH, (epoch + 1) * EPOCH
    p, th = anchor(epoch)
    st = {"p": p, "th": th, "v": 0.0, "mode": "", "w": p, "since": t, "final": False}
    segs, i, hops = [], 0, 0
    goal_p, goal_th = anchor(epoch + 1)
    while True:
        rem = t_end - t
        if rem < APPROACH and not st["final"]:
            st["final"], st["mode"], st["w"] = True, "paseo", goal_p
        h = lambda f: rnd(epoch, i, 11, f)
        if st["final"] and (length(sub(goal_p, st["p"])) < NEAR or rem < FINAL_REST + 6):
            if st["v"] > 0.25 * U and rem > FINAL_REST + 2:
                seg = brake_seg(t, st["p"], st["th"], st["v"], min(5.0, rem - FINAL_REST))
            else:
                last = rest_seg(t, st["p"], st["th"], st["v"], rem, goal_p, goal_th)
                last["mode"] = "descanso"
                segs.append(last)
                break
        else:
            if not st["final"]:
                reached = length(sub(st["w"], st["p"])) < NEAR
                if st["mode"] == "orilla" and reached and hops > 0:
                    hops -= 1
                    st["w"] = target(epoch, i, "orilla", st["p"])
                elif st["mode"] in ("", "descanso") or reached or t - st["since"] > INTENT_SECONDS:
                    st["mode"] = pick_mode(epoch, i, st["mode"])
                    st["w"] = target(epoch, i, st["mode"], st["p"])
                    st["since"], hops = t, 1 + math.floor(2 * h(0))
            room = max(rem - FINAL_REST - 6, 1.0)
            if st["mode"] == "descanso" and st["v"] > 0.25 * U:
                seg = brake_seg(t, st["p"], st["th"], st["v"], min(4 + 2 * h(2), room))
                st["mode"] = "frenar"  # termina de frenar y después descansa
            elif st["mode"] in ("descanso", "frenar"):
                st["mode"] = "descanso"
                seg = rest_seg(t, st["p"], st["th"], st["v"], min(10 + 10 * h(3), room), drift=0.02 + 0.03 * h(4))
            else:
                seg = travel(epoch, i, t, st, room)
        seg["mode"] = st["mode"]
        segs.append(seg)
        advance(st, seg)
        t += seg["D"]
        i += 1
    _cache[epoch] = segs
    return segs


def route(t):
    epoch = math.floor(t / EPOCH)
    segs = build(epoch)
    lo, hi = 0, len(segs) - 1
    while lo < hi:  # búsqueda binaria del tramo
        mid = (lo + hi + 1) // 2
        if segs[mid]["t0"] <= t:
            lo = mid
        else:
            hi = mid - 1
    seg = segs[lo]
    tau = t - seg["t0"]
    pos, vel, th = seg_eval(seg, tau)
    rest = 0.0
    if seg["kind"] == "rest":
        rest = smooth(tau / 3) * smooth((seg["D"] - tau) / 3)
    effort = 0.15 if seg["kind"] == "rest" else (1.0 if seg["v1"] > seg["v0"] else 0.3)
    return pos, vel, effort, rest, seg["mode"], th, seg["kind"] == "rest"


# --- Path/Aliento: respirar en series ---------------------------------------------
GAP, DIVE, JITTER, SINK, DIVE_DEPTH, LEAD = 0.32, 1.5, 0.25, 0.6, 2.2, 0.5
BREATH_DOMAIN = 7777


def breath_unit(t, seconds):
    gap, dive = seconds * GAP, seconds * DIVE
    period = 4 * gap + dive
    c = math.floor(t / period)

    def start(k):
        return k * period + JITTER * period * unit(k * 8 + 1, BREATH_DOMAIN)

    if t < start(c):
        c -= 1
    s0, s1 = start(c), start(c + 1)
    n = 2 + min(2, math.floor(3 * unit(c * 8 + 2, BREATH_DOMAIN)))
    g = gap * (0.85 + 0.3 * unit(c * 8 + 3, BREATH_DOMAIN))
    while n > 1 and (s1 - s0) - n * g < 0.6 * dive:
        n -= 1
    u = t - s0
    if u < n * g:
        k = math.floor(u / g)
        return (u - k * g) / g, False
    return (u - n * g) / ((s1 - s0) - n * g), True


def breath_depth(t, br):
    seconds, shallow, deep = br
    phase, diving = breath_unit(t, seconds)
    if diving:
        plateau = smooth(phase / 0.25) * smooth((1 - phase) / 0.25)
        return shallow + (deep * DIVE_DEPTH - shallow) * plateau
    sink = shallow + (deep - shallow) * SINK
    return shallow + (sink - shallow) * math.sin(math.pi * phase) ** 2


def yaw_of(d):
    return math.atan2(-d[0], -d[1])


def sample(t, radius, br):
    pos, vel, effort, rest, mode, th, resting = route(t)
    phase, _ = breath_unit(t, br[0])
    depth = breath_depth(t + LEAD, br)
    depth += (br[1] - depth) * rest
    return {
        "position": mul(pos, radius), "velocity": mul(vel, radius), "depth": depth, "breath": phase,
        "mode": mode, "effort": effort, "heading": yaw_of(dirv(th)), "resting": resting,
    }


def path_radius(height):
    return max(0.0, LAKE_RADIUS - height * 0.9 - 4)


def path_speed(height):
    return max(3.0, U * path_radius(height))


# --- Steer -------------------------------------------------------------------------
CHASE = 0.9  # 1/s: cuánto corrige la distancia a la meta
SPEED_UP, SLOW_DOWN = 1.0, 2.0  # 1/s: qué tan rápido cambia de velocidad
BRAKE = 4.0  # studs/s²: frena a tiempo para no pasarse de la meta
BIG_TURN = 2.2  # rad: giros más grandes que esto eligen el lado de la rampa
MIN_ALIGN = 0.2  # mientras gira mucho avanza al menos esta parte
ON_PLAN = 0.2  # altos: descansando y más cerca que esto del plan, mira como el plan
TURN_RATE = 1.1  # rad/s como máximo
TURN_GAIN = 4.0  # 1/s: qué tan rápido alcanza el rumbo que quiere


def forward(yaw):
    return (-math.sin(yaw), -math.cos(yaw))


def wrap(a):
    return (a + math.pi) % (2 * math.pi) - math.pi


def turn_rate(height):
    return TURN_RATE


class Steer:
    def __init__(self, pos, vel):
        self.pos, self.vel = pos, vel
        self.yaw = yaw_of(vel) if length(vel) > 0.5 else 0.0
        self.speed, self.turn, self.sign = length(vel), 0.0, 0

    def update(self, dt, goal, goal_vel, max_speed, face, idle_yaw, rate, plan_yaw, near):
        err = sub(goal, self.pos)
        desired = add(goal_vel, mul(err, CHASE))
        cap = max_speed
        if length(goal_vel) < 0.5:
            cap = min(cap, math.sqrt(2 * BRAKE * length(err)))
        if length(desired) > cap:
            desired = mul(unitv(desired), cap)
        want = self.yaw
        # llegó a comer (mira a la orilla) o descansa: se deja llevar, aunque sea de costado
        drift = face is not None or (plan_yaw is not None and length(err) < near)
        if face is not None:
            want = yaw_of(face)
        elif drift:  # descansa: mira como el plan y se deja llevar despacio, de costado si hace falta
            want = plan_yaw
        elif length(desired) > 0.3:
            want = yaw_of(desired)
        elif idle_yaw is not None:
            want = idle_yaw
        diff = wrap(want - self.yaw)
        if abs(diff) > BIG_TURN:
            if self.sign == 0:
                alt = diff - math.copysign(2 * math.pi, diff)
                to_door = unitv(sub(DOOR, self.pos))
                a = dot(forward(self.yaw + diff / 2), to_door)
                b = dot(forward(self.yaw + alt / 2), to_door)
                self.sign = math.copysign(1, diff if a >= b else alt)
            if math.copysign(1, diff) != self.sign:
                diff -= math.copysign(2 * math.pi, diff)
        elif abs(diff) < 1.0:
            self.sign = 0
        change = diff * (1 - math.exp(-dt * TURN_GAIN))
        change = min(max(change, -rate * dt), rate * dt)
        self.yaw = wrap(self.yaw + change)
        self.turn += (change / dt - self.turn) * (1 - math.exp(-dt * 4))
        if drift:
            self.vel = add(self.vel, mul(sub(desired, self.vel), 1 - math.exp(-dt * SLOW_DOWN)))
            self.speed = max(0.0, dot(self.vel, forward(self.yaw)))
        else:
            target = length(desired) * min(max(math.cos(diff), MIN_ALIGN), 1.0)
            k = SPEED_UP if target > self.speed else SLOW_DOWN
            self.speed += (target - self.speed) * (1 - math.exp(-dt * k))
            self.vel = mul(forward(self.yaw), self.speed)
        self.pos = add(self.pos, mul(self.vel, dt))

    def follow(self, dt, smp, direction, radius, height, cruise, boost, now):
        goal = mul(direction, radius * 0.92) if direction else smp["position"]
        close = min(max(1 - length(sub(goal, self.pos)) / height, 0), 1) if direction else 0.0
        self.update(
            dt,
            goal,
            (0.0, 0.0) if direction else mul(smp["velocity"], boost),
            cruise * boost * (2.2 if direction else 1.5),
            direction if direction and close > 0.3 else None,
            now * 0.1 if radius < 1 else None,
            turn_rate(height),
            smp["heading"] if smp["resting"] and not direction and radius >= 1 else None,
            max(2.0, ON_PLAN * height),
        )
        m = length(self.pos)  # nunca contra la roca: se queda dentro del radio de nado
        if m > radius and m > 0:
            self.pos = mul(self.pos, radius / m)
        return close


# --- Correr y medir ----------------------------------------------------------------
def run(stage, t0, seconds, dt, feed=None):
    h = HEIGHTS[stage]
    radius = path_radius(h)
    cruise = path_speed(h) * SWIM_SPEED[stage]
    br = BREATH[stage]
    smp = sample(t0, radius, br)
    steer = Steer(smp["position"], smp["velocity"])
    steer.yaw = smp["heading"]
    out = {"xy": [], "facing": [], "route": [], "blows": 0, "max_r": 0.0, "max_yaw_rate": 0.0, "max_err": 0.0}
    last_breath, run_back, worst, front, side, back, frames = 1.0, 0.0, 0.0, 0, 0, 0, 0
    mode_time = {}
    t = t0
    while t < t0 + seconds:
        smp = sample(t, radius, br)
        direction = None
        if feed and feed[0] <= t - t0 < feed[1]:
            direction = unitv(feed[2])
        yaw_before = steer.yaw
        steer.follow(dt, smp, direction, radius, h, cruise, 1.0, t)
        out["max_yaw_rate"] = max(out["max_yaw_rate"], abs(wrap(steer.yaw - yaw_before)) / dt)
        if not feed:
            out["max_err"] = max(out["max_err"], length(sub(smp["position"], steer.pos)))
        if smp["breath"] < last_breath:
            out["blows"] += 1
        last_breath = smp["breath"]
        fac = dot(forward(steer.yaw), unitv(sub(DOOR, steer.pos)))
        frames += 1
        if fac > 0.5:
            front += 1
        elif fac < -0.5:
            back += 1
        else:
            side += 1
        if fac < -0.5 and not direction:
            run_back += dt
            worst = max(worst, run_back)
        else:
            run_back = 0.0
        mode_time[smp["mode"]] = mode_time.get(smp["mode"], 0) + dt
        out["max_r"] = max(out["max_r"], length(steer.pos))
        out["xy"].append(steer.pos)
        out["facing"].append(fac)
        out["route"].append(smp["position"])
        t += dt
    out.update(
        front=front / frames, side=side / frames, back=back / frames, worst_back=worst,
        radius=radius, height=h, modes=mode_time,
        cliff=LAKE_RADIUS - 0.75 * h,  # la cabeza toca la roca más allá de esto
    )
    return out


# --- Path.trick: cuándo hace el truco (lo elige de costado o de frente a la rampa) ----
TRICK_DOMAIN, TRICK_EDGE, TRICK_STARTS, TRICK_LOOKS = 9100, 2.0, 4, 5


def plan_facing(t):
    pos, _, _, _, _, th, _ = route(t)
    return math.cos(facing(th, pos))


def show_score(start, seconds):
    score = 0.0
    for k in range(TRICK_LOOKS):
        f = plan_facing(start + seconds * k / (TRICK_LOOKS - 1))
        score += -10 if f < -0.5 else (1 - abs(f)) + 0.3 * max(f, 0)
    return score


def trick_start(slot, every, seconds):
    first = slot * every + TRICK_EDGE
    span = max(0.0, every - seconds - 2 * TRICK_EDGE)
    start, best = first, -math.inf
    for k in range(TRICK_STARTS):
        at = first + span * (k + unit(slot, TRICK_DOMAIN + 2 + k)) / TRICK_STARTS
        sc = show_score(at, seconds)
        if sc > best:
            start, best = at, sc
    return start


def trick_facing(t0, seconds, every=24.0, length=4.2):
    """Durante los trucos (cada `every` s, de `length` s): parte de costado, de frente y de espaldas."""
    side = front = back = n = 0
    for slot in range(math.floor(t0 / every), math.floor((t0 + seconds) / every)):
        start = trick_start(slot, every, length)
        for k in range(43):
            f = plan_facing(start + length * k / 42)
            n += 1
            back += f < -0.5
            front += f > 0.5
            side += -0.5 <= f <= 0.5
    return side / n, front / n, back / n


def epoch_seams(t0, count):
    worst = 0.0
    e = math.floor(t0 / EPOCH)
    for k in range(count):
        t = (e + k + 1) * EPOCH
        a, b = route(t - 1e-6), route(t + 1e-6)
        worst = max(worst, length(sub(a[0], b[0])), abs(wrapa(a[5] - b[5])))
    return worst


def main():
    png = sys.argv[1] if len(sys.argv) > 1 else "build/orca_recorrido.png"
    t0 = float(sys.argv[2]) if len(sys.argv) > 2 else 1792512345.0
    seconds, dt = 600.0, 1 / 30
    results = {}
    for stage in HEIGHTS:
        results[stage] = run(stage, t0, seconds, dt)
        r = results[stage]
        print(
            f"{stage:12s} alto {r['height']:6.1f}  radio {r['radius']:6.1f}  "
            f"frente {r['front']*100:5.1f}%  costado {r['side']*100:5.1f}%  espaldas {r['back']*100:5.1f}%  "
            f"espaldas seguidas máx {r['worst_back']:4.1f} s  r máx {r['max_r']:6.1f} (acantilado {r['cliff']:6.1f})  "
            f"lejos del plan máx {r['max_err']:5.1f}  soplidos {r['blows']}  giro máx {r['max_yaw_rate']:.2f} rad/s"
        )
        print("             modos (s):", {k: round(v) for k, v in sorted(r["modes"].items())})
    print(f"Costura entre épocas (posición en radios o rumbo en rad): {epoch_seams(t0, 6):.2e}")
    side, front, back = trick_facing(t0, 1800.0)
    print(f"Durante los trucos (30 min): de costado {side*100:.0f}%  de frente {front*100:.0f}%  de espaldas {back*100:.0f}%")
    feed = run("OrcaJoven", t0, 120.0, dt, feed=(20.0, 50.0, (0.7, 0.7)))
    print(
        f"Prueba de comer (joven, 30 s desde el NE): giro máx {feed['max_yaw_rate']:.2f} rad/s, "
        f"r máx {feed['max_r']:.1f} de {feed['radius']:.1f}"
    )
    draw(results, feed, png)
    print("PNG:", png)


def draw(results, feed, png):
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    items = list(results.items()) + [("OrcaJoven comiendo (NE, s 20-50)", feed)]
    for ax, (name, r) in zip(axes.flat, items):
        ax.add_patch(plt.Circle((0, 0), LAKE_RADIUS, fill=False, color="#3a6ea5", lw=2))
        ax.add_patch(plt.Circle((0, 0), r["radius"], fill=False, color="#999", ls="--"))
        xs = [p[0] for p in r["xy"]]
        zs = [p[1] for p in r["xy"]]
        colors = ["#2a9d3a" if f > 0.5 else ("#d62828" if f < -0.5 else "#8a8a8a") for f in r["facing"]]
        ax.scatter(xs, zs, c=colors, s=1.2)
        ax.plot(xs[0], zs[0], "ko")
        ax.plot(DOOR[0], DOOR[1], "s", color="#e09f3e", ms=12)
        ax.annotate("rampa", DOOR, textcoords="offset points", xytext=(10, -4))
        ax.set_xlim(-280, 280)
        ax.set_ylim(-280, 220)
        ax.set_aspect("equal")
        ax.set_title(f"{name}: frente {r['front']*100:.0f}%  espaldas {r['back']*100:.0f}%  máx {r['worst_back']:.1f} s")
    ax = axes.flat[5]  # el plan solo, en radios, 30 minutos
    ax.add_patch(plt.Circle((0, 0), 1, fill=False, color="#3a6ea5", lw=2))
    t0 = float(sys.argv[2]) if len(sys.argv) > 2 else 1792512345.0
    pts = [route(t0 + k * 0.5)[0] for k in range(3600)]
    ax.plot([p[0] for p in pts], [p[1] for p in pts], lw=0.5, color="#1d3557")
    ax.plot(0, -1.0, "s", color="#e09f3e", ms=10)
    ax.set_xlim(-1.1, 1.1)
    ax.set_ylim(-1.1, 1.1)
    ax.set_aspect("equal")
    ax.set_title("Plan en radios del lago, 30 min (rampa abajo)")
    fig.text(0.5, 0.01, "verde: de frente a la rampa · gris: de costado · rojo: de espaldas", ha="center")
    fig.tight_layout()
    fig.savefig(png, dpi=80)


if __name__ == "__main__":
    main()
