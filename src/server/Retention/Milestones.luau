--!strict
--[[
	Milestones

	Punto único al que los servicios del juego avisan lo que hace cada
	jugador (pescó, alimentó, entrenó, compró, llenó a un monstruo). Desde
	aquí se reparte a lo que le interesa: tutorial, colección de peces y
	logros. Así la pesca o la tienda no necesitan saber de la retención.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Remotes = require(script.Parent.Parent.Remotes)
local Badges = require(script.Parent.Badges)
local Tutorial = require(script.Parent.Tutorial)

local RETENTION = Config.Retention
local RARITY_BADGES: { [number]: string } =
	{ [3] = "PrimerRaro", [5] = "PrimerLegendario", [6] = "PrimerMitico" }

local Milestones = {}

-- Pescó `added` peces de la especie fishId. firstTime = primera vez que saca esa especie.
function Milestones.caught(player: Player, fishId: string, added: number, firstTime: boolean)
	Tutorial.progress(player, "pescar", added)
	Badges.award(player, "PrimerPez")
	local rarity, level = FishCatalog.rarity(fishId)
	local badge = RARITY_BADGES[level] or (if level == 4 then RARITY_BADGES[3] else nil)
	if badge then
		Badges.award(player, badge)
	end
	if not firstTime then
		return
	end
	local coins =
		math.floor((RETENTION.discoveryCoins[rarity.id] or 0) * Perks.coinMultiplier(player))
	PlayerData.addCoins(player, coins)
	Remotes.Notice:FireClient(player, "newFish", fishId, coins)
	local save = PlayerData.read(player)
	if not save then
		return
	end
	for _, fish in Config.Economy.fish do
		if (save.species[fish.id] or 0) == 0 then
			return
		end
	end
	PlayerData.addCoins(player, RETENTION.collectionBonus)
	Remotes.Notice:FireClient(player, "collection", RETENTION.collectionBonus)
	Badges.award(player, "Coleccion")
end

function Milestones.fed(player: Player, fishCount: number)
	if fishCount > 0 then
		Tutorial.progress(player, "alimentar", 1)
	end
end

function Milestones.trained(player: Player, pondIndex: number)
	Tutorial.progress(player, "entrenar", 1)
	if pondIndex >= #Config.Progression.ponds then
		Badges.award(player, "EstanqueMaximo")
	end
end

function Milestones.bought(player: Player)
	Tutorial.progress(player, "comprar", 1)
end

function Milestones.killed(player: Player)
	Badges.award(player, "PrimeraKill")
	local save = PlayerData.read(player)
	if save and save.kills >= 10 then
		Badges.award(player, "DiezKills")
	end
end

function Milestones.init()
	Players.PlayerRemoving:Connect(Tutorial.forget)
end

return Milestones
