--!strict
--[[
	Peces limitados: uno por actualización semanal (docs/roadmap.md). Solo
	pican entre `limited.from` y `limited.to` (unix UTC, hora del servidor);
	quien lo pescó lo conserva en el índice para siempre. No cuentan para la
	colección completa, sus hitos ni la suerte de su sección (shared/FishCatalog).
	Su forma 3D está en client/Effects/FishShapesMore2 y su color en
	UIConfig/FishColors.
]]

local Types = require(script.Parent.Types)

local FishLimited: { Types.FishDef } = {
	{
		-- Cierre de Halloween: del sábado 31 de octubre a las 9:00 de México al 3 de noviembre.
		id = "PezEsqueleto",
		displayName = "Pez esqueleto",
		rarity = "Legendario",
		weight = 6, -- más fácil que un legendario de la colección: solo hay un fin de semana
		food = 50,
		coins = 140,
		limited = { from = 1793458800, to = 1793664000 },
	},
}

return FishLimited
