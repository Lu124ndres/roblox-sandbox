--!strict
--[[
	ShopStone

	Piezas de piedra de la TIENDA de Robux y sus ofertas (Interface/Kit), como
	en las referencias: tarjeta de pizarra oscura con biselado, "chip" de
	piedra de color detrás del ícono y placas de piedra para descuentos.
		card(frame)            pone de fondo la pizarra con borde biselado
		chip(parent, color)    cuadro de piedra teñida de `color` con los rayos
		                       claros encima (suaves), para poner un ícono o un
		                       personaje delante
		seal(parent, text)     placa roja de piedra con un texto ("-79%")
		robuxIcon(parent)      ícono de Robux cuadrado, para botones de compra
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Kit = require(script.Parent.Parent.Interface.Kit)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)

local RAYS_TRANSPARENCY = 0.7 -- sobre la piedra los rayos van más suaves que antes
local SEAL_COLOR = Style.PALETTE.Cards.Red

local ShopStone = {}

function ShopStone.card(frame: GuiObject): ImageLabel
	return Kit.skin(frame, "panel")
end

function ShopStone.chip(parent: Instance, color: Color3): Frame
	local chip = Instance.new("Frame")
	chip.Name = "Chip"
	ShopParts.sunburst(chip, color)
	local skin = Kit.skin(chip, "boton", color)
	-- Los rayos van dentro de la piedra: así quedan encima de ella y debajo
	-- de todo lo demás de la tarjeta.
	local rays = chip:FindFirstChild("Rayos")
	if rays and rays:IsA("ImageLabel") then
		rays.ImageTransparency = RAYS_TRANSPARENCY
		rays.Parent = skin
	end
	chip.Parent = parent
	return chip
end

function ShopStone.seal(parent: Instance, text: string): (Frame, TextLabel)
	local seal = Instance.new("Frame")
	seal.Name = "Descuento"
	seal.ZIndex = 4
	Kit.skin(seal, "boton", SEAL_COLOR)
	local label = Style.text(seal, "Texto", 34, nil, 3)
	label.Text = text
	label.Position = UDim2.fromScale(0.08, 0.2)
	label.Size = UDim2.fromScale(0.84, 0.6)
	label.ZIndex = 5
	seal.Parent = parent
	return seal, label
end

function ShopStone.robuxIcon(parent: Instance): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = "Robux"
	icon.BackgroundTransparency = 1
	icon.Image = Assets.UI.RobuxIcon
	icon.ScaleType = Enum.ScaleType.Fit
	local square = Instance.new("UIAspectRatioConstraint")
	square.DominantAxis = Enum.DominantAxis.Height -- cuadrado del alto que le den
	square.Parent = icon
	icon.Parent = parent
	return icon
end

return table.freeze(ShopStone)
