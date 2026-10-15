--!strict
--[[
	RewardScale

	Premios que crecen con el avance del jugador, para que sigan valiendo la
	pena a mitad y al final del juego (si no, 2,500 monedas no sirven de nada
	cuando la caña cuesta millones y el diario deja de traer a la gente):
		share  diario y regalos por tiempo: lo mayor entre las monedas de
		       Config y una fracción del precio de la siguiente caña
		of     misiones: x(precio de la siguiente caña / BASE_PRICE), mínimo x1
	Al renacer vuelve a empezar, igual que las cañas. Lo usan el servidor
	(paga) y el cliente (muestra).
]]

local Upgrades = require(script.Parent.Upgrades)

local BASE_PRICE = 3000 -- precio de la caña 4

local RewardScale = {}

function RewardScale.nextRodPrice(player: Player): number
	local rods = Upgrades.list("Rod")
	return rods[math.min(Upgrades.level(player, "Rod") + 1, #rods)].price
end

function RewardScale.of(player: Player): number
	return math.max(1, RewardScale.nextRodPrice(player) / BASE_PRICE)
end

function RewardScale.share(player: Player, base: number, share: number?): number
	if not share then
		return base
	end
	return math.floor(math.max(base, share * RewardScale.nextRodPrice(player)))
end

function RewardScale.coins(player: Player, base: number): number
	return math.floor(base * RewardScale.of(player))
end

return RewardScale
