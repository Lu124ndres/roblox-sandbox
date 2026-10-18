--!strict
--[[
	ToastFx

	Efectos de los avisos: entrada con rebote y salida desvanecida de los
	avisos chicos (una placa de piedra con texto con contorno, Interface/Kit),
	y el brillo, las chispas y el ícono sobre rayos de las tarjetas grandes
	(ToastBanner).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Interface.Icons)
local Kit = require(script.Parent.Interface.Kit)
local Style = require(script.Parent.Interface.Style)

local TWEENS = UIConfig.Tweens
local WHITE = Color3.new(1, 1, 1)
local SMALL_SLICE = 0.3 -- borde de la placa de los avisos chicos (son bajitos)

local ToastFx = {}

local function tween(target: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local run = TweenService:Create(target, info, goal)
	run:Play()
	return run
end

function ToastFx.popIn(target: GuiObject): UIScale
	local scale = Instance.new("UIScale")
	scale.Scale = 0.6
	scale.Parent = target
	TweenService:Create(scale, TWEENS.Pop, { Scale = 1 }):Play()
	return scale
end

function ToastFx.fadeOut(target: GuiObject, label: TextLabel, seconds: number)
	task.delay(seconds, function()
		for _, holder in { target, label } do
			local stroke = holder:FindFirstChildOfClass("UIStroke")
			if stroke then
				TweenService:Create(stroke, TWEENS.Fade, { Transparency = 1 }):Play()
			end
		end
		local skin = target:FindFirstChild("Piedra")
		if skin and skin:IsA("ImageLabel") then
			TweenService:Create(skin, TWEENS.Fade, { ImageTransparency = 1 }):Play()
		end
		TweenService:Create(target, TWEENS.Fade, { BackgroundTransparency = 1 }):Play()
		local fade = TweenService:Create(
			label,
			TWEENS.Fade,
			{ TextTransparency = 1, TextStrokeTransparency = 1 }
		)
		fade:Play()
		fade.Completed:Wait()
		target:Destroy()
	end)
end

-- Franja de luz que cruza la tarjeta una vez.
function ToastFx.shine(group: CanvasGroup)
	local streak = Instance.new("Frame")
	streak.Name = "Brillo"
	streak.BackgroundColor3 = WHITE
	streak.BackgroundTransparency = 0.55
	streak.BorderSizePixel = 0
	streak.AnchorPoint = Vector2.new(0.5, 0.5)
	streak.Rotation = 20
	streak.Size = UDim2.new(0, 34, 2, 0)
	streak.Position = UDim2.fromScale(-0.1, 0.5)
	streak.ZIndex = 5
	streak.Parent = group
	task.delay(0.25, function()
		tween(
			streak,
			TweenInfo.new(0.7, Enum.EasingStyle.Quad),
			{ Position = UDim2.fromScale(1.1, 0.5) }
		)
	end)
end

-- Chispas que saltan de las esquinas y se apagan.
function ToastFx.sparkles(holder: Frame, color: Color3)
	local spots = {
		Vector2.new(0.02, 0.1),
		Vector2.new(0.98, 0.15),
		Vector2.new(0.06, 0.95),
		Vector2.new(0.95, 0.9),
	}
	for index, spot in spots do
		local star = Icons.view(holder, "glow")
		if star:IsA("ImageLabel") then
			star.ImageColor3 = color:Lerp(WHITE, 0.5)
		end
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.Position = UDim2.fromScale(spot.X, spot.Y)
		star.Size = UDim2.fromOffset(4, 4)
		star.ZIndex = 6
		task.delay(0.1 + index * 0.08, function()
			local size = 30 + (index % 2) * 12
			tween(
				star,
				TweenInfo.new(0.3, Enum.EasingStyle.Back),
				{ Size = UDim2.fromOffset(size, size) }
			)
			task.wait(0.35)
			if star:IsA("ImageLabel") then
				tween(star, TWEENS.Fade, { ImageTransparency = 1, Rotation = 90 })
			end
		end)
	end
end

function ToastFx.badge(group: CanvasGroup, color: Color3, icon: string, HEIGHT: number)
	local rays = Icons.view(group, "sunburst")
	if rays:IsA("ImageLabel") then
		rays.ImageColor3 = color:Lerp(WHITE, 0.3)
		rays.ImageTransparency = 0.25
		tween(
			rays,
			TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
			{ Rotation = 360 }
		)
	end
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.new(0, HEIGHT / 2 + 4, 0.5, 0)
	rays.Size = UDim2.fromOffset(HEIGHT + 20, HEIGHT + 20)
	rays.ZIndex = 2
	local image = Icons.view(group, icon)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.new(0, HEIGHT / 2 + 4, 0.5, 0)
	image.Size = UDim2.fromOffset(HEIGHT - 6, HEIGHT - 6)
	image.ZIndex = 3
end

-- Aviso chico de una línea en la pila; se borra solo.
function ToastFx.small(stack: Frame, order: number, text: string, color: Color3, seconds: number)
	local toast = Instance.new("Frame")
	toast.Name = "Aviso"
	toast.LayoutOrder = order
	toast.Size = UDim2.new(1, 0, 0, 40)
	Kit.skin(toast, "panel").SliceScale = SMALL_SLICE
	toast.Parent = stack
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(460, 40)
	limit.Parent = toast
	local label = Style.text(toast, "Texto", UIConfig.TextSizes.Body, nil, 2)
	label.FontFace = UIConfig.Fonts.Body
	label.Size = UDim2.new(1, -20, 1, -10)
	label.Position = UDim2.fromOffset(10, 5)
	label.Text = text
	label.TextColor3 = color
	ToastFx.popIn(toast)
	ToastFx.fadeOut(toast, label, seconds)
end

return ToastFx
