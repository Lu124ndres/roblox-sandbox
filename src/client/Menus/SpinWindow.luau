--!strict
--[[
	SpinWindow

	Ruleta gratis (botón Ruleta arriba, con punto rojo cuando toca): las
	casillas de Config/Spin con rayos y el botón ¡GIRAR! o la cuenta
	regresiva (atributo RuletaListaEn). El servidor (Retention/SpinWheel)
	elige la casilla y avisa con Notice "spin": la luz recorre las casillas y
	se frena en la que salió; el cartel del premio lo pone NoticesMore.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RewardScale = require(ReplicatedStorage.Shared.RewardScale)
local SPIN = require(ReplicatedStorage.Shared.Config.Spin)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local ATTR = Protocol.PlayerAttributes
local CARDS = Style.PALETTE.Cards
local ICONS = { coins = "coin", boost = "bolt", fill = "orca" }
local COLORS = { coins = CARDS.Yellow, boost = CARDS.Purple, fill = CARDS.Red }

type Tile = { box: Frame, label: TextLabel, color: Color3, lit: boolean? }

local SpinWindow = {}

local function prizeText(player: Player, prize: SPIN.Prize): string
	if prize.kind == "boost" then
		return `{prize.minutes} min x{Config.Social.personalBoostMultiplier} poder`
	elseif prize.kind == "fill" then
		return `Llena {math.round((prize.fraction or 0) * 100)}% del monstruo`
	end
	return `{NumberFormat.short(RewardScale.share(player, prize.coins or 0, prize.share))} monedas`
end

local function makeTile(parent: Instance, index: number, prize: SPIN.Prize): Tile
	local color = COLORS[prize.kind] or CARDS.Blue
	local box = CardParts.card(parent, `Casilla{index}`, color)
	box.LayoutOrder = index
	local icon = Icons.view(box, ICONS[prize.kind] or "gift")
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.fromScale(0.5, 0.08)
	icon.Size = UDim2.fromScale(0.62, 0.5)
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = icon
	local label = Style.text(box, "Premio", 24, UIConfig.Colors.Text, 2.5)
	label.Position = UDim2.fromScale(0.05, 0.62)
	label.Size = UDim2.fromScale(0.9, 0.32)
	return { box = box, label = label, color = color }
end

local function light(tile: Tile, on: boolean)
	if tile.lit == on then
		return
	end
	tile.lit = on
	CardParts.paint(tile.box, if on then Color3.fromRGB(255, 255, 255) else tile.color)
	local stroke = tile.box:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Thickness = if on then 6 else 3
	end
end

function SpinWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local claimRemote = remotes:WaitForChild(Protocol.Remotes.ClaimSpin) :: RemoteEvent
	local notice = remotes:WaitForChild(Protocol.Remotes.Notice) :: RemoteEvent
	local window = Window.create(screen, "Ruleta", "Ruleta gratis", Vector2.new(720, 420))
	local hud = HudButtons.top("Ruleta", "chest", window.toggle)

	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(1, 0, 0.72, 0)
	grid.Parent = window.content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.25, -10, 0.5, -10)
	layout.CellPadding = UDim2.fromOffset(10, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	local tiles: { Tile } = {}
	for index, prize in SPIN.prizes do
		tiles[index] = makeTile(grid, index, prize)
	end

	local button = Style.button(window.content, "Girar", Style.PALETTE.Buy, "")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.fromScale(0.5, 1)
	button.Size = UDim2.new(0.5, 0, 0.22, 0)
	local buttonText = button:FindFirstChild("Texto") :: TextLabel
	local spinning = false

	local function secondsLeft(): number
		local at = player:GetAttribute(ATTR.SpinAt)
		local ready = if type(at) == "number" then at else 0
		return math.max(0, ready - Workspace:GetServerTimeNow())
	end
	local function ready(): boolean
		return player:GetAttribute(ATTR.DataLoaded) == true and secondsLeft() <= 0
	end

	local function render()
		if window.isOpen() then
			for index, tile in tiles do
				tile.label.Text = prizeText(player, SPIN.prizes[index])
			end
		end
		local can = ready() and not spinning
		local left = secondsLeft()
		buttonText.Text = if spinning
			then "Girando..."
			elseif can then "¡GIRAR!"
			else string.format(
				"Vuelve en %d:%02d:%02d",
				left // 3600,
				(left % 3600) // 60,
				left % 60
			)
		local tint = if can then Style.PALETTE.Buy else Style.PALETTE.Disabled
		if button.BackgroundColor3 ~= tint then
			button.BackgroundColor3 = tint
			local gradient = button:FindFirstChildOfClass("UIGradient")
			if gradient then
				gradient:Destroy()
			end
			Style.gradient(button, tint)
		end
		hud.setAlert(ready())
	end

	-- La luz da vueltas por las casillas, cada vez más lento, y se frena en `target`.
	local function spinTo(target: number)
		spinning = true
		render()
		local count = #tiles
		local steps = count * 3 + (target - 1)
		local elapsed = 0
		for step = 0, steps do
			for index, tile in tiles do
				light(tile, index == step % count + 1)
			end
			Sounds.play("Click")
			local wait = 0.04 + 0.22 * (step / steps) ^ 3
			elapsed += wait
			task.wait(wait)
		end
		task.wait(math.max(0, SPIN.spinSeconds - elapsed))
		spinning = false
		render()
	end

	button.Activated:Connect(function()
		if ready() and not spinning then
			spinning = true
			claimRemote:FireServer()
			render()
			task.delay(3, function() -- sin respuesta del servidor: se puede volver a intentar
				if spinning and ready() then
					spinning = false
					render()
				end
			end)
		end
	end)
	notice.OnClientEvent:Connect(function(kind: unknown, index: unknown)
		if kind == "spin" and type(index) == "number" and tiles[index] then
			window.open()
			task.spawn(spinTo, index)
		end
	end)
	window.onOpen(function()
		for _, tile in tiles do
			light(tile, false)
		end
		render()
	end)
	player:GetAttributeChangedSignal(ATTR.SpinAt):Connect(render)
	player:GetAttributeChangedSignal(ATTR.DataLoaded):Connect(render)
	task.spawn(function() -- cuenta regresiva y punto rojo cuando vuelve a tocar
		while true do
			render()
			task.wait(1)
		end
	end)
end

return SpinWindow
