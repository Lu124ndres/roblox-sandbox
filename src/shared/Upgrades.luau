--!strict
--[[
	Upgrades

	Lectura de las mejoras de la tienda (Config.Shop) para servidor y
	cliente: qué nivel tiene un jugador (atributo con el nombre de la
	categoría), qué da ese nivel y cómo se describe en la tienda.
	rodLuck es lo que rinde su caña de verdad: con la caña suprema de la
	ruleta (atributo CanaSuprema), x`superRod.multiplier`. La caña solo da
	suerte; ya no multiplica el poder (2026-10-21).
]]

local Config = require(script.Parent.Config)
local NumberFormat = require(script.Parent.NumberFormat)
local Protocol = require(script.Parent.Protocol)
local SPIN = require(script.Parent.Config.Spin)

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

local function superRodMultiplier(player: Player): number
	return if player:GetAttribute(Protocol.PlayerAttributes.SuperRod) == true
		then SPIN.superRod.multiplier
		else 1
end

-- Suerte de su caña (peso extra de los peces mejores); con la caña suprema, x3 la mejor que tenga.
function Upgrades.rodLuck(player: Player): number
	return Upgrades.current(player, "Rod").value * superRodMultiplier(player)
end

-- La suerte que daría la caña `level` (la caña nunca baja: si ya tiene una mejor, la suya),
-- con la caña suprema si la tiene. Para mostrar el antes y el después de una compra.
function Upgrades.rodLuckAt(player: Player, level: number): number
	local list = Upgrades.list("Rod")
	local best = math.max(Upgrades.level(player, "Rod"), math.clamp(math.floor(level), 1, #list))
	return list[best].value * superRodMultiplier(player)
end

local function times(value: number): string
	return if value % 1 == 0 then NumberFormat.short(value) else string.format("%.1f", value)
end

local function percent(value: number): string
	return `+{NumberFormat.short(math.round(value * 100))}%`
end

-- Texto corto de lo que da un nivel ("+15% suerte").
function Upgrades.describe(category: Category, def: Config.UpgradeDef): string
	if category == "Rod" then
		return if def.value > 0 then `{percent(def.value)} suerte` else "Sin suerte extra"
	elseif category == "Basket" then
		return `x{times(def.value)} capacidad de la canasta`
	end
	return `Velocidad {def.value}`
end

export type Stat = { label: string, value: string }

-- Lo que da un nivel, dato por dato (para comparar "ahora → siguiente" en MEJORAS).
function Upgrades.stats(category: Category, def: Config.UpgradeDef): { Stat }
	if category == "Rod" then
		return { { label = "Suerte", value = percent(def.value) } }
	elseif category == "Basket" then
		return { { label = "Capacidad", value = `x{times(def.value)}` } }
	end
	return { { label = "Velocidad", value = times(def.value) } }
end

return Upgrades
