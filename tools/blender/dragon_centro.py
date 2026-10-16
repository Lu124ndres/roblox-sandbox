"""
Línea central de cada extremidad del dragón: geodésica desde la punta; los
vértices se agrupan por distancia y el centro de cada grupo da la línea.
Uso: python3 -I centro.py -- <modelo.blend> <spec.json> <salida.json> <render_base>
"""
import sys, math, json, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dragon_geo as geo
SRC, SPEC, OUT, IMG = sys.argv[-4], sys.argv[-3], sys.argv[-2], sys.argv[-1]
spec = json.load(open(SPEC))
o, V, adj = geo.load(SRC)
def sub(a, b): return [a[i] - b[i] for i in range(3)]
def add(a, b): return [a[i] + b[i] for i in range(3)]
def mul(a, k): return [a[i] * k for i in range(3)]
def length(pts): return sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))
def at(pts, s):
    """Punto a distancia s a lo largo de la polilínea."""
    for i in range(len(pts) - 1):
        l = math.dist(pts[i], pts[i + 1])
        if s <= l or i == len(pts) - 2:
            t = min(s / l, 1) if l > 0 else 0
            return add(pts[i], mul(sub(pts[i + 1], pts[i]), t))
        s -= l
    return pts[-1]
def centerline(tip, base, bins=18):
    t = geo.nearest(V, tip); b = geo.nearest(V, base)
    dist = geo.dijkstra(adj, [t])
    D = dist[b]
    groups = [[] for _ in range(bins)]
    for v, d in dist.items():
        if d < D:
            groups[min(int(d / D * bins), bins - 1)].append(V[v])
    pts = [list(V[t])]
    for g in groups[1:]:
        if len(g) >= 3:
            pts.append([sum(p[i] for p in g) / len(g) for i in range(3)])
    pts.append(list(base))
    pts.reverse()  # de la base a la punta
    # suavizado ligero
    sm = [pts[0]] + [mul(add(add(pts[i - 1], pts[i + 1]), mul(pts[i], 2)), 0.25) for i in range(1, len(pts) - 1)] + [pts[-1]]
    return sm
out = {"P": spec["P"], "C": spec["C"], "limbs": {}, "jaw": spec.get("jaw"), "boca": spec.get("boca"), "lines": {}}
for name, L in spec["limbs"].items():
    if "joints" in L:
        out["limbs"][name] = L["joints"]; out["lines"][name] = L["joints"]; continue
    line = centerline(L["tip"], L["base"])
    total = length(line)
    joints = [at(line, f * total) for f in L["fr"]]
    out["limbs"][name] = joints
    out["lines"][name] = line
json.dump(out, open(OUT, "w"), indent=1)
# Dibujo sobre las vistas con cuadrícula.
from PIL import Image, ImageDraw
S = 900 / 2.2
def proj(view, p):
    x, y, z = p
    if view == "front": return (450 + x * S, 450 - (z - 0.95) * S)
    if view == "side": return (450 + y * S, 450 - (z - 0.95) * S)
    return (450 + x * S, 450 - y * S)
cols = [(255, 60, 60), (60, 255, 60), (80, 160, 255), (255, 255, 60), (255, 60, 255), (60, 255, 255), (255, 160, 60), (200, 200, 200), (160, 90, 255), (255, 120, 160)]
W = Image.new("RGB", (2700, 900))
for k, view in enumerate(["front", "side", "top"]):
    im = Image.open(f"{IMG}_{view}_g.png").convert("RGB"); d = ImageDraw.Draw(im)
    for i, (name, joints) in enumerate(out["limbs"].items()):
        c = cols[i % len(cols)]
        pts = [proj(view, p) for p in joints]
        d.line(pts, fill=c, width=3)
        for p in pts: d.ellipse([p[0] - 4, p[1] - 4, p[0] + 4, p[1] + 4], outline=c, width=2)
        d.text((pts[-1][0] + 5, pts[-1][1]), name, fill=c)
    for key in ("P", "C"):
        p = proj(view, spec[key]); d.rectangle([p[0] - 5, p[1] - 5, p[0] + 5, p[1] + 5], outline=(255, 255, 255), width=2)
    if spec.get("jaw"):
        pts = [proj(view, p) for p in spec["jaw"]]; d.line(pts, fill=(255, 255, 255), width=3)
    W.paste(im, (k * 900, 0))
W.save(OUT.replace(".json", ".png"))
print("OK", {k: round(length(v), 2) for k, v in out["limbs"].items()})
