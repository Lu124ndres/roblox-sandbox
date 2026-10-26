--!strict
--[[
	RestTime

	Producto RestTime: +restTime.seconds al descanso del volcán (para todo el
	servidor). Si se compra durante el descanso se suma enseguida; si no,
	queda guardado para el próximo. GiantCycle lo cobra con take() en cada
	tick del descanso y alarga la cuenta regresiva. Se avisa a todos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(script.Parent.Parent.Remotes)

local RestTime = {}

local pending = 0

function RestTime.add(buyer: Player): boolean
	return RestTime.addAs(buyer.DisplayName)
end

-- Como add, a nombre de `name` (el panel de administrador, también desde otro servidor).
function RestTime.addAs(name: string): boolean
	local seconds = Config.Monetization.restTime.seconds
	pending += seconds
	Remotes.Notice:FireAllClients("restTime", name, seconds)
	return true
end

-- Segundos comprados que todavía no se sumaron (y los da por usados).
function RestTime.take(): number
	local seconds = pending
	pending = 0
	return seconds
end

return RestTime
