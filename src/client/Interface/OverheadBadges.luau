--!strict
--[[
	OverheadBadges

	Insignias del cartel sobre la cabeza (Overhead), todas dentro de un solo
	marco: una placa con marco de lava (Interface/Kit, como TIENDA); con el pase
	VIP la placa es de oro y lleva una cinta de lava "VIP" inclinada en la
	esquina de arriba (pedido del usuario el 2026-10-20). Adentro, sin líneas
	entre las partes (la dorada se quitó por pedido del usuario el 2026-10-23):
		Monstruos  el monstruo alimentado (Icons "fed", el de "monstruos llenados"
		           del HUD) y cuántos llenó
		Premium    el ícono de Roblox Premium (solo si es Premium)
	La placa se ajusta al ancho de lo que se muestra y queda centrada; los
	íconos sobresalen un poco del marco.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Icons = require(script.Parent.Icons)
local Kit = require(script.Parent.Kit)
local OverheadVip = require(script.Parent.OverheadVip)
local Style = require(script.Parent.Style)

export type Badges = {
	setKills: (count: number) -> (),
	setVip: (on: boolean) -> (),
}

local rgb = Color3.fromRGB
-- Ancho de cada parte (fracción del ancho del cartel) y el margen de la placa.
local WIDTH = { kills = 0.27, premium = 0.11 }
local SIDES = 0.07 -- un poco más: el marco de lava es más grueso que el de oro
local PLATE_SLICE = 0.3
-- La placa, más ancha en la misma proporción en que Overhead subió el alto de su fila.
local GROW = 1.25

local OverheadBadges = {}

local function plate(row: Frame): (Frame, Frame)
	local back = Instance.new("Frame")
	back.Name = "Placa"
	back.AnchorPoint = Vector2.new(0.5, 0.5)
	back.Position = UDim2.fromScale(0.5, 0.52)
	back.BorderSizePixel = 0
	Kit.skin(back, "lava").SliceScale = PLATE_SLICE
	back.Parent = row
	-- Las partes van en su propio cuadro (la piel de piedra no entra en la fila).
	local inside = Instance.new("Frame")
	inside.Name = "Contenido"
	inside.BackgroundTransparency = 1
	inside.Size = UDim2.fromScale(1, 1)
	inside.Parent = back
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = inside
	return back, inside
end

local function part(parent: Instance, name: string, order: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.LayoutOrder = order
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	return frame
end

local function icon(parent: Instance, kind: string, size: number, x: number)
	local image = Icons.view(parent, kind)
	image.SizeConstraint = Enum.SizeConstraint.RelativeYY
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(x, 0.46)
	image.Size = UDim2.fromScale(size, size)
	image.ZIndex = 3
end

local function label(parent: Instance, text: string, color: Color3, x: number): TextLabel
	local value = Style.text(parent, "Texto", 90, color, 2.5)
	value.Text = text
	value.Position = UDim2.fromScale(x, 0.12)
	value.Size = UDim2.fromScale(0.96 - x, 0.76)
	value.ZIndex = 3
	return value
end

function OverheadBadges.build(row: Frame, player: Player): Badges
	local back, inside = plate(row)
	local tag = OverheadVip.ribbon(back)
	local kills = part(inside, "Monstruos", 1)
	icon(kills, "fed", 1.45, 0.2)
	local count = label(kills, "0", rgb(255, 244, 214), 0.44)
	local premium = part(inside, "Premium", 5)
	local glyph = Instance.new("ImageLabel")
	glyph.Name = "Icono"
	glyph.BackgroundTransparency = 1
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	glyph.Size = UDim2.fromScale(0.62, 0.62)
	glyph.SizeConstraint = Enum.SizeConstraint.RelativeYY
	glyph.Image = Assets.UI.PremiumIcon -- el ícono de Premium que trae Roblox
	glyph.ScaleType = Enum.ScaleType.Fit
	glyph.ZIndex = 3
	glyph.Parent = premium

	local hasVip = false
	local isPremium = player.MembershipType == Enum.MembershipType.Premium
	-- Ancho de la placa según lo que se ve; cada parte, en proporción.
	local function layout()
		type Entry = { frame: Frame, width: number, on: boolean }
		local shown: { Entry } = {
			{ frame = kills, width = WIDTH.kills, on = true },
			{ frame = premium, width = WIDTH.premium, on = isPremium },
		}
		local total = SIDES
		for _, entry in shown do
			if entry.on then
				total += entry.width
			end
		end
		back.Size = UDim2.fromScale(total * GROW, 0.84)
		for _, entry in shown do
			entry.frame.Visible = entry.on
			entry.frame.Size = UDim2.fromScale(entry.width / total, 1)
		end
	end
	layout()

	return {
		setKills = function(value: number)
			count.Text = NumberFormat.short(value)
		end,
		setVip = function(on: boolean)
			if on ~= hasVip then
				hasVip = on
				OverheadVip.paint(back, on, PLATE_SLICE)
				tag.Visible = on
			end
		end,
	}
end

return table.freeze(OverheadBadges)
