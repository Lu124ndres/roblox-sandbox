--!strict
--[[
	EventScheduler

	Cada Config.Events.everyMinutes empieza un evento al azar (distinto del
	anterior) para todo el servidor, que dura durationMinutes. Lo publica en
	la carpeta de impulsos (Evento, EventoHasta, EventoSiguiente) y avisa a
	todos (Notice "event"). Los multiplicadores los aplica Shared/Perks.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = require(ReplicatedStorage.Shared.Config.Events)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Remotes = require(script.Parent.Parent.Remotes)

local ATTR = Protocol.BoostAttributes

local EventScheduler = {}

local rng = Random.new()
local forced: string? = nil -- el panel de administrador puede lanzar uno ya

local function pick(last: string?): Events.EventDef
	if forced then
		for _, kind in Events.kinds do
			if kind.id == forced then
				forced = nil
				return kind
			end
		end
	end
	local options = {}
	for _, kind in Events.kinds do
		if kind.id ~= last then
			table.insert(options, kind)
		end
	end
	return options[rng:NextInteger(1, #options)]
end

-- Espera hasta `time` (hora del servidor), o hasta que el admin pida uno.
local function waitUntil(time: number)
	while Workspace:GetServerTimeNow() < time and not forced do
		task.wait(1)
	end
end

-- Panel de administrador: lanza ese evento ahora.
function EventScheduler.force(id: string)
	forced = id
end

function EventScheduler.init()
	local boosts = ReplicatedStorage:WaitForChild(Protocol.BoostFolder)
	task.spawn(function()
		local last: string? = nil
		local nextAt = Workspace:GetServerTimeNow() + Events.firstDelayMinutes * 60
		while true do
			boosts:SetAttribute(ATTR.NextEventAt, nextAt)
			waitUntil(nextAt)
			local kind = pick(last)
			last = kind.id
			local endsAt = Workspace:GetServerTimeNow() + Events.durationMinutes * 60
			boosts:SetAttribute(ATTR.Event, kind.id)
			boosts:SetAttribute(ATTR.EventUntil, endsAt)
			Remotes.Notice:FireAllClients("event", kind.id)
			nextAt = endsAt + Events.everyMinutes * 60
			boosts:SetAttribute(ATTR.NextEventAt, nextAt)
			waitUntil(endsAt)
			boosts:SetAttribute(ATTR.Event, "")
		end
	end)
end

return EventScheduler
