--!strict
--[[
	QuestsWindow

	Misiones diarias (botón MISIONES) con el estilo de la TIENDA: tarjetas
	con rayos (azul pendiente, verde cumplida), ícono, barra y premio; abajo
	el cofre por cumplir las tres. El servidor paga y avisa; aquí solo se
	muestra el atributo Misiones (JSON de server/Retention/Quests).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local QUESTS = require(ReplicatedStorage.Shared.Config.Quests)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Icons = require(script.Parent.Parent.Interface.Icons)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local ROW_HEIGHT = 84
local CARDS = Style.PALETTE.Cards
local KIND_ICONS: { [string]: string } = {
	catch = "fish",
	rare = "crystal",
	feed = "meat",
	kill = "skull",
	train = "bolt",
	eventCatch = "fish",
}

type Quest = {
	text: string,
	kind: string?,
	progress: number,
	goal: number,
	done: boolean,
	coins: number,
	boost: number,
}
type Row = {
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

local QuestsWindow = {}

local function makeRow(parent: Instance, order: number): Row
	local box = CardParts.card(parent, `Mision{order}`, CARDS.Blue)
	box.LayoutOrder = order
	box.Size = UDim2.new(1, -8, 0, ROW_HEIGHT)
	local title = Style.text(box, "Texto", 26, nil, 2.5)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(ROW_HEIGHT, 8)
	title.Size = UDim2.new(0.62, -ROW_HEIGHT, 0, 30)
	local bar = CardParts.bar(box, CARDS.Green, 20)
	bar.track.Position = UDim2.fromOffset(ROW_HEIGHT, 44)
	bar.track.Size = UDim2.new(0.66, -ROW_HEIGHT, 0, 28)
	local prize, reward = CardParts.iconText(box, "coin", 28, UIConfig.Colors.Coins)
	prize.AnchorPoint = Vector2.new(1, 0.5)
	prize.Position = UDim2.new(1, -14, 0.5, 0)
	prize.Size = UDim2.new(0.3, -14, 0, 40)
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

local function setIcon(row: Row, kind: string)
	if row.kind == kind then
		return
	end
	if row.icon then
		row.icon:Destroy()
	end
	local view = Icons.view(row.box, kind)
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.new(0, ROW_HEIGHT / 2 + 4, 0.5, 0)
	view.Size = UDim2.fromOffset(ROW_HEIGHT - 14, ROW_HEIGHT - 14)
	row.icon, row.kind = view, kind
end

local function paint(row: Row, color: Color3)
	if row.color ~= color then
		row.color = color
		CardParts.paint(row.box, color)
	end
end

local function setBoost(row: Row, minutes: number)
	local tag = row.boost.Parent :: Frame
	tag.Visible = minutes > 0
	row.boost.Text = `x2 poder {minutes}m`
end

function QuestsWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local window = Window.create(screen, "Misiones", "Misiones del día", Vector2.new(740, 500))
	local hud = HudButtons.side("Misiones", "bolt", window.toggle)
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 14)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = window.content
	local top = Instance.new("UIPadding")
	top.PaddingTop = UDim.new(0, 10)
	top.Parent = window.content
	local rows: { Row } = {}
	for index = 1, QUESTS.perDay do
		rows[index] = makeRow(window.content, index)
	end
	local chest = makeRow(window.content, QUESTS.perDay + 1)
	setIcon(chest, "chest")
	chest.title.Text = "Cofre: cumple las tres"
	chest.reward.Text = NumberFormat.short(QUESTS.bonus.coins)
	setBoost(chest, QUESTS.bonus.boostMinutes)
	local reset = Style.text(window.content, "Reinicio", 20, UIConfig.Colors.TextMuted, 2)
	reset.LayoutOrder = 99
	reset.Size = UDim2.new(1, 0, 0, 24)

	local function render()
		local raw = player:GetAttribute(Protocol.PlayerAttributes.Quests)
		if type(raw) ~= "string" then
			return
		end
		local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
		if not ok or type(data) ~= "table" or type(data.list) ~= "table" then
			return
		end
		local pending, doneCount = false, 0
		for index, row in rows do
			local quest = data.list[index] :: Quest?
			row.box.Visible = quest ~= nil
			if quest then
				setIcon(row, KIND_ICONS[quest.kind or ""] or "fish")
				row.title.Text = quest.text
				row.bar.set(
					quest.progress / quest.goal,
					`{NumberFormat.short(quest.progress)} / {NumberFormat.short(quest.goal)}`
				)
				row.reward.Text = NumberFormat.short(quest.coins)
				setBoost(row, quest.boost)
				row.check.Visible = quest.done
				if row.icon then
					row.icon.Visible = not quest.done
				end
				paint(row, if quest.done then CARDS.Green else CARDS.Blue)
				pending = pending or not quest.done
				doneCount += if quest.done then 1 else 0
			end
		end
		chest.bar.set(
			doneCount / QUESTS.perDay,
			if data.bonus then "¡Cobrado!" else `{doneCount} / {QUESTS.perDay}`,
			CARDS.Yellow
		)
		chest.check.Visible = data.bonus == true
		paint(chest, if data.bonus then CARDS.Green else CARDS.Orange)
		hud.setAlert(pending)
	end

	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.Quests):Connect(render)
	render()
	task.spawn(function() -- cuenta hasta las nuevas misiones (medianoche UTC)
		while true do
			local left = 86400 - Workspace:GetServerTimeNow() % 86400
			reset.Text = string.format(
				"Nuevas misiones en %d:%02d:%02d",
				left // 3600,
				(left % 3600) // 60,
				left % 60
			)
			task.wait(1)
		end
	end)
end

return QuestsWindow
