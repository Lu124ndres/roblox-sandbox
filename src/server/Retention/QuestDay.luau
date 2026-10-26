--!strict
--[[
	QuestDay

	Qué misiones tocan hoy (Config/Quests) y el estado del día en el guardado.
	Cada día UTC salen `perDay` de la lista, iguales para todos (sorteadas con
	el día como semilla), y al final una EXTRA (QUESTS.extra) que el cofre no
	pide. save.quests se reinicia al cambiar el día (ensure), que devuelve lo
	del día anterior para que Quests pague lo cumplido sin reclamar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QUESTS = require(ReplicatedStorage.Shared.Config.Quests)
local SaveExtra = require(script.Parent.Parent.Save.SaveExtra)

local QuestDay = {}

function QuestDay.today(): number
	return os.time() // 86400
end

-- Las misiones de un día: perDay de la lista y, al final, la extra (índice > perDay).
function QuestDay.list(day: number): { QUESTS.QuestDef }
	local pool = table.clone(QUESTS.pool)
	local rng = Random.new(day * 7919 + 13)
	for index = #pool, 2, -1 do
		local other = rng:NextInteger(1, index)
		pool[index], pool[other] = pool[other], pool[index]
	end
	local list = { table.unpack(pool, 1, math.min(QUESTS.perDay, #pool)) }
	if #QUESTS.extra > 0 then
		table.insert(list, QUESTS.extra[rng:NextInteger(1, #QUESTS.extra)])
	end
	return list
end

-- Si el guardado es de otro día, empieza de cero.
function QuestDay.ensure(save: any): SaveExtra.QuestsSave?
	if save.quests.day ~= QuestDay.today() then
		local previous = save.quests
		save.quests = SaveExtra.quests()
		save.quests.day = QuestDay.today()
		return previous
	end
	return nil
end

-- ¿Cumplió las perDay (sin la extra)? Entonces el cofre se puede reclamar.
function QuestDay.allDone(state: SaveExtra.QuestsSave, list: { QUESTS.QuestDef }): boolean
	for index, quest in list do
		if index <= QUESTS.perDay and not state.done[quest.id] then
			return false
		end
	end
	return true
end

return QuestDay
