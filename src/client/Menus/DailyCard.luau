--!strict
--[[
	DailyCard

	Tarjeta de un día del premio diario (Menus/DailyWindow), como las de los
	simuladores pero volcánica: casilla de piedra con lava teñida suave del
	color del día, las monedas arriba, el ícono grande sobre rayos que giran,
	la etiqueta de los giros y abajo el estado:
		claimed  ¡RECLAMADO! en placa verde de piedra y la tarjeta atenuada
		today    marco de lava y el botón ¡RECLAMAR! de lava, que late
		next     "Mañana" dorado (hoy ya se cobró: es el próximo)
		future   "Día N" dorado
	La del último día (`big`) es alta, con "¡GRAN PREMIO!" y el cofre flotando
	sobre un pedestal volcánico con cristales. Solo presenta: qué da cada día
	lo calcula DailyWindow.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Assets)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)

export type State = "claimed" | "today" | "next" | "future"
export type Info = {
	day: number,
	coins: string, -- monedas ya formateadas ("1.2K")
	spins: number,
	state: State,
	big: boolean,
	onClaim: () -> (),
}

local CARDS = Style.PALETTE.Cards
local WHITE = Color3.new(1, 1, 1)
local SOFT = Color3.fromRGB(190, 190, 196) -- se mezcla con el tinte: piedra teñida suave
local DIM = Color3.fromRGB(50, 50, 56) -- las cobradas se oscurecen hacia aquí
local SPIN = TweenInfo.new(40, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
local BEAT = TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local FLOAT = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

-- Ícono y color de cada día (solo presentación: todos dan monedas y giros).
local LOOKS: { { icon: string, tint: Color3 } } = {
	{ icon = "coin", tint = CARDS.Green },
	{ icon = "coin", tint = CARDS.Yellow },
	{ icon = "gift", tint = CARDS.Blue },
	{ icon = "giftPink", tint = CARDS.Pink },
	{ icon = "gift", tint = CARDS.Purple },
	{ icon = "giftPink", tint = CARDS.Cyan },
	{ icon = "chest", tint = CARDS.Orange },
}

local DailyCard = {}

-- Rayos claros detrás del ícono, centrados en `y` y cuadrados de `size` del lado corto.
local function rays(card: Frame, tint: Color3, y: number, size: number, big: boolean)
	if not Icons.has("sunburst") then
		return
	end
	local image = Instance.new("ImageLabel")
	image.Name = "Rayos"
	image.BackgroundTransparency = 1
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, y)
	image.Size = UDim2.fromScale(size, size)
	image.ImageColor3 = tint:Lerp(WHITE, 0.55)
	image.ImageTransparency = 0.5
	image.ZIndex = 1
	Icons.paint(image, "sunburst")
	local square = Instance.new("UIAspectRatioConstraint")
	square.DominantAxis = if big then Enum.DominantAxis.Width else Enum.DominantAxis.Height
	square.Parent = image
	image.Parent = card
	TweenService:Create(image, SPIN, { Rotation = 360 }):Play()
end

local function place(object: GuiObject, y: number, width: number, height: number)
	object.AnchorPoint = Vector2.new(0.5, 0)
	object.Position = UDim2.fromScale(0.5, y)
	object.Size = UDim2.fromScale(width, height)
end

