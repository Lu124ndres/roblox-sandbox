--!strict
--[[
	OutfitCard

	PERSONAJES de la TIENDA (como los simuladores): una tarjeta ancha por cada
	traje de pase, dos por fila (una si la ventana es angosta):
		fondo de color con rayos que giran y marco negro
		el personaje en 3D a la izquierda, saliendo un poco por arriba (copia de
		su vitrina del mapa, Workspace.Vitrinas)
		nombre grande y sus ventajas en dos líneas (salen del pase en Config)
		etiqueta inclinada arriba a la derecha ("x2 Kills")
		botón verde: Robux y precio; si ya lo tiene, Equipar o Desequipar
		(remote ElegirTraje) y el regalo rosa para comprárselo a otro
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Trajes = require(ReplicatedStorage.Shared.Trajes)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local OfferCard = require(script.Parent.OfferCard)
local OutfitView = require(script.Parent.OutfitView)
local RobuxOffers = require(script.Parent.RobuxOffers)

local PASSES = Config.Monetization.passes
local CARDS = Style.PALETTE.Cards
local CARD_HEIGHT = 230
local BUTTON_HEIGHT = 56
local MARGIN = 12
local ONE_COLUMN_BELOW = 760 -- ancho del contenido (sin escalar) para pasar a una por fila
local COLORS: { [string]: Color3 } = { DiosDelVolcan = CARDS.Orange, ReyDelMar = CARDS.Blue }
local TAG_COLORS: { [string]: Color3 } = {
	DiosDelVolcan = Color3.fromRGB(200, 40, 20),
	ReyDelMar = Color3.fromRGB(20, 90, 200),
}

local OutfitCard = {}

local function text(
	parent: Instance,
	name: string,
	max: number,
	top: number,
	height: number
): TextLabel
	local label = Style.text(parent, name, max, nil, if max > 30 then 3.5 else 2.2)
	label.Position = UDim2.new(0.36, 0, 0, top)
	label.Size = UDim2.new(0.62, 0, 0, height)
	label.ZIndex = 3
	return label
end

local function card(
	parent: Instance,
	order: number,
	passKey: string,
	actions: OfferCard.Actions,
	choose: RemoteEvent
): () -> ()
	local player = Players.LocalPlayer
	local pass = PASSES[passKey]
	local spec = RobuxOffers.pass(player, passKey)
	local frame = Instance.new("Frame")
	frame.Name = passKey
	frame.LayoutOrder = order
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = frame
	Style.border(frame, 4.5)
	ShopParts.sunburst(frame, COLORS[passKey] or CARDS.Purple, 1.6)
	frame.ClipsDescendants = false
	frame.Parent = parent
	OutfitView.portrait(frame, passKey)

	text(frame, "Nombre", 56, 10, 58).Text = pass.name
	for index, line in OutfitView.perks(pass) do
		text(frame, `Ventaja{index}`, 34, 70 + (index - 1) * 38, 36).Text = line
	end
	if pass.kills and pass.kills > 1 then
		local tag = ShopParts.tag(frame, `x{pass.kills} Kills`, TAG_COLORS[passKey] or CARDS.Red)
		local holder = tag.Parent :: Frame
		holder.AnchorPoint = Vector2.new(1, 0.5)
		holder.Position = UDim2.new(1, 8, 0, 4)
		holder.Size = UDim2.fromOffset(150, 40)
		holder.Rotation = 6
	end

	local buy = Style.button(frame, "Comprar", Style.PALETTE.Buy, "")
	buy.AnchorPoint = Vector2.new(0, 1)
	buy.Position = UDim2.new(0.2, 0, 1, -MARGIN)
	buy.Size = UDim2.new(0.8, -3 * MARGIN - BUTTON_HEIGHT, 0, BUTTON_HEIGHT)
	buy.ZIndex = 3
	local label = buy:FindFirstChild("Texto") :: TextLabel
	label.ZIndex = 4
	local robux = Instance.new("ImageLabel")
	robux.BackgroundTransparency = 1
	robux.Image = Assets.UI.RobuxIcon
	robux.ScaleType = Enum.ScaleType.Fit
	robux.AnchorPoint = Vector2.new(0, 0.5)
	robux.Position = UDim2.new(0.22, 0, 0.5, 0)
	robux.Size = UDim2.fromScale(0.16, 0.7)
	robux.ZIndex = 4
	robux.Parent = buy
	local gift = ShopParts.gift(frame)
	gift.AnchorPoint = Vector2.new(1, 1)
	gift.Position = UDim2.new(1, -MARGIN, 1, -MARGIN)
	gift.Size = UDim2.fromOffset(BUTTON_HEIGHT, BUTTON_HEIGHT)
	gift.ZIndex = 3

	buy.Activated:Connect(function()
		if Perks.hasPass(player, passKey) then
			choose:FireServer(passKey)
		else
			actions.buy(spec())
		end
	end)
	gift.Activated:Connect(function()
		actions.gift(spec())
	end)

	return function()
		local owned = Perks.hasPass(player, passKey)
		robux.Visible = not owned
		if owned then
			local character = player.Character
			local costume = character and character:FindFirstChild(Trajes.FOLDER)
			local wearing = costume ~= nil and costume:GetAttribute("Outfit") == pass.outfit
			label.Text = if wearing then "Desequipar" else "Equipar"
			label.Position, label.Size = UDim2.fromOffset(5, 4), UDim2.new(1, -10, 1, -8)
		else
			local current = spec()
			label.Text = tostring(actions.price(current.key, true, current.robux))
			label.Position, label.Size = UDim2.new(0.4, 0, 0, 4), UDim2.new(0.5, 0, 1, -8)
		end
		gift.Visible = spec().gift ~= nil
	end
end

-- La sección entera: una grilla con una tarjeta por traje de pase. `scale` es
-- la escala de la ventana (para medir el ancho sin escalar).
function OutfitCard.mount(
	parent: Instance,
	order: number,
	actions: OfferCard.Actions,
	scale: () -> number
): () -> ()
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local choose = remotes:WaitForChild(Protocol.Remotes.ChooseOutfit) :: RemoteEvent
	local holder = Instance.new("Frame")
	holder.Name = "Personajes"
	holder.LayoutOrder = order
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, -12, 0, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Parent = parent
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 30) -- el personaje y la etiqueta salen por arriba
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = holder
	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(16, 34)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = holder
	local painters: { () -> () } = {}
	for index, key in Config.Monetization.passOrder do
		if PASSES[key].outfit then
			table.insert(painters, card(holder, index, key, actions, choose))
		end
	end
	local function columns()
		local width = holder.AbsoluteSize.X / math.max(scale(), 0.01)
		grid.CellSize = if width < ONE_COLUMN_BELOW
			then UDim2.new(1, 0, 0, CARD_HEIGHT)
			else UDim2.new(0.5, -8, 0, CARD_HEIGHT)
	end
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(columns)
	columns()
	return function()
		for _, paint in painters do
			paint()
		end
	end
end

return table.freeze(OutfitCard)
