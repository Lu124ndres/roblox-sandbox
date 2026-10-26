--!strict
--[[
	ServerEvents

	Lee los eventos del servidor que están activos (Config/Events) de la
	carpeta de impulsos: el programado (atributos Evento, EventoHasta y
	EventoSiguiente) y los extra que sumó el panel admin (EventosExtra, JSON
	{ [id] = { inicio, fin } }); los pone server/Social/EventScheduler. Puede
	haber varios a la vez: Perks suma lo de todos (la suerte se suma, lo demás
	se multiplica). Lo usan Perks y el HUD.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = require(script.Parent.Config.Events)
local Protocol = require(script.Parent.Protocol)

local ATTR = Protocol.BoostAttributes
local SUMMED = { luck = true } -- el resto de los campos se multiplica

export type Active = { kind: Events.EventDef, started: number, ends: number }

local ServerEvents = {}

local function folder(): Instance?
	return ReplicatedStorage:FindFirstChild(Protocol.BoostFolder)
end

local function find(id: unknown): Events.EventDef?
	for _, kind in Events.kinds do
		if kind.id == id then
			return kind
		end
	end
	return nil
end

-- JSON de EventosExtra (se relee solo cuando cambia).
local cachedText: string? = nil
local cachedExtras: { [string]: any } = {}
local function extras(boosts: Instance): { [string]: any }
	local text = boosts:GetAttribute(ATTR.ExtraEvents)
	if type(text) ~= "string" then
		return {}
	end
	if text ~= cachedText then
		cachedText = text
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, text)
		cachedExtras = if ok and type(decoded) == "table" then decoded else {}
	end
	return cachedExtras
end

-- Todos los activos ahora, el que empezó último primero.
function ServerEvents.list(): { Active }
	local boosts = folder()
	if not boosts then
		return {}
	end
	local now = Workspace:GetServerTimeNow()
	local list: { Active } = {}
	local byId: { [string]: Active } = {}
	local function add(kind: Events.EventDef?, started: number, ends: number)
		if not kind or ends <= now then
			return
		end
		local seen = byId[kind.id]
		if seen then -- el mismo como programado y extra: cuenta una vez, hasta el que dure más
			seen.ends = math.max(seen.ends, ends)
			seen.started = math.max(seen.started, started)
			return
		end
		local entry = { kind = kind, started = started, ends = ends }
		byId[kind.id] = entry
		table.insert(list, entry)
	end
	local untilTime = boosts:GetAttribute(ATTR.EventUntil)
	if type(untilTime) == "number" then
		add(
			find(boosts:GetAttribute(ATTR.Event)),
			untilTime - Events.durationMinutes * 60,
			untilTime
		)
	end
	for id, span in extras(boosts) do
		if type(span) == "table" and type(span[1]) == "number" and type(span[2]) == "number" then
			add(find(id), span[1], span[2])
		end
	end
	table.sort(list, function(a, b)
		return a.started > b.started
	end)
	return list
end

-- El evento que se ve (el último que empezó; nil si no hay ninguno).
function ServerEvents.active(): Events.EventDef?
	local first = ServerEvents.list()[1]
	return if first then first.kind else nil
end

-- Segundos que le quedan al que más dura de los activos (0 si no hay).
function ServerEvents.secondsLeft(): number
	local now, left = Workspace:GetServerTimeNow(), 0
	for _, entry in ServerEvents.list() do
		left = math.max(left, entry.ends - now)
	end
	return left
end

-- Segundos que le quedan a ese evento (0 si no está activo).
function ServerEvents.secondsLeftOf(id: string): number
	for _, entry in ServerEvents.list() do
		if entry.kind.id == id then
			return math.max(0, entry.ends - Workspace:GetServerTimeNow())
		end
	end
	return 0
end

function ServerEvents.secondsToNext(): number
	local boosts = folder()
	local nextAt = boosts and boosts:GetAttribute(ATTR.NextEventAt)
	return if type(nextAt) == "number"
		then math.max(0, nextAt - Workspace:GetServerTimeNow())
		else 0
end

-- Lo que dan todos los activos juntos en ese campo ("coins", "power", "luck",
-- "biteDelay"): la suerte se suma y lo demás se multiplica. `fallback` si ninguno lo da.
function ServerEvents.value(field: string, fallback: number): number
	local total: number? = nil
	for _, entry in ServerEvents.list() do
		local value = (entry.kind :: any)[field]
		if type(value) == "number" then
			total = if total == nil
				then value
				elseif SUMMED[field] then total + value
				else total * value
		end
	end
	return total or fallback
end

return ServerEvents
