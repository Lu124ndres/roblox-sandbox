"""Las 16 cámaras de las fotos del mapa antes y después (docs/capturas/mapa_antes_despues),
en Roblox (x, y, z). cz = z del centro del cráter (520 hoy, 722 con el volcán separado).
En Studio, las aéreas (01 a 05) y la 14 se sacaron con la niebla de la atmósfera baja.
Uso: python tools/blender/mapa_bloques_vistas.py 722 > vistas.json"""
import json, sys

def vistas(cz):
    m = cz * 0.5
    return [
        ("01_aerea_sur", (0, 330, -440), (0, 0, m)),
        ("02_aerea_este", (560, 300, 180), (0, 0, m)),
        ("03_aerea_oeste", (-560, 300, 180), (0, 0, m)),
        ("04_aerea_norte", (0, 420, cz + 680), (0, 0, m)),
        ("05_cenital", (0, 1250, m - 1), (0, 0, m)),
        ("06_plaza_desde_la_aparicion", (0, 48, -165), (0, 4, 0)),
        ("07_plaza_hacia_el_volcan", (0, 12, -120), (0, 30, cz)),
        ("08_plaza_desde_arriba", (120, 150, -120), (0, 0, 0)),
        ("09_estanque", (56, 11, 50), (31, 5, 76)),
        ("10_estanque_sagrado", (34, 12, -30), (0, 5, 0)),
        ("11_playa", (210, 8, -150), (0, 8, 0)),
        ("12_faro_y_costa", (-260, 30, -250), (0, 10, 0)),
        ("13_puente_hacia_el_arco", (0, 20, 150), (0, 45, 258)),
        ("14_volcan_desde_el_mar", (680, 60, cz), (0, 90, cz)),
        ("15_paseo_del_crater", (0, 36, cz - 222), (0, 40, cz)),
        ("16_lago_del_gigante", (150, 85, cz - 150), (0, 0, cz)),
    ]

if __name__ == "__main__":
    cz = float(sys.argv[1])
    print(json.dumps([{"nombre": n, "pos": p, "mira": l} for n, p, l in vistas(cz)]))
