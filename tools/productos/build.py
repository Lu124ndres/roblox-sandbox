from compose import *
L = load
P = []
for n in range(1, 11):
    P.append((f"Power{n}", "poder", L("cristales.png"), f"x{2**n}"))
    P.append((f"Coins{n}", "monedas", L("monedas.png"), f"x{2**n}"))
for n in range(1, 7):
    P.append((f"ServerBoost{n}", "boost", L("rayo_impulso.png"), f"x{2**n}"))
for p in (25, 50, 75):
    P.append((f"Fill{p}", "llenar", L("cubeta.png"), f"+{p}%"))
P += [
    ("PackInicio", "pack", L("pack_inicio.png"), "Inicio"),
    ("ChooseOrca", "monstruo", L("orca.png"), ""),
    ("ChooseOrcaFantasma", "monstruo", L("orca_fantasma.png"), ""),
    ("ChooseMinotauro", "monstruo", L("minotauro.png"), ""),
    ("ChooseDragonMarino", "monstruo", L("dragon.png"), ""),
    ("ChooseZorroDeAgua", "monstruo", L("zorro.png"), ""),
    ("RestTime", "descanso", L("descanso.png"), "+1 min"),
    ("Spin1", "ruleta", L("ruleta.png"), "+1 giro"),
    ("Spin5", "ruleta", L("ruleta.png"), "+5 giros"),
    ("Pase_VIP", "vip", L("corona.png"), "VIP"),
    ("Pase_ReyDelMar", "mar", L("rey_del_mar.png"), ""),
    ("Pase_DiosDelVolcan", "volcan", L("dios_volcan.png"), ""),
]
mult = {2: "1.5", 3: "2", 4: "3", 5: "4", 6: "6", 7: "8", 8: "12", 9: "16", 10: "25", 11: "50"}
for n, m in mult.items():
    P.append((f"Pond{n}", "estanque", L("estanque.png"), f"x{m}"))
for n in range(2, 11):
    P.append((f"Rod{n}", "cana", cell("equipo_rod.png", n), f"Nv {n}"))
for n in range(2, 7):
    P.append((f"Basket{n}", "canasta", cell("equipo_basket.png", n), f"Nv {n}"))
    P.append((f"Boots{n}", "botas", cell("equipo_boots.png", n), f"Nv {n}"))
for k in P:
    make(*k)
gift = L("regalo.png")
for key, kind, ic in (("GiftVIP", "vip", "corona.png"), ("GiftReyDelMar", "mar", "rey_del_mar.png"),
                      ("GiftDiosDelVolcan", "volcan", "dios_volcan.png")):
    make(key, kind, L(ic), "Regalo", sub=(gift, 170, (390, 330)))
print(len(P) + 3)
