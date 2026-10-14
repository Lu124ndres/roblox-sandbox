--!strict
--[[
	FishLanding

	Lo que pasa al sacar un pez (lo llama FishingService cuando se llena la
	barra de recoger): van a la canasta tantos como dé el poder, se marcan
	para que todos vean el pez saltar, cuentan para logros y colección, y si
	es legendario o mejor (Config.Reel.announceFromRarity) todo el servidor
	ve un cartel con quién lo sacó.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Reel = require(ReplicatedStorage.Shared.Config.Reel)
local PlayerData = require(script.Parent.PlayerData)
local Milestones = require(script.Parent.Retention.Milestones)
local Remotes = require(script.Parent.Remotes)

local ATTR = Protocol.PlayerAttributes

local FishLanding = {}

-- Todos menos quien lo sacó (él ya ve su tarjeta de captura).
local function announce(player: Player, fishId: string)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Remotes.Notice:FireClient(other, "rare", player.DisplayName, fishId)
		end
	end
end

-- true y { id, count } si lo sacó; false y la capacidad si ya no cabía nada.
function FishLanding.land(player: Player, fish: Config.FishDef, rarityIndex: number): (boolean, any)
	local count = FishingPower.fishPerCatch(PlayerData.getPower(player))
	local before = PlayerData.read(player)
	local firstTime = before ~= nil and (before.species[fish.id] or 0) == 0
	local added = PlayerData.addFish(player, fish.id, count)
	if added == 0 then
		return false, PlayerData.getCapacity(player)
	end
	player:SetAttribute(ATTR.FishingCatch, fish.id)
	player:SetAttribute(ATTR.FishingCatchCount, added)
	Milestones.caught(player, fish.id, added, firstTime)
	if rarityIndex >= Reel.announceFromRarity then
		announce(player, fish.id)
	end
	return true, { id = fish.id, count = added }
end

return FishLanding
