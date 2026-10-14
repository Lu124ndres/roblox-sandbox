--!strict
--[[
	CatchLabels

	Adornos de una captura que ven todos: el cartel flotante sobre la cabeza
	("¡ÉPICO!" + nombre del pez y "xN") que sube y se desvanece, y el haz de
	luz del color de la rareza que sale del piso cuando se saca un trofeo.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)

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
		text(billboard, `¡{string.upper(rarityName)}!`, color, 0, 0.5, UIConfig.Fonts.Title)
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

-- Columna de luz desde los pies del jugador; más ancha y alta cuanto más raro.
function CatchLabels.beam(feet: Vector3, color: Color3, seconds: number, level: number)
	local height = 18 + level * 8
	local beam = Instance.new("Part")
	beam.Name = "HazCaptura"
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(height, 0.6, 0.6)
	beam.CFrame = CFrame.new(feet + Vector3.new(0, height / 2 - 3, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	beam.Color = color
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.35
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.CastShadow = false
	beam.Parent = Workspace
	local width = 1.6 + level * 0.5
	TweenService:Create(
		beam,
		TweenInfo.new(0.25, Enum.EasingStyle.Back),
		{ Size = Vector3.new(height, width, width) }
	):Play()
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 18
	light.Brightness = 2
	light.Parent = beam
	task.delay(seconds, function()
		TweenService:Create(
			beam,
			TweenInfo.new(0.5),
			{ Transparency = 1, Size = Vector3.new(height, 0.2, 0.2) }
		):Play()
	end)
	Debris:AddItem(beam, seconds + 0.6)
end

return CatchLabels
