--!strict
--[[
	PlaytimeWindow

	Regalos por tiempo jugado (Config.Retention.playtime): en la columna
	izquierda, un aviso "Regalo en 4:32" (o "¡Regalo listo!") que abre la
	ventana, armada como los "Premios" de los simuladores con la piedra
	volcánica: un regalo grande asoma junto al título, los regalos van en
	tarjetas de 3 columnas (PlaytimeCard: premio arriba, ícono sobre rayos y
	la placa con el tiempo que falta) y el último, el más grande, en una franja
	ancha al final. El tiempo cuenta desde que entró al servidor (atributo
	RegalosDesde); el servidor decide.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RewardScale = require(ReplicatedStorage.Shared.RewardScale)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)
local GamepadNav = require(script.Parent.GamepadNav)
local PlaytimeCard = require(script.Parent.PlaytimeCard)
local PlaytimeEntry = require(script.Parent.PlaytimeEntry)
local Window = require(script.Parent.Window)

local GIFTS = Config.Retention.playtime
local ATTR = Protocol.PlayerAttributes
local CARDS = Style.PALETTE.Cards

local COLUMNS = 3
local GAP = 10
local HEADER_ICON = 104 -- el regalo que asoma arriba a la izquierda
local TITLE_SHIFT = 84 -- el título se corre para dejarle lugar al regalo

local PlaytimeWindow = {}

local function clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

-- Premio en dos líneas: lo grande (monedas o el poder) y el detalle.
local function rewardOf(player: Player, gift: Config.PlaytimeGift): (string, string)
	local boost = gift.boostMinutes
	if gift.coins then
		local coins = NumberFormat.short(RewardScale.share(player, gift.coins, gift.share))
		return coins, if boost then `+ x2 PODER {boost} MIN` else "MONEDAS"
	end
	return "x2 PODER", `{boost or 0} MIN`
end

-- Dibujo y color del premio: monedas, poder o las dos cosas (cofre).
local function lookOf(gift: Config.PlaytimeGift): (string, Color3)
	if gift.coins and gift.boostMinutes then
		return "chest", CARDS.Purple
	elseif gift.coins then
		return "coin", CARDS.Yellow
	end
	return "bolt", CARDS.Cyan
end

-- Celda de la grilla (columna y fila desde 0) que ocupa `span` columnas.
local function cell(object: GuiObject, column: number, row: number, span: number, rows: number)
	object.Position =
		UDim2.new(column / COLUMNS, column * GAP / COLUMNS, row / rows, row * GAP / rows)
	object.Size = UDim2.new(
		span / COLUMNS,
		(span - COLUMNS) * GAP / COLUMNS,
		1 / rows,
		(1 - rows) * GAP / rows
	)
end

-- El regalo grande que asoma arriba a la izquierda, junto al título.
local function headerGift(window: Window.Window)
	local heading = window.frame:FindFirstChild("Encabezado") :: GuiObject?
	if heading then
		heading.Position += UDim2.fromOffset(TITLE_SHIFT, 0)
	end
	local gift = Icons.view(window.frame, "giftPink")
	gift.Name = "RegaloGrande"
	gift.AnchorPoint = Vector2.new(0.5, 0.5)
	gift.Position = UDim2.fromOffset(HEADER_ICON * 0.4, HEADER_ICON * 0.3)
	gift.Size = UDim2.fromOffset(HEADER_ICON, HEADER_ICON)
	gift.Rotation = -10
	gift.ZIndex = 5
end

function PlaytimeWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local claimRemote = remotes:WaitForChild(Protocol.Remotes.ClaimPlaytime) :: RemoteEvent
	local window = Window.create(screen, "Regalos", "Regalos por jugar", Vector2.new(760, 500))
	headerGift(window)

	-- Botón grande en la columna de estadísticas (abre la ventana).
	local entry = PlaytimeEntry.build(16, window.toggle)
	GamepadNav.setGift(window.toggle) -- Y (Triángulo) del mando

	local function elapsed(): number
		local since = player:GetAttribute(ATTR.PlaytimeSince)
		return if type(since) == "number" then Workspace:GetServerTimeNow() - since else 0
	end

	local function stateOf(index: number): PlaytimeCard.State
		local claimed = player:GetAttribute(ATTR.PlaytimeClaimed)
		local bit = 2 ^ (index - 1)
		if type(claimed) == "number" and (claimed // bit) % 2 == 1 then
			return "claimed" :: PlaytimeCard.State
		end
		local ready = elapsed() >= GIFTS[index].minutes * 60
		return (if ready then "ready" else "waiting") :: PlaytimeCard.State
	end

	-- Todos menos el último en tarjetas de COLUMNS; el último, en una franja que ocupa
	-- lo que sobra de la última fila (o una fila entera si no sobra nada).
	local small = #GIFTS - 1
	local leftover = small % COLUMNS
	local rows = math.ceil(small / COLUMNS) + (if leftover == 0 then 1 else 0)
	local cards: { PlaytimeCard.Card } = {}
	for index, gift in GIFTS do
		local final = index == #GIFTS
		local icon, color = lookOf(gift)
		local card = PlaytimeCard.new(
			window.content,
			`Regalo{index}`,
			icon,
			if final then CARDS.Orange else color,
			final
		)
		if final then
			cell(card.button, leftover, rows - 1, COLUMNS - leftover, rows)
		else
			cell(card.button, (index - 1) % COLUMNS, (index - 1) // COLUMNS, 1, rows)
		end
		card.button.Activated:Connect(function()
			if stateOf(index) == "ready" then
				claimRemote:FireServer(index)
			end
		end)
		cards[index] = card
	end

	local shown: { [number]: string } = {}
	local function render()
		local nextWait: number? = nil
		local anyReady = false
		for index, card in cards do
			local state = stateOf(index)
			if state ~= shown[index] then
				shown[index] = state
				card.setState(state)
			end
			card.setReward(rewardOf(player, GIFTS[index])) -- crece con la caña
			local left = GIFTS[index].minutes * 60 - elapsed()
			card.setTime(
				if state == "claimed"
					then "¡RECLAMADO!"
					elseif state == "ready" then "¡RECLAMAR!"
					else clock(left)
			)
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
