--!strict
--[[
	Perks

	Lo que cambian las compras con Robux, leído de atributos que solo pone el
	servidor (así servidor y cliente calculan igual y el cliente no puede
	hacer trampa):
		Pase_<clave> en el jugador          pases (Config.Monetization.passes)
		Nivel<Power|Coins> en el jugador    mejoras que se acumulan (x2^nivel)
		Estanque_<i> en el jugador          estanques comprados
		ReplicatedStorage.Impulsos          entrenamiento de todo el servidor (x2^nivel)

	Lo usan el entrenamiento, el descanso, la entrega, la pesca, el premio
	diario, los carteles de los estanques y la tienda.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)

local MONETIZATION = Config.Monetization
local SOCIAL = Config.Social
local PONDS = Config.Progression.ponds
local ATTR = Protocol.PlayerAttributes

local Perks = {}

function Perks.hasPass(player: Player, key: string): boolean
	return player:GetAttribute(`{ATTR.PassPrefix}{key}`) == true
end

-- Producto de un campo numérico de todos los pases que tiene (1 si ninguno).
local function passProduct(player: Player, field: string): number
	local result = 1
	for key, pass in MONETIZATION.passes do
		local value = (pass :: any)[field]
		if type(value) == "number" and Perks.hasPass(player, key) then
			result *= value
		end
	end
	return result
end

-- Nivel comprado de una mejora que se acumula ("Power", "Coins"): x2^nivel.
function Perks.level(player: Player, key: string): number
	local value = player:GetAttribute(`{ATTR.LevelPrefix}{key}`)
	return if type(value) == "number" then value else 0
end

local function boostFolder(): Instance?
	return ReplicatedStorage:FindFirstChild(Protocol.BoostFolder)
end

-- Segundos que le quedan al entrenamiento del servidor (0 = no hay).
function Perks.serverBoostSeconds(): number
	local folder = boostFolder()
	local untilTime = folder and folder:GetAttribute(Protocol.BoostAttributes.TrainingUntil)
	if type(untilTime) ~= "number" then
		return 0
	end
	return math.max(0, untilTime - Workspace:GetServerTimeNow())
end

-- Nivel activo del entrenamiento del servidor (0 si venció): x2^nivel.
function Perks.serverBoostLevel(): number
	if Perks.serverBoostSeconds() <= 0 then
		return 0
	end
	local folder = boostFolder()
	local level = folder and folder:GetAttribute(Protocol.BoostAttributes.TrainingLevel)
	return if type(level) == "number" then level else 0
end

-- Impulso de amigos: 1 + perFriend por amigo en el servidor (hasta maxFriends).
function Perks.friendMultiplier(player: Player): number
	local value = player:GetAttribute(ATTR.FriendsInServer)
	local friends = if type(value) == "number" then value else 0
	return 1 + math.min(friends, SOCIAL.friendBoost.maxFriends) * SOCIAL.friendBoost.perFriend
end

-- Segundos que le quedan al impulso personal de poder (códigos, grupo).
function Perks.personalBoostSeconds(player: Player): number
	local value = player:GetAttribute(ATTR.BoostUntil)
	return if type(value) == "number" then math.max(0, value - Workspace:GetServerTimeNow()) else 0
end

function Perks.powerMultiplier(player: Player): number
	local personal = if Perks.personalBoostSeconds(player) > 0
		then SOCIAL.personalBoostMultiplier
		else 1
	return 2 ^ Perks.level(player, "Power")
		* 2 ^ Perks.serverBoostLevel()
		* personal
		* Perks.friendMultiplier(player)
end

function Perks.coinMultiplier(player: Player): number
	return 2 ^ Perks.level(player, "Coins") * Perks.friendMultiplier(player)
end

function Perks.dailyMultiplier(player: Player): number
	return passProduct(player, "dailyMultiplier")
end

function Perks.luckBonus(player: Player): number
	local bonus = 0
	for key, pass in MONETIZATION.passes do
		if pass.luck and Perks.hasPass(player, key) then
			bonus += pass.luck
		end
	end
	return bonus
end

function Perks.ownsPond(player: Player, index: number): boolean
	return player:GetAttribute(`{ATTR.PondPrefix}{index}`) == true
end

-- Puede entrenar ahí: tiene el poder pedido o lo compró.
function Perks.pondOpen(player: Player, index: number): boolean
	local pond = PONDS[index]
	if not pond then
		return false
	end
	local kills = player:GetAttribute(ATTR.Kills)
	return (type(kills) == "number" and kills >= pond.requiredKills)
		or Perks.ownsPond(player, index)
end

-- ¿Este atributo del jugador cambia qué estanques tiene abiertos? (poder o compra)
function Perks.affectsPonds(attribute: string): boolean
	return attribute == ATTR.Kills or string.sub(attribute, 1, #ATTR.PondPrefix) == ATTR.PondPrefix
end

-- Multiplicador del mejor estanque abierto (para el descanso del volcán).
function Perks.bestPondMultiplier(player: Player): number
	local best = 1
	for index, pond in PONDS do
		if Perks.pondOpen(player, index) then
			best = math.max(best, pond.multiplier)
		end
	end
	return best
end

return Perks
