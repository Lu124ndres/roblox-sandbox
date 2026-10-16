--!strict
--[[
	SpinWheelView

	La rueda de la ruleta, como la de los simuladores: la imagen de la rueda
	(Assets.UI.RuedaRuleta, 8 casillas con la 1 arriba) y, encima de cada
	casilla, su ícono, su premio cerca del borde y su % cerca del centro; la
	flecha roja arriba marca la casilla que sale. Todo va en `rotor`, que gira.
	La usan la ventana (SpinWindow) y la rueda del mundo (SpinStand).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Assets)
local SPIN = require(ReplicatedStorage.Shared.Config.Spin)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)
local SpinOffers = require(script.Parent.SpinOffers)

local SLICE = 360 / #SPIN.prizes
local RIM = 0.43 -- radio de las casillas en la imagen (fracción del lado)
local COLORS: { [string]: Color3 } = {
	coins = Color3.fromRGB(90, 220, 90),
	boost = Color3.fromRGB(80, 170, 255),
	fill = Color3.fromRGB(255, 120, 90),
	spins = Color3.fromRGB(255, 210, 60),
	coinBoost = Color3.fromRGB(255, 120, 210),
}

export type Wheel = {
	root: Frame,
	rotor: Frame,
	labels: { TextLabel },
	spinTo: (index: number, seconds: number) -> (),
}

local SpinWheelView = {}

local function place(child: GuiObject, angle: number, radius: number, size: number)
	local a = math.rad(angle - 90)
	child.AnchorPoint = Vector2.new(0.5, 0.5)
	child.Position = UDim2.fromScale(0.5 + math.cos(a) * radius, 0.5 + math.sin(a) * radius)
	child.Size = UDim2.fromScale(size, size)
	child.Rotation = angle
end

function SpinWheelView.build(parent: Instance, textScale: number?): Wheel
	local big = textScale or 1
	local root = Instance.new("Frame")
	root.Name = "Rueda"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = root
	root.Parent = parent

	local rotor = Instance.new("Frame")
	rotor.Name = "Rotor"
	rotor.BackgroundTransparency = 1
	rotor.AnchorPoint = Vector2.new(0.5, 0.5)
	rotor.Position = UDim2.fromScale(0.5, 0.5)
	rotor.Size = UDim2.fromScale(1, 1)
	rotor.Parent = root
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Image = Assets.UI.RuedaRuleta
	image.Size = UDim2.fromScale(1, 1)
	image.Parent = rotor

	local labels: { TextLabel } = {}
	for index, prize in SPIN.prizes do
		local angle = (index - 1) * SLICE
		local color = COLORS[prize.kind] or Color3.new(1, 1, 1)
		local icon = Icons.view(rotor, prize.icon)
		place(icon, angle, RIM * 0.56, 0.15)
		icon.ZIndex = 2
		local label = Style.text(rotor, "Premio", math.floor(30 * big), color, 2.5)
		place(label, angle, RIM * 0.86, 0.2)
		label.Size = UDim2.fromScale(0.26, 0.07)
		label.Text = prize.label
		label.ZIndex = 3
		labels[index] = label
		local percent = Style.text(rotor, "Probabilidad", math.floor(28 * big), nil, 2.5)
		place(percent, angle, RIM * 0.28, 0.1)
		percent.Size = UDim2.fromScale(0.12, 0.06)
		local value = SpinOffers.percent(index)
		percent.Text = if value < 1 then string.format("%.1f%%", value) else `{math.round(value)}%`
		percent.ZIndex = 3
	end

	local pointer = Instance.new("ImageLabel")
	pointer.Name = "Flecha"
	pointer.BackgroundTransparency = 1
	pointer.Image = Assets.UI.PunteroRuleta
	pointer.AnchorPoint = Vector2.new(0.5, 0.5)
	pointer.Position = UDim2.fromScale(0.5, 0.025)
	pointer.Size = UDim2.fromScale(0.13, 0.13)
	pointer.ZIndex = 5
	pointer.Parent = root

	-- Gira varias vueltas y frena con la casilla `index` bajo la flecha.
	local function spinTo(index: number, seconds: number)
		local target = -(index - 1) * SLICE
		local current = rotor.Rotation % 360
		rotor.Rotation = current
		local finish = target - 360 * 5
		while finish > current - 360 * 4 do
			finish -= 360
		end
		local info = TweenInfo.new(seconds, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		TweenService:Create(rotor, info, { Rotation = finish }):Play()
	end

	return { root = root, rotor = rotor, labels = labels, spinTo = spinTo }
end

return SpinWheelView
