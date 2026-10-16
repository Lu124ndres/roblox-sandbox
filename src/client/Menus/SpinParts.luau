--!strict
--[[
	SpinParts

	Botones de la ventana de la ruleta (SpinWindow): el de comprar giros con
	Robux (Spin1 / Spin5, con la etiqueta verde del precio) y el repintado de
	un botón cuando cambia de color.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Style = require(script.Parent.Parent.Interface.Style)
local Purchases = require(script.Parent.Purchases)

local PRODUCTS = Config.Monetization.spinProducts

local SpinParts = {}

function SpinParts.paint(button: TextButton, color: Color3)
	if button.BackgroundColor3 == color then
		return
	end
	button.BackgroundColor3 = color
	local old = button:FindFirstChildOfClass("UIGradient")
	if old then
		old:Destroy()
	end
	Style.gradient(button, color)
end

function SpinParts.buyButton(parent: Instance, key: string, color: Color3, x: number): TextButton
	local def = PRODUCTS[key]
	local spins = if def then def.spins else 1
	local button = Style.button(parent, `Comprar{spins}`, color, "")
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

return SpinParts
