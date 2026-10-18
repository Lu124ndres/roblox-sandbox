--!strict
--[[
	PondSigns

	Un cartel flotante sobre cada estanque de entrenamiento (lo dibuja
	PondSignView): su nombre, el multiplicador de poder y una cápsula con lo
	que pide para abrirse (monstruos llenados o poder, lo que llegue primero;
	el sagrado, su pase de Robux) o «¡Abierto! Entrenar». Se actualiza cuando
	cambia el poder o las kills del jugador. Mientras entrena en un estanque,
	el cartel de ese se esconde: de cerca tapaba su nombre y su título. Solo
	muestra: el servidor decide quién entrena dónde (TrainingService).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local PondSignView = require(script.Parent.PondSignView)

local PONDS = Config.Progression.ponds
local SIGN_HEIGHT = 12 -- sobre el espíritu del estanque
local SACRED_SIGN_HEIGHT = 21 -- sobre el pez dorado del sagrado

local PondSigns = {}

local function multiplier(value: number): string
	return `x{value}`
end

local function build(index: number): PondSignView.View
	local sacred = PONDS[index].robuxOnly == true
	local anchor = Instance.new("Attachment")
	anchor.Name = `CartelEstanque{index}`
	anchor.WorldPosition = WorldZones.pondCenter(index)
		+ Vector3.new(0, if sacred then SACRED_SIGN_HEIGHT else SIGN_HEIGHT, 0)
	anchor.Parent = Workspace.Terrain
	return PondSignView.build(anchor, index, sacred, multiplier(PONDS[index].multiplier))
end

function PondSigns.start()
	local player = Players.LocalPlayer
	local signs: { PondSignView.View } = {}
	for index = 1, #PONDS do
		signs[index] = build(index)
	end
	local function refresh()
		for index, sign in signs do
			local def = PONDS[index]
			local state: PondSignView.State = if Perks.pondOpen(player, index)
				then "open"
				elseif def.robuxOnly then "robux"
				else "locked"
			sign.set(state, `{def.requiredKills}`, NumberFormat.short(def.requiredPower))
		end
	end
	local function hideCurrent()
		local current = player:GetAttribute(Protocol.PlayerAttributes.TrainingPond)
		for index, sign in signs do
			sign.show(index ~= current)
		end
	end
	player.AttributeChanged:Connect(function(name: string)
		if Perks.affectsPonds(name) then
			refresh()
		elseif name == Protocol.PlayerAttributes.TrainingPond then
			hideCurrent()
		end
	end)
	refresh()
	hideCurrent()
end

return PondSigns
