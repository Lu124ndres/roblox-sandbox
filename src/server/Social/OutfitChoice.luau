--!strict
--[[
	OutfitChoice

	Ponerse o quitarse el traje de un pase (vitrinas con E y botón Equipar de la
	TIENDA, remote ElegirTraje). Si ya lo lleva puesto vuelve a Marinero; si no,
	se lo pone. Solo si tiene el pase. Lo aplica Outfits (atributo TrajeElegido)
	y queda guardado (save.outfit): al volver a entrar lleva el mismo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Trajes = require(ReplicatedStorage.Shared.Trajes)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)

local OutfitChoice = {}

function OutfitChoice.toggle(player: Player, passKey: string)
	local pass = Config.Monetization.passes[passKey]
	local outfit = pass and pass.outfit
	if not outfit or not Perks.hasPass(player, passKey) then
		return
	end
	local character = player.Character
	local current = character and character:FindFirstChild(Trajes.FOLDER)
	local wearing = current and current:GetAttribute("Outfit") == outfit
	local chosen = if wearing then Trajes.SAILOR else outfit
	player:SetAttribute(Trajes.CHOSEN, chosen)
	PlayerData.edit(player, function(save)
		save.outfit = chosen
	end)
end

function OutfitChoice.init()
	Remotes.ChooseOutfit.OnServerEvent:Connect(
		RateLimit.wrap("ElegirTraje", 1, 2, function(player: Player, passKey: unknown)
			if type(passKey) == "string" and player.Parent == Players then
				OutfitChoice.toggle(player, passKey)
			end
		end)
	)
end

return table.freeze(OutfitChoice)
