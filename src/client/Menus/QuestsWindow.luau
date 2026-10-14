--!strict
--[[
	QuestsWindow

	Misiones diarias (botón MISIONES de la columna derecha): las tres del día
	con su barra de avance y premio, y el cofre por cumplirlas todas. Se
	cumplen solas (el servidor paga y avisa); aquí solo se muestran. Lee el
	atributo Misiones (JSON que publica server/Retention/Quests). El botón
	lleva un punto rojo mientras quede alguna sin cumplir.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local QUESTS = require(ReplicatedStorage.Shared.Config.Quests)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Parent.Ui)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local ROW_HEIGHT = 74
local CARDS = Style.PALETTE.Cards

type Quest = {
	text: string,
	progress: number,
	goal: number,
	done: boolean,
	coins: number,
	boost: number,
}
type Row = { box: Frame, title: TextLabel, fill: Frame, count: TextLabel, reward: TextLabel }

local QuestsWindow = {}

local function rewardText(coins: number, boost: number): string
	local text = `+{NumberFormat.short(coins)} monedas`
	return if boost > 0 then `{text} · x2 poder {boost} min` else text
end

local function makeRow(parent: Instance, order: number): Row
	local box = Ui.panel(`Mision{order}`, parent)
	box.LayoutOrder = order
	box.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	Style.border(box, 3)
	local title = Style.text(box, "Texto", 24, nil, 2)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(12, 6)
	title.Size = UDim2.new(0.62, 0, 0, 28)
	local reward = Style.text(box, "Premio", 18, UIConfig.Colors.Coins, 2)
	reward.TextXAlignment = Enum.TextXAlignment.Right
	reward.AnchorPoint = Vector2.new(1, 0)
	reward.Position = UDim2.new(1, -12, 0, 8)
	reward.Size = UDim2.new(0.36, 0, 0, 24)
	local track = Instance.new("Frame")
	track.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
	track.Position = UDim2.fromOffset(12, 40)
	track.Size = UDim2.new(1, -24, 0, 24)
	Ui.corner(track, 8)
	track.ClipsDescendants = true
	track.Parent = box
	local fill = Instance.new("Frame")
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = CARDS.Green
	fill.Size = UDim2.fromScale(0, 1)
	Ui.corner(fill, 8)
	fill.Parent = track
	local count = Style.text(track, "Cuenta", 18, nil, 2)
	count.Size = UDim2.fromScale(1, 1)
	count.ZIndex = 3
	return { box = box, title = title, fill = fill, count = count, reward = reward }
end

function QuestsWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local window = Window.create(screen, "Misiones", "Misiones del día", Vector2.new(720, 470))
	local hud = HudButtons.side("Misiones", "bolt", window.toggle)
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = window.content
	local rows: { Row } = {}
	for index = 1, QUESTS.perDay do
		rows[index] = makeRow(window.content, index)
	end
	local chest = makeRow(window.content, QUESTS.perDay + 1)
	chest.title.Text = "Cofre: cumple las tres"
	chest.reward.Text = rewardText(QUESTS.bonus.coins, QUESTS.bonus.boostMinutes)
	local reset = Style.text(window.content, "Reinicio", 18, UIConfig.Colors.TextMuted, 1.5)
	reset.LayoutOrder = 99
	reset.Size = UDim2.new(1, 0, 0, 22)

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
				row.title.Text = (if quest.done then "✓ " else "") .. quest.text
				row.fill.Size = UDim2.fromScale(math.clamp(quest.progress / quest.goal, 0, 1), 1)
				row.count.Text =
					`{NumberFormat.short(quest.progress)} / {NumberFormat.short(quest.goal)}`
				row.reward.Text = rewardText(quest.coins, quest.boost)
				row.box.BackgroundColor3 = if quest.done then CARDS.Green else UIConfig.Colors.Panel
				pending = pending or not quest.done
				doneCount += if quest.done then 1 else 0
			end
		end
		chest.fill.Size = UDim2.fromScale(doneCount / QUESTS.perDay, 1)
		chest.count.Text = if data.bonus then "¡Cobrado!" else `{doneCount} / {QUESTS.perDay}`
		chest.box.BackgroundColor3 = if data.bonus then CARDS.Yellow else UIConfig.Colors.Panel
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
