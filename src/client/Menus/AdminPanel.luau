--!strict
--[[
	AdminPanel

	Panel de pruebas para los administradores (atributo EsAdmin, lo pone el
	servidor; nadie más ve el botón). Cada fila manda AdminCommand(nombre,
	valor) y el servidor vuelve a comprobar que sea admin y responde con un
	aviso. Las órdenes están en server/Admin/AdminCommands.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Config.Events)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local CARDS = Style.PALETTE.Cards
local ROW_HEIGHT = 46

type Button = { text: string, name: string, value: any? }

local AdminPanel = {}

function AdminPanel.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	while player:GetAttribute(Protocol.PlayerAttributes.IsAdmin) ~= true do
		player:GetAttributeChangedSignal(Protocol.PlayerAttributes.IsAdmin):Wait()
	end
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local command = remotes:WaitForChild(Protocol.Remotes.AdminCommand) :: RemoteEvent
	local window = Window.create(screen, "Admin", "Panel admin", Vector2.new(860, 600))
	HudButtons.top("Admin", "crown", window.toggle)

	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Size = UDim2.fromScale(1, 1)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 8
	list.Parent = window.content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local order = 0
	-- Una fila: nombre a la izquierda, (casilla para escribir) y botones.
	local function row(title: string, buttons: { Button }, withInput: boolean?)
		order += 1
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.LayoutOrder = order
		frame.Size = UDim2.new(1, -12, 0, ROW_HEIGHT)
		frame.Parent = list
		local flow = Instance.new("UIListLayout")
		flow.FillDirection = Enum.FillDirection.Horizontal
		flow.VerticalAlignment = Enum.VerticalAlignment.Center
		flow.Padding = UDim.new(0, 6)
		flow.SortOrder = Enum.SortOrder.LayoutOrder
		flow.Parent = frame
		local name = Style.text(frame, "Nombre", 24, nil, 2)
		name.Text = title
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Size = UDim2.fromOffset(150, ROW_HEIGHT)
		local box: TextBox? = nil
		if withInput then
			local input = Instance.new("TextBox")
			input.LayoutOrder = 1
			input.Size = UDim2.fromOffset(140, ROW_HEIGHT - 6)
			input.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
			input.TextColor3 = Color3.fromRGB(20, 20, 30)
			input.PlaceholderText = "número"
			input.Text = ""
			input.TextScaled = true
			input.ClearTextOnFocus = false
			input.Font = Enum.Font.GothamBold
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = input
			input.Parent = frame
			box = input
		end
		for index, spec in buttons do
			local button = Style.button(frame, spec.name, CARDS.Blue, spec.text)
			button.LayoutOrder = 1 + index
			button.Size = UDim2.fromOffset(math.max(90, #spec.text * 14 + 24), ROW_HEIGHT - 6)
			button.Activated:Connect(function()
				local value = spec.value
				if value == nil and box then
					value = tonumber((string.gsub(box.Text, "[,%s]", "")))
				end
				command:FireServer(spec.name, value)
			end)
		end
	end

	row("Poder", { { text = "Poner", name = "power" } }, true)
	row("Monedas", { { text = "Poner", name = "coins" } }, true)
	row("Kills", { { text = "Poner", name = "kills" } }, true)
	row("Peces", {
		{ text = "Agregar", name = "fish" },
		{ text = "Vaciar", name = "emptyBasket", value = 0 },
	}, true)
	row("Velocidad", {
		{ text = "Poner", name = "speed" },
		{ text = "16", name = "speed", value = 16 },
		{ text = "60", name = "speed", value = 60 },
		{ text = "120", name = "speed", value = 120 },
	}, true)
	row("Mejoras (nivel)", {
		{ text = "Caña", name = "Rod" },
		{ text = "Canasta", name = "Basket" },
		{ text = "Botas", name = "Boots" },
	}, true)
	local giants: { Button } = {}
	for _, def in Config.Giants.chain do
		table.insert(giants, { text = def.displayName, name = "giant", value = def.id })
	end
	row("Monstruo", giants)
	row("Barra", {
		{ text = "+25%", name = "fill", value = 0.25 },
		{ text = "+50%", name = "fill", value = 0.5 },
		{ text = "Llenar", name = "fill", value = 1 },
		{ text = "Fin descanso", name = "skipRest", value = 0 },
	})
	local passes: { Button } = {}
	for _, key in Config.Monetization.passOrder do
		table.insert(
			passes,
			{ text = Config.Monetization.passes[key].name, name = "pass", value = key }
		)
	end
	row("Pases (on/off)", passes)
	local events: { Button } = {}
	for _, kind in Events.kinds do
		table.insert(events, { text = kind.name, name = "event", value = kind.id })
	end
	row("Evento ya", events)
	row("Regalos tiempo", {
		{ text = "+10 min", name = "playtime", value = 10 },
		{ text = "+1 h", name = "playtime", value = 60 },
	})
	row("Ir a", {
		{ text = "Muelle", name = "tp", value = "muelle" },
		{ text = "Volcán", name = "tp", value = "volcan" },
		{ text = "Plaza", name = "tp", value = "plaza" },
		{ text = "Tienda", name = "tp", value = "tienda" },
	})
end

return AdminPanel
