--!strict
--[[
	SaveSchema

	Forma de los datos guardados de un jugador y cómo se leen. Todo lo que
	viene del DataStore se trata como desconocido: se validan los tipos, se
	descartan los peces que ya no existen y se migra desde versiones viejas.

	Para agregar un campo: subir VERSION, agregarlo a SaveData y a default(), y
	leerlo en read() con un valor por defecto (los datos viejos siguen cargando).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local SaveExtra = require(script.Parent.SaveExtra)

export type Stats = {
	fishCaught: number, -- peces sacados del agua en total
	fishDelivered: number, -- peces entregados al gigante en total
}

export type SaveData = {
	version: number,
	coins: number,
	power: number,
	carried: { [string]: number }, -- canasta: cuántos de cada especie (nunca se pierden al salir)
	species: { [string]: number }, -- cuántos de cada especie ha pescado (colección)
	stats: Stats,
	kills: number, -- monstruos llenados en los que participó (estadística "Kills")
	killsByGiant: { [string]: number }, -- las mismas, por id de gigante
	upgrades: { [string]: number }, -- nivel de cada mejora de la tienda (Rod, Basket, Boots)
	tutorial: number, -- pasos del tutorial ya hechos (0 = recién llega)
	daily: { lastDay: number, streak: number }, -- recompensa diaria: último día cobrado (UTC) y racha
	settings: { music: boolean, sfx: boolean, shake: boolean, lowFx: boolean, lowFxChosen: boolean },
	badges: { [string]: boolean }, -- insignias ya entregadas (para no pedirlas otra vez)
	ponds: { [string]: boolean }, -- estanques comprados con Robux ("2".."10")
	receipts: { string }, -- PurchaseId de las últimas compras (no cobrar dos veces)
	levels: { [string]: number }, -- mejoras de Robux: Power y Coins (x2^nivel)
	codes: { [string]: boolean }, -- códigos ya canjeados
	groupClaimed: boolean, -- ya reclamó el regalo del grupo
	boostUntil: number, -- unix en que termina su impulso personal de poder
	gifts: { [string]: boolean }, -- pases que le regalaron ("VIP")
	rebirths: number, -- veces que renació (v8, ver SaveExtra)
	quests: SaveExtra.QuestsSave, -- misiones del día (v8)
	starterPack: boolean, -- ya compró el pack de inicio (v8)
	spinAt: number, -- unix en que vuelve a tocar la ruleta gratis (v9, ver SaveExtra)
	spins: number, -- giros de ruleta guardados (v10)
	coinBoostUntil: number, -- unix en que termina el x2 monedas de la ruleta (v10)
	playMinutes: number, -- minutos jugados en total (v11, para la telemetría)
	outfit: string, -- traje que eligió en la vitrina ("" = el del mejor pase; v12)
	passTests: { [string]: boolean }, -- pases puestos (true) o quitados (false) por un admin (v13)
}

local SaveSchema = {}

-- 2: kills; 3: mejoras de la tienda; 4: tutorial, diario, ajustes, insignias;
-- 5: compras, códigos, grupo; 6: pases regalados; 7: canasta como conteo por especie;
-- 8: renacer, misiones, pack de inicio; 9: ruleta gratis; 10: giros guardados y
-- x2 monedas; 11: minutos jugados; 12: traje elegido; 13: pases de prueba del admin (8 a 13
-- en SaveExtra; lo que falta en un guardado viejo queda en 0 o vacío)
SaveSchema.VERSION = 13

function SaveSchema.default(): SaveData
	return {
		version = SaveSchema.VERSION,
		coins = 0,
		power = 0,
		carried = {},
		species = {},
		stats = { fishCaught = 0, fishDelivered = 0 },
		kills = 0,
		killsByGiant = {},
		upgrades = { Rod = 1, Basket = 1, Boots = 1 },
		tutorial = 0,
		daily = { lastDay = 0, streak = 0 },
		settings = { music = true, sfx = true, shake = true, lowFx = false, lowFxChosen = false },
		badges = {},
		ponds = {},
		receipts = {},
		levels = { Power = 0, Coins = 0 },
		codes = {},
		groupClaimed = false,
		boostUntil = 0,
		gifts = {},
		rebirths = 0,
		quests = SaveExtra.quests(),
		starterPack = false,
		spinAt = 0,
		spins = 0,
		coinBoostUntil = 0,
		playMinutes = 0,
		outfit = "",
		passTests = {},
	}
end

local count = SaveExtra.count
local flags = SaveExtra.flags

-- Copia profunda (para guardar sin que el juego la cambie mientras se escribe).
function SaveSchema.copy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value :: any do
		copy[key] = SaveSchema.copy(child)
	end
	return copy :: any
end

-- Convierte lo que haya en el DataStore (o nada) en un SaveData válido.
function SaveSchema.read(raw: unknown): SaveData
	local data = SaveSchema.default()
	if type(raw) ~= "table" then
		return data
	end
	local source = raw :: { [string]: any }
	data.coins = count(source.coins)
	data.power = count(source.power)
	-- Canasta: hasta la versión 6 era una lista de ids ({ "Sardina", ... });
	-- desde la 7, un conteo ({ Sardina = 12 }). Se leen las dos formas.
	if type(source.carried) == "table" then
		for key, value in source.carried do
			local fishId, amount = key, count(value)
			if type(key) == "number" then
				fishId, amount = value, 1
			end
			if type(fishId) == "string" and FishCatalog.get(fishId) and amount > 0 then
				data.carried[fishId] = (data.carried[fishId] or 0) + amount
			end
		end
	end
	if type(source.species) == "table" then
		for fishId, amount in source.species do
			if type(fishId) == "string" and FishCatalog.get(fishId) then
				data.species[fishId] = count(amount)
			end
		end
	end
	data.kills = count(source.kills)
	if type(source.killsByGiant) == "table" then
		for giantId, amount in source.killsByGiant do
			if type(giantId) == "string" then
				data.killsByGiant[giantId] = count(amount)
			end
		end
	end
	if type(source.upgrades) == "table" then
		for category, level in data.upgrades do
			local list = Config.Shop[category]
			local saved = count(source.upgrades[category])
			data.upgrades[category] = if saved >= 1 then math.min(saved, #list) else level
		end
	end
	data.tutorial = count(source.tutorial)
	if type(source.daily) == "table" then
		data.daily.lastDay = count(source.daily.lastDay)
		data.daily.streak = count(source.daily.streak)
	end
	if type(source.settings) == "table" then
		for key, value in data.settings do
			local saved = source.settings[key]
			data.settings[key] = if type(saved) == "boolean" then saved else value
		end
	end
	flags(source.badges, data.badges)
	flags(source.ponds, data.ponds)
	if type(source.receipts) == "table" then
		for _, id in source.receipts do
			if type(id) == "string" then
				table.insert(data.receipts, id)
			end
		end
	end
	if type(source.levels) == "table" then
		for key in data.levels do
			local max = #Config.Monetization.levels[key].robux
			data.levels[key] = math.min(count(source.levels[key]), max)
		end
	end
	flags(source.codes, data.codes)
	data.groupClaimed = source.groupClaimed == true
	data.boostUntil = count(source.boostUntil)
	flags(source.gifts, data.gifts)
	SaveExtra.read(source, data)
	if type(source.stats) == "table" then
		data.stats.fishCaught = count(source.stats.fishCaught)
		data.stats.fishDelivered = count(source.stats.fishDelivered)
	end
	return data
end

return SaveSchema
