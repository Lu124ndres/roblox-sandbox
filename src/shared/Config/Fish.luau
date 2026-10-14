--!strict
--[[
	Peces y rarezas.

	weight es el peso relativo en la tirada (no un porcentaje). Con estos
	pesos (total 1,031): común 70 %, poco común 19 %, raro 7.8 %, épico 2.3 %,
	legendario 0.6 % y mítico 0.05 % (1 de cada ~2,000 peces).

	Comida media por pez: 2.75. Monedas base medias: 4.57 (se multiplican por
	el gigante actual). Ver docs/alcance.md, "Calibración".
]]

local Types = require(script.Parent.Types)

local Fish: Types.EconomyConfig = {
	rarities = {
		{ id = "Comun", displayName = "Común" },
		{ id = "PocoComun", displayName = "Poco común" },
		{ id = "Raro", displayName = "Raro" },
		{ id = "Epico", displayName = "Épico" },
		{ id = "Legendario", displayName = "Legendario" },
		{ id = "Mitico", displayName = "Mítico" },
	},
	fish = {
		{
			id = "Sardina",
			displayName = "Sardina",
			rarity = "Comun",
			weight = 300,
			food = 1,
			coins = 1,
		},
		{
			id = "Anchoa",
			displayName = "Anchoa",
			rarity = "Comun",
			weight = 240,
			food = 1,
			coins = 1,
		},
		{
			id = "Caballa",
			displayName = "Caballa",
			rarity = "Comun",
			weight = 180,
			food = 2,
			coins = 3,
		},
		{
			id = "PezPayaso",
			displayName = "Pez payaso",
			rarity = "PocoComun",
			weight = 110,
			food = 3,
			coins = 5,
		},
		{
			id = "PargoRojo",
			displayName = "Pargo rojo",
			rarity = "PocoComun",
			weight = 90,
			food = 4,
			coins = 6,
		},
		{
			id = "PezGlobo",
			displayName = "Pez globo",
			rarity = "Raro",
			weight = 45,
			food = 6,
			coins = 10,
		},
		{ id = "Atun", displayName = "Atún", rarity = "Raro", weight = 35, food = 8, coins = 14 },
		{
			id = "PezEspada",
			displayName = "Pez espada",
			rarity = "Epico",
			weight = 14,
			food = 15,
			coins = 30,
		},
		{
			id = "RapeAbisal",
			displayName = "Rape abisal",
			rarity = "Epico",
			weight = 10,
			food = 18,
			coins = 36,
		},
		{
			id = "PezLuna",
			displayName = "Pez luna",
			rarity = "Legendario",
			weight = 4,
			food = 35,
			coins = 80,
		},
		{
			id = "PezDorado",
			displayName = "Pez dorado",
			rarity = "Legendario",
			weight = 2.5,
			food = 45,
			coins = 120,
		},
		{
			id = "PezArcoiris",
			displayName = "Pez arcoíris",
			rarity = "Mitico",
			weight = 0.5,
			food = 100,
			coins = 400,
		},
	},
}

return Fish
