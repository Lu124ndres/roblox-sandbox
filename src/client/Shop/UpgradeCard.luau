--!strict
--[[
	UpgradeCard

	Tarjeta de un nivel en la cuadrícula de MEJORAS: el ícono del equipo
	(GearIcons) sobre piedra teñida del color de su rareza, "Nv N" y abajo el
	estado en una placa de piedra:
		equipada      placa verde "EQUIPADA"
		comprada      placa verde oscura "TIENES"
		la siguiente  placa gris con el precio dorado y la cinta "¡SIGUIENTE!"
		              (el canto late en dorado)
		bloqueada     piedra e ícono oscurecidos y el precio en gris
	Tocarla la selecciona: el panel de la izquierda (UpgradeDetail) la muestra.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local GearIcons = require(script.Parent.Parent.Interface.GearIcons)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
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
	bar.Position = UDim2.new(0.5, 0, 1, -7)
	bar.Size = UDim2.new(1, -14, 0.22, 0)
	bar.BackgroundColor3 = color
	bar.BorderSizePixel = 0
	bar.ZIndex = 2
	Kit.skin(bar, "boton", color).SliceScale = 0.24 -- placa chica: canto fino
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
	label.Position = UDim2.fromScale(left, 0.14)
	label.Size = UDim2.fromScale(0.94 - left, 0.72)
	if coin and color == Kit.STONE then
		Kit.gold(label) -- el precio a pagar, dorado sobre piedra gris (como MEJORAS)
	end
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
	-- El borde queda escondido bajo la piedra y se ve al elegirla o si es la siguiente.
	Style.border(card, 3)
	-- Casilla de piedra volcánica con lava (la referencia del usuario): oscura, con un toque
	-- del color del nivel; las bloqueadas más apagadas.
	local skin = ShopParts.stone(card, "casilla", card.BackgroundColor3:Lerp(WHITE, 0.55))
	Kit.press(card, skin)
	local stroke = card:FindFirstChildOfClass("UIStroke") :: UIStroke
	card.Parent = parent

	local icon = GearIcons.view(card, spec.category, level)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.fromScale(0.5, 0.07)
	icon.Size = UDim2.fromScale(0.82, 0.66)
	if not isOwned and not isNext then
		icon.ImageColor3 = Color3.fromRGB(70, 70, 80)
	end

	local chip = Style.text(card, "Nivel", 20, WHITE, 2)
	chip.Text = `Nv {level}`
	chip.TextXAlignment = Enum.TextXAlignment.Left
	chip.Position = UDim2.fromOffset(10, 6)
	chip.Size = UDim2.fromScale(0.6, 0.16)
	chip.ZIndex = 2

	if level == spec.owned then
		strip(card, PALETTE.Buy, "EQUIPADA", false)
	elseif isOwned then
		strip(card, Kit.STONE, "TIENES", false) -- placa de piedra gris, como en la referencia
	elseif isNext then
		strip(card, Kit.STONE, NumberFormat.short(spec.price), true)
		local ribbon = Style.text(card, "Siguiente", 18, PALETTE.Coins, 2)
		ribbon.Text = "¡SIGUIENTE!"
		Kit.gold(ribbon)
		ribbon.Rotation = 12
		ribbon.AnchorPoint = Vector2.new(1, 0)
		-- Girada, la cinta se asoma por la derecha: hacia adentro, que la grilla recorta
		-- lo que sale de la última columna
		ribbon.Position = UDim2.new(1, -8, 0, 6)
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
