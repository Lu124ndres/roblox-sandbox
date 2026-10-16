--!strict
--[[
	PondSigns

	Cartel flotante sobre cada estanque de entrenamiento, como los simuladores:
	"25x" enorme con degradado y contorno del color de su nivel, debajo
	"Requisito: 3 kills o 25K poder" (o "¡Abierto! Entrenar [E]") del mismo
	color, sobre una franja de luz de ese color que se desvanece a los lados.
	Se actualiza cuando cambia el poder o las kills del jugador.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Perks = require(ReplicatedStorage.Shared.Perks)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Style = require(script.Parent.Parent.Interface.Style)

local PONDS = Config.Progression.ponds
local SIGN_HEIGHT = 10 -- sobre el cristal flotante
local SACRED_SIGN_HEIGHT = 21
local WHITE = Color3.new(1, 1, 1)

local PondSigns = {}

type Sign = { requirement: TextLabel, multiplier: TextLabel, glow: Frame }

-- Texto grande con contorno oscuro del color del estanque y degradado blanco → color.
local function text(parent: Instance, name: string, color: Color3, big: boolean): TextLabel
	local label = Style.text(parent, name, if big then 200 else 80, WHITE, if big then 5 else 3)
	label.ZIndex = 2
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = if big
		then ColorSequence.new(color:Lerp(WHITE, 0.55), color)
		else ColorSequence.new(color:Lerp(WHITE, 0.25), color)
	fill.Parent = label
	local outline = label:FindFirstChildOfClass("UIStroke")
	if outline then
		outline.Color = color:Lerp(Color3.new(0, 0, 0), 0.72)
	end
	return label
end

-- Fondo de luz del color del estanque que se desvanece hacia los costados.
local function glow(parent: Instance, color: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Brillo"
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = frame
	frame.Parent = parent
	return frame
end

local function build(index: number): Sign
	local anchor = Instance.new("Attachment")
	anchor.Name = `CartelEstanque{index}`
	local sacred = PONDS[index].robuxOnly == true -- más alto: arriba de la estatua del centro
	anchor.WorldPosition = WorldZones.pondCenter(index)
		+ Vector3.new(0, if sacred then SACRED_SIGN_HEIGHT else SIGN_HEIGHT, 0)
	anchor.Parent = Workspace.Terrain
	local billboard = Instance.new("BillboardGui")
	billboard.Size = if sacred then UDim2.fromScale(20, 8) else UDim2.fromScale(16, 6.4) -- en studs
	billboard.MaxDistance = 110
	billboard.LightInfluence = 0
	billboard.Adornee = anchor
	billboard.Parent = anchor
	local base = UIConfig.PondColors[index] or UIConfig.Colors.Text
	local h, sat = base:ToHSV()
	local color = Color3.fromHSV(h, math.max(sat, 0.7), 1) -- vivo, como los simuladores
	local back = glow(billboard, color)
	local multiplier = text(billboard, "Multiplicador", color, true)
	multiplier.Position = UDim2.fromScale(0, 0.02)
	multiplier.Size = UDim2.fromScale(1, 0.62)
	multiplier.Text = `{PONDS[index].multiplier}x`
	local requirement = text(billboard, "Requisito", color, false)
	requirement.Position = UDim2.fromScale(0.04, 0.64)
	requirement.Size = UDim2.fromScale(0.92, 0.3)
	return { requirement = requirement, multiplier = multiplier, glow = back }
end

function PondSigns.start()
	local player = Players.LocalPlayer
	local signs: { Sign } = {}
	for index = 1, #PONDS do
		signs[index] = build(index)
	end
	local function refresh()
		for index, sign in signs do
			local open = Perks.pondOpen(player, index)
			if open then
				sign.requirement.Text = "¡Abierto! Entrenar [E]"
			elseif PONDS[index].robuxOnly then
				sign.requirement.Text = "Requisito: pase SAGRADO (R$)"
			else
				sign.requirement.Text =
					`Requisito: {FishingPower.pondRequirement(PONDS[index], true)}`
			end
			sign.glow.BackgroundTransparency = if open then 0.3 else 0.5
			sign.multiplier.TextTransparency = if open then 0 else 0.15
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
