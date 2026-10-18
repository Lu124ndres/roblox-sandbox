--!strict
--[[
	SpinParts

	Piezas de la ventana de la ruleta (SpinWindow), con el kit de piedra
	volcánica (Interface/Kit):
		paint      tiñe la piedra de un botón cuando cambia de color
		buyButton  botón de piedra gris con texto dorado para comprar giros con
		           Robux (Spin1 / Spin5, con la etiqueta verde del precio)
		glow       resplandor de lava detrás de la rueda
		slot       hueco tallado con texto dorado (el próximo giro)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local Purchases = require(script.Parent.Purchases)

local PRODUCTS = Config.Monetization.spinProducts
local LAVA_GLOW = Color3.fromRGB(255, 110, 30)

local SpinParts = {}

-- Tiñe la piedra del botón (también la del de lava: blanco = encendido).
function SpinParts.paint(button: TextButton, color: Color3)
	if button.BackgroundColor3 == color then
		return
	end
	button.BackgroundColor3 = color
	local skin = button:FindFirstChild("Piedra")
	if skin and skin:IsA("ImageLabel") then
		Kit.tint(skin, color)
	end
end

function SpinParts.buyButton(parent: Instance, key: string, x: number): TextButton
	local def = PRODUCTS[key]
	local spins = if def then def.spins else 1
	-- Piedra gris con canto dorado (como MEJORAS): Style.button le pone el texto dorado.
	local button = Style.button(parent, `Comprar{spins}`, Kit.STONE, "")
	button.AnchorPoint = Vector2.new(x, 0)
	button.Position = UDim2.fromScale(x, 0)
	button.Size = UDim2.fromScale(0.3, 1)
	local title = button:FindFirstChild("Texto") :: TextLabel
	title.Text = `Comprar {spins}`
	title.Size = UDim2.fromScale(0.94, 0.5)
	title.Position = UDim2.fromScale(0.03, 0.05)
	local price = Style.robuxBadge(button, if def then def.robux else nil)
	local badge = price.Parent :: Frame
	badge.AnchorPoint = Vector2.new(0.5, 0)
	badge.Position = UDim2.fromScale(0.5, 0.58)
	badge.Size = UDim2.fromScale(0.6, 0.36)
	task.spawn(function()
		price.Text = tostring(Purchases.price(key, false, if def then def.robux else 0))
	end)
	button.Activated:Connect(function()
		Purchases.promptProduct(key)
	end)
	return button
end

-- Resplandor de lava detrás de la rueda (el brillo de la hoja de íconos, teñido).
function SpinParts.glow(wheelRoot: GuiObject)
	local glow = Instance.new("ImageLabel")
	glow.Name = "Resplandor"
	glow.BackgroundTransparency = 1
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromScale(1.45, 1.45)
	glow.ImageColor3 = LAVA_GLOW
	glow.ImageTransparency = 0.25
	glow.ZIndex = 0
	if Icons.paint(glow, "glow") then
		glow.Parent = wheelRoot
	end
end

-- Hueco tallado (piedra honda) con un texto dorado adentro; devuelve el texto.
function SpinParts.slot(parent: Instance, name: string): TextLabel
	local slot = Instance.new("Frame")
	slot.Name = name
	Kit.skin(slot, "hondo").SliceScale = 0.3 -- canto fino: más alto para el texto
	local label = Style.text(slot, "Texto", 26, nil, 2)
	label.Position = UDim2.fromOffset(10, 2)
	label.Size = UDim2.new(1, -20, 1, -4)
	Kit.gold(label)
	slot.Parent = parent
	return label
end

return SpinParts
