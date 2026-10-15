--!strict
--[[
	Peces nuevos de la colección (se agregan al final de Config/Fish): dos
	por rareza. Su forma 3D está en client/Effects/FishShapesMore y su color
	en UIConfig/FishColors.
]]

local Types = require(script.Parent.Types)

local function fish(
	id: string,
	name: string,
	rarity: string,
	weight: number,
	food: number,
	coins: number
): Types.FishDef
	return {
		id = id,
		displayName = name,
		rarity = rarity,
		weight = weight,
		food = food,
		coins = coins,
	}
end

local FishMore: { Types.FishDef } = {
	fish("Arenque", "Arenque", "Comun", 160, 1, 2),
	fish("Lenguado", "Lenguado", "Comun", 140, 2, 2),
	fish("PezCirujano", "Pez cirujano", "PocoComun", 80, 3, 5),
	fish("PezLoro", "Pez loro", "PocoComun", 70, 4, 6),
	fish("PezLeon", "Pez león", "Raro", 30, 7, 12),
	fish("Barracuda", "Barracuda", "Raro", 28, 9, 15),
	fish("Mantarraya", "Mantarraya", "Raro", 22, 10, 18),
	fish("TiburonMartillo", "Tiburón martillo", "Epico", 8, 22, 45),
	fish("PezVela", "Pez vela", "Epico", 7, 25, 50),
	fish("Celacanto", "Celacanto", "Legendario", 2, 55, 150),
	fish("PezCristal", "Pez de cristal", "Legendario", 1.5, 60, 180),
	fish("PezGalaxia", "Pez galaxia", "Mitico", 0.3, 150, 600),
}

return FishMore
