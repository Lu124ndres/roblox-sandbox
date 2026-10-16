--!strict
--[[
	StarterParts

	Piezas de la ventana del pack de inicio (StarterOffer): la cabecera con
	el regalo, el título y el sello de descuento que se mece, y las tarjetas
	de lo que trae (con el ícono de MEJORAS si es equipo).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local GearIcons = require(script.Parent.Parent.Interface.GearIcons)
local Icons = require(script.Parent.Parent.Interface.Icons)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)

local CARDS = Style.PALETTE.Cards
local GOLD = UIConfig.Colors.Coins
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
	local art = CardParts.card(content, "Regalo", CARDS.Pink, 50)
	art.Position = UDim2.fromOffset(4, 0)
	art.Size = UDim2.fromOffset(96, 96)
	local gift = Icons.view(art, "giftPink")
	gift.Position = UDim2.fromOffset(6, 4)
	gift.Size = UDim2.fromOffset(84, 84)
	local title = Style.text(content, "Titulo", 44, GOLD, 3.5)
	title.Text = "¡PACK DE INICIO!"
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
		local seal = CardParts.card(content, "Descuento", CARDS.Red, 48)
		seal.AnchorPoint = Vector2.new(1, 0)
		seal.Position = UDim2.new(1, -4, 0, -4)
		seal.Size = UDim2.fromOffset(96, 96)
		seal.Rotation = 12
		local off = Style.text(seal, "Texto", 34, nil, 3)
		off.Text = `-{discount}%`
		off.Position = UDim2.fromScale(0.08, 0.25)
		off.Size = UDim2.fromScale(0.84, 0.5)
		TweenService:Create(seal, PULSE, { Rotation = -6 }):Play()
	end
end

function StarterParts.card(content: Frame, index: number, item: Item)
	local frame = CardParts.card(content, `Item{index}`, item.color, 14)
	frame.Position = UDim2.new((index - 1) * 0.2 + 0.005, 0, 0, 110)
	frame.Size = UDim2.new(0.19, 0, 0, 190)
	local icon: GuiObject = if item.gear and item.level
		then GearIcons.view(frame, item.gear, item.level)
		else Icons.view(frame, item.icon or "coin")
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.fromScale(0.5, 0.04)
	icon.Size = UDim2.fromScale(0.9, 0.52)
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = icon
	local title = Style.text(frame, "Titulo", 24, if index == 1 then GOLD else nil, 2.5)
	title.Text = item.title
	title.Position = UDim2.fromScale(0.04, 0.58)
	title.Size = UDim2.fromScale(0.92, 0.2)
	local detail = Style.text(frame, "Detalle", 18, nil, 2)
	detail.Text = item.detail
	detail.Position = UDim2.fromScale(0.04, 0.78)
	detail.Size = UDim2.fromScale(0.92, 0.17)
end

return StarterParts
