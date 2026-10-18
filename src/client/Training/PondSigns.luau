--!strict
--[[
	PondSigns

	Cartel flotante sobre cada estanque de entrenamiento, como los simuladores,
	con el estilo de la interfaz (Interface/Kit): una placa de piedra volcánica
	con "25x" enorme en dorado y debajo "Requisito: 3 kills o 25K poder" (o
	"¡Abierto! Entrenar [E]") del color del nivel del estanque, ambos con
	contorno marrón oscuro. Cerrado, la placa se apaga un poco. Se actualiza
	cuando cambia el poder o las kills del jugador.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local FishingPower = require(ReplicatedStorage.Shared.FishingPower)
local Perks = require(ReplicatedStorage.Shared.Perks)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)

local PONDS = Config.Progression.ponds
local SIGN_HEIGHT = 10 -- sobre el cristal flotante
local SACRED_SIGN_HEIGHT = 21
local WHITE = Color3.new(1, 1, 1)
local CLOSED = Color3.fromRGB(170, 166, 170) -- la piedra apagada de un estanque cerrado
-- El cartel se mide en studs, así que sus píxeles cambian con la distancia: el canto de la
-- placa y el contorno de las letras se ajustan a su alto en pantalla.
local PANEL_EDGE = 44 -- píxeles del canto en la imagen de la placa (Kit)
local EDGE_SHARE = 0.09 -- el canto, como fracción del alto del cartel
local OUTLINE_SHARE: { [string]: number } = { big = 0.028, small = 0.016 }

local PondSigns = {}

type Sign = { requirement: TextLabel, multiplier: TextLabel, plate: ImageLabel }

-- El multiplicador en dorado; el requisito en el color del estanque (degradado claro →
-- color). Los dos con contorno marrón oscuro, como el texto dorado del kit.
local function text(parent: Instance, name: string, color: Color3, big: boolean): TextLabel
	local label = Style.text(parent, name, if big then 200 else 80, WHITE, if big then 5 else 3)
	label.ZIndex = 2
	if big then
		Kit.gold(label)
		return label
	end
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new(color:Lerp(WHITE, 0.45), color)
	fill.Parent = label
	local outline = label:FindFirstChildOfClass("UIStroke")
	if outline then
		outline.Color = Kit.GOLD_OUTLINE
	end
	return label
end

-- Placa de piedra volcánica que ocupa todo el cartel; su canto y los contornos de las
-- letras siguen al alto del cartel en pantalla.
local function plate(billboard: BillboardGui, labels: { [string]: TextLabel }): ImageLabel
	local frame = Instance.new("Frame")
	frame.Name = "Placa"
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = billboard
	local skin = Kit.skin(frame, "panel")
	local function fit()
		local height = frame.AbsoluteSize.Y
		skin.SliceScale = math.max(0.05, height * EDGE_SHARE / PANEL_EDGE)
		for size, label in labels do
			local stroke = label:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Thickness = math.clamp(height * OUTLINE_SHARE[size], 1, 8)
			end
		end
	end
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	return skin
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
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboard.Adornee = anchor
	billboard.Parent = anchor
	local base = UIConfig.PondColors[index] or UIConfig.Colors.Text
	local h, sat = base:ToHSV()
	local color = Color3.fromHSV(h, math.max(sat, 0.7), 1) -- vivo, como los simuladores
	local multiplier = text(billboard, "Multiplicador", color, true)
	multiplier.Position = UDim2.fromScale(0.06, 0.08)
	multiplier.Size = UDim2.fromScale(0.88, 0.54)
	multiplier.Text = `{PONDS[index].multiplier}x`
	local requirement = text(billboard, "Requisito", color, false)
	requirement.Position = UDim2.fromScale(0.07, 0.63)
	requirement.Size = UDim2.fromScale(0.86, 0.26)
	local back = plate(billboard, { big = multiplier, small = requirement })
	return { requirement = requirement, multiplier = multiplier, plate = back }
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
			sign.plate.ImageColor3 = if open then WHITE else CLOSED
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