-- Abajo: el botón de hoy, la placa de cobrado o el día dorado.
local function status(card: Frame, info: Info)
	local y = if info.big then 0.82 else 0.75
	local height = if info.big then 0.13 else 0.21
	if info.state == "today" then
		local button = Style.lavaButton(card, "Reclamar", "¡RECLAMAR!")
		place(button, y, 0.88, height)
		button.ZIndex = 4
		local beat = Instance.new("UIScale")
		beat.Parent = button
		TweenService:Create(beat, BEAT, { Scale = 1.07 }):Play()
		button.Activated:Connect(info.onClaim)
	elseif info.state == "claimed" then
		local plate = Instance.new("Frame")
		plate.Name = "Reclamado"
		place(plate, y, 0.92, height)
		plate.ZIndex = 4
		Kit.skin(plate, "boton", CARDS.Green).SliceScale = 0.3
		local label = Style.text(plate, "Texto", 26, nil, 2.5)
		label.Text = "¡RECLAMADO!"
		label.Position = UDim2.fromScale(0.06, 0.12)
		label.Size = UDim2.fromScale(0.88, 0.76)
		plate.Parent = card
	else
		local label = Style.text(card, "Dia", if info.big then 54 else 34, nil, 3)
		label.Text = if info.state == "next" then "Mañana" else `Día {info.day}`
		Kit.gold(label)
		place(label, y, 0.9, height)
		label.ZIndex = 4
	end
end

-- Cofre del gran premio sobre el pedestal volcánico, con cristales y flotando.
local function pedestal(card: Frame, icon: GuiObject)
	local base = Instance.new("ImageLabel")
	base.Name = "Pedestal"
	base.BackgroundTransparency = 1
	base.Image = Assets.UI.PiedraPedestal
	base.ScaleType = Enum.ScaleType.Fit
	base.AnchorPoint = Vector2.new(0.5, 0.5)
	base.Position = UDim2.fromScale(0.5, 0.63)
	base.Size = UDim2.fromScale(0.96, 0.26)
	base.ZIndex = 1
	base.Parent = card
	Kit.crystals(base, 50)
	TweenService:Create(icon, FLOAT, { Position = icon.Position - UDim2.fromScale(0, 0.025) })
		:Play()
end

function DailyCard.build(parent: Instance, info: Info): Frame
	local look = LOOKS[info.day] or LOOKS[#LOOKS]
	local card = Instance.new("Frame")
	card.Name = `Dia{info.day}`
	card.LayoutOrder = info.day
	card.Size = UDim2.fromScale(1, 1)
	local today = info.state == "today"
	local claimed = info.state == "claimed"
	local skin = if today
		then Kit.skin(card, "lava")
		else Kit.skin(card, "casilla", look.tint:Lerp(SOFT, 0.4))
	if claimed then
		skin.ImageColor3 = skin.ImageColor3:Lerp(DIM, 0.45)
	end

	local top = if info.big then 0.13 else 0.05
	if info.big then
		local title = Style.text(card, "Titulo", 34, nil, 3)
		title.Text = "¡GRAN PREMIO!"
		Kit.gold(title)
		place(title, 0.035, 0.9, 0.085)
		title.ZIndex = 3
	end
	local coins =
		Style.text(card, "Monedas", if info.big then 32 else 28, UIConfig.Colors.Coins, 2.5)
	coins.Text = `{info.coins} monedas`
	place(coins, top, 0.9, if info.big then 0.075 else 0.16)
	coins.ZIndex = 3

	local center = if info.big then 0.44 else 0.47
	if not claimed then
		rays(card, look.tint, center, if info.big then 1 else 0.95, info.big)
	end
	local icon = Icons.view(card, look.icon)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, center)
	icon.Size = if info.big then UDim2.fromScale(0.86, 0.3) else UDim2.fromScale(0.7, 0.44)
	icon.ZIndex = 2
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = icon
	if claimed and icon:IsA("ImageLabel") then
		icon.ImageTransparency = 0.35
	end
	if info.big then
		pedestal(card, icon)
	end

	if info.spins > 0 then
		local tag = ShopParts.tag(
			card,
			`+{info.spins} giro{if info.spins == 1 then "" else "s"}`,
			CARDS.Purple
		)
		local plate = tag.Parent :: GuiObject
		plate.AnchorPoint = Vector2.new(1, 1)
		plate.Position = if info.big then UDim2.new(1, 6, 0.8, -4) else UDim2.new(1, 4, 0.74, -2)
		plate.Size = UDim2.fromOffset(if info.big then 104 else 86, if info.big then 32 else 26)
	end
	status(card, info)
	card.Parent = parent
	return card
end

return DailyCard
