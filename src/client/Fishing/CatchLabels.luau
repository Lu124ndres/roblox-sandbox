--!strict
--[[
	CatchLabels

	Adornos de una captura que ven todos: el cartel flotante sobre la cabeza
	("¡ÉPICO!" + nombre del pez y "xN") que sube y se desvanece. El aura de
	los trofeos está en Effects/LightAura.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local TextCase = require(ReplicatedStorage.Shared.TextCase)

local LABEL_DISTANCE = 160 -- a qué distancia todavía se ve el cartel

local CatchLabels = {}

local function text(
	parent: Instance,
	value: string,
	color: Color3,
	y: number,
	height: number,
	font: Font
)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, y)
	label.Size = UDim2.fromScale(1, height)
	label.Text = value
	label.TextScaled = true
	label.FontFace = font
	label.TextColor3 = color
	label.TextStrokeColor3 = UIConfig.Colors.TextStroke
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

function CatchLabels.billboard(
	head: BasePart,
	rarityName: string,
	fishId: string,
	count: number,
	color: Color3,
	seconds: number
)
	local fish = FishCatalog.get(fishId)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CartelCaptura"
	billboard.Size = UDim2.fromOffset(220, 74)
	billboard.StudsOffset = Vector3.new(0, 5.2, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = LABEL_DISTANCE
	billboard.LightInfluence = 0
	local top =
		text(billboard, `¡{TextCase.upper(rarityName)}!`, color, 0, 0.5, UIConfig.Fonts.Title)
	local name = if fish then fish.displayName else fishId
	local bottom = text(
		billboard,
		if count > 1 then `{name} x{count}` else name,
		UIConfig.Colors.Text,
		0.5,
		0.42,
		UIConfig.Fonts.Body
	)
	local pop = Instance.new("UIScale")
	pop.Scale = 0.3
	pop.Parent = billboard
	billboard.Parent = head
	TweenService:Create(pop, UIConfig.Tweens.Pop, { Scale = 1 }):Play()

	task.delay(seconds, function()
		local fade = TweenInfo.new(0.5)
		TweenService:Create(billboard, fade, { StudsOffset = Vector3.new(0, 7, 0) }):Play()
		for _, label in { top, bottom } do
			TweenService:Create(label, fade, { TextTransparency = 1, TextStrokeTransparency = 1 })
				:Play()
		end
		Debris:AddItem(billboard, 0.6)
	end)
end

return CatchLabels
