--!strict
--[[
	FoodBank

	La comida que ya se lanzó y el gigante todavía está «tragando». Los peces
	salen de la canasta al ritmo completo de la entrega (se ve un chorro
	continuo, pedido del usuario), pero su comida entra a la barra de a poco:
	nunca más de 1/minSoloSeconds de la barra por segundo por persona (x el pase
	de alimentar), la misma regla de siempre. Así una persona sola sigue
	tardando al menos minSoloSeconds en llenar un monstruo.

		add       anota la comida que lanzó un jugador
		pending   cuánta comida está esperando entrar (de todos): FeedingService
		          no saca más peces de los que el gigante todavía necesita
	Un solo bucle la suelta cada stepSeconds mientras el gigante come; durante
	la evolución espera, y si el gigante ya no come (lleno o descansando) se
	descarta.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)

local DELIVERY = Config.Giants.delivery

export type Giant = {
	isFeeding: () -> boolean,
	isEvolving: () -> boolean,
	getFood: () -> number,
	feed: (food: number, feeder: Player, count: number, fishId: string) -> (),
}

local FoodBank = {}

local banked: { [Player]: number } = {}

function FoodBank.add(player: Player, food: number)
	if food > 0 then
		banked[player] = (banked[player] or 0) + food
	end
end

function FoodBank.pending(): number
	local total = 0
	for _, food in banked do
		total += food
	end
	return total
end

function FoodBank.start(giant: Giant)
	Players.PlayerRemoving:Connect(function(player: Player)
		banked[player] = nil
	end)
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(DELIVERY.stepSeconds)
			local now = os.clock()
			local dt = now - last
			last = now
			if giant.isEvolving() then
				continue
			elseif not giant.isFeeding() then
				table.clear(banked)
				continue
			end
			for player, food in banked do
				local rate = Perks.feedMultiplier(player)
					* giant.getFood()
					/ DELIVERY.minSoloSeconds
				local release = math.min(food, rate * dt)
				local left = food - release
				banked[player] = if left > 1e-6 then left else nil
				if player.Parent then
					giant.feed(release, player, 0, "")
				end
			end
		end
	end)
end

return FoodBank
