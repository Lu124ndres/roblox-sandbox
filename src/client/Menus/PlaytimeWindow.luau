--!strict
--[[
	PlaytimeWindow

	Regalos por tiempo jugado (Config.Retention.playtime): en la columna
	izquierda, un aviso "Regalo en 4:32" (o "¡Regalo listo!") que abre la
	ventana con los 8 regalos en casillas de piedra: los listos con marco de
	lava y ¡RECLAMAR!, los que faltan (piedra gris) con su cuenta regresiva y
	los cobrados (verdes) con ✓. El tiempo cuenta
	desde que entró al servidor (atributo RegalosDesde); el servidor decide.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RewardScale = require(ReplicatedStorage.Shared.RewardScale)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local PlaytimeEntry = require(script.Parent.PlaytimeEntry)
local Window = require(script.Parent.Window)

local GIFTS = Config.Retention.playtime
local ATTR = Protocol.PlayerAttributes
local CARDS = Style.PALETTE.Cards

type State = "claimed" | "ready" | "waiting"

local PlaytimeWindow = {}

local function clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

local function rewardText(player: Player, gift: Config.PlaytimeGift): string
	local parts = {}
	if gift.coins then
		table.insert(
			parts,
			`{NumberFormat.short(RewardScale.share(player, gift.coins, gift.share))} monedas`
		)
	end
	if gift.boostMinutes then
		table.insert(parts, `x2 poder {gift.boostMinutes} min`)
	end
	return table.concat(parts, "\n")
end

function PlaytimeWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local claimRemote = remotes:WaitForChild(Protocol.Remotes.ClaimPlaytime) :: RemoteEvent
	local window = Window.create(screen, "Regalos", "Regalos por jugar", Vector2.new(760, 420))

	-- Botón grande en la columna izquierda (abre la ventana).
	local entry = PlaytimeEntry.build(16, window.toggle)

	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1, 1)
	grid.Parent = window.content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.25, -10, 0.5, -10)
	layout.CellPadding = UDim2.fromOffset(10, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local function elapsed(): number
		local since = player:GetAttribute(ATTR.PlaytimeSince)
		return if type(since) == "number" then Workspace:GetServerTimeNow() - since else 0
	end

	local function stateOf(index: number): State
		local claimed = player:GetAttribute(ATTR.PlaytimeClaimed)
		local bit = 2 ^ (index - 1)
		if type(claimed) == "number" and (claimed // bit) % 2 == 1 then
			return "claimed" :: State
		end
		local ready = elapsed() >= GIFTS[index].minutes * 60
		return (if ready then "ready" else "waiting") :: State
	end

	type Card = { box: TextButton, status: TextLabel, check: TextLabel, reward: TextLabel }
	local cards: { Card } = {}
	for index, gift in GIFTS do
		local box = Instance.new("TextButton")
		box.Name = `Regalo{index}`
		box.Text = ""
		box.LayoutOrder = index
		box.AutoButtonColor = false
		box.BackgroundTransparency = 1
		box.Parent = grid
		local time = Style.text(box, "Tiempo", 22, nil, 2.5)
		time.Text = if gift.minutes >= 60 then `{gift.minutes / 60} h` else `{gift.minutes} min`
		Kit.gold(time)
		time.Position = UDim2.fromScale(0, 0.03)
		time.Size = UDim2.fromScale(1, 0.16)
		local picture = Icons.view(box, if index == #GIFTS then "chest" else "giftPink")
		picture.AnchorPoint = Vector2.new(0.5, 0)
		picture.Position = UDim2.fromScale(0.5, 0.2)
		picture.Size = UDim2.fromScale(0.7, 0.36)
		local reward = Style.text(box, "Premio", 18, UIConfig.Colors.Coins, 2)
		reward.Text = rewardText(player, gift)
		reward.Position = UDim2.fromScale(0.04, 0.56)
		reward.Size = UDim2.fromScale(0.92, 0.22)
		local status = Style.text(box, "Estado", 20, nil, 2.5)
		status.Position = UDim2.fromScale(0.04, 0.8)
		status.Size = UDim2.fromScale(0.92, 0.16)
		local check = Style.text(box, "Hecho", 60, Style.PALETTE.Buy, 4)
		check.Text = "✓"
		check.AnchorPoint = Vector2.new(0.5, 0.5)
		check.Position = UDim2.fromScale(0.5, 0.4)
		check.Size = UDim2.fromScale(0.8, 0.5)
		box.Activated:Connect(function()
			if stateOf(index) == "ready" then
				claimRemote:FireServer(index)
			end
		end)
		cards[index] = { box = box, status = status, check = check, reward = reward }
	end

	local shown: { [number]: string } = {}
	local function render()
		local nextWait: number? = nil
		local anyReady = false
		for index, card in cards do
			local state = stateOf(index)
			if state ~= shown[index] then
				shown[index] = state
				-- Listo: marco de lava. Cobrado: piedra verde. Esperando: piedra gris.
				if state == "ready" then
					Kit.skin(card.box, "lava")
				else
					Kit.skin(
						card.box,
						"boton",
						if state == "claimed" then CARDS.Green else Kit.STONE
					)
				end
				card.check.Visible = state == "claimed"
				card.status.TextColor3 = if state == "ready"
					then Style.PALETTE.Buy
					else UIConfig.Colors.Text
			end
			card.reward.Text = rewardText(player, GIFTS[index]) -- crece con la caña
			local left = GIFTS[index].minutes * 60 - elapsed()
			card.status.Text = if state == "claimed"
				then "Cobrado"
				elseif state == "ready" then "¡RECLAMAR!"
				else clock(left)
			anyReady = anyReady or state == "ready"
			if state == "waiting" and (not nextWait or left < nextWait) then
				nextWait = left
			end
		end
		entry.set(anyReady, if nextWait then `en {clock(nextWait)}` else nil)
	end

	player:GetAttributeChangedSignal(ATTR.PlaytimeClaimed):Connect(render)
	task.spawn(function()
		while true do
			render()
			task.wait(1)
		end
	end)
end

return PlaytimeWindow
