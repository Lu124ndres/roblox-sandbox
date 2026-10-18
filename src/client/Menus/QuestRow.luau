--!strict
--[[
	QuestRow

	Una tarjeta de la ventana MISIONES (QuestsWindow): rayos azules o verdes,
	ícono del tipo de misión en un hueco de piedra, texto, barra, premio en monedas, etiqueta de
	impulso y ✓ al cumplirla.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)

local ROW_HEIGHT = 84

local QuestRow = {}

QuestRow.ROW_HEIGHT = ROW_HEIGHT
local CARDS = Style.PALETTE.Cards
QuestRow.KIND_ICONS = table.freeze({
	catch = "fish",
	rare = "crystal",
	feed = "meat",
	kill = "skull",
	train = "bolt",
	eventCatch = "fish",
	food = "orca",
} :: { [string]: string })

export type Quest = {
	text: string,
	kind: string?,
	progress: number,
	goal: number,
	done: boolean,
	coins: number,
	boost: number,
	extra: boolean?, -- misión extra: paga, pero el cofre no la pide
}
export type Row = {
	box: Frame,
	icon: GuiObject?,
	title: TextLabel,
	bar: CardParts.Bar,
	reward: TextLabel,
	boost: TextLabel,
	check: TextLabel,
	color: Color3?,
	kind: string?,
}

-- wide: tarjeta de media ventana (táctil): el texto puede ir en dos líneas y
-- le quita ancho al premio, que si no los textos largos quedaban diminutos.
function QuestRow.make(parent: Instance, order: number, wide: boolean?): Row
	local box = CardParts.card(parent, `Mision{order}`, CARDS.Blue)
	box.LayoutOrder = order
	box.Size = UDim2.new(1, -8, 0, ROW_HEIGHT)
	-- El ícono va en un hueco tallado en la piedra (como el del monstruo en el HUD).
	local socket = Instance.new("Frame")
	socket.Name = "Hueco"
	socket.AnchorPoint = Vector2.new(0.5, 0.5)
	socket.Position = UDim2.new(0, ROW_HEIGHT / 2 + 4, 0.5, 0)
	socket.Size = UDim2.fromOffset(ROW_HEIGHT - 12, ROW_HEIGHT - 12)
	socket.ZIndex = 1
	socket.Parent = box
	Kit.skin(socket, "hondo")
	local title = Style.text(box, "Texto", 26, nil, 2.5)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextWrapped = wide == true
	title.Position = UDim2.fromOffset(ROW_HEIGHT, if wide then 3 else 8)
	title.Size = UDim2.new(if wide then 0.74 else 0.62, -ROW_HEIGHT, 0, if wide then 44 else 30)
	local bar = CardParts.bar(box, CARDS.Green, 20)
	bar.track.Position = UDim2.fromOffset(ROW_HEIGHT, if wide then 50 else 44)
	bar.track.Size = UDim2.new(if wide then 0.7 else 0.66, -ROW_HEIGHT, 0, if wide then 26 else 28)
	local prize, reward = CardParts.iconText(box, "coin", 28, UIConfig.Colors.Coins)
	prize.AnchorPoint = Vector2.new(1, 0.5)
	prize.Position = UDim2.new(1, -14, 0.5, 0)
	prize.Size = UDim2.new(if wide then 0.24 else 0.3, -14, 0, 40)
	local boost = ShopParts.tag(box, "", CARDS.Purple)
	local tag = boost.Parent :: Frame
	tag.AnchorPoint = Vector2.new(1, 0)
	tag.Position = UDim2.new(1, -8, 0, -10)
	tag.Size = UDim2.fromOffset(118, 28)
	local check = Style.text(box, "Hecho", 64, Style.PALETTE.Buy, 4)
	check.Text = "✓"
	check.AnchorPoint = Vector2.new(0.5, 0.5)
	check.Position = UDim2.new(0, ROW_HEIGHT / 2, 0.5, 0)
	check.Size = UDim2.fromOffset(ROW_HEIGHT, ROW_HEIGHT)
	check.ZIndex = 4
	return { box = box, title = title, bar = bar, reward = reward, boost = boost, check = check }
end

function QuestRow.setIcon(row: Row, kind: string)
	if row.kind == kind then
		return
	end
	if row.icon then
		row.icon:Destroy()
	end
	local view = Icons.view(row.box, kind)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.new(0, ROW_HEIGHT / 2 + 4, 0.5, 0)
	view.Size = UDim2.fromOffset(ROW_HEIGHT - 22, ROW_HEIGHT - 22)
	view.ZIndex = 2 -- encima del hueco
	row.icon, row.kind = view, kind
end

function QuestRow.paint(row: Row, color: Color3)
	if row.color ~= color then
		row.color = color
		CardParts.paint(row.box, color)
	end
end

function QuestRow.setBoost(row: Row, minutes: number)
	local tag = row.boost.Parent :: Frame
	tag.Visible = minutes > 0
	row.boost.Text = `x2 poder {minutes}m`
end

return QuestRow
