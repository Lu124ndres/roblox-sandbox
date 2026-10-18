--!strict
--[[
	GiftPicker

	Ventanita de piedra encima de la TIENDA para regalar (título dorado con
	el regalo rosa al lado): la lista de los demás jugadores del servidor,
	cada uno en un hueco de piedra con su foto, su nombre y lo que costaría regalarle
	esa tarjeta a él (su propio siguiente nivel, o "Ya lo tiene"). Al tocar
	uno, avisa al servidor para quién es (SetGift) y abre la compra; lo
	entrega el servidor (Gifts, Receipts).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Device = require(script.Parent.Parent.Interface.Device)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local Purchases = require(script.Parent.Purchases)
local RobuxOffers = require(script.Parent.RobuxOffers)
local Window = require(script.Parent.Window)

type Offer = RobuxOffers.Offer

local PALETTE = Style.PALETTE
local ROW_HEIGHT = 76
local CLOSE_SIZE = 56
local SCREEN_SHARE = Vector2.new(0.86, 0.8) -- parte de la pantalla que ocupa, ya escalado

export type Picker = { open: (offer: Offer) -> () }

local GiftPicker = {}

function GiftPicker.mount(screen: ScreenGui): Picker
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local setGift = remotes:WaitForChild(Protocol.Remotes.SetGift) :: RemoteEvent

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Regalar"
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.45
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Visible = false
	backdrop.ZIndex = 30
	backdrop.Parent = screen

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.55)
	panel.Size = UDim2.fromScale(SCREEN_SHARE.X, SCREEN_SHARE.Y)
	panel.Active = true -- un toque en el panel no llega al fondo (que lo cierra)
	panel.Parent = backdrop
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(480, 440)
	limit.Parent = panel
	local scale = Instance.new("UIScale")
	scale.Parent = panel
	Kit.skin(panel, "panel")

	local giftIcon = Icons.view(panel, "giftPink")
	giftIcon.Position = UDim2.fromOffset(4, -40)
	giftIcon.Size = UDim2.fromOffset(70, 70)
	giftIcon.ZIndex = 3
	local title = Style.text(panel, "Titulo", 56, nil, 4.5)
	title.Position = UDim2.fromOffset(78, -36)
	title.Size = UDim2.new(1, -144, 0, 66)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Rotation = -2
	Kit.gold(title)
	local subtitle = Style.text(panel, "Que", 30, nil, 2.5)
	subtitle.Position = UDim2.fromOffset(16, 30)
	subtitle.Size = UDim2.new(1, -32, 0, 28)
	local close = Style.button(panel, "Cerrar", PALETTE.Close, "X")
	close.AnchorPoint = Vector2.new(0.5, 0.5)
	close.Position = UDim2.new(1, -8, 0, 6)
	close.Size = UDim2.fromOffset(CLOSE_SIZE, CLOSE_SIZE)
	close.ZIndex = 3

	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(14, 66)
	list.Size = UDim2.new(1, -28, 1, -78)
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local function hide()
		backdrop.Visible = false
	end
	-- Como Window: el tamaño se divide entre la escala, así solo se achica una vez.
	local function resize()
		local fit = Window.fit()
		scale.Scale = fit
		panel.Size = UDim2.fromScale(SCREEN_SHARE.X / fit, SCREEN_SHARE.Y / fit)
	end
	Device.onResize(function()
		if backdrop.Visible then
			resize()
		end
	end)
	close.Activated:Connect(hide)
	backdrop.Activated:Connect(hide)

	local function row(target: Player, offer: Offer, order: number)
		assert(offer.gift, "GiftPicker: la tarjeta no se puede regalar")
		local gift = offer.gift(target)
		local box = Instance.new("Frame")
		box.LayoutOrder = order
		box.Size = UDim2.new(1, -8, 0, ROW_HEIGHT)
		Kit.skin(box, "hondo")
		box.Parent = list
		local face = Instance.new("ImageLabel")
		face.BackgroundTransparency = 1
		face.Position = UDim2.fromOffset(8, 6)
		face.Size = UDim2.fromOffset(ROW_HEIGHT - 12, ROW_HEIGHT - 12)
		face.Parent = box
		task.spawn(function()
			local ok, image = pcall(function()
				return Players:GetUserThumbnailAsync(
					target.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size100x100
				)
			end)
			if ok then
				face.Image = image
			end
		end)
		local name = Style.text(box, "Nombre", 24, nil, 2)
		name.Text = target.DisplayName
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Position = UDim2.fromOffset(ROW_HEIGHT + 4, 10)
		name.Size = UDim2.new(0.55, -ROW_HEIGHT, 1, -20)
		local price = ShopParts.price(box, PALETTE.Buy, "robux")
		price.button.AnchorPoint = Vector2.new(1, 0.5)
		price.button.Position = UDim2.new(1, -10, 0.5, 0)
		price.button.Size = UDim2.new(0.38, 0, 1, -14)
		if gift.blocked then
			price.set(gift.blocked, false)
		else
			price.set(tostring(Purchases.price(gift.key, false, gift.robux)), true)
		end
		price.button.Activated:Connect(function()
			if gift.blocked then
				return
			end
			setGift:FireServer(gift.key, target.UserId)
			if Purchases.promptProduct(gift.key) then
				hide()
			end
		end)
	end

	local function open(offer: Offer)
		for _, child in list:GetChildren() do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		title.Text = "REGALAR"
		subtitle.Text = `{offer.title} para...`
		local order = 0
		for _, other in Players:GetPlayers() do
			if other ~= Players.LocalPlayer then
				order += 1
				row(other, offer, order)
			end
		end
		if order == 0 then
			local empty = Style.text(list, "Nadie", 32, nil, 2.5)
			empty.Text = "No hay más jugadores en el servidor. ¡Invita a un amigo!"
			empty.TextWrapped = true
			empty.Size = UDim2.new(1, -8, 0, 80)
		end
		resize()
		backdrop.Visible = true
	end

	return { open = open }
end

return GiftPicker
