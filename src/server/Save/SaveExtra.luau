--!strict
--[[
	SaveExtra

	Campos del guardado que llegaron en las versiones 8 a 15 (SaveSchema los
	declara y llama a read; en un guardado viejo faltan y quedan en 0 o vacíos):
		rebirths     veces que renació (Retention/Rebirth)
		quests       misiones del día: día UTC, avance y cuáles se cumplieron
		starterPack  ya compró el pack de inicio (se ofrece una sola vez)
		spinAt       unix en que vuelve a tocar la ruleta gratis (v9, Retention/SpinWheel)
		spins        giros de ruleta guardados (v10)
		coinBoostUntil  unix en que termina el x2 monedas de la ruleta (v10)
		playMinutes  minutos jugados en total, en todas las sesiones (v11, Analytics/Sesion)
		outfit       traje que eligió en la vitrina o la TIENDA (v12, Social/OutfitChoice):
		             "Marinero", el de un pase, o "" para el del mejor pase que tenga
		passTests    pases que un admin puso (true) o quitó (false) para probar (v13,
		             Monetization/Passes): mandan sobre lo que dice Roblox hasta que lo
		             compre o se lo regalen
		starterSeenAt  unix en que el pack de inicio se le abrió solo (v14,
		             Monetization/StarterSeen): ya no se vuelve a abrir solo, y su
		             atajo cuenta 24 horas desde ahí
		superRod     sacó la caña suprema en la ruleta (v15, Retention/SpinWheel)
	También flags, que copia los `clave = true` de un mapa guardado.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Trajes = require(ReplicatedStorage.Shared.Trajes)

export type QuestsSave = {
	day: number,
	progress: { [string]: number },
	done: { [string]: boolean },
	bonus: boolean, -- ya cobró el cofre por cumplir las tres
}

local SaveExtra = {}

function SaveExtra.quests(): QuestsSave
	return { day = 0, progress = {}, done = {}, bonus = false }
end

-- Entero >= 0 de lo guardado (0 si falta o no es un número válido).
function SaveExtra.count(value: unknown): number
	return if type(value) == "number"
			and value == value
			and value >= 0
		then math.floor(value)
		else 0
end

-- El avance de una misión puede tener decimales (el % de la barra aportado).
local function amount(value: unknown): number
	return if type(value) == "number" and value == value and value >= 0 then value else 0
end

local count = SaveExtra.count

-- Copia los `clave = true` de un mapa guardado (insignias, estanques, códigos...).
function SaveExtra.flags(saved: unknown, into: { [string]: boolean })
	if type(saved) == "table" then
		for key, value in saved :: { [any]: any } do
			if type(key) == "string" and value == true then
				into[key] = true
			end
		end
	end
end

-- Un traje que existe: el marinero o el de algún pase ("" si no).
local function outfit(value: unknown): string
	if value == Trajes.SAILOR then
		return Trajes.SAILOR
	end
	for _, pass in Config.Monetization.passes do
		if pass.outfit and pass.outfit == value then
			return pass.outfit
		end
	end
	return ""
end

-- Lee lo de las versiones 8 a 15 de `source` (lo guardado) dentro de `data` (ya con valores por defecto).
function SaveExtra.read(source: { [string]: any }, data: any)
	data.rebirths = count(source.rebirths)
	data.starterPack = source.starterPack == true
	data.spinAt = count(source.spinAt)
	data.spins = count(source.spins)
	data.coinBoostUntil = count(source.coinBoostUntil)
	data.playMinutes = count(source.playMinutes)
	data.outfit = outfit(source.outfit)
	data.starterSeenAt = count(source.starterSeenAt)
	data.superRod = source.superRod == true
	if type(source.passTests) == "table" then
		for key, on in source.passTests do
			if
				type(key) == "string"
				and Config.Monetization.passes[key]
				and type(on) == "boolean"
			then
				data.passTests[key] = on
			end
		end
	end
	local saved = source.quests
	if type(saved) == "table" then
		data.quests.day = count(saved.day)
		data.quests.bonus = saved.bonus == true
		if type(saved.progress) == "table" then
			for id, value in saved.progress do
				if type(id) == "string" then
					data.quests.progress[id] = amount(value)
				end
			end
		end
		if type(saved.done) == "table" then
			for id, value in saved.done do
				if type(id) == "string" and value == true then
					data.quests.done[id] = true
				end
			end
		end
	end
end

return SaveExtra
