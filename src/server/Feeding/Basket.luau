--!strict
--[[
	Basket

	La canasta guardada es un conteo por especie ({ [fishId]: cantidad }), no
	una lista de peces: con poder alto se llevan decenas de miles y una lista
	así pesa en el guardado y en cada entrega. Aquí viven las cuentas sobre
	ese mapa; PlayerData es quien las llama (y publica el resultado).

	Los peces se sacan en el orden de la tabla de Config (de común a mítico),
	así cada entrega es determinista.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)

export type Counts = { [string]: number }

local Basket = {}

-- Total de peces en la canasta.
function Basket.total(carried: Counts): number
	local total = 0
	for _, amount in carried do
		total += amount
	end
	return total
end

-- Suma `count` peces de una especie (el que llama ya validó el espacio).
function Basket.add(carried: Counts, fishId: string, count: number)
	if count > 0 then
		carried[fishId] = (carried[fishId] or 0) + count
	end
end

-- Saca hasta maxCount peces, parando en cuanto la comida sacada llega a
-- maxFood (el gigante no necesita más). Devuelve lo sacado por especie, cuántos,
-- su comida y sus monedas base (sin multiplicadores).
function Basket.take(
	carried: Counts,
	maxCount: number,
	maxFood: number
): (Counts, number, number, number)
	local taken: Counts = {}
	local count, food, coins = 0, 0, 0
	for _, fish in Config.Economy.fish do
		local have = carried[fish.id] or 0
		if count >= maxCount or food >= maxFood then
			break
		end
		if have > 0 then
			local needed = math.ceil((maxFood - food) / math.max(fish.food, 1))
			local amount = math.min(have, maxCount - count, needed)
			if amount >= have then
				carried[fish.id] = nil
			else
				carried[fish.id] = have - amount
			end
			taken[fish.id] = amount
			count += amount
			food += amount * fish.food
			coins += amount * fish.coins
		end
	end
	return taken, count, food, coins
end

-- La especie más rara de un lote (la que se dibuja volando).
function Basket.rarest(taken: Counts): string
	local best, bestLevel = "Sardina", 0
	for fishId in taken do
		local _, level = FishCatalog.rarity(fishId)
		if level > bestLevel then
			best, bestLevel = fishId, level
		end
	end
	return best
end

return Basket
