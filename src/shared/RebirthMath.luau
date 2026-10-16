--!strict
--[[
	RebirthMath

	Cuentas del renacer (Config/Rebirth), compartidas por el servidor (que
	decide) y el HUD (que muestra): cuántas monedas y cuánto poder pide el
	siguiente, qué tan rápido alimenta con los que ya tiene (atributo
	Rebirths del jugador) y cuánto multiplica sus monedas y su poder. Los
	precios se redondean a dos cifras.
]]

local Giants = require(script.Parent.Config.Giants)
local NumberFormat = require(script.Parent.NumberFormat)
local Rebirth = require(script.Parent.Config.Rebirth)
local Protocol = require(script.Parent.Protocol)

local RebirthMath = {}

function RebirthMath.count(player: Player): number
	local value = player:GetAttribute(Protocol.PlayerAttributes.Rebirths)
	return if type(value) == "number" then value else 0
end

-- Redondea a dos cifras significativas (48,234 -> 48,000).
local function round(value: number): number
	local step = 10 ^ math.max(0, math.floor(math.log10(math.max(value, 1))) - 1)
	return math.floor(value / step + 0.5) * step
end

-- Monedas que pide el renacimiento número rebirths + 1.
function RebirthMath.cost(rebirths: number): number
	return round(Rebirth.baseCoins * Rebirth.growth ^ rebirths)
end

-- Poder que pide el renacimiento número rebirths + 1.
function RebirthMath.powerCost(rebirths: number): number
	return round(Rebirth.basePower * Rebirth.powerGrowth ^ rebirths)
end

function RebirthMath.canRebirth(coins: number, power: number, rebirths: number): boolean
	return coins >= RebirthMath.cost(rebirths) and power >= RebirthMath.powerCost(rebirths)
end

-- Cuántas veces más rápido alimenta con `rebirths` renacimientos.
function RebirthMath.feedMultiplier(rebirths: number): number
	return Rebirth.feedGrowth ^ rebirths
end

-- Peces por segundo que entrega al monstruo (sin contar el tope de una persona).
function RebirthMath.fishPerSecond(rebirths: number): number
	return Giants.delivery.fishPerSecond * RebirthMath.feedMultiplier(rebirths)
end

-- Peces por segundo que entrega con esa canasta: los de renacer o, si es más
-- rápido, la canasta llena en Giants.delivery.basketSeconds.
function RebirthMath.deliveryPerSecond(rebirths: number, capacity: number): number
	return math.max(RebirthMath.fishPerSecond(rebirths), capacity / Giants.delivery.basketSeconds)
end

-- Multiplicador permanente de monedas y poder con `rebirths` renacimientos (x1.25 cada uno).
function RebirthMath.bonusMultiplier(rebirths: number): number
	return Rebirth.bonusGrowth ^ rebirths
end

-- "x1.25" / "x2" para la ventana de renacer.
function RebirthMath.bonusText(rebirths: number): string
	local value = RebirthMath.bonusMultiplier(rebirths)
	if value >= 100 then
		return `x{NumberFormat.short(value)}`
	end
	local text = string.gsub(string.format("%.2f", value), "0+$", "")
	return `x{(string.gsub(text, "%.$", ""))}`
end

-- Peces por segundo para mostrar: con un decimal mientras son pocos ("4.1", "10").
function RebirthMath.speedText(rebirths: number): string
	local perSecond = RebirthMath.fishPerSecond(rebirths)
	if perSecond < 100 then
		return (string.gsub(string.format("%.1f", perSecond), "%.0$", ""))
	end
	return NumberFormat.short(perSecond)
end

return RebirthMath
