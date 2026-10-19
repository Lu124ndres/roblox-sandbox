--!strict
--[[
	GroupReward

	Regalo por unirse al grupo del juego (Config.Social.group): quien está en
	el grupo y lleva `minutes` en esta partida lo reclama una vez (remote
	ClaimGroup) y recibe monedas e impulso personal. El atributo EntroEn
	(hora del servidor al entrar) deja que el cliente muestre la cuenta.
	Con groupId = 0 el regalo está apagado.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)
local Rewards = require(script.Parent.Rewards)

local GROUP = Config.Social.group
local ATTR = Protocol.PlayerAttributes

local GroupReward = {}

local joinedAt: { [Player]: number } = {}

local function isMember(player: Player): boolean
	local ok, result = pcall(function()
		return player:IsInGroupAsync(GROUP.groupId)
	end)
	return ok and result == true
end

local inFlight: { [Player]: boolean } = {} -- una consulta al grupo por jugador a la vez

local function claim(player: Player)
	local function reply(status: string, text: string?)
		Remotes.Notice:FireClient(player, "group", status, text)
	end
	local save = PlayerData.read(player)
	if not save or inFlight[player] then
		return
	end
	if GROUP.groupId == 0 then
		return reply("off")
	elseif save.groupClaimed then
		return reply("claimed")
	end
	inFlight[player] = true
	local member = isMember(player) -- cede el hilo: otro reclamo puede llegar mientras
	inFlight[player] = nil
	-- Se vuelve a leer tras la espera: pudo salir o reclamar por otra vía.
	local fresh = PlayerData.read(player)
	if not fresh or not player.Parent then
		return
	elseif fresh.groupClaimed then
		return reply("claimed")
	elseif not member then
		return reply("notMember")
	elseif os.clock() - (joinedAt[player] or os.clock()) < GROUP.minutes * 60 then
		return reply("wait")
	end
	PlayerData.edit(player, function(data)
		data.groupClaimed = true
	end)
	local reward = { coins = GROUP.coins, boostMinutes = GROUP.boostMinutes }
	Rewards.give(player, reward, "grupo")
	reply("ok", Rewards.describe(reward, Config.Social.personalBoostMultiplier))
end

local function onJoin(player: Player)
	joinedAt[player] = os.clock()
	player:SetAttribute(ATTR.JoinedAt, Workspace:GetServerTimeNow())
end

function GroupReward.init()
	Players.PlayerAdded:Connect(onJoin)
	for _, player in Players:GetPlayers() do
		onJoin(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		joinedAt[player] = nil
		inFlight[player] = nil
	end)
	Remotes.ClaimGroup.OnServerEvent:Connect(RateLimit.wrap("ClaimGroup", 0.5, 2, claim))
end

return GroupReward
