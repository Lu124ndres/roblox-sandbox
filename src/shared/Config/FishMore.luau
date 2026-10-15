--!strict
--[[
	Peces nuevos de la colección (se agregan al final de Config/Fish): dos
	tandas de dos por rareza (36 especies en total). Su forma 3D está en client/Effects/FishShapesMore y su color
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
	-- Tercera tanda (formas en client/Effects/FishShapesMore2).
	fish("Boqueron", "Boquerón", "Comun", 150, 1, 2),
	fish("PezGato", "Pez gato", "Comun", 120, 2, 3),
	fish("PezMariposa", "Pez mariposa", "PocoComun", 75, 3, 5),
	fish("PezAngel", "Pez ángel", "PocoComun", 65, 4, 6),
	fish("Morena", "Morena", "Raro", 26, 8, 14),
	fish("PezNapoleon", "Pez napoleón", "Raro", 24, 10, 17),
	fish("TiburonBlanco", "Tiburón blanco", "Epico", 7, 24, 48),
	fish("PezRemo", "Pez remo", "Epico", 6, 26, 55),
	fish("PezDragon", "Pez dragón", "Legendario", 1.8, 58, 165),
	fish("PezFenix", "Pez fénix", "Legendario", 1.4, 62, 190),
	fish("PezEstelar", "Pez estelar", "Mitico", 0.25, 160, 650),
	fish("PezCelestial", "Pez celestial", "Mitico", 0.2, 170, 700),
}

return FishMore
