--!strict
--[[
	Toasts

	Mensajes cortos de feedback ("¡Pescaste una Caballa!", "+12 monedas") y
	banners grandes para momentos importantes (la barra cambia de estado).
	Aparecen con un rebote, esperan y se desvanecen solos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Ui)

export type Toasts = {
	show: (text: string, color: Color3?) -> (),
	banner: (text: string, color: Color3?) -> (),
}

local COLORS = UIConfig.Colors
local SIZES = UIConfig.TextSizes
local TWEENS = UIConfig.Tweens
local EFFECTS = UIConfig.Effects

local Toasts = {}

local function popIn(target: GuiObject): UIScale
	local scale = Instance.new("UIScale")
	scale.Scale = 0.6
	scale.Parent = target
	TweenService:Create(scale, TWEENS.Pop, { Scale = 1 }):Play()
	return scale
end

local function fadeOutAndDestroy(target: GuiObject, label: TextLabel, seconds: number)
	task.delay(seconds, function()
		local stroke = target:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, TWEENS.Fade, { Transparency = 1 }):Play()
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

function Toasts.mount(screen: ScreenGui): Toasts
	local stack = Instance.new("Frame")
	stack.Name = "Avisos"
	stack.BackgroundTransparency = 1
	stack.AnchorPoint = Vector2.new(0.5, 0)
	stack.Position = UDim2.new(0.5, 0, 0.26, 10) -- debajo de la barra de hambre (se escala con el alto)
	stack.Size = UDim2.fromScale(0.46, 0.4)
	stack.ZIndex = 40 -- encima de las ventanas (TIENDA, MEJORAS...)
	stack.Parent = screen
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = stack

	local order = 0

	local function show(text: string, color: Color3?)
		order += 1
		local toast = Ui.panel("Aviso", stack)
		toast.LayoutOrder = order
		toast.Size = UDim2.new(1, 0, 0, 40)
		local limit = Instance.new("UISizeConstraint")
		limit.MaxSize = Vector2.new(460, 40)
		limit.Parent = toast
		local label = Ui.label("Texto", toast, UIConfig.Fonts.Body, SIZES.Body)
		label.Size = UDim2.new(1, -16, 1, -8)
		label.Position = UDim2.fromOffset(8, 4)
		label.Text = text
		label.TextColor3 = color or COLORS.Text
		popIn(toast)
		fadeOutAndDestroy(toast, label, EFFECTS.ToastSeconds)
	end

	local function banner(text: string, color: Color3?)
		local frame = Instance.new("Frame")
		frame.Name = "Banner"
		frame.BackgroundTransparency = 1
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.38)
		frame.Size = UDim2.new(0.9, 0, 0, 72)
		frame.ZIndex = 40
		frame.Parent = screen
		local label = Ui.label("Texto", frame, UIConfig.Fonts.Title, SIZES.Banner)
		label.Size = UDim2.fromScale(1, 1)
		label.Text = text
		label.TextColor3 = color or COLORS.Text
		label.TextStrokeTransparency = 0
		popIn(frame)
		fadeOutAndDestroy(frame, label, EFFECTS.BannerSeconds)
	end

	return { show = show, banner = banner }
end

return Toasts
