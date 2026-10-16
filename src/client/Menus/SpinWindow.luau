--!strict
--[[
	SpinWindow

	Ruleta como la de los simuladores (botón Ruleta arriba y la rueda del
	mundo, SpinStand): la rueda grande (SpinWheelView) con la flecha roja y,
	abajo, tres botones: azul "Comprar 1" (R$), verde "¡Girar! (N)" y amarillo
	"Comprar 5" (R$); debajo, cuándo toca el próximo giro gratis y el próximo
	giro por jugar. N = giros guardados + el gratis si ya toca. El servidor
	(Retention/SpinWheel) elige la casilla y avisa con Notice "spin": la rueda
	gira y frena en ella; el cartel del premio lo pone NoticesMore.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local SPIN = require(ReplicatedStorage.Shared.Config.Spin)
local Style = require(script.Parent.Parent.Interface.Style)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local HudButtons = require(script.Parent.HudButtons)
local Purchases = require(script.Parent.Purchases)
local SpinOffers = require(script.Parent.SpinOffers)
local SpinWheelView = require(script.Parent.SpinWheelView)
local Window = require(script.Parent.Window)

local ATTR = Protocol.PlayerAttributes
local PALETTE = Style.PALETTE
local PRODUCTS = Config.Monetization.spinProducts

local SpinWindow = {}

-- Abre la ventana desde otro lado (la rueda del mundo).
SpinWindow.open = function() end

local function clock(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	if s >= 3600 then
		return string.format("%dh %02dm", s // 3600, (s % 3600) // 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

local function paint(button: TextButton, color: Color3)
	if button.BackgroundColor3 == color then
		return
	end
	button.BackgroundColor3 = color
	local old = button:FindFirstChildOfClass("UIGradient")
	if old then
		old:Destroy()
	end
	Style.gradient(button, color)
end

local function buyButton(parent: Instance, key: string, color: Color3, x: number): TextButton
	local def = PRODUCTS[key]
	local spins = if def then def.spins else 1
	local button = Style.button(parent, `Comprar{spins}`, color, "")
	button.AnchorPoint = Vector2.new(x, 0)
	button.Position = UDim2.fromScale(x, 0)
	button.Size = UDim2.fromScale(0.3, 1)
	local title = button:FindFirstChild("Texto") :: TextLabel
	title.Text = `Comprar {spins}`
	title.Size = UDim2.fromScale(0.94, 0.5)
	title.Position = UDim2.fromScale(0.03, 0.05)
	local price = Style.robuxBadge(button, if def then def.robux else nil)
	local badge = price.Parent :: Frame
	badge.AnchorPoint = Vector2.new(0.5, 0)
	badge.Position = UDim2.fromScale(0.5, 0.58)
	badge.Size = UDim2.fromScale(0.6, 0.36)
	task.spawn(function()
		price.Text = tostring(Purchases.price(key, false, if def then def.robux else 0))
	end)
	button.Activated:Connect(function()
		Purchases.promptProduct(key)
	end)
	return button
end

function SpinWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local claimRemote = remotes:WaitForChild(Protocol.Remotes.ClaimSpin) :: RemoteEvent
	local notice = remotes:WaitForChild(Protocol.Remotes.Notice) :: RemoteEvent
	local window = Window.create(screen, "Ruleta", "Ruleta", Vector2.new(620, 640))
	local hud = HudButtons.top("Ruleta", "chest", window.toggle)
	SpinWindow.open = window.open
	local content = window.content

	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 0.74)
	holder.Parent = content
	local wheel = SpinWheelView.build(holder)
	wheel.root.AnchorPoint = Vector2.new(0.5, 0)
	wheel.root.Position = UDim2.fromScale(0.5, 0)

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromScale(0, 0.76)
	row.Size = UDim2.fromScale(1, 0.15)
	row.Parent = content
	buyButton(row, "Spin1", PALETTE.Cards.Blue, 0)
	buyButton(row, "Spin5", PALETTE.Cards.Yellow, 1)
	local spinButton = Style.button(row, "Girar", PALETTE.Buy, "")
	spinButton.AnchorPoint = Vector2.new(0.5, 0)
	spinButton.Position = UDim2.fromScale(0.5, 0)
	spinButton.Size = UDim2.fromScale(0.36, 1)
	local spinText = spinButton:FindFirstChild("Texto") :: TextLabel
	local nextText = Style.text(content, "Proximo", 22, nil, 2)
	nextText.Position = UDim2.fromScale(0, 0.92)
	nextText.Size = UDim2.fromScale(1, 0.075)
	local spinning = false

	local function now(): number
		return Workspace:GetServerTimeNow()
	end
	local function freeLeft(): number
		local at = player:GetAttribute(ATTR.SpinAt)
		return math.max(0, (if type(at) == "number" then at else 0) - now())
	end
	local function available(): number
		if player:GetAttribute(ATTR.DataLoaded) ~= true then
			return 0
		end
		local banked = player:GetAttribute(ATTR.Spins)
		return (if type(banked) == "number" then banked else 0) + (if freeLeft() <= 0 then 1 else 0)
	end

	local function render()
		local count = available()
		local can = count > 0 and not spinning
		spinText.Text = if spinning then "Girando..." else `¡Girar! ({count})`
		paint(spinButton, if can then PALETTE.Buy else PALETTE.Disabled)
		local lines = {}
		local free = freeLeft()
		table.insert(
			lines,
			if free <= 0 then "¡Giro gratis listo!" else `Próximo giro gratis en {clock(free)}`
		)
		local playAt = player:GetAttribute(ATTR.SpinTimeAt)
		if type(playAt) == "number" and playAt > 0 then
			table.insert(lines, `+1 giro por jugar en {clock(playAt - now())}`)
		end
		nextText.Text = table.concat(lines, "   ·   ")
		hud.setAlert(count > 0)
	end

	spinButton.Activated:Connect(function()
		if available() > 0 and not spinning then
			spinning = true
			Sounds.play("Click")
			claimRemote:FireServer()
			render()
			task.delay(3, function() -- sin respuesta del servidor: se puede volver a intentar
				if spinning then
					spinning = false
					render()
				end
			end)
		end
	end)
	notice.OnClientEvent:Connect(function(kind: unknown, index: unknown)
		if kind == "spin" and type(index) == "number" and SPIN.prizes[index] then
			window.open()
			spinning = true
			render()
			wheel.spinTo(index, SPIN.spinSeconds)
			for k = 1, 10 do -- clic de la rueda, cada vez más lento
				task.delay(SPIN.spinSeconds * (1 - (1 - k / 10) ^ 0.5), Sounds.play, "Click")
			end
			task.delay(SPIN.spinSeconds, function()
				spinning = false
				render()
			end)
		end
	end)
	window.onOpen(function()
		for index, label in wheel.labels do
			label.Text = SpinOffers.prizeText(player, SPIN.prizes[index])
		end
		render()
	end)
	for _, name in { ATTR.SpinAt, ATTR.Spins, ATTR.SpinTimeAt, ATTR.DataLoaded } do
		player:GetAttributeChangedSignal(name):Connect(render)
	end
	task.spawn(function() -- cuentas regresivas y punto rojo cuando hay giros
		while true do
			render()
			task.wait(1)
		end
	end)
end

return SpinWindow
