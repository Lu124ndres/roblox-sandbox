--!strict
--[[
	Upgrades

	Lectura de las mejoras de la tienda (Config.Shop) para servidor y
	cliente: qué nivel tiene un jugador (atributo con el nombre de la
	categoría), qué da ese nivel y cómo se describe en la tienda.
]]

local Config = require(script.Parent.Config)
local NumberFormat = require(script.Parent.NumberFormat)

export type Category = "Rod" | "Basket" | "Boots"

local Upgrades = {}

local CATEGORIES: { Category } = { "Rod", "Basket", "Boots" }
local TITLES: { [Category]: string } = {
	Rod = "Cañas",
	Basket = "Canastas",
	Boots = "Botas",
}
Upgrades.categories = CATEGORIES
Upgrades.titles = TITLES

function Upgrades.list(category: Category): { Config.UpgradeDef }
	return Config.Shop[category]
end

function Upgrades.isCategory(value: unknown): boolean
	return value == "Rod" or value == "Basket" or value == "Boots"
end

-- Nivel actual de un jugador (1 si todavía no se cargó).
function Upgrades.level(player: Player, category: Category): number
	local value = player:GetAttribute(category)
	local list = Upgrades.list(category)
	return if type(value) == "number" then math.clamp(math.floor(value), 1, #list) else 1
end

function Upgrades.current(player: Player, category: Category): Config.UpgradeDef
	return Upgrades.list(category)[Upgrades.level(player, category)]
end

local function times(value: number): string
	return if value % 1 == 0 then NumberFormat.short(value) else string.format("%.1f", value)
end

-- Texto corto de lo que da un nivel ("x3 poder · +15 % suerte").
function Upgrades.describe(category: Category, def: Config.UpgradeDef): string
	if category == "Rod" then
		local luck = def.luck or 0
		local text = `x{times(def.value)} poder al entrenar`
		return if luck > 0 then `{text} · +{math.round(luck * 100)} % suerte` else text
	elseif category == "Basket" then
		return `x{times(def.value)} capacidad de la canasta`
	end
	return `Velocidad {def.value}`
end

return Upgrades
