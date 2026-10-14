--!strict
--[[
	ProfilePublish

	Lo que el cliente ve de los datos de un jugador: leaderstats (Poder y
	Kills) y atributos del jugador (monedas, peces, mejoras, colección,
	tutorial, recompensa diaria y ajustes). Lo usa PlayerData cada vez que
	cambian los datos. SetAttribute con el mismo valor no se vuelve a enviar.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local SaveSchema = require(script.Parent.Save.SaveSchema)

local ATTR = Protocol.PlayerAttributes

local ProfilePublish = {}

-- Leaderstats en cero apenas entra (la tabla de jugadores no espera al guardado).
function ProfilePublish.prepare(player: Player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in { Protocol.Leaderstats.Power, Protocol.Leaderstats.Kills } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = leaderstats
	end
	leaderstats.Parent = player
	for _, attribute in { ATTR.Power, ATTR.CarriedFish, ATTR.Coins, ATTR.Kills } do
		player:SetAttribute(attribute, 0)
	end
end

local function stat(player: Player, name: string, value: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local holder = leaderstats and leaderstats:FindFirstChild(name)
	if holder and holder:IsA("IntValue") then
		holder.Value = value
	end
end

function ProfilePublish.all(player: Player, save: SaveSchema.SaveData)
	stat(player, Protocol.Leaderstats.Power, save.power)
	stat(player, Protocol.Leaderstats.Kills, save.kills)
	player:SetAttribute(ATTR.Coins, save.coins)
	player:SetAttribute(ATTR.Kills, save.kills)
	player:SetAttribute(ATTR.Power, save.power)
	player:SetAttribute(ATTR.CarriedFish, #save.carried)
	for category, level in save.upgrades do
		player:SetAttribute(category, level)
	end
	-- Colección: cuántos de cada especie (Pez_<id>), para la ventana de peces.
	for _, fish in Config.Economy.fish do
		player:SetAttribute(`{ATTR.FishPrefix}{fish.id}`, save.species[fish.id] or 0)
	end
	player:SetAttribute(ATTR.Tutorial, save.tutorial)
	player:SetAttribute(ATTR.DailyStreak, save.daily.streak)
	player:SetAttribute(ATTR.DailyDay, save.daily.lastDay)
	player:SetAttribute(ATTR.Settings, HttpService:JSONEncode(save.settings))
	player:SetAttribute(ATTR.BoostUntil, save.boostUntil)
	player:SetAttribute(ATTR.GroupClaimed, save.groupClaimed)
	for key, level in save.levels do
		player:SetAttribute(`{ATTR.LevelPrefix}{key}`, level)
	end
	for key in save.gifts do
		player:SetAttribute(`{ATTR.PassPrefix}{key}`, true) -- pase regalado
	end
	for index in Config.Progression.ponds do
		if save.ponds[tostring(index)] then
			player:SetAttribute(`{ATTR.PondPrefix}{index}`, true)
		end
	end
end

return ProfilePublish
