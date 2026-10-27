--!strict
--[[
	OfferCard

	Tarjeta de la TIENDA como en los simuladores, de piedra (ShopStone): pizarra
	oscura con borde biselado, el ícono grande sobre un chip de piedra de su
	color con rayos, nombre dorado, descripción, botón de piedra verde con el
	precio en Robux y, si se puede regalar, el botón rosa del regalo. Se repinta con
	spec() (lo que toca vender ahora) y compra o regala lo que diga spec()
	en ese momento.
	Los botones tienen alto fijo (BUTTON_HEIGHT) para que se puedan tocar en
	cualquier pantalla; el resto se acomoda arriba de ellos.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local LuckOdds = require(ReplicatedStorage.Shared.LuckOdds)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local LuckLine = require(script.Parent.LuckLine)
local RobuxOffers = require(script.Parent.RobuxOffers)
local ShopStone = require(script.Parent.ShopStone)

type Offer = RobuxOffers.Offer

local PALETTE = Style.PALETTE
local BUTTON_HEIGHT = 56
local MARGIN = 14 -- deja ver el borde biselado de la piedra
local LUCK_HEIGHT = 72 -- línea de suerte de los pases que la dan (dos filas: % y botón)
local PASSES = Config.Monetization.passes
local DESCRIPTION_MIN_TEXT = 20
local DESCRIPTION_MAX_TEXT = 22

export type Actions = {
	buy: (offer: Offer) -> (),
	gift: (offer: Offer) -> (),
	price: (key: string, isPass: boolean, robux: number) -> number,
}

local OfferCard = {}

function OfferCard.new(
	parent: Instance,
	order: number,
	color: Color3,
	icon: string,
	spec: () -> Offer,
	actions: Actions
): () -> ()
	local card = Instance.new("Frame")
	card.Name = "Tarjeta"
	card.LayoutOrder = order
	ShopStone.card(card)
	card.Parent = parent

	-- De arriba abajo (tarjeta de 268): chip 14..92 con el ícono, nombre 94..122,
	-- descripción 122..194 (hasta 3 líneas) y botones 198..254.
	local chip = ShopStone.chip(card, color)
	chip.Position = UDim2.fromOffset(MARGIN, MARGIN)
	chip.Size = UDim2.new(1, -2 * MARGIN, 0, 92 - MARGIN)
	local view = Icons.view(chip, icon)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, -6) -- asoma un poco por arriba del chip
	view.Size = UDim2.new(0.7, 0, 1, 8)

	local title = Style.text(card, "Nombre", 30, nil, 3)
	title.Position = UDim2.fromOffset(8, 94)
	title.Size = UDim2.new(1, -16, 0, 28)
	Kit.gold(title)

	local description = Style.text(card, "Detalle", DESCRIPTION_MAX_TEXT, nil, 1.6)
	description.TextWrapped = true
	description.Position = UDim2.fromOffset(MARGIN, 122)
	description.Size = UDim2.new(1, -2 * MARGIN, 1, -122 - BUTTON_HEIGHT - MARGIN - 4)
	local limit = description:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then
		limit.MinTextSize = DESCRIPTION_MIN_TEXT
	end

	-- Pases que dan suerte (campo `luck` en Config): la línea con los números va debajo
	-- de la descripción, que se acorta para dejarle sitio.
	local luckBox = Instance.new("Frame")
	luckBox.Name = "Suerte"
	luckBox.BackgroundTransparency = 1
	luckBox.Visible = false
	luckBox.Position = UDim2.new(0, MARGIN, 1, -BUTTON_HEIGHT - MARGIN - 4 - LUCK_HEIGHT)
	luckBox.Size = UDim2.new(1, -2 * MARGIN, 0, LUCK_HEIGHT)
	luckBox.Parent = card
	local luckLine: LuckLine.Line? = nil

	local price = ShopParts.price(card, PALETTE.Buy, "robux")
	price.button.AnchorPoint = Vector2.new(0, 1)
	price.button.Position = UDim2.new(0, MARGIN, 1, -MARGIN)

	local giftButton = ShopParts.gift(card)
	giftButton.AnchorPoint = Vector2.new(1, 1)
	giftButton.Position = UDim2.new(1, -MARGIN, 1, -MARGIN)
	giftButton.Size = UDim2.fromOffset(BUTTON_HEIGHT, BUTTON_HEIGHT)

	price.button.Activated:Connect(function()
		local current = spec()
		if not current.blocked then
			actions.buy(current)
		end
	end)
	giftButton.Activated:Connect(function()
		actions.gift(spec())
	end)

	local function layout(giftable: boolean)
		giftButton.Visible = giftable
		price.button.Size = if giftable
			then UDim2.new(1, -3 * MARGIN - BUTTON_HEIGHT, 0, BUTTON_HEIGHT)
			else UDim2.new(1, -2 * MARGIN, 0, BUTTON_HEIGHT)
	end
	layout(false)

	return function()
		local current = spec()
		title.Text = current.title
		description.Text = current.description
		layout(current.gift ~= nil)
		local pass = if current.isPass then PASSES[current.key] else nil
		local hasLuck = pass ~= nil and pass.luck ~= nil
		luckBox.Visible = hasLuck
		local passName = if pass then pass.name else ""
		description.Size = UDim2.new(
			1,
			-2 * MARGIN,
			1,
			-122 - BUTTON_HEIGHT - MARGIN - 4 - (if hasLuck then LUCK_HEIGHT + 2 else 0)
		)
		if hasLuck and not luckLine then
			local key = current.key
			luckLine = LuckLine.mount(luckBox, passName, function()
				return LuckOdds.withPass(Players.LocalPlayer, key)
			end)
		elseif luckLine then
			luckLine.refresh()
		end
		if current.blocked then
			price.set(current.blocked, false)
		else
			price.set(tostring(actions.price(current.key, current.isPass, current.robux)), true)
		end
	end
end

return OfferCard
