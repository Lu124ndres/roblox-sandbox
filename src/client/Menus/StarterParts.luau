--!strict
--[[
	StarterParts

	Piezas de la ventana del pack de inicio (StarterOffer), de piedra
	(ShopStone): la cabecera con el regalo sobre un chip rosa, el título
	dorado y la placa roja de descuento que se mece, y las tarjetas de
	pizarra de lo que trae (chip de su color con el ícono de MEJORAS si es
	equipo, nombre dorado).
]]

local TweenService = game:GetService("TweenService")

local GearIcons = require(script.Parent.Parent.Interface.GearIcons)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local ShopStone = require(script.Parent.ShopStone)

local CARDS = Style.PALETTE.Cards
local PULSE = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

export type Item = {
	color: Color3,
	title: string,
	detail: string,
	gear: string?,
	level: number?,
	icon: string?,
}

local StarterParts = {}

function StarterParts.header(content: Frame, discount: number)
	local art = ShopStone.chip(content, CARDS.Pink)
	art.Name = "Regalo"
	art.Position = UDim2.fromOffset(4, 0)
	art.Size = UDim2.fromOffset(96, 96)
	local gift = Icons.view(art, "giftPink")
	gift.Position = UDim2.fromOffset(2, -4) -- asoma un poco por arriba
	gift.Size = UDim2.fromOffset(92, 92)
	local title = Style.text(content, "Titulo", 44, nil, 3.5)
	title.Text = "¡PACK DE INICIO!"
	Kit.gold(title)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(112, 4)
	title.Size = UDim2.new(0.62, -112, 0, 52)
	local sub = Style.text(content, "Subtitulo", 22, nil, 2)
	sub.Text = "Todo para empezar fuerte"
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Position = UDim2.fromOffset(114, 58)
	sub.Size = UDim2.new(0.6, -114, 0, 28)
	local once = ShopParts.tag(content, "¡SOLO UNA VEZ!", CARDS.Red)
	local tag = once.Parent :: Frame
	tag.AnchorPoint = Vector2.new(1, 0)
	tag.Position = UDim2.new(1, -110, 0, 30)
	tag.Size = UDim2.fromOffset(170, 34)
	if discount > 0 then
		local seal = ShopStone.seal(content, `-{discount}%`)
		seal.AnchorPoint = Vector2.new(1, 0)
		seal.Position = UDim2.new(1, -4, 0, 4)
		seal.Size = UDim2.fromOffset(100, 80)
		seal.Rotation = 12
		TweenService:Create(seal, PULSE, { Rotation = -6 }):Play()
	end
end

function StarterParts.card(content: Frame, index: number, item: Item)
	local frame = Instance.new("Frame")
	frame.Name = `Item{index}`
	frame.Position = UDim2.new((index - 1) * 0.2 + 0.005, 0, 0, 110)
	frame.Size = UDim2.new(0.19, 0, 0, 190)
	ShopStone.card(frame)
	frame.Parent = content
	local chip = ShopStone.chip(frame, item.color)
	chip.Position = UDim2.fromOffset(10, 10)
	chip.Size = UDim2.new(1, -20, 0.5, -6)
	local icon: GuiObject = if item.gear and item.level
		then GearIcons.view(chip, item.gear, item.level)
		else Icons.view(chip, item.icon or "coin")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.46)
	icon.Size = UDim2.fromScale(1, 1.08)
	local square = Instance.new("UIAspectRatioConstraint")
	square.DominantAxis = Enum.DominantAxis.Height -- el chip es más ancho que alto
	square.Parent = icon
	local title = Style.text(frame, "Titulo", 24, nil, 2.5)
	title.Text = item.title
	title.Position = UDim2.fromScale(0.06, 0.55)
	title.Size = UDim2.fromScale(0.88, 0.2)
	Kit.gold(title)
	local detail = Style.text(frame, "Detalle", 18, nil, 2)
	detail.Text = item.detail
	detail.Position = UDim2.fromScale(0.06, 0.75)
	detail.Size = UDim2.fromScale(0.88, 0.16)
end

return StarterParts
