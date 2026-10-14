--!strict
--[[
	Toasts

	Mensajes cortos de feedback ("¡Pescaste una Caballa!", "+12 monedas") y
	banners grandes para momentos importantes (la barra cambia de estado).
	Aparecen con un rebote, esperan y se desvanecen solos. La pila va justo
	debajo del panel de hambre (Toasts.placeBelow), así no tapa los atajos
	para llenar al monstruo, y por encima de las ventanas.
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

local GAP_BELOW = 8 -- aire entre el panel de hambre y el primer aviso

local Toasts = {}

local stack: Frame? = nil
-- Toasts.hold: mientras dura (la ruleta), los avisos esperan y salen después.
local heldUntil = 0
local waiting: { () -> () } = {}

-- Guarda los avisos `seconds` segundos (y esconde los que ya están) para no tapar algo.
function Toasts.hold(seconds: number)
	heldUntil = math.max(heldUntil, os.clock() + seconds)
	if stack then
		stack.Visible = false
	end
	task.delay(seconds + 0.05, function()
		if os.clock() < heldUntil then
			return
		end
		if stack then
			stack.Visible = true
		end
		local pending = waiting
		waiting = {}
		for index, run in pending do
			task.delay((index - 1) * 0.6, run)
		end
	end)
end

local function held(run: () -> ()): boolean
	if os.clock() < heldUntil then
		table.insert(waiting, run)
		return true
	end
	return false
end

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
	local frame = Instance.new("Frame")
	frame.Name = "Avisos"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0.26, 10) -- hasta que placeBelow la acomode
	frame.Size = UDim2.fromScale(0.46, 0.4)
	frame.ZIndex = 40 -- encima de las ventanas (TIENDA, MEJORAS...)
	frame.Parent = screen
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	stack = frame

	local order = 0

	local function show(text: string, color: Color3?)
		if held(function()
			show(text, color)
		end) then
			return
		end
		order += 1
		local toast = Ui.panel("Aviso", frame)
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
		if held(function()
			banner(text, color)
		end) then
			return
		end
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

-- Pone la pila justo debajo de lo que se ve de `panel` (los atajos de llenar
-- solo se ven mientras el monstruo come) y la sigue si el panel cambia.
function Toasts.placeBelow(panel: GuiObject)
	local function place()
		local target = stack
		if not target then
			return
		end
		local bottom = panel.AbsolutePosition.Y
		for _, child in panel:GetChildren() do
			if child:IsA("GuiObject") and child.Visible then
				bottom = math.max(bottom, child.AbsolutePosition.Y + child.AbsoluteSize.Y)
			end
		end
		local parent = target.Parent
		local top = if parent and parent:IsA("GuiBase2d") then parent.AbsolutePosition.Y else 0
		target.Position = UDim2.new(0.5, 0, 0, math.floor(bottom - top + GAP_BELOW))
	end
	local function watch(child: Instance)
		if child:IsA("GuiObject") then
			child:GetPropertyChangedSignal("Visible"):Connect(place)
			child:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
		end
	end
	for _, child in panel:GetChildren() do
		watch(child)
	end
	panel.ChildAdded:Connect(function(child)
		watch(child)
		task.defer(place)
	end)
	panel:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
	panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	task.defer(place)
end

return Toasts
