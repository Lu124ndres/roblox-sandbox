r"""
Salidas de ojos_medir.py (lo carga con exec): la comprobación contra el FBX, el informe en la
consola y GiantEyesData.luau (con stylua, si está en el PATH).
"""
import shutil, subprocess


def srgb(c):
    """Color lineal -> sRGB (0..1), como lo pinta paleta() en la textura del rig."""
    return c * 12.92 if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def comparar_fbx(fbx, P, e):
    """Importa el FBX en una escena vacía y compara su malla (en el mundo) con la del .blend."""
    if not os.path.exists(fbx):
        return {"fbx": "no existe"}
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=fbx)
    o = next(o for o in bpy.data.objects if o.type == "MESH")
    Q = [o.matrix_world @ v.co for v in o.data.vertices]
    lo = V([min(q[i] for q in Q) for i in range(3)])
    hi = V([max(q[i] for q in Q) for i in range(3)])
    caja = max(max(abs(a - b) for a, b in zip(lo, e["boundsMin"])), max(abs(a - b) for a, b in zip(hi, e["boundsMax"])))
    r = {"vertices": (len(P), len(Q)), "caja_max_dif": round(caja, 6)}
    if len(P) == len(Q):
        r["vertice_max_dif"] = round(max((p - q).length for p, q in zip(P, Q)), 6)
    return r


def informe(nombre, e):
    print(f"OJOS {nombre} ({e['fuente']}): caja {tuple(round(x, 3) for x in e['boundsMin'])} .. "
          f"{tuple(round(x, 3) for x in e['boundsMax'])}, celda {e['celda']:.4f}, tapa {e.get('cover')}, "
          f"fbx {e.get('fbx')}")
    for k, o in enumerate(e["eyes"]):
        c = o["center"] / e["celda"]
        print(f"OJOS   {'izq' if k == 0 else 'der'}: centro {tuple(round(x, 4) for x in o['center'])} "
              f"(celdas {tuple(round(x, 3) for x in c)}), normal {tuple(round(x, 3) for x in o['normal'])}, "
              f"tamaño {tuple(round(x, 4) for x in o['size'])} (celdas {o['celdas']}), huesos {o['huesos']}, "
              f"máscara {o['mascara']:.2f}")


def _n(x):
    s = f"{x:.4f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def _v(t, v):
    return f"{t}.new({', '.join(_n(x) for x in v)})"


ENCABEZADO = """--!strict
--[[
	GiantEyesData

	GENERADO por tools/blender/ojos_medir.py: no se edita a mano, se vuelve a correr el script.

	Dónde está cada ojo de los gigantes v2, para las pupilas que siguen al jugador
	(src/client/Giant/GiantEyes.luau). Todo en ejes de Blender (x = izquierda del personaje,
	-y = frente, z = arriba), en las unidades de la malla exportada al FBX y en la pose de bind.
	La caja (boundsMin/boundsMax) es la de toda la malla: su tamaño es MeshPart.Size y su centro,
	MeshPart.CFrame. A la MeshPart: (x, y, z) -> (-x, z, y) y local = (p - centro) / tamaño * Size.

	Con `cover`, la malla ya trae una pupila pintada: se tapa el ojo con una placa de ese color
	(la cara medida es la de la tapa, delante de la pupila pintada) y la pupila móvil va encima.
]]

export type Eye = {
	center: Vector3, -- centro de la cara visible del ojo (BU, ejes de Blender)
	normal: Vector3, -- unitario, hacia afuera del ojo (ejes de Blender)
	up: Vector3, -- unitario, el "arriba" del ojo en su plano (ejes de Blender)
	size: Vector2, -- ancho y alto de la cara del ojo en su plano (BU)
}

export type ModelEyes = {
	bone: string, -- el hueso que lleva los ojos (normalmente "Cabeza")
	boundsMin: Vector3, -- caja de TODA la malla exportada (BU, ejes de Blender, pose de bind)
	boundsMax: Vector3,
	requiresBone: string?, -- se usa solo si el modelo tiene este hueso (orca v2: "OjoIzqMira")
	cover: Color3?, -- tapa del color del ojo que esconde la pupila pintada en la malla
	eyes: { Eye }, -- izquierdo primero
}

-- Clave: nombre del modelo en el juego ("MinotauroE3", "OrcaE1"...).
local data: { [string]: ModelEyes } = {
"""


def escribir_luau(ruta, datos):
    """GiantEyesData.luau con los modelos medidos, en el orden de CRIATURAS y de las etapas."""
    lineas = [ENCABEZADO]
    for nombre, e in datos.items():
        lineas.append(f"\t-- {e['fuente'].replace(os.sep, '/')}\n\t{nombre} = {{\n\t\tbone = \"{e['bone']}\",\n")
        lineas.append(f"\t\tboundsMin = {_v('Vector3', e['boundsMin'])},\n\t\tboundsMax = {_v('Vector3', e['boundsMax'])},\n")
        if e.get("requiresBone"):
            lineas.append(f"\t\trequiresBone = \"{e['requiresBone']}\",\n")
        if e.get("cover"):
            lineas.append(f"\t\tcover = Color3.fromRGB({', '.join(str(x) for x in e['cover'])}),\n")
        lineas.append("\t\teyes = {\n")
        for o in e["eyes"]:
            lineas.append(f"\t\t\t{{\n\t\t\t\tcenter = {_v('Vector3', o['center'])},\n"
                          f"\t\t\t\tnormal = {_v('Vector3', o['normal'])},\n\t\t\t\tup = {_v('Vector3', o['up'])},\n"
                          f"\t\t\t\tsize = {_v('Vector2', o['size'])},\n\t\t\t}},\n")
        lineas.append("\t\t},\n\t},\n")
    lineas.append("}\n\nreturn data\n")
    with open(ruta, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("".join(lineas))
    stylua = shutil.which("stylua")
    if stylua:
        subprocess.run([stylua, ruta], cwd=RAIZ, check=False)
    print(f"OJOS escrito {ruta} ({len(datos)} modelos{'' if stylua else ', sin stylua'})")
