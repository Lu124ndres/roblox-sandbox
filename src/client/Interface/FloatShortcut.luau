--!strict
--[[
	FloatShortcut

	Un atajo suelto, sin casilla, que llama la atención: el ícono sobre rayos
	dorados que giran, el nombre dorado abajo y el precio en Robux arriba a la
	derecha (Style.robuxBadge), todo subiendo y bajando. Lo usan los atajos de
	Poder y Monedas (QuickBuys) y el del pack de inicio (Menus/StarterShortcut).
	`phase` (0..1) desfasa el vaivén para que dos atajos juntos no suban a la vez.
]]

local TweenService = game:GetService("TweenService")

local Icons = require(script.Parent.Icons)
local Kit = require(script.Parent.Kit)
local Style = require(script.Parent.Style)

local FLOAT = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local FLOAT_RISE = 6 -- píxeles que sube y baja
local SPIN = TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
local RAYS_COLOR = Color3.fromRGB(255, 214, 80)

export type Shortcut = { button: TextButton, label: TextLabel, price: TextLabel }

local FloatShortcut = {}

function FloatShortcut.new(
	parent: Instance,
	name: string,
	icon: string,
	size: number,
	phase: number
): Shortcut
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Size = UDim2.fromOffset(size, size)
	button.Parent = parent
	local float = Instance.new("Frame")
	float.Name = "Flota"
	float.BackgroundTransparency = 1
	float.Size = UDim2.fromScale(1, 1)
	float.Interactable = false
	float.Parent = button
	local rays = Icons.view(float, "sunburst")
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.42)
	rays.Size = UDim2.fromScale(1.15, 1.15)
	if rays:IsA("ImageLabel") then -- vienen blancos para teñir
		rays.ImageColor3 = RAYS_COLOR
		rays.ImageTransparency = 0.25
	end
	local view = Icons.view(float, icon)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.42)
	view.Size = UDim2.fromScale(0.72, 0.72)
	view.ZIndex = 2
	local label = Style.text(float, "Nombre", 22, nil, 2.5)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.fromScale(0.5, 1)
	label.Size = UDim2.new(1, 0, 0, 24)
	label.ZIndex = 3
	Kit.gold(label)
	local price = Style.robuxBadge(float)
	float.Position = UDim2.fromOffset(0, FLOAT_RISE / 2)
	task.delay(phase * FLOAT.Time, function()
		TweenService:Create(float, FLOAT, { Position = UDim2.fromOffset(0, -FLOAT_RISE / 2) })
			:Play()
	end)
	TweenService:Create(rays, SPIN, { Rotation = 360 }):Play()
	return { button = button, label = label, price = price }
end

return table.freeze(FloatShortcut)
