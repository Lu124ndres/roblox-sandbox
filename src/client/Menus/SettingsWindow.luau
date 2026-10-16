--!strict
--[[
	SettingsWindow

	Ventana de ajustes (botón Ajustes del HUD), con el estilo de la TIENDA:
	una tarjeta por opción con su ícono, el nombre y un botón SÍ / NO (verde
	o rojo). Se aplican al momento y se guardan con la partida
	(ver ClientSettings).
]]

local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local PALETTE = Style.PALETTE
local ROW_HEIGHT = 70
local OPTIONS: { { key: ClientSettings.Key, text: string, icon: string, hint: string } } = {
	{ key = "music", text = "Música", icon = "🎵", hint = "La música del juego" },
	{ key = "sfx", text = "Sonidos", icon = "🔊", hint = "Pesca, monedas y avisos" },
	{
		key = "shake",
		text = "Temblor de cámara",
		icon = "📳",
		hint = "Cuando el monstruo ataca",
	},
	{
		key = "lowFx",
		text = "Modo rápido",
		icon = "⚡",
		hint = "Menos efectos, más fluido",
	},
}

local SettingsWindow = {}

local function row(
	parent: Instance,
	order: number,
	option: { text: string, icon: string, hint: string }
): TextButton
	local card = CardParts.card(parent, `Opcion{order}`, PALETTE.Cards.Blue, 12)
	card.LayoutOrder = order
	card.Size = UDim2.new(1, -8, 0, ROW_HEIGHT)
	local icon = Style.text(card, "Icono", 40, nil, 0)
	icon.Text = option.icon
	icon.Position = UDim2.fromOffset(8, 8)
	icon.Size = UDim2.fromOffset(ROW_HEIGHT - 16, ROW_HEIGHT - 16)
	local title = Style.text(card, "Texto", 26, nil, 2.5)
	title.Text = option.text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(ROW_HEIGHT, 8)
	title.Size = UDim2.new(0.62, -ROW_HEIGHT, 0, 30)
	local hint = Style.text(card, "Ayuda", 17, nil, 1.5)
	hint.Text = option.hint
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Position = UDim2.fromOffset(ROW_HEIGHT, 40)
	hint.Size = UDim2.new(0.62, -ROW_HEIGHT, 0, 20)
	local toggle = Style.button(card, "Interruptor", PALETTE.Buy, "SÍ")
	toggle.AnchorPoint = Vector2.new(1, 0.5)
	toggle.Position = UDim2.new(1, -12, 0.5, 0)
	toggle.Size = UDim2.new(0.26, 0, 0, ROW_HEIGHT - 20)
	return toggle
end

function SettingsWindow.start(screen: ScreenGui)
	local window = Window.create(screen, "Ajustes", "Ajustes", Vector2.new(520, 400))
	HudButtons.top("Ajustes", "gear", window.toggle)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.Parent = window.content
	local top = Instance.new("UIPadding")
	top.PaddingTop = UDim.new(0, 6)
	top.Parent = window.content

	local toggles: { [string]: TextButton } = {}
	local function paint(key: string)
		local toggle = toggles[key]
		if not toggle then
			return
		end
		local on = ClientSettings.get(key :: ClientSettings.Key)
		local color = if on then PALETTE.Buy else PALETTE.Close
		local label = toggle:FindFirstChild("Texto") :: TextLabel
		label.Text = if on then "SÍ" else "NO"
		toggle.BackgroundColor3 = color
		local gradient = toggle:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient:Destroy()
		end
		Style.gradient(toggle, color)
	end
	for index, option in OPTIONS do
		local key: ClientSettings.Key = option.key
		local toggle = row(window.content, index, option)
		toggles[key] = toggle
		toggle.Activated:Connect(function()
			ClientSettings.set(key, not ClientSettings.get(key))
			Sounds.play("Click")
		end)
		paint(key)
	end
	ClientSettings.onChanged(paint)
end

return SettingsWindow
