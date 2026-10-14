--!strict
--[[
	Contributions

	Cuánta comida aportó cada jugador (por userId) al gigante actual, peces y
	llenados con Robux. Al llenarse, la kill es solo para quien aportó al
	menos scaling.minKillShare de la barra: tirar un pez no alcanza.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SCALING = Config.Giants.scaling

local Contributions = {}

local foodByUser: { [number]: number } = {}

function Contributions.add(userId: number, food: number)
	foodByUser[userId] = (foodByUser[userId] or 0) + math.max(0, food)
end

-- Gigante nuevo: nadie aportó nada todavía.
function Contributions.reset()
	table.clear(foodByUser)
end

-- userIds que aportaron al menos minKillShare de `totalFood`.
function Contributions.participants(totalFood: number): { number }
	local needed = SCALING.minKillShare * totalFood
	local list = {}
	for userId, food in foodByUser do
		if food >= needed then
			table.insert(list, userId)
		end
	end
	return list
end

return Contributions
