--!strict
--[[
	EventScheduler

	Cada Config.Events.everyMinutes empieza un evento al azar (distinto del
	anterior y nunca uno adminOnly) para todo el servidor, que dura
	durationMinutes. Lo publica en la carpeta de impulsos (Evento,
	EventoHasta, EventoSiguiente) y avisa a todos (Notice "event").
	El panel de administrador suma eventos EXTRA encima del programado, cada
	uno con sus minutos, y se pueden tener todos a la vez (pedido del usuario
	el 2026-10-26): van en el atributo EventosExtra como JSON
	{ [id] = { inicio, fin } }. stop corta el programado y todos los extra.
	Shared/ServerEvents los junta y Shared/Perks aplica la suma.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = require(ReplicatedStorage.Shared.Config.Events)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Remotes = require(script.Parent.Parent.Remotes)

local ATTR = Protocol.BoostAttributes

local EventScheduler = {}

local rng = Random.new()
local stopped = false -- el admin cortó el programado
local extras: { [string]: { number } } = {} -- id -> { inicio, fin } (hora del servidor)
local boosts: Instance? = nil

local function find(id: string): Events.EventDef?
	for _, kind in Events.kinds do
		if kind.id == id then
			return kind
		end
	end
	return nil
end

local function pick(last: string?): Events.EventDef
	local options = {}
	for _, option in Events.kinds do
		if option.id ~= last and not option.adminOnly then
			table.insert(options, option)
		end
	end
	return options[rng:NextInteger(1, #options)]
end

-- Espera hasta `time` (hora del servidor), o hasta que el admin corte el actual.
local function waitUntil(time: number)
	while Workspace:GetServerTimeNow() < time and not stopped do
		task.wait(1)
	end
	stopped = false
end

local function publishExtras()
	if boosts then
		boosts:SetAttribute(ATTR.ExtraEvents, HttpService:JSONEncode(extras))
	end
end

-- Panel de administrador: suma ese evento ya, por `minutes` (nil = la duración normal).
-- Si ya estaba, vuelve a empezar con esos minutos.
function EventScheduler.force(id: string, minutes: number?): boolean
	if not find(id) then
		return false
	end
	local now = Workspace:GetServerTimeNow()
	extras[id] = { now, now + (minutes or Events.durationMinutes) * 60 }
	publishExtras()
	Remotes.Notice:FireAllClients("event", id)
	return true
end

-- Panel de administrador: todos los eventos normales a la vez.
function EventScheduler.all(minutes: number?): number
	local count = 0
	for _, kind in Events.kinds do
		if not kind.adminOnly and EventScheduler.force(kind.id, minutes) then
			count += 1
		end
	end
	return count
end

-- Panel de administrador: termina el programado y todos los extra (el siguiente sigue su horario).
function EventScheduler.stop()
	-- Solo si hay uno programado activo: en la espera, cortar adelantaría el siguiente.
	local current = boosts and boosts:GetAttribute(ATTR.Event)
	stopped = type(current) == "string" and current ~= ""
	table.clear(extras)
	publishExtras()
end

function EventScheduler.init()
	local folder = ReplicatedStorage:WaitForChild(Protocol.BoostFolder)
	boosts = folder
	publishExtras()
	-- Los extra vencidos se borran solos.
	task.spawn(function()
		while true do
			task.wait(1)
			local now, changed = Workspace:GetServerTimeNow(), false
			for id, span in extras do
				if span[2] <= now then
					extras[id] = nil
					changed = true
				end
			end
			if changed then
				publishExtras()
			end
		end
	end)
	task.spawn(function()
		local last: string? = nil
		local nextAt = Workspace:GetServerTimeNow() + Events.firstDelayMinutes * 60
		while true do
			folder:SetAttribute(ATTR.NextEventAt, nextAt)
			waitUntil(nextAt)
			local kind = pick(last)
			last = kind.id
			local endsAt = Workspace:GetServerTimeNow() + Events.durationMinutes * 60
			folder:SetAttribute(ATTR.Event, kind.id)
			folder:SetAttribute(ATTR.EventUntil, endsAt)
			Remotes.Notice:FireAllClients("event", kind.id)
			nextAt = endsAt + Events.everyMinutes * 60
			folder:SetAttribute(ATTR.NextEventAt, nextAt)
			waitUntil(endsAt)
			folder:SetAttribute(ATTR.Event, "")
		end
	end)
end

return EventScheduler
