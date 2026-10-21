--!strict
--[[
	Toasts

	Mensajes cortos de feedback ("¡Pescaste una Caballa!", "+12 monedas") y
	tarjetas grandes para momentos importantes (ToastBanner), todos en una sola
	pila arriba: nunca más de MAX_SHOWN a la vez, así no se amontonan ni bajan
	hasta el jugador.
	Aparecen con un rebote, esperan y se desvanecen solos. La pila va justo
	debajo del panel de hambre (Toasts.placeBelow), así no tapa los atajos
	para llenar al monstruo, y por encima de las ventanas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Layout = require(script.Parent.Interface.Layout)
local ToastBanner = require(script.Parent.ToastBanner)
local ToastFx = require(script.Parent.ToastFx)

export type Toasts = {
	show: (text: string, color: Color3?) -> (),
	banner: (text: string, color: Color3?, icon: string?, caption: string?) -> (),
}

local COLORS = UIConfig.Colors
local EFFECTS = UIConfig.Effects

local GAP_BELOW = 8 -- aire entre el panel de hambre y el primer aviso
local STACK_WIDTH, STACK_HEIGHT = 480, 260 -- antes de la escala del HUD
local MAX_SHOWN = 2 -- más avisos que esto empujan fuera al más viejo (no bajan hasta el jugador)
local QUICK_SECONDS = 1.6 -- tarjetas en fila: cada una dura menos para no atrasarse

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

function Toasts.mount(screen: ScreenGui): Toasts
	local frame = Instance.new("Frame")
	frame.Name = "Avisos"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0.26, 10) -- hasta que placeBelow la acomode
	frame.Size = UDim2.fromOffset(STACK_WIDTH, STACK_HEIGHT)
	frame.ZIndex = 40 -- encima de las ventanas (TIENDA, MEJORAS...)
	frame.Parent = screen
	-- Se achica con el HUD: en un teléfono a tamaño de PC tapaban al jugador.
	Layout.scaleWith(frame)
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	stack = frame

	local order = 0

	-- Saca enseguida lo más viejo si hay demasiado a la vez (primero los avisos chicos).
	local function trim()
		local items: { GuiObject } = {}
		for _, child in frame:GetChildren() do
			if child:IsA("GuiObject") then
				table.insert(items, child)
			end
		end
		table.sort(items, function(x, y)
			if (x.Name == "Banner") ~= (y.Name == "Banner") then
				return y.Name == "Banner"
			end
			return x.LayoutOrder < y.LayoutOrder
		end)
		for index = 1, #items - MAX_SHOWN do
			items[index]:Destroy()
		end
	end

	-- Las tarjetas grandes salen de a una, en fila.
	type Card = { text: string, color: Color3?, icon: string?, caption: string? }
	local cards: { Card } = {}
	local showing = false
	local function pump()
		local card = if showing then nil else table.remove(cards, 1)
		if not card then
			return
		end
		showing = true
		order += 1
		local seconds = if #cards > 0 then QUICK_SECONDS else EFFECTS.BannerSeconds
		local color = card.color or COLORS.Text
		local holder =
			ToastBanner.show(frame, order, card.text, color, seconds, card.icon, card.caption)
		holder.Destroying:Once(function()
			showing = false
			task.defer(pump)
		end)
		trim()
	end

	local function show(text: string, color: Color3?)
		if held(function()
			show(text, color)
		end) then
			return
		end
		order += 1
		ToastFx.small(frame, order, text, color or COLORS.Text, EFFECTS.ToastSeconds)
		trim()
	end

	local function banner(text: string, color: Color3?, icon: string?, caption: string?)
		if held(function()
			banner(text, color, icon, caption)
		end) then
			return
		end
		table.insert(cards, { text = text, color = color, icon = icon, caption = caption })
		pump()
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
