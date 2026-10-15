--!strict
--[[
	FeedFeedback

	Avisos al alimentar al gigante: monedas ganadas (con monedas que vuelan
	al contador), carga vacía o gigante
	satisfecho. Los números vienen del servidor; aquí solo se muestran.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Audio.Sounds)
local CoinBurst = require(script.Parent.Effects.CoinBurst)
local GiantName = require(script.Parent.GiantName)
local Toasts = require(script.Parent.Toasts)

local COLORS = UIConfig.Colors

local FeedFeedback = {}

function FeedFeedback.start(toasts: Toasts.Toasts, screen: ScreenGui, coinLabel: GuiObject)
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local feedResult = remotes:WaitForChild(Protocol.Remotes.FeedResult) :: RemoteEvent

	feedResult.OnClientEvent:Connect(function(status: unknown, fishCount: unknown, coins: unknown)
		if status == "ok" and type(fishCount) == "number" and type(coins) == "number" then
			Sounds.play("Coins")
			CoinBurst.burst(screen, coinLabel, coins, function() end)
			local noun = if fishCount == 1 then "pez" else "peces"
			toasts.show(
				`+{coins} monedas · {fishCount} {noun} para {GiantName.current()}`,
				COLORS.Coins
			)
		elseif status == "empty" then
			toasts.show("No llevas peces: pesca en la orilla de la isla", COLORS.Fishing)
		elseif status == "evolving" then
			toasts.show(
				`¡{GiantName.current(true)} está evolucionando! Espera unos segundos`,
				COLORS.Power
			)
		elseif status == "resting" then
			toasts.show("Está descansando: quédate en el volcán y entrena", COLORS.Power)
		elseif status == "full" then
			toasts.show(`{GiantName.current(true)} ya no tiene hambre`, COLORS.Success)
		end
	end)
end

return FeedFeedback
