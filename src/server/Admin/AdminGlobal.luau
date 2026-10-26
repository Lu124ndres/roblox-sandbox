--!strict
--[[
	Admin/AdminGlobal

	Órdenes del panel para TODOS los servidores del juego (pedido del usuario
	el 2026-10-26: mensaje, eventos y el mismo monstruo en todos). Se mandan
	por MessagingService y cada servidor (este incluido) corre la orden de
	AdminWorld o AdminFun sin admin presente. Solo un admin puede mandarlas
	(AdminService ya lo comprobó) y solo los servidores del juego publican en
	el tema, pero igual se revisa la forma de cada mensaje.
	El anuncio se filtra aquí, una sola vez, antes de salir.
	`servers` pregunta a todos los servidores cómo están y junta las
	respuestas unos segundos (Notice "adminServers" al admin).
	Si MessagingService falla (Studio sin acceso a la API), la orden corre
	solo en este servidor y el aviso lo dice.
]]

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Remotes = require(script.Parent.Parent.Remotes)
local AdminFun = require(script.Parent.AdminFun)
local AdminWorld = require(script.Parent.AdminWorld)

local TOPIC = "PanelAdmin"
local INFO_TOPIC = "PanelAdminInfo"
local PING = "__servidores"
local COLLECT_SECONDS = 3
local NOT_GLOBAL = { unban = true } -- el baneo ya vale para todo el juego
local STATE = Protocol.GiantAttributes
local BOOSTS = Protocol.BoostAttributes

export type ServerInfo = {
	job: string,
	players: number,
	giant: string,
	event: string,
	minutes: number,
}

local HANDLERS: { [string]: AdminWorld.Handler } = table.clone(AdminWorld.HANDLERS)
for name, handler in AdminFun.HANDLERS do
	if not NOT_GLOBAL[name] then
		HANDLERS[name] = handler
	end
end

local AdminGlobal = {}

local startedAt = os.clock()
local collecting: { ServerInfo }? = nil

local function info(): ServerInfo
	local state = ReplicatedStorage:FindFirstChild(Protocol.GiantStateFolder)
	local boosts = ReplicatedStorage:FindFirstChild(Protocol.BoostFolder)
	local giant = state and state:GetAttribute(STATE.DisplayName)
	local event = boosts and boosts:GetAttribute(BOOSTS.Event)
	return {
		job = if game.JobId == "" then "Studio" else string.sub(game.JobId, 1, 8),
		players = #Players:GetPlayers(),
		giant = if type(giant) == "string" then giant else "?",
		event = if type(event) == "string" then event else "",
		minutes = math.floor((os.clock() - startedAt) / 60),
	}
end

local function publish(topic: string, payload: { [string]: any }): boolean
	local ok, err = pcall(MessagingService.PublishAsync, MessagingService, topic, payload)
	if not ok then
		warn(`AdminGlobal: no se pudo publicar ({err})`)
	end
	return ok
end

local function run(name: string, value: unknown, by: string): string
	local handler = HANDLERS[name]
	if not handler then
		return "orden desconocida"
	end
	local ok, result = pcall(handler, value, by, nil)
	return if ok then tostring(result) else `Error: {result}`
end

function AdminGlobal.has(name: string): boolean
	return HANDLERS[name] ~= nil or name == "servers"
end

-- Manda la orden a todos los servidores (este incluido). Devuelve el aviso para el admin.
function AdminGlobal.send(admin: Player, name: string, value: unknown): string
	if name == "servers" then
		return AdminGlobal.servers(admin)
	end
	assert(HANDLERS[name], "esa orden no es para todos los servidores")
	if name == "announce" then
		value = AdminFun.filter(value, admin.UserId)
	end
	local payload = { n = name, v = value, by = admin.DisplayName }
	if publish(TOPIC, payload) then
		return `Enviado a todos los servidores: {name}`
	end
	return `Solo este servidor (MessagingService falló): {run(name, value, admin.DisplayName)}`
end

-- Pregunta a todos los servidores y manda la lista al admin.
function AdminGlobal.servers(admin: Player): string
	collecting = {}
	local list = collecting :: { ServerInfo }
	if not publish(TOPIC, { n = PING }) then
		table.insert(list, info())
	end
	task.wait(COLLECT_SECONDS)
	collecting = nil
	table.sort(list, function(a, b)
		return a.players > b.players
	end)
	Remotes.Notice:FireClient(admin, "adminServers", list)
	local players = 0
	for _, server in list do
		players += server.players
	end
	return `{#list} servidores, {players} jugadores`
end

function AdminGlobal.init()
	task.spawn(function()
		local ok, err = pcall(
			MessagingService.SubscribeAsync,
			MessagingService,
			TOPIC,
			function(message)
				local data = message.Data
				if type(data) ~= "table" or type(data.n) ~= "string" then
					return
				end
				if data.n == PING then
					publish(INFO_TOPIC, info())
				elseif type(data.by) == "string" then
					print(`AdminGlobal: {data.by} -> {data.n}: {run(data.n, data.v, data.by)}`)
				end
			end
		)
		if not ok then
			warn(`AdminGlobal: sin MessagingService ({err})`)
		end
		pcall(MessagingService.SubscribeAsync, MessagingService, INFO_TOPIC, function(message)
			local data = message.Data
			if collecting and type(data) == "table" and type(data.job) == "string" then
				table.insert(collecting, {
					job = data.job,
					players = tonumber(data.players) or 0,
					giant = tostring(data.giant),
					event = tostring(data.event),
					minutes = tonumber(data.minutes) or 0,
				})
			end
		end)
	end)
end

return AdminGlobal
