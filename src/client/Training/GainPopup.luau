--!strict
--[[
	GainPopup

	El "+13.4K" que salta sobre la cabeza en cada tick de entrenamiento:
	cristal + número grande con degradado y contorno grueso. Aparece de golpe
	(crece y rebota), sube, gira un poco y se desvanece. Con la racha (ticks
	seguidos sin parar) cambia de color y crece un poco: azul, después morado
	(10 ticks) y dorado (25 ticks), para que quedarse entrenando se sienta.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)

local STREAK_GAP = 1.5 -- segundos sin tick: la racha vuelve a cero
local TIERS = { -- desde cuántos ticks seguidos, colores del degradado y del contorno
	{
		from = 0,
		top = Color3.fromRGB(235, 250, 255),
		bottom = Color3.fromRGB(90, 190, 255),
		edge = Color3.fromRGB(10, 45, 110),
	},
	{
		from = 10,
		top = Color3.fromRGB(250, 235, 255),
		bottom = Color3.fromRGB(190, 110, 255),
		edge = Color3.fromRGB(55, 15, 100),
	},
	{
		from = 25,
		top = Color3.fromRGB(255, 252, 220),
		bottom = Color3.fromRGB(255, 190, 40),
		edge = Color3.fromRGB(110, 50, 0),
	},
}

local GainPopup = {}

local rng = Random.new()
local streak, lastAt = 0, 0

local function tierFor(count: number)
	local chosen = TIERS[1]
	for _, tier in TIERS do
		if count >= tier.from then
			chosen = tier
		end
	end
	return chosen
end

function GainPopup.show(character: Model, gained: number)
	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end
	local now = os.clock()
	streak = if now - lastAt <= STREAK_GAP then streak + 1 else 1
	lastAt = now
	local tier = tierFor(streak)
	local grow = 1 + math.min(streak, 25) / 100 -- hasta +25 % con la racha

	local board = Instance.new("BillboardGui")
	board.Name = "GananciaPoder"
	board.Size = UDim2.fromScale(5 * grow, 1.6 * grow) -- en studs: crece con el personaje
	board.StudsOffset = Vector3.new(rng:NextNumber(-1.8, 1.8), 4.6, 0) -- sobre el título
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	board.MaxDistance = 140
	board.Adornee = head
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Rotation = rng:NextNumber(-8, 8)
	holder.Parent = board
	local pop = Instance.new("UIScale")
	pop.Scale = 0.3
	pop.Parent = holder

	local icon = Icons.view(holder, "crystal")
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.fromScale(0, 0.5)
	icon.Size = UDim2.fromScale(0.3, 1)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = icon
	local text = Style.text(holder, "Numero", 200, Color3.new(1, 1, 1), 3)
	text.AnchorPoint = Vector2.new(0, 0.5)
	text.Position = UDim2.fromScale(0.28, 0.5)
	text.Size = UDim2.fromScale(0.72, 1)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Text = `+{NumberFormat.short(gained)}`
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new(tier.top, tier.bottom)
	shade.Parent = text
	local stroke = text:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = tier.edge
	stroke.Thickness = 3.5
	board.Parent = head

	-- Golpe: crece de más y rebota; después sube y se apaga.
	TweenService
		:Create(pop, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1.3,
		})
		:Play()
	task.delay(0.14, function()
		TweenService:Create(pop, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
	end)
	local rise = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(board, rise, { StudsOffset = board.StudsOffset + Vector3.new(0, 3.2, 0) })
		:Play()
	TweenService:Create(holder, rise, { Rotation = holder.Rotation * -0.5 }):Play()
	local fade = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.65)
	TweenService:Create(text, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
	if icon:IsA("ImageLabel") then
		TweenService:Create(icon, fade, { ImageTransparency = 1 }):Play()
	end
	task.delay(1.15, function()
		board:Destroy()
	end)
end

return GainPopup
