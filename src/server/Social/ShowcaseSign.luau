--!strict
--[[
	ShowcaseSign

	El cartel grande de cada vitrina (Social/Showcase): sobre una franja
	translúcida en el color del traje, el precio con el ícono de Robux, el
	nombre del pase con degradado y sus ventajas en una línea.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local ShowcaseStage = require(script.Parent.ShowcaseStage)

type Look = ShowcaseStage.Look

local rgb = Color3.fromRGB

local ShowcaseSign = {}

local function text(
	parent: Instance,
	value: string,
	y: number,
	h: number,
	color: Color3,
	gradient: { Color3 }?
): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position, label.Size = UDim2.fromScale(0, y), UDim2.fromScale(1, h)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = value
	label.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Thickness, stroke.Color = 4, rgb(30, 20, 18)
	stroke.Parent = label
	if gradient then
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(gradient[1], gradient[2])
		g.Rotation = 90
		g.Parent = label
	end
	label.Parent = parent
	return label
end

-- El cartel grande sobre el traje: precio, nombre y ventajas, sobre una franja translúcida.
function ShowcaseSign.build(parent: BasePart, passKey: string, height: number, look: Look)
	local pass = Config.Monetization.passes[passKey]
	local gui = Instance.new("BillboardGui")
	gui.Name = "Cartel"
	gui.Size = UDim2.fromScale(20, 6.5)
	gui.StudsOffset = Vector3.new(0, height + 3.4, 0)
	gui.MaxDistance = 110
	gui.LightInfluence = 0
	local band = Instance.new("Frame")
	band.BackgroundColor3 = look.deep
	band.BackgroundTransparency = 0.55
	band.BorderSizePixel = 0
	band.Position, band.Size = UDim2.fromScale(0, 0.05), UDim2.fromScale(1, 0.9)
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = band
	band.Parent = gui
	local price = Instance.new("Frame")
	price.BackgroundTransparency = 1
	price.Position, price.Size = UDim2.fromScale(0.36, 0.02), UDim2.fromScale(0.28, 0.28)
	price.Parent = gui
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = Assets.UI.RobuxIcon
	icon.ImageColor3 = rgb(110, 255, 120)
	icon.Size = UDim2.fromScale(1, 1)
	icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
	icon.Parent = price
	local amount = text(price, tostring(pass.robux), 0, 1, rgb(110, 255, 120))
	amount.Position, amount.Size = UDim2.fromScale(0.32, 0), UDim2.fromScale(0.68, 1)
	amount.TextXAlignment = Enum.TextXAlignment.Left
	text(gui, pass.name, 0.28, 0.42, Color3.new(1, 1, 1), { look.light, look.main })
	text(
		gui,
		pass.perks or pass.description,
		0.72,
		0.24,
		Color3.new(1, 1, 1),
		{ look.light, look.main }
	)
	gui.Parent = parent
end
return table.freeze(ShowcaseSign)
