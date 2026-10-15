--!strict
--[[
	PlaytimeGifts

	Regalos por tiempo jugado (Config.Retention.playtime): cuenta desde que
	el jugador entra al servidor (atributo RegalosDesde, hora del servidor) y
	se cobran con ClaimPlaytime(index) cuando ya pasaron sus minutos. Los
	cobrados van en RegalosCobrados (bits). Al volver a entrar empieza de cero.
	Los premios son monedas y minutos de impulso de poder (Social/Rewards).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RewardScale = require(ReplicatedStorage.Shared.RewardScale)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)
local Rewards = require(script.Parent.Parent.Social.Rewards)

local GIFTS = Config.Retention.playtime
local ATTR = Protocol.PlayerAttributes
local GRACE_SECONDS = 2 -- el reloj del cliente puede ir un poco adelantado

local PlaytimeGifts = {}

local function claim(player: Player, index: unknown)
	if type(index) ~= "number" or index % 1 ~= 0 or not GIFTS[index] then
		return
	end
	if not PlayerData.isLoaded(player) then
		return
	end
	local since = player:GetAttribute(ATTR.PlaytimeSince)
	local claimed = player:GetAttribute(ATTR.PlaytimeClaimed)
	if type(since) ~= "number" or type(claimed) ~= "number" then
		return
	end
	local bit = 2 ^ (index - 1)
	if (claimed // bit) % 2 == 1 then
		return -- ya lo cobró
	end
	local gift = GIFTS[index]
	if Workspace:GetServerTimeNow() - since < gift.minutes * 60 - GRACE_SECONDS then
		return -- todavía no
	end
	player:SetAttribute(ATTR.PlaytimeClaimed, claimed + bit)
	local coins = if gift.coins then RewardScale.share(player, gift.coins, gift.share) else nil
	local reward = { coins = coins, boostMinutes = gift.boostMinutes }
	Rewards.give(player, reward)
	local text = Rewards.describe(reward, Config.Social.personalBoostMultiplier)
	Remotes.Notice:FireClient(player, "playtime", index, text)
end

local function start(player: Player)
	player:SetAttribute(ATTR.PlaytimeSince, Workspace:GetServerTimeNow())
	player:SetAttribute(ATTR.PlaytimeClaimed, 0)
end

function PlaytimeGifts.init()
	Players.PlayerAdded:Connect(start)
	for _, player in Players:GetPlayers() do
		start(player)
	end
	Remotes.ClaimPlaytime.OnServerEvent:Connect(RateLimit.wrap("ClaimPlaytime", 2, 4, claim))
end

return PlaytimeGifts
