--!strict
--[[
	ServerEvents

	Lee el evento del servidor que está activo (Config/Events) de la carpeta
	de impulsos (atributos Evento, EventoHasta y EventoSiguiente, los pone
	server/Social/EventScheduler). Lo usan Perks (multiplicadores) y el HUD.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = require(script.Parent.Config.Events)
local Protocol = require(script.Parent.Protocol)

local ATTR = Protocol.BoostAttributes

local ServerEvents = {}

local function folder(): Instance?
	return ReplicatedStorage:FindFirstChild(Protocol.BoostFolder)
end

-- El evento activo ahora (nil si no hay).
function ServerEvents.active(): Events.EventDef?
	local boosts = folder()
	if not boosts then
		return nil
	end
	local id = boosts:GetAttribute(ATTR.Event)
	local untilTime = boosts:GetAttribute(ATTR.EventUntil)
	if type(id) ~= "string" or type(untilTime) ~= "number" then
		return nil
	end
	if untilTime <= Workspace:GetServerTimeNow() then
		return nil
	end
	for _, kind in Events.kinds do
		if kind.id == id then
			return kind
		end
	end
	return nil
end

-- Segundos que le quedan al activo, o que faltan para el siguiente.
function ServerEvents.secondsLeft(): number
	local boosts = folder()
	local untilTime = boosts and boosts:GetAttribute(ATTR.EventUntil)
	return if type(untilTime) == "number"
		then math.max(0, untilTime - Workspace:GetServerTimeNow())
		else 0
end

function ServerEvents.secondsToNext(): number
	local boosts = folder()
	local nextAt = boosts and boosts:GetAttribute(ATTR.NextEventAt)
	return if type(nextAt) == "number"
		then math.max(0, nextAt - Workspace:GetServerTimeNow())
		else 0
end

-- Valor del campo del evento activo ("coins", "power", "luck", "biteDelay") o `fallback`.
function ServerEvents.value(field: string, fallback: number): number
	local kind = ServerEvents.active()
	local value = kind and (kind :: any)[field]
	return if type(value) == "number" then value else fallback
end

return ServerEvents
