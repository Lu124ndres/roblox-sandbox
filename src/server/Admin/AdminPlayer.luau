--!strict
--[[
	Admin/AdminPlayer

	Órdenes del panel que cambian a un jugador: el elegido arriba del panel
	(uno mismo u otro del servidor). Cada una recibe (objetivo, valor, admin)
	y devuelve el texto del aviso. Lo que se compra con Robux está en AdminShop.
		power, coins, kills, rebirths   número: pone ese valor
		fish, emptyBasket               agrega peces al azar (hasta llenar) / vacía la canasta
		speed                           velocidad al caminar (hasta reaparecer)
		Rod, Basket, Boots              nivel de esa mejora; maxUpgrades: las tres al máximo
		playtime                        minutos: adelanta los regalos por tiempo
		tp                              "orilla", "volcan", "plaza" o "tienda"
		visit, bring                    el admin va con el jugador / lo trae a su lado
		reset                           "progress" o "all": como recién llegado (AdminReset)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local PlayerData = require(script.Parent.Parent.PlayerData)
local AdminReset = require(script.Parent.AdminReset)

export type Handler = (target: Player, value: unknown, admin: Player) -> string

local ATTR = Protocol.PlayerAttributes
local MAX_VALUE = 1e15
local CATEGORIES = { "Rod", "Basket", "Boots" }
local rng = Random.new()

local AdminPlayer = {}

function AdminPlayer.number(value: unknown, low: number, high: number): number
	assert(type(value) == "number" and value == value, "falta un número")
	return math.clamp(value, low, high)
end
local number = AdminPlayer.number

local function setField(field: "power" | "coins" | "kills" | "rebirths"): Handler
	return function(target, value)
		local amount = math.floor(number(value, 0, MAX_VALUE))
		assert(
			PlayerData.edit(target, function(save)
				save[field] = amount
			end),
			"todavía no cargó sus datos"
		)
		return `{field} = {amount}`
	end
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function setLevel(target: Player, category: Upgrades.Category, level: number)
	PlayerData.setUpgrade(target, category, level)
	local humanoid = humanoidOf(target)
	if category == "Boots" and humanoid then
		humanoid.WalkSpeed = Upgrades.current(target, "Boots").value
	end
end

local function upgrade(category: Upgrades.Category): Handler
	return function(target, value)
		local level = math.floor(number(value, 1, #Upgrades.list(category)))
		setLevel(target, category, level)
		return `{Upgrades.list(category)[level].name} (nivel {level})`
	end
end

local function polar(angle: number, radius: number, height: number): Vector3
	local a = math.rad(angle)
	return Vector3.new(math.cos(a) * radius, height, math.sin(a) * radius)
end

local function place(name: string): Vector3?
	local L = WorldLayout
	if name == "orilla" then
		return polar(L.pierAngles[1], L.shoreRadius - 6, L.plateauHeight + 4)
	elseif name == "volcan" then
		local _, finish = WorldZones.bridgeEnds()
		return finish + Vector3.new(0, 4, 0)
	elseif name == "plaza" then
		return WorldZones.spawnPoint() + Vector3.new(0, 4, 0)
	elseif name == "tienda" then
		return polar(L.shopAngle, L.shopRadius - 10, L.plateauHeight + 4)
	end
	return nil
end

local function pivotOf(player: Player): CFrame
	local character = player.Character
	assert(character and character.PrimaryPart, `{player.Name} no tiene personaje`)
	return character:GetPivot()
end

AdminPlayer.HANDLERS = {
	power = setField("power"),
	coins = setField("coins"),
	kills = setField("kills"),
	rebirths = setField("rebirths"),
	Rod = upgrade("Rod"),
	Basket = upgrade("Basket"),
	Boots = upgrade("Boots"),
	maxUpgrades = function(target)
		for _, name in CATEGORIES do
			local category: Upgrades.Category = name :: any
			setLevel(target, category, #Upgrades.list(category))
		end
		return "Mejoras al máximo"
	end,
	fish = function(target, value)
		local wanted = math.floor(number(value, 1, 100000))
		local added = 0
		for _ = 1, wanted do
			if PlayerData.addFish(target, FishCatalog.roll(rng, 0).id, 1) == 0 then
				break
			end
			added += 1
		end
		local count, capacity = PlayerData.getCarriedCount(target), PlayerData.getCapacity(target)
		return `+{added} peces (canasta {count}/{capacity})`
	end,
	emptyBasket = function(target)
		local _, count = PlayerData.takeFishBatch(target, math.huge, math.huge)
		return `Canasta vaciada ({count} peces)`
	end,
	speed = function(target, value)
		local speed = number(value, 8, 300)
		local humanoid = humanoidOf(target)
		if humanoid then
			humanoid.WalkSpeed = speed
		end
		return `Velocidad {speed}`
	end,
	playtime = function(target, value)
		local since = target:GetAttribute(ATTR.PlaytimeSince)
		assert(type(since) == "number", "sin reloj de regalos")
		local minutes = number(value, 0, 600)
		target:SetAttribute(ATTR.PlaytimeSince, since - minutes * 60)
		return `Regalos: +{minutes} min`
	end,
	tp = function(target, value)
		local spot = if type(value) == "string" then place(value) else nil
		assert(spot, "lugar desconocido")
		pivotOf(target)
		local character = target.Character :: Model
		character:PivotTo(CFrame.new(spot))
		return `Llevado a {value}`
	end,
	visit = function(target, _value, admin)
		assert(target ~= admin, "elige a otro jugador arriba")
		local destination = pivotOf(target) * CFrame.new(0, 0, 5)
		pivotOf(admin)
		local character = admin.Character :: Model
		character:PivotTo(destination)
		return `Fuiste con {target.Name}`
	end,
	bring = function(target, _value, admin)
		assert(target ~= admin, "elige a otro jugador arriba")
		local destination = pivotOf(admin) * CFrame.new(0, 0, -5)
		pivotOf(target)
		local character = target.Character :: Model
		character:PivotTo(destination)
		return `Trajiste a {target.Name}`
	end,
	reset = function(target, value)
		return AdminReset.run(target, if value == "all" then "all" else "progress")
	end,
} :: { [string]: Handler }

return AdminPlayer
