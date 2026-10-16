"""Herramientas de geodésicas sobre la malla (Dijkstra por aristas)."""
import heapq, math
def load(path):
    import bpy
    bpy.ops.wm.open_mainfile(filepath=path)
    o = [x for x in bpy.context.scene.objects if x.type == 'MESH'][0]
    V = [tuple(v.co) for v in o.data.vertices]
    adj = [[] for _ in V]
    for e in o.data.edges:
        a, b = e.vertices
        d = math.dist(V[a], V[b]); adj[a].append((b, d)); adj[b].append((a, d))
    return o, V, adj
def dijkstra(adj, sources, limit=math.inf):
    dist = {}
    h = [(0.0, s) for s in sources]
    while h:
        d, v = heapq.heappop(h)
        if v in dist: continue
        dist[v] = d
        if d > limit: continue
        for w, l in adj[v]:
            if w not in dist: heapq.heappush(h, (d + l, w))
    return dist
def nearest(V, p):
    return min(range(len(V)), key=lambda i: math.dist(V[i], p))
