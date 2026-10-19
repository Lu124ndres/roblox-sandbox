--!strict
--[[
	Referrals

	Premio por invitar (Config.Social.referral): cuando un jugador NUEVO (sin
	tutorial ni peces) entra por la invitación de otro (GetJoinData:
	ReferredByPlayerId), gana monedas e impulso de poder; quien lo invitó,
	si está en el servidor, gana más. Como solo cuenta la primera partida
	del invitado, no se puede repetir con la misma cuenta.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Remotes = require(script.Parent.Parent.Remotes)
local Rewards = require(script.Parent.Rewards)

local REFERRAL = Config.Social.referral
local WAIT_SECONDS = 30 -- cuánto se espera a que carguen sus datos

local Referrals = {}

local function referrerOf(player: Player): number
	local ok, data = pcall(function()
		return player:GetJoinData()
	end)
	local id = ok and type(data) == "table" and (data :: any).ReferredByPlayerId
	return if type(id) == "number" then id else 0
end

local function check(player: Player)
	local referrer = referrerOf(player)
	if referrer == 0 or referrer == player.UserId then
		return
	end
	local deadline = os.clock() + WAIT_SECONDS
	while not PlayerData.isLoaded(player) and player.Parent and os.clock() < deadline do
		task.wait(1)
	end
	local save = PlayerData.read(player)
	if not save or save.tutorial > 0 or save.stats.fishCaught > 0 then
		return -- no es su primera partida
	end
	local multiplier = Config.Social.personalBoostMultiplier
	local welcome = { coins = REFERRAL.newCoins, boostMinutes = REFERRAL.newBoostMinutes }
	Rewards.give(player, welcome, "invitaciones")
	Remotes.Notice:FireClient(
		player,
		"purchase",
		`¡Bienvenido! {Rewards.describe(welcome, multiplier)}`
	)
	local inviter = Players:GetPlayerByUserId(referrer)
	if inviter and PlayerData.isLoaded(inviter) then
		local thanks =
			{ coins = REFERRAL.inviterCoins, boostMinutes = REFERRAL.inviterBoostMinutes }
		Rewards.give(inviter, thanks, "invitaciones")
		Remotes.Notice:FireClient(
			inviter,
			"purchase",
			`¡{player.DisplayName} entró por tu invitación! {Rewards.describe(thanks, multiplier)}`
		)
	end
end

function Referrals.init()
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(check, player)
	end)
end

return Referrals
