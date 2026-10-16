--!strict
--[[
	UpgradeCard

	Tarjeta de un nivel en la cuadrícula de MEJORAS: el ícono del equipo
	(GearIcons) sobre el color de su rareza, "Nv N" y abajo el estado:
		equipada      franja verde "EQUIPADA"
		comprada      franja verde oscura "TIENES"
		la siguiente  franja dorada con el precio y la cinta "¡SIGUIENTE!" (late)
		bloqueada     ícono oscurecido y el precio en gris
	Tocarla la selecciona: el panel de la izquierda (UpgradeDetail) la muestra.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local GearIcons = require(script.Parent.Parent.Interface.GearIcons)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)

local PALETTE = Style.PALETTE
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local PULSE = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

export type CardSpec = {
	category: string,
	level: number,
	price: number,
	owned: number, -- nivel que ya tiene el jugador
	onSelect: () -> (),
}

export type Card = {
	button: TextButton,
	setSelected: (on: boolean) -> (),
}

local UpgradeCard = {}

local function strip(card: TextButton, color: Color3, text: string, coin: boolean): TextLabel
	local bar = Instance.new("Frame")
	bar.Name = "Estado"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -6)
	bar.Size = UDim2.new(1, -12, 0.22, 0)
	bar.BackgroundColor3 = color
	bar.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bar
	Style.gradient(bar, color)
	Style.border(bar, 2)
	bar.Parent = card
	local left = 0.06
	if coin then
		local icon = Icons.view(bar, "coin")
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.fromScale(0.04, 0.5)
		icon.Size = UDim2.fromScale(0.26, 1.1)
		local square = Instance.new("UIAspectRatioConstraint")
		square.Parent = icon
		left = 0.3
	end
	local label = Style.text(bar, "Texto", 22, WHITE, 2)
	label.Text = text
	label.Position = UDim2.fromScale(left, 0.1)
	label.Size = UDim2.fromScale(0.96 - left, 0.8)
	return label
end

function UpgradeCard.new(parent: Instance, spec: CardSpec): Card
	local level = spec.level
	local isOwned = level <= spec.owned
	local isNext = level == spec.owned + 1
	local tier = GearIcons.tierColor(spec.category, level)
	local card = Instance.new("TextButton")
	card.Name = `Nivel{level}`
	card.LayoutOrder = level
	card.Text = ""
	card.AutoButtonColor = false
	card.BackgroundColor3 = if isOwned or isNext then tier else tier:Lerp(BLACK, 0.55)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card
	Style.gradient(card, card.BackgroundColor3)
	Style.border(card, 3)
	local stroke = card:FindFirstChildOfClass("UIStroke") :: UIStroke
	card.Parent = parent

	local icon = GearIcons.view(card, spec.category, level)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.fromScale(0.5, 0.06)
	icon.Size = UDim2.fromScale(0.82, 0.66)
	if not isOwned and not isNext then
		icon.ImageColor3 = Color3.fromRGB(70, 70, 80)
	end

	local chip = Style.text(card, "Nivel", 20, WHITE, 2)
	chip.Text = `Nv {level}`
	chip.TextXAlignment = Enum.TextXAlignment.Left
	chip.Position = UDim2.fromOffset(8, 4)
	chip.Size = UDim2.new(0.6, 0, 0.16, 0)
	chip.ZIndex = 2

	if level == spec.owned then
		strip(card, PALETTE.Buy, "EQUIPADA", false)
	elseif isOwned then
		strip(card, PALETTE.Buy:Lerp(BLACK, 0.35), "TIENES", false)
	elseif isNext then
		strip(card, PALETTE.Coins, NumberFormat.short(spec.price), true)
		local ribbon = Style.text(card, "Siguiente", 18, PALETTE.Coins, 2)
		ribbon.Text = "¡SIGUIENTE!"
		ribbon.Rotation = 12
		ribbon.AnchorPoint = Vector2.new(1, 0)
		ribbon.Position = UDim2.new(1, 4, 0, 2)
		ribbon.Size = UDim2.fromScale(0.62, 0.15)
		ribbon.ZIndex = 3
		stroke.Color = PALETTE.Coins
		TweenService:Create(stroke, PULSE, { Color = WHITE }):Play()
	else
		strip(card, PALETTE.Disabled, NumberFormat.short(spec.price), true)
	end

	local scale = Instance.new("UIScale")
	scale.Parent = card
	local baseThickness = stroke.Thickness
	local function setSelected(on: boolean)
		scale.Scale = if on then 1.05 else 1
		stroke.Thickness = if on then 5 else baseThickness
		card.ZIndex = if on then 2 else 1
		if on and not isNext then
			stroke.Color = WHITE
		elseif not isNext then
			stroke.Color = Style.OUTLINE
		end
	end
	card.Activated:Connect(spec.onSelect)
	return { button = card, setSelected = setSelected }
end

return UpgradeCard
