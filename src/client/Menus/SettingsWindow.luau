--!strict
--[[
	SettingsWindow

	Ventana de ajustes (botón Ajustes del HUD), de piedra: una fila por opción
	en un hueco tallado, con su ícono, el nombre en dorado y un interruptor de
	piedra (una perilla que se desliza: verde SÍ a la derecha, roja NO a la
	izquierda). Se aplican al momento y se guardan con la partida
	(ver ClientSettings).
]]

local TweenService = game:GetService("TweenService")

local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local PALETTE = Style.PALETTE
local ROW_HEIGHT = 70
local TRACK = Color3.fromRGB(70, 74, 86) -- piedra oscura del riel del interruptor
local SLIDE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
	-- "English" no se traduce: así lo encuentra quien no lee español
	{ key = "english", text = "English", icon = "🌐", hint = "Jugar en inglés" },
}

type Switch = { button: TextButton, knob: Frame, skin: ImageLabel, label: TextLabel }

local SettingsWindow = {}

-- Interruptor: riel de piedra oscura (el botón) y perilla de piedra teñida con SÍ / NO.
local function switch(parent: Instance): Switch
	local button = Instance.new("TextButton")
	button.Name = "Interruptor"
	button.Text = ""
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -14, 0.5, 0)
	button.Size = UDim2.new(0.3, 0, 0, ROW_HEIGHT - 22)
	Kit.skin(button, "boton", TRACK)
	button.Parent = parent
	local knob = Instance.new("Frame")
	knob.Name = "Perilla"
	knob.Size = UDim2.fromScale(0.6, 1)
	knob.ZIndex = 2
	knob.Parent = button
	local skin = Kit.skin(knob, "boton", PALETTE.Buy)
	Kit.press(button, skin)
	local label = Style.text(knob, "Texto", 26, nil, 2)
	label.Position = UDim2.fromOffset(6, 4)
	label.Size = UDim2.new(1, -12, 1, -10)
	label.ZIndex = 3
	return { button = button, knob = knob, skin = skin, label = label }
end

local function row(
	parent: Instance,
	order: number,
	option: { text: string, icon: string, hint: string }
): Switch
	local card = Instance.new("Frame")
	card.Name = `Opcion{order}`
	card.LayoutOrder = order
	card.Size = UDim2.new(1, -8, 0, ROW_HEIGHT)
	card.Parent = parent
	Kit.skin(card, "hondo")
	local icon = Style.text(card, "Icono", 40, nil, 0)
	icon.Text = option.icon
	icon.Position = UDim2.fromOffset(10, 8)
	icon.Size = UDim2.fromOffset(ROW_HEIGHT - 16, ROW_HEIGHT - 16)
	local title = Style.text(card, "Texto", 26, nil, 2.5)
	title.Text = option.text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(ROW_HEIGHT, 8)
	title.Size = UDim2.new(0.62, -ROW_HEIGHT, 0, 30)
	Kit.gold(title)
	local hint = Style.text(card, "Ayuda", 17, nil, 1.5)
	hint.Text = option.hint
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Position = UDim2.fromOffset(ROW_HEIGHT, 40)
	hint.Size = UDim2.new(0.62, -ROW_HEIGHT, 0, 20)
	return switch(card)
end

function SettingsWindow.start(screen: ScreenGui)
	local window = Window.create(screen, "Ajustes", "Ajustes", Vector2.new(520, 480))
	HudButtons.top("Ajustes", "gear", window.toggle)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.Parent = window.content
	local top = Instance.new("UIPadding")
	top.PaddingTop = UDim.new(0, 6)
	top.Parent = window.content

	local toggles: { [string]: Switch } = {}
	local function paint(key: string)
		local toggle = toggles[key]
		if not toggle then
			return
		end
		local on = ClientSettings.get(key :: ClientSettings.Key)
		toggle.label.Text = if on then "SÍ" else "NO"
		Kit.tint(toggle.skin, if on then PALETTE.Buy else PALETTE.Close)
		local place = { Position = UDim2.fromScale(if on then 0.4 else 0, 0) }
		TweenService:Create(toggle.knob, SLIDE, place):Play()
	end
	for index, option in OPTIONS do
		local key: ClientSettings.Key = option.key
		local toggle = row(window.content, index, option)
		toggles[key] = toggle
		toggle.button.Activated:Connect(function()
			ClientSettings.set(key, not ClientSettings.get(key))
			Sounds.play("Click")
		end)
		paint(key)
	end
	ClientSettings.onChanged(paint)
end

return SettingsWindow
