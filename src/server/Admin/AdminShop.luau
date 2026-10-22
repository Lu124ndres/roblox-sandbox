--!strict
--[[
	Admin/AdminShop

	Órdenes del panel que ponen o quitan lo que se compra con Robux, sobre el
	jugador elegido (para probar sin pagar):
		pass          clave: pone o quita ese pase (prueba trajes y ventajas)
		level         "Power:n" / "Coins:n": esa mejora en x2^n (0 la quita)
		ponds         "all": abre todos los estanques; "none": los cierra
		starterPack   entrega el pack de inicio (lo mismo que Grants, sin contarlo como compra)
		spins         +n giros de ruleta guardados
		allProducts   todo lo de arriba al máximo: pases, Poder, Monedas,
		              estanques y pack de inicio (pedido del usuario el 2026-10-21)
		clearProducts quita pases, Poder, Monedas y estanques (no el pack)
	Con otro jugador solo funciona `pass`, y dura esta partida (al volver a entrar
	recupera lo que pagó); las demás quedan guardadas, así que van solo en admins.
	En un admin los pases también quedan guardados (passTests).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local PlayerData = require(script.Parent.Parent.PlayerData)
local AdminPlayer = require(script.Parent.AdminPlayer)
local Admins = require(script.Parent.Admins)

local MONETIZATION = Config.Monetization
local PONDS = Config.Progression.ponds
local ATTR = Protocol.PlayerAttributes
local MAX_SPINS = 100

local function edit(target: Player, change: (save: any) -> ())
	assert(PlayerData.edit(target, change), "todavía no cargó sus datos")
end

-- Lo que se guarda (mejoras x2, estanques, pack) solo se toca en admins: en otro
-- jugador quitaría para siempre lo que pagó (Roblox no lo vuelve a entregar) o le
-- regalaría lo que no pagó.
local function onlyAdmins(target: Player)
	assert(Admins.is(target), "solo en admins: cambiaría compras reales")
end

-- Pone (on) o quita el pase. Devuelve si quedó guardado (solo en admins).
local function setPass(target: Player, key: string, on: boolean): boolean
	target:SetAttribute(`{ATTR.PassPrefix}{key}`, if on then true else nil)
	return Admins.is(target)
		and PlayerData.edit(target, function(save)
			save.passTests[key] = on
		end)
end

local function setLevel(target: Player, key: string, level: number)
	local max = #MONETIZATION.levels[key].robux
	edit(target, function(save)
		save.levels[key] = math.clamp(level, 0, max)
	end)
end

local function setPonds(target: Player, open: boolean)
	edit(target, function(save)
		save.ponds = {}
		if open then
			for index in PONDS do
				save.ponds[tostring(index)] = true
			end
		end
	end)
	-- ProfilePublish solo pone los abiertos: los cerrados se borran aquí (como AdminReset).
	if not open then
		for index in PONDS do
			target:SetAttribute(`{ATTR.PondPrefix}{index}`, nil)
		end
	end
end

-- El pack de inicio sin pasar por Grants: no cuenta como compra en Analytics.
local function starterPack(target: Player)
	local pack = MONETIZATION.starterPack
	edit(target, function(save)
		save.starterPack = true
		save.coins += pack.coins
		save.boostUntil = math.max(save.boostUntil, os.time()) + pack.boostMinutes * 60
	end)
	for category, level in { Rod = pack.rod, Basket = pack.basket, Boots = pack.boots } do
		local name: Upgrades.Category = category :: any
		PlayerData.setUpgrade(target, name, math.max(Upgrades.level(target, name), level))
	end
end

local HANDLERS: { [string]: AdminPlayer.Handler } = {
	pass = function(target, value)
		assert(type(value) == "string" and MONETIZATION.passes[value], "ese pase no existe")
		local now = target:GetAttribute(`{ATTR.PassPrefix}{value}`) ~= true
		local saved = setPass(target, value, now)
		local state = if now then "puesto" else "quitado"
		return `{MONETIZATION.passes[value].name}: {state}{if saved then "" else " (esta partida)"}`
	end,
	level = function(target, value)
		onlyAdmins(target)
		assert(type(value) == "string", "falta la mejora")
		local key, levelText = string.match(value, "^(%a+):(%d+)$")
		assert(key and MONETIZATION.levels[key], "esa mejora no existe")
		local level = math.clamp(tonumber(levelText) or 0, 0, #MONETIZATION.levels[key].robux)
		setLevel(target, key, level)
		return `{MONETIZATION.levels[key].name} x{2 ^ level}`
	end,
	ponds = function(target, value)
		onlyAdmins(target)
		assert(value == "all" or value == "none", "usa all o none")
		local open = value == "all"
		setPonds(target, open)
		return if open then "Estanques abiertos" else "Estanques cerrados"
	end,
	starterPack = function(target)
		onlyAdmins(target)
		starterPack(target)
		return "Pack de inicio"
	end,
	spins = function(target, value)
		onlyAdmins(target)
		local spins = math.floor(AdminPlayer.number(value, 1, MAX_SPINS))
		edit(target, function(save)
			save.spins += spins
		end)
		return `+{spins} giros de ruleta`
	end,
	allProducts = function(target)
		onlyAdmins(target)
		for _, key in MONETIZATION.passOrder do
			setPass(target, key, true)
		end
		for _, key in MONETIZATION.levelOrder do
			setLevel(target, key, #MONETIZATION.levels[key].robux)
		end
		setPonds(target, true)
		starterPack(target)
		return "Todos los productos puestos"
	end,
	clearProducts = function(target)
		onlyAdmins(target)
		for _, key in MONETIZATION.passOrder do
			setPass(target, key, false)
		end
		for _, key in MONETIZATION.levelOrder do
			setLevel(target, key, 0)
		end
		setPonds(target, false)
		return "Productos quitados"
	end,
}

return table.freeze({ HANDLERS = HANDLERS })
