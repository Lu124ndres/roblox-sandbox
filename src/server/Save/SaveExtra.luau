--!strict
--[[
	SaveExtra

	Campos del guardado que llegaron en las versiones 8 y 9 (SaveSchema los
	declara y llama a read):
		rebirths     veces que renació (Retention/Rebirth)
		quests       misiones del día: día UTC, avance y cuáles se cumplieron
		starterPack  ya compró el pack de inicio (se ofrece una sola vez)
		spinAt       unix en que vuelve a tocar la ruleta gratis (v9, Retention/SpinWheel)
]]

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

local function count(value: unknown): number
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

-- Lee lo de las versiones 8 y 9 de `source` (lo guardado) dentro de `data` (ya con valores por defecto).
function SaveExtra.read(source: { [string]: any }, data: any)
	data.rebirths = count(source.rebirths)
	data.starterPack = source.starterPack == true
	data.spinAt = count(source.spinAt)
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
