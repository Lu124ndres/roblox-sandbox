--!strict
--[[
	QuickBuys

	Atajos de Robux siempre a la vista, debajo de los botones de arriba
	(TopBar): el siguiente nivel de Poder y de Monedas ("x4 Poder") con su
	precio en una placa de piedra verde (Style.robuxBadge). Sin casilla: el
	ícono suelto, más grande que los botones de la columna, flota arriba y
	abajo con rayos que giran detrás para llamar la atención (pedido del
	usuario el 2026-10-21). Tocarlos abre la compra de Roblox.
	Lo que muestran sale de RobuxOffers (lo mismo que la tienda de Robux).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local HudButtonParts = require(script.Parent.Parent.Menus.HudButtonParts)
local Purchases = require(script.Parent.Parent.Menus.Purchases)
local RobuxOffers = require(script.Parent.Parent.Menus.RobuxOffers)
local Icons = require(script.Parent.Icons)
local Kit = require(script.Parent.Kit)
local Layout = require(script.Parent.Layout)
local Style = require(script.Parent.Style)
local TopBar = require(script.Parent.TopBar)

local SIZE = 100 -- cada atajo, antes de escalar (los botones de la columna miden 88)
local GAP = 16 -- entre los dos atajos (los nombres no se tocan)
local BELOW_BAR = 6 -- aire bajo los botones de arriba
local ICONS = { Power = "crystal", Coins = "coin" }
local FLOAT = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local FLOAT_RISE = 6 -- píxeles que sube y baja
local SPIN = TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
local RAYS_COLOR = Color3.fromRGB(255, 214, 80)

local QuickBuys = {}

-- Un atajo: rayos que giran, el ícono y el nombre dorado, todo flotando.
local function shortcut(row: Frame, key: string, index: number): (TextButton, TextLabel, TextLabel)
	local button = Instance.new("TextButton")
	button.Name = `Atajo{key}`
	button.LayoutOrder = index
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Size = UDim2.fromOffset(SIZE, SIZE)
	button.Parent = row
	local float = Instance.new("Frame")
	float.Name = "Flota"
	float.BackgroundTransparency = 1
	float.Size = UDim2.fromScale(1, 1)
	float.Interactable = false
	float.Parent = button
	local rays = Icons.view(float, "sunburst")
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.42)
	rays.Size = UDim2.fromScale(1.15, 1.15)
	if rays:IsA("ImageLabel") then -- vienen blancos para teñir
		rays.ImageColor3 = RAYS_COLOR
		rays.ImageTransparency = 0.25
	end
	local icon = Icons.view(float, ICONS[key] or "coin")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.42)
	icon.Size = UDim2.fromScale(0.72, 0.72)
	icon.ZIndex = 2
	local label = Style.text(float, "Nombre", 22, nil, 2.5)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.fromScale(0.5, 1)
	label.Size = UDim2.new(1, 0, 0, 24)
	label.ZIndex = 3
	Kit.gold(label)
	local price = Style.robuxBadge(float)
	-- El vaivén, desfasado entre los dos para que no suban a la vez.
	float.Position = UDim2.fromOffset(0, FLOAT_RISE / 2)
	task.delay((index - 1) * FLOAT.Time / 2, function()
		TweenService:Create(float, FLOAT, { Position = UDim2.fromOffset(0, -FLOAT_RISE / 2) })
			:Play()
	end)
	TweenService:Create(rays, SPIN, { Rotation = 360 }):Play()
	return button, label, price
end

function QuickBuys.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local row = Instance.new("Frame")
	row.Name = "AtajosRobux"
	row.AnchorPoint = Vector2.new(1, 0)
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(SIZE * 2 + GAP, SIZE)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, GAP)
	list.Parent = row
	Layout.scaleWith(row)
	row.Parent = screen

	-- Pegado al borde derecho de los botones de arriba, justo debajo de ellos.
	local bar = TopBar.frame()
	local function place()
		local origin = screen.AbsolutePosition
		local right = bar.AbsolutePosition.X + bar.AbsoluteSize.X - origin.X
		row.Position = UDim2.fromOffset(right, TopBar.bottom() - origin.Y + BELOW_BAR)
	end
	bar:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
	bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	place()
	Layout.avoid(row) -- la columna derecha empieza debajo

	local painters: { () -> () } = {}
	for index, key in Config.Monetization.levelOrder do
		local spec = RobuxOffers.level(player, key)
		local button, label, price = shortcut(row, key, index)
		HudButtonParts.press(button, function()
			local offer = spec()
			if not offer.blocked then
				Purchases.promptProduct(offer.key)
			end
		end)
		table.insert(painters, function()
			local offer = spec()
			label.Text = TextCase.upper((string.gsub(offer.title, "^(%S+) (x%d+)$", "%2 %1")))
			price.Text = if offer.blocked
				then "MAX"
				else tostring(Purchases.price(offer.key, false, offer.robux))
		end)
	end
	local function paint()
		for _, painter in painters do
			task.spawn(painter)
		end
	end
	player.AttributeChanged:Connect(paint)
	paint()
end

return QuickBuys
