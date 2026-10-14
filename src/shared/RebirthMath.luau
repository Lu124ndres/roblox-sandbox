--!strict
--[[
	RebirthMath

	Cuentas del renacer (Config/Rebirth), compartidas por el servidor (que
	decide) y el HUD (que muestra): cuánto cuesta el siguiente y cuánto
	multiplica el que ya tiene (atributo Rebirths del jugador).
]]

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

function RebirthMath.multiplier(rebirths: number): number
	return 1 + Rebirth.bonusPerRebirth * rebirths
end

return RebirthMath
