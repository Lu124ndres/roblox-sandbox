--!strict
--[[
	RebirthParts

	Piezas de la ventana RENACER (RebirthWindow): las tarjetas AHORA / AL
	RENACER con el pez y el número grande, las barras de lo que pide con su
	ícono que se ponen verdes al alcanzar, y las tarjetas de qué se reinicia
	y qué te quedas con una fila de íconos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)

export type Entry = { icon: string, label: string }
export type Requirement = { set: (have: number, need: number, text: string) -> () }

local RebirthParts = {}

-- Tarjeta de peces por segundo: título, pez + número grande y nota (el bono
-- de monedas y poder). Devuelve el número, la etiqueta "+N%" (solo la usa AL
-- RENACER) y la nota.
function RebirthParts.speedCard(
	parent: Instance,
	title: string,
	color: Color3,
	x: number
): (TextLabel, TextLabel, TextLabel)
	local card = CardParts.card(parent, title, color, 18)
	card.Position = UDim2.fromScale(x, 0)
	card.Size = UDim2.new(0.4, 0, 0, 138)
	local head = Style.text(card, "Titulo", 26, nil, 2.5)
	head.Text = title
	head.Position = UDim2.fromScale(0, 0.05)
	head.Size = UDim2.fromScale(1, 0.2)
	local fish = Icons.view(card, "fish")
	fish.Position = UDim2.fromScale(0.05, 0.26)
	fish.Size = UDim2.fromScale(0.3, 0.5)
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = fish
	local value = Style.text(card, "Valor", 64, UIConfig.Colors.Coins, 4)
	value.Position = UDim2.fromScale(0.3, 0.26)
	value.Size = UDim2.fromScale(0.66, 0.48)
	local note = Style.text(card, "Nota", 18, nil, 2)
	note.Text = "peces por segundo al alimentar"
	note.Position = UDim2.fromScale(0.04, 0.77)
	note.Size = UDim2.fromScale(0.92, 0.17)
	local chip = Style.text(card, "Mas", 34, Style.PALETTE.Buy, 3)
	chip.AnchorPoint = Vector2.new(1, 0)
	chip.Position = UDim2.new(1, 14, 0, -18)
	chip.Size = UDim2.fromOffset(110, 42)
	chip.Rotation = 10
	chip.ZIndex = 4
	chip.Visible = false
	return value, chip, note
end

-- Barra de un requisito con su ícono a la izquierda; se vuelve verde al alcanzarlo.
function RebirthParts.requirement(
	parent: Instance,
	icon: string,
	color: Color3,
	x: number,
	y: number
): Requirement
	local bar = CardParts.bar(parent, color, 22)
	bar.track.Position = UDim2.new(x, 26, 0, y)
	bar.track.Size = UDim2.new(0.46, -26, 0, 40)
	local image = Icons.view(parent, icon)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.new(x, 26, 0, y + 20)
	image.Size = UDim2.fromOffset(56, 56)
	image.ZIndex = 4
	return {
		set = function(have: number, need: number, text: string)
			local done = have >= need
			bar.set(
				have / math.max(need, 1),
				if done then `✓ {text}` else text,
				if done then Style.PALETTE.Buy else color
			)
		end,
	}
end

-- Tarjeta con título y una fila de íconos con su nombre debajo.
function RebirthParts.listCard(
	parent: Instance,
	title: string,
	color: Color3,
	x: number,
	y: number,
	entries: { Entry }
)
	local card = CardParts.card(parent, title, color, 14)
	card.Position = UDim2.new(x, 0, 0, y)
	card.Size = UDim2.new(0.48, 0, 0, 132)
	local head = Style.text(card, "Titulo", 24, nil, 2.5)
	head.Text = title
	head.Position = UDim2.fromScale(0.04, 0.04)
	head.Size = UDim2.fromScale(0.92, 0.22)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromScale(0.03, 0.28)
	row.Size = UDim2.fromScale(0.94, 0.68)
	row.Parent = card
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = row
	for index, entry in entries do
		local slot = Instance.new("Frame")
		slot.BackgroundTransparency = 1
		slot.LayoutOrder = index
		slot.Size = UDim2.fromScale(1 / math.max(#entries, 4), 1)
		slot.Parent = row
		local image = Icons.view(slot, entry.icon)
		image.AnchorPoint = Vector2.new(0.5, 0)
		image.Position = UDim2.fromScale(0.5, 0)
		image.Size = UDim2.fromScale(0.9, 0.66)
		local square = Instance.new("UIAspectRatioConstraint")
		square.Parent = image
		local label = Style.text(slot, "Nombre", 16, nil, 2)
		label.Text = entry.label
		label.Position = UDim2.fromScale(0, 0.7)
		label.Size = UDim2.fromScale(1, 0.28)
	end
end

return RebirthParts
