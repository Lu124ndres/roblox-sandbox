--!strict
--[[
	PondSigns

	Cartel flotante sobre cada estanque de entrenamiento: el multiplicador en
	grande, del color de su nivel, y debajo "Entrenar (E)" o cuánto poder
	falta para desbloquearlo. Se actualiza cuando cambia el poder del jugador.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local PONDS = Config.Progression.ponds
local SIGN_HEIGHT = 8.5 -- sobre el cristal flotante

local PondSigns = {}

type Sign = { requirement: TextLabel, multiplier: TextLabel }

local function label(
	parent: Instance,
	size: UDim2,
	position: UDim2,
	font: Font,
	color: Color3
): TextLabel
	local text = Instance.new("TextLabel")
	text.Size = size
	text.Position = position
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.FontFace = font
	text.TextColor3 = color
	text.TextStrokeColor3 = UIConfig.Colors.TextStroke
	text.TextStrokeTransparency = 0.2
	text.Parent = parent
	return text
end

local function build(index: number): Sign
	local anchor = Instance.new("Attachment")
	anchor.Name = `CartelEstanque{index}`
	anchor.WorldPosition = WorldZones.pondCenter(index) + Vector3.new(0, SIGN_HEIGHT, 0)
	anchor.Parent = Workspace.Terrain
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(7, 3.6) -- en studs: se ve del tamaño del estanque
	billboard.MaxDistance = 90
	billboard.LightInfluence = 0
	billboard.Adornee = anchor
	billboard.Parent = anchor
	local color = UIConfig.PondColors[index] or UIConfig.Colors.Text
	local multiplier =
		label(billboard, UDim2.fromScale(1, 0.62), UDim2.new(), UIConfig.Fonts.Title, color)
	multiplier.Text = `x{PONDS[index].multiplier}`
	local requirement = label(
		billboard,
		UDim2.fromScale(1, 0.34),
		UDim2.fromScale(0, 0.64),
		UIConfig.Fonts.Body,
		UIConfig.Colors.Text
	)
	return { requirement = requirement, multiplier = multiplier }
end

function PondSigns.start()
	local player = Players.LocalPlayer
	local signs: { Sign } = {}
	for index = 1, #PONDS do
		signs[index] = build(index)
	end
	local function refresh()
		for index, sign in signs do
			local needed = PONDS[index].requiredKills
			if Perks.pondOpen(player, index) then
				sign.requirement.Text = "Entrenar [E]"
				sign.requirement.TextColor3 = UIConfig.Colors.Success
				sign.multiplier.TextTransparency = 0
			else
				sign.requirement.Text = `{needed} monstruos · [E] R$`
				sign.requirement.TextColor3 = UIConfig.Colors.Warning
				sign.multiplier.TextTransparency = 0.45
			end
		end
	end
	player.AttributeChanged:Connect(function(name: string)
		if Perks.affectsPonds(name) then
			refresh()
		end
	end)
	refresh()
end

return PondSigns
