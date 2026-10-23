--!strict
--[[
	QuestsWindow

	Misiones diarias (botón MISIONES) con el estilo de la TIENDA: tarjetas
	con rayos (azul pendiente, verde cumplida; la EXTRA morada), ícono, barra
	y premio (QuestRow); abajo el cofre por cumplir las tres (la extra de
	llenar monstruos paga, pero no hace falta para el cofre). Cumplida, la
	tarjeta muestra ¡RECLAMAR! y se cobra aquí con QuestClaim(index; 0 = el
	cofre): no hay autorreclamo (pedido del usuario el 2026-10-23). El servidor
	valida y paga; aquí solo se muestra el atributo Misiones (JSON de
	server/Retention/Quests). El botón MISIONES avisa mientras quede algo por
	hacer o por reclamar. En táctil la ventana es ancha y las tarjetas van de
	dos en dos.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local QUESTS = require(ReplicatedStorage.Shared.Config.Quests)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local QuestRow = require(script.Parent.QuestRow)
local Window = require(script.Parent.Window)
local WindowLayout = require(script.Parent.WindowLayout)

local CARDS = Style.PALETTE.Cards
local CHEST = 0 -- índice de QuestClaim para el cofre

local QuestsWindow = {}

function QuestsWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local claimRemote = remotes:WaitForChild(Protocol.Remotes.QuestClaim) :: RemoteEvent
	local wide = WindowLayout.wide()
	local size = WindowLayout.size(Vector2.new(740, 590), Vector2.new(1120, 400))
	local window = Window.create(screen, "Misiones", "Misiones del día", size)
	local hud = HudButtons.side("Misiones", "bolt", window.toggle)
	local list: UIGridStyleLayout
	if wide then
		local grid = Instance.new("UIGridLayout")
		grid.CellPadding = UDim2.fromOffset(14, 14)
		grid.CellSize = UDim2.new(0.5, -7, 0, QuestRow.ROW_HEIGHT)
		list = grid
	else
		local column = Instance.new("UIListLayout")
		column.Padding = UDim.new(0, 14)
		list = column
	end
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = window.content
	local top = Instance.new("UIPadding")
	top.PaddingTop = UDim.new(0, 10)
	top.Parent = window.content
	local rows: { QuestRow.Row } = {}
	local count = QUESTS.perDay + (if #QUESTS.extra > 0 then 1 else 0)
	for index = 1, count do
		local row = QuestRow.make(window.content, if index > QUESTS.perDay then 98 else index, wide)
		row.claim.Activated:Connect(function()
			row.claim.Visible = false -- hasta que el servidor confirme (o lo vuelva a mostrar)
			claimRemote:FireServer(index)
		end)
		rows[index] = row
	end
	local chest = QuestRow.make(window.content, QUESTS.perDay + 1, wide)
	chest.claim.Activated:Connect(function()
		chest.claim.Visible = false
		claimRemote:FireServer(CHEST)
	end)
	QuestRow.setIcon(chest, "chest")
	chest.title.Text = "Cofre: cumple las tres"
	chest.reward.Text = NumberFormat.short(QUESTS.bonus.coins)
	QuestRow.setBoost(chest, QUESTS.bonus.boostMinutes)
	local reset = Style.text(window.content, "Reinicio", 20, nil, 2)
	Kit.gold(reset)
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
		local pending, ready, doneCount = false, false, 0
		for index, row in rows do
			local quest = data.list[index] :: QuestRow.Quest?
			row.box.Visible = quest ~= nil
			if quest then
				QuestRow.setIcon(row, QuestRow.KIND_ICONS[quest.kind or ""] or "fish")
				row.title.Text = if quest.extra then `EXTRA · {quest.text}` else quest.text
				row.bar.set(
					quest.progress / quest.goal,
					if quest.kind == "food"
						then `{string.format("%.1f", quest.progress)}% / {quest.goal}%`
						else `{NumberFormat.short(quest.progress)} / {NumberFormat.short(
							quest.goal
						)}`
				)
				row.reward.Text = NumberFormat.short(quest.coins)
				QuestRow.setBoost(row, quest.boost)
				local claimed = quest.claimed == true
				QuestRow.setState(row, quest.done, claimed)
				ready = ready or (quest.done and not claimed)
				local idle = if quest.extra then CARDS.Purple else CARDS.Blue
				QuestRow.paint(row, if quest.done then CARDS.Green else idle)
				if not quest.extra then
					pending = pending or not quest.done
					doneCount += if quest.done then 1 else 0
				end
			end
		end
		if type(data.bonusCoins) == "number" then
			chest.reward.Text = NumberFormat.short(data.bonusCoins)
		end
		chest.bar.set(
			doneCount / QUESTS.perDay,
			if data.bonus then "¡Cobrado!" else `{doneCount} / {QUESTS.perDay}`,
			CARDS.Yellow
		)
		local chestReady = doneCount >= QUESTS.perDay
		QuestRow.setState(chest, chestReady, data.bonus == true)
		ready = ready or (chestReady and data.bonus ~= true)
		QuestRow.paint(chest, if data.bonus then CARDS.Green else CARDS.Orange)
		hud.setAlert(pending or ready)
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
