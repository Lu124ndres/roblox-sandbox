--!strict
--[[
	CatchLabels

	Adornos de una captura que ven todos: el cartel flotante sobre la cabeza,
	una placa de piedra volcánica (Interface/Kit) con "¡ÉPICO!" del color de
	la rareza, el nombre del pez dorado y el ícono del pez con "xN"; sube y se
	desvanece. El aura de los trofeos está en Effects/LightAura.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)

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
	billboard.Size = UDim2.fromOffset(230, 96)
	billboard.StudsOffset = Vector3.new(0, 5.4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = LABEL_DISTANCE
	billboard.LightInfluence = 0
	local plate = Instance.new("Frame")
	plate.Name = "Placa"
	plate.Size = UDim2.fromScale(1, 1)
	plate.Parent = billboard
	local skin = Kit.skin(plate, "panel")
	skin.SliceScale = 0.28
	local top =
		text(plate, `¡{TextCase.upper(rarityName)}!`, color, 0.08, 0.32, UIConfig.Fonts.Title)
	local name = text(
		plate,
		if fish then fish.displayName else fishId,
		Color3.new(1, 1, 1),
		0.4,
		0.26,
		UIConfig.Fonts.Title
	)
	Kit.gold(name)
	local icon = Icons.view(plate, "fish")
	icon.AnchorPoint = Vector2.new(1, 0)
	icon.Position = UDim2.fromScale(0.5, 0.64)
	icon.Size = UDim2.fromScale(0.13, 0.3)
	local amount = text(plate, `x{count}`, UIConfig.Colors.Text, 0.66, 0.26, UIConfig.Fonts.Title)
	amount.Position = UDim2.fromScale(0.52, 0.66)
	amount.Size = UDim2.fromScale(0.4, 0.26)
	amount.TextXAlignment = Enum.TextXAlignment.Left
	local pop = Instance.new("UIScale")
	pop.Scale = 0.3
	pop.Parent = billboard
	billboard.Parent = head
	TweenService:Create(pop, UIConfig.Tweens.Pop, { Scale = 1 }):Play()

	task.delay(seconds, function()
		local fade = TweenInfo.new(0.5)
		TweenService:Create(billboard, fade, { StudsOffset = Vector3.new(0, 7, 0) }):Play()
		for _, label in { top, name, amount } do
			TweenService:Create(label, fade, { TextTransparency = 1, TextStrokeTransparency = 1 })
				:Play()
			local stroke = label:FindFirstChildOfClass("UIStroke")
			if stroke then
				TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
			end
		end
		for _, image in { skin, icon } do
			if image:IsA("ImageLabel") then
				TweenService:Create(image, fade, { ImageTransparency = 1 }):Play()
			end
		end
		Debris:AddItem(billboard, 0.6)
	end)
end

return CatchLabels
