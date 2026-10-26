--!strict
--[[
	EventScheduler

	Cada Config.Events.everyMinutes empieza un evento al azar (distinto del
	anterior y nunca uno adminOnly) para todo el servidor, que dura
	durationMinutes. El panel de administrador puede lanzar uno ya, con los
	minutos que quiera, o terminar el que está (force, stop). Lo publica en
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
-- El panel de administrador puede lanzar uno ya (con sus minutos) o cortar el actual.
local forced: { id: string, minutes: number? }? = nil
local stopped = false

local function find(id: string): Events.EventDef?
	for _, kind in Events.kinds do
		if kind.id == id then
			return kind
		end
	end
	return nil
end

local function pick(last: string?): (Events.EventDef, number)
	local order = forced
	forced = nil
	local kind = order and find(order.id)
	if order and kind then
		return kind, order.minutes or Events.durationMinutes
	end
	local options = {}
	for _, option in Events.kinds do
		if option.id ~= last and not option.adminOnly then
			table.insert(options, option)
		end
	end
	return options[rng:NextInteger(1, #options)], Events.durationMinutes
end

-- Espera hasta `time` (hora del servidor), o hasta que el admin pida uno o corte el actual.
local function waitUntil(time: number)
	while Workspace:GetServerTimeNow() < time and not forced and not stopped do
		task.wait(1)
	end
	stopped = false
end

-- Panel de administrador: lanza ese evento ahora (minutes: su duración; nil = la normal).
function EventScheduler.force(id: string, minutes: number?): boolean
	if not find(id) then
		return false
	end
	forced = { id = id, minutes = minutes }
	return true
end

-- Panel de administrador: termina el evento que está activo (el siguiente sigue su horario).
function EventScheduler.stop()
	stopped = true
end

function EventScheduler.init()
	local boosts = ReplicatedStorage:WaitForChild(Protocol.BoostFolder)
	task.spawn(function()
		local last: string? = nil
		local nextAt = Workspace:GetServerTimeNow() + Events.firstDelayMinutes * 60
		while true do
			boosts:SetAttribute(ATTR.NextEventAt, nextAt)
			waitUntil(nextAt)
			local kind, minutes = pick(last)
			last = kind.id
			local endsAt = Workspace:GetServerTimeNow() + minutes * 60
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
