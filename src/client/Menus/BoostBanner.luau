--!strict
--[[
	BoostBanner

	Banner verde arriba de la TIENDA: "¡Impulsa el entrenamiento del
	servidor!", el salto de nivel (x2 → x4), cuánto le queda (en rosa) y el
	botón con el precio. Lo que muestra sale de RobuxOffers.boost.
]]

local Icons = require(script.Parent.Parent.Interface.Icons)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local RobuxOffers = require(script.Parent.RobuxOffers)

type Offer = RobuxOffers.Offer

local PALETTE = Style.PALETTE

local BoostBanner = {}

function BoostBanner.new(
	parent: Instance,
	order: number,
	buy: (offer: Offer) -> (),
	price: (key: string, isPass: boolean, robux: number) -> number
): () -> ()
	local banner = Instance.new("Frame")
	banner.Name = "Impulso"
	banner.LayoutOrder = order
	banner.Size = UDim2.new(1, -8, 0, 136)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = banner
	Style.border(banner, 4)
	ShopParts.sunburst(banner, PALETTE.Cards.Green)
	banner.Parent = parent

	local icon = Icons.view(banner, "bolt")
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 6, 0.5, 0)
	icon.Size = UDim2.new(0.2, 0, 0.92, 0)

	local title = Style.text(banner, "Titulo", 30, nil, 3)
	title.Text = "¡Impulsa el entrenamiento del servidor!"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.new(0.2, 8, 0, 10)
	title.Size = UDim2.new(0.56, -8, 0.3, 0)

	local jump = Style.text(banner, "Nivel", 40, nil, 3.5)
	jump.TextXAlignment = Enum.TextXAlignment.Left
	jump.Position = UDim2.new(0.2, 8, 0.36, 0)
	jump.Size = UDim2.new(0.56, -8, 0.32, 0)

	local timer = Style.text(banner, "Tiempo", 22, Color3.fromRGB(255, 235, 110), 2.5) -- amarillo: se lee sobre el verde
	timer.TextXAlignment = Enum.TextXAlignment.Left
	timer.Position = UDim2.new(0.2, 8, 0.7, 0)
	timer.Size = UDim2.new(0.56, -8, 0.22, 0)

	local button = ShopParts.price(banner, PALETTE.Buy, "robux")
	button.button.AnchorPoint = Vector2.new(1, 0.5)
	button.button.Position = UDim2.new(1, -12, 0.5, 0)
	button.button.Size = UDim2.new(0.22, 0, 0.46, 0)
	button.button.Activated:Connect(function()
		local current = RobuxOffers.boost()
		if not current.blocked then
			buy(current)
		end
	end)

	return function()
		local current = RobuxOffers.boost()
		jump.Text = current.title
		timer.Text = current.description
		if current.blocked then
			button.set(current.blocked, false)
		else
			button.set(tostring(price(current.key, false, current.robux)), true)
		end
	end
end

return BoostBanner
