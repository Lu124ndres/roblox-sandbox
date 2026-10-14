--!strict
--[[
	OfferCard

	Tarjeta de la TIENDA como en los simuladores: fondo de color con rayos,
	ícono grande arriba, nombre, descripción, botón verde con el precio en
	Robux y, si se puede regalar, el botón rosa del regalo. Se repinta con
	spec() (lo que toca vender ahora) y compra o regala lo que diga spec()
	en ese momento.
	Los botones tienen alto fijo (BUTTON_HEIGHT) para que se puedan tocar en
	cualquier pantalla; el resto se acomoda arriba de ellos.
]]

local Icons = require(script.Parent.Parent.Interface.Icons)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local RobuxOffers = require(script.Parent.RobuxOffers)

type Offer = RobuxOffers.Offer

local PALETTE = Style.PALETTE
local BUTTON_HEIGHT = 56
local MARGIN = 10
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
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = card
	Style.border(card, 4)
	ShopParts.sunburst(card, color)
	card.Parent = parent

	-- De arriba abajo (tarjeta de 260): ícono 8..92, nombre 92..122,
	-- descripción 122..190 (hasta 3 líneas) y botones 194..250.
	local view = Icons.view(card, icon)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.new(0.5, 0, 0, 8)
	view.Size = UDim2.new(0.62, 0, 0, 84)

	local title = Style.text(card, "Nombre", 30, nil, 3)
	title.Position = UDim2.fromOffset(8, 92)
	title.Size = UDim2.new(1, -16, 0, 30)

	local description = Style.text(card, "Detalle", DESCRIPTION_MAX_TEXT, nil, 1.6)
	description.TextWrapped = true
	description.Position = UDim2.fromOffset(MARGIN, 122)
	description.Size = UDim2.new(1, -2 * MARGIN, 1, -122 - BUTTON_HEIGHT - MARGIN - 4)
	local limit = description:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then
		limit.MinTextSize = DESCRIPTION_MIN_TEXT
	end

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
		if current.blocked then
			price.set(current.blocked, false)
		else
			price.set(tostring(actions.price(current.key, current.isPass, current.robux)), true)
		end
	end
end

return OfferCard
