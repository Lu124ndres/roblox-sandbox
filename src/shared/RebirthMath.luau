--!strict
--[[
	RebirthMath

	Cuentas del renacer (Config/Rebirth), compartidas por el servidor (que
	decide) y el HUD (que muestra): cuánto cuesta el siguiente y qué tan
	rápido alimenta con los que ya tiene (atributo Rebirths del jugador).
]]

local Giants = require(script.Parent.Config.Giants)
local Rebirth = require(script.Parent.Config.Rebirth)
local Protocol = require(script.Parent.Protocol)

local RebirthMath = {}

function RebirthMath.count(player: Player): number
	local value = player:GetAttribute(Protocol.PlayerAttributes.Rebirths)
	return if type(value) == "number" then value else 0
end

function RebirthMath.cost(rebirths: number): number
	return Rebirth.baseCoins * Rebirth.growth ^ rebirths
end

-- Cuántas veces más rápido alimenta con `rebirths` renacimientos.
function RebirthMath.feedMultiplier(rebirths: number): number
	return Rebirth.feedGrowth ^ rebirths
end

-- Peces por segundo que entrega al monstruo (sin contar el tope de una persona).
function RebirthMath.fishPerSecond(rebirths: number): number
	return Giants.delivery.fishPerSecond * RebirthMath.feedMultiplier(rebirths)
end

return RebirthMath
