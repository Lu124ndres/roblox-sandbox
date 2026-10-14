--!strict
--[[
	AdminCommands

	Las órdenes del panel de administrador (AdminService ya comprobó quién
	las manda). run(jugador, nombre, valor) devuelve el texto del aviso.
		power, coins, kills   número: pone ese valor
		fish                  número: agrega esos peces (al azar, hasta llenar)
		emptyBasket           vacía la canasta
		speed                 número: velocidad al caminar (hasta reaparecer)
		Rod, Basket, Boots    número: nivel de esa mejora
		giant                 id: si está comiendo lo cambia ya; si no, es el siguiente
		fill                  fracción 0..1 de la barra del monstruo
		skipRest              termina el descanso del volcán
		event                 id: lanza ya ese evento del servidor (Config/Events)
		pass                  clave: pone o quita ese pase (prueba trajes y ventajas)
		playtime              minutos: adelanta los regalos por tiempo
		tp                    "muelle", "volcan", "plaza" o "tienda"
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local EventScheduler = require(script.Parent.Parent.Social.EventScheduler)
local GiantCycle = require(script.Parent.Parent.GiantCycle)
local GiantService = require(script.Parent.Parent.GiantService)
local PlayerData = require(script.Parent.Parent.PlayerData)

local ATTR = Protocol.PlayerAttributes
local MAX_VALUE = 1e15
local rng = Random.new()

type Handler = (player: Player, value: unknown) -> string

local AdminCommands = {}

local function number(value: unknown, low: number, high: number): number
	assert(type(value) == "number" and value == value, "falta un número")
	return math.clamp(value, low, high)
end

local function setField(field: "power" | "coins" | "kills"): Handler
	return function(player, value)
		local amount = math.floor(number(value, 0, MAX_VALUE))
		PlayerData.edit(player, function(save)
			save[field] = amount
		end)
		return `{field} = {amount}`
	end
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function polar(angle: number, radius: number, height: number): Vector3
	local a = math.rad(angle)
	return Vector3.new(math.cos(a) * radius, height, math.sin(a) * radius)
end

local function place(name: string): Vector3?
	if name == "muelle" then
		local tip = WorldLayout.pierStartRadius + WorldLayout.pierLength - 4
		return polar(WorldLayout.pierAngles[1], tip, WorldLayout.deckHeight + 4)
	elseif name == "volcan" then
		local _, finish = WorldZones.bridgeEnds()
		return finish + Vector3.new(0, 4, 0)
	elseif name == "plaza" then
		return polar(WorldLayout.spawnAngle, WorldLayout.spawnRadius, WorldLayout.plateauHeight + 4)
	elseif name == "tienda" then
		return polar(
			WorldLayout.shopAngle,
			WorldLayout.shopRadius - 10,
			WorldLayout.plateauHeight + 4
		)
	end
	return nil
end

local function upgrade(category: Upgrades.Category): Handler
	return function(player, value)
		local level = math.floor(number(value, 1, #Upgrades.list(category)))
		PlayerData.setUpgrade(player, category, level)
		local humanoid = humanoidOf(player)
		if category == "Boots" and humanoid then
			humanoid.WalkSpeed = Upgrades.current(player, "Boots").value
		end
		return `{Upgrades.list(category)[level].name} (nivel {level})`
	end
end

local HANDLERS: { [string]: Handler } = {
	power = setField("power"),
	coins = setField("coins"),
	kills = setField("kills"),
	Rod = upgrade("Rod"),
	Basket = upgrade("Basket"),
	Boots = upgrade("Boots"),
	fish = function(player, value)
		local wanted = math.floor(number(value, 1, 100000))
		local added = 0
		for _ = 1, wanted do
			if PlayerData.addFish(player, FishCatalog.roll(rng, 0).id, 1) == 0 then
				break
			end
			added += 1
		end
		return `+{added} peces (canasta {PlayerData.getCarriedCount(player)}/{PlayerData.getCapacity(
			player
		)})`
	end,
	emptyBasket = function(player)
		local _, count = PlayerData.takeFishBatch(player, math.huge, math.huge)
		return `Canasta vaciada ({count} peces)`
	end,
	speed = function(player, value)
		local speed = number(value, 8, 300)
		local humanoid = humanoidOf(player)
		if humanoid then
			humanoid.WalkSpeed = speed
		end
		return `Velocidad {speed}`
	end,
	giant = function(_player, value)
		for _, def in Config.Giants.chain do
			if def.id == value then
				if GiantService.isFeeding() then
					GiantService.reset(def)
					return `Monstruo ahora: {def.displayName}`
				end
				GiantCycle.setNext(def)
				return `Siguiente monstruo: {def.displayName}`
			end
		end
		return "Ese monstruo no existe"
	end,
	fill = function(player, value)
		local done = GiantService.fill(number(value, 0, 1), player)
		return if done then "Barra llenada" else "Ahora no está comiendo"
	end,
	event = function(_player, value)
		assert(type(value) == "string", "falta el evento")
		EventScheduler.force(value)
		return `Evento {value} en camino`
	end,
	skipRest = function()
		GiantCycle.skipRest()
		return "Descanso terminado"
	end,
	pass = function(player, value)
		assert(type(value) == "string" and Config.Monetization.passes[value], "ese pase no existe")
		local attribute = `{ATTR.PassPrefix}{value}`
		local now = player:GetAttribute(attribute) ~= true
		player:SetAttribute(attribute, if now then true else nil)
		return `{Config.Monetization.passes[value].name}: {if now then "puesto" else "quitado"}`
	end,
	playtime = function(player, value)
		local since = player:GetAttribute(ATTR.PlaytimeSince)
		assert(type(since) == "number", "sin reloj de regalos")
		local minutes = number(value, 0, 600)
		player:SetAttribute(ATTR.PlaytimeSince, since - minutes * 60)
		return `Regalos: +{minutes} min`
	end,
	tp = function(player, value)
		local target = if type(value) == "string" then place(value) else nil
		local character = player.Character
		assert(target and character, "lugar desconocido")
		character:PivotTo(CFrame.new(target))
		return `Teletransportado a {value}`
	end,
}

function AdminCommands.run(player: Player, name: string, value: unknown): string
	local handler = HANDLERS[name]
	assert(handler, `orden desconocida: {name}`)
	return handler(player, value)
end

return AdminCommands
