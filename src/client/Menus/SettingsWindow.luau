--!strict
--[[
	SettingsWindow

	Ventana de ajustes (botón Ajustes del HUD): cuatro interruptores que se
	aplican al momento y se guardan con la partida (ver ClientSettings).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Ui = require(script.Parent.Parent.Ui)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local COLORS = UIConfig.Colors
local OPTIONS: { { key: ClientSettings.Key, text: string } } = {
	{ key = "music", text = "Música" },
	{ key = "sfx", text = "Sonidos" },
	{ key = "shake", text = "Temblor de cámara" },
	{ key = "lowFx", text = "Modo rápido (celulares)" },
}

local SettingsWindow = {}

local function row(parent: Instance, order: number, text: string): TextButton
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.BackgroundColor3 = COLORS.Track
	frame.BackgroundTransparency = 0.3
	frame.Size = UDim2.new(1, 0, 0.22, 0)
	Ui.corner(frame, 10)
	frame.Parent = parent
	local label = Ui.label("Texto", frame, UIConfig.Fonts.Title, UIConfig.TextSizes.Body)
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.fromScale(0.05, 0.15)
	label.Size = UDim2.fromScale(0.6, 0.7)
	local toggle = Instance.new("TextButton")
	toggle.Name = "Interruptor"
	toggle.AnchorPoint = Vector2.new(1, 0.5)
	toggle.Position = UDim2.new(1, -10, 0.5, 0)
	toggle.Size = UDim2.fromScale(0.28, 0.72)
	toggle.FontFace = UIConfig.Fonts.Title
	toggle.TextScaled = true
	toggle.TextColor3 = COLORS.Text
	toggle.TextStrokeTransparency = 0.3
	Ui.corner(toggle, 10)
	toggle.Parent = frame
	return toggle
end

function SettingsWindow.start(screen: ScreenGui)
	local window = Window.create(screen, "Ajustes", "Ajustes", Vector2.new(460, 340))
	HudButtons.top("Ajustes", "gear", window.toggle)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.04, 0)
	layout.Parent = window.content

	local toggles: { [string]: TextButton } = {}
	local function paint(key: string)
		local toggle = toggles[key]
		if not toggle then
			return
		end
		local on = ClientSettings.get(key :: ClientSettings.Key)
		toggle.Text = if on then "Sí" else "No"
		toggle.BackgroundColor3 = if on then COLORS.Success else COLORS.Feeding
	end
	for index, option in OPTIONS do
		local key: ClientSettings.Key = option.key
		local toggle = row(window.content, index, option.text)
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
