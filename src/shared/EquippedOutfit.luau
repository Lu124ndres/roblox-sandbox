--!strict
--[[
	EquippedOutfit

	Qué traje lleva puesto el jugador, leído de atributos que solo pone el
	servidor (servidor y cliente calculan igual): el que eligió en una vitrina
	(TrajeElegido) si tiene su pase, o el del pase más caro, o marinero.
	Lo usan server/Social/Outfits (para vestirlo) y Perks (las ventajas de un
	traje solo valen con ese traje puesto).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Trajes = require(ReplicatedStorage.Shared.Trajes)

local PASSES = Config.Monetization.passes
local PASS_PREFIX = Protocol.PlayerAttributes.PassPrefix

local EquippedOutfit = {}

function EquippedOutfit.of(player: Player): string
	local chosen = player:GetAttribute(Trajes.CHOSEN)
	local best, price = Trajes.SAILOR, -1
	for key, pass in PASSES do
		if pass.outfit and player:GetAttribute(`{PASS_PREFIX}{key}`) == true then
			if pass.outfit == chosen then
				return pass.outfit
			elseif pass.robux > price then
				best, price = pass.outfit, pass.robux
			end
		end
	end
	return if chosen == Trajes.SAILOR then Trajes.SAILOR else best
end

return EquippedOutfit
