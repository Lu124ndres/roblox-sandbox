--!strict
--[[
	PlaytimeEntry

	Botón grande de los regalos por jugar en la columna izquierda: tarjeta
	rosa con el regalo que sobresale, "REGALO GRATIS" y la cuenta regresiva
	grande. Cuando hay uno listo se vuelve verde, dice ¡RECLAMAR!, late y el
	regalo se sacude para llamar la atención.
]]

local TweenService = game:GetService("TweenService")

local Icons = require(script.Parent.Parent.Interface.Icons)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local PALETTE = Style.PALETTE
local HEIGHT = 58
local ICON = 70
local PULSE = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local SHAKE = TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 5, true)

export type Entry = {
	set: (ready: boolean, text: string?) -> (),
}

local PlaytimeEntry = {}

local function paint(button: TextButton, color: Color3)
	button.BackgroundColor3 = color
	local old = button:FindFirstChildOfClass("UIGradient")
	if old then
		old:Destroy()
	end
	Style.gradient(button, color)
end

function PlaytimeEntry.build(order: number, onClick: () -> ()): Entry
	local holder = Instance.new("Frame")
	holder.Name = "RegalosTiempo"
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = order
	holder.Size = UDim2.fromOffset(Layout.statWidth(), HEIGHT + 8)
	holder.Parent = Layout.left()
	local button = Instance.new("TextButton")
	button.Name = "Boton"
	button.Text = ""
	button.Position = UDim2.fromOffset(ICON / 2, 6)
	button.Size = UDim2.new(1, -ICON / 2 - 6, 0, HEIGHT - 4)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = button
	Style.border(button, 3)
	paint(button, PALETTE.Gift)
	button.Parent = holder
	local beat = Instance.new("UIScale")
	beat.Parent = holder

	local icon = Icons.view(holder, "giftPink")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0, ICON / 2, 0.5, 0)
	icon.Size = UDim2.fromOffset(ICON, ICON)
	icon.ZIndex = 3
	local left = ICON / 2 + 4
	local title = Style.text(button, "Titulo", 18, Color3.fromRGB(255, 240, 250), 2)
	title.Text = "REGALO GRATIS"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(left, 3)
	title.Size = UDim2.new(1, -left - 6, 0.36, 0)
	local value = Style.text(button, "Texto", 30, nil, 2.5)
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Position = UDim2.new(0, left, 0.38, 0)
	value.Size = UDim2.new(1, -left - 6, 0.56, 0)
	button.Activated:Connect(onClick)

	local wasReady: boolean? = nil
	local pulse: Tween? = nil
	local shaking = false

	local function set(ready: boolean, text: string?)
		holder.Visible = ready or text ~= nil
		value.Text = if ready then "¡RECLAMAR!" else text or ""
		if ready == wasReady then
			if ready and not shaking then -- se sacude cada tanto
				shaking = true
				TweenService:Create(icon, SHAKE, { Rotation = 14 }):Play()
				task.delay(3, function()
					shaking = false
				end)
			end
			return
		end
		wasReady = ready
		paint(button, if ready then PALETTE.Buy else PALETTE.Gift)
		title.Text = if ready then "¡TU REGALO ESTÁ LISTO!" else "REGALO GRATIS"
		if pulse then
			pulse:Cancel()
			pulse = nil
			beat.Scale = 1
		end
		if ready then
			pulse = TweenService:Create(beat, PULSE, { Scale = 1.06 });
			(pulse :: Tween):Play()
		end
	end

	return { set = set }
end

return PlaytimeEntry
