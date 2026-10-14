--!strict
--[[
	OfferCard

	Tarjeta de la TIENDA como en los simuladores: fondo de color con rayos,
	ícono grande arriba, nombre, descripción, botón verde con el precio en
	Robux y, si se puede regalar, el botón rosa del regalo. Se repinta con
	spec() (lo que toca vender ahora) y compra o regala lo que diga spec()
	en ese momento.
]]

local Icons = require(script.Parent.Parent.Interface.Icons)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local RobuxOffers = require(script.Parent.RobuxOffers)

type Offer = RobuxOffers.Offer

local PALETTE = Style.PALETTE

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

	local view = Icons.view(card, icon)
	view.AnchorPoint = Vector2.new(0.5, 0)
	view.Position = UDim2.fromScale(0.5, 0.03)
	view.Size = UDim2.fromScale(0.62, 0.45)

	local title = Style.text(card, "Nombre", 30, nil, 3)
	title.Position = UDim2.new(0, 8, 0.49, 0)
	title.Size = UDim2.new(1, -16, 0.13, 0)

	local description = Style.text(card, "Detalle", 17, nil, 1.6)
	description.TextWrapped = true
	description.Position = UDim2.new(0, 10, 0.62, 0)
	description.Size = UDim2.new(1, -20, 0.16, 0)

	local price = ShopParts.price(card, PALETTE.Buy, "robux")
	price.button.AnchorPoint = Vector2.new(0, 1)
	price.button.Position = UDim2.new(0, 10, 1, -10)

	local giftButton = ShopParts.gift(card)
	giftButton.AnchorPoint = Vector2.new(1, 1)
	giftButton.Position = UDim2.new(1, -10, 1, -10)
	giftButton.Size = UDim2.new(0.2, 0, 0.17, 0)
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = giftButton

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
			then UDim2.new(0.74, -22, 0.17, 0)
			else UDim2.new(1, -20, 0.17, 0)
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
