--!strict
--[[
	PromptKey

	La tecla tallada a la izquierda del aviso de los ProximityPrompt
	(PromptView): letra dorada en PC, el botón del mando en consola o «TOCA»
	en celular, sobre un botón de piedra.
]]

local UserInputService = game:GetService("UserInputService")

local InputHints = require(script.Parent.InputHints)
local Kit = require(script.Parent.Kit)
local Style = require(script.Parent.Style)

local KEY_SLICE = 0.2

local PromptKey = {}

PromptKey.SIZE = 56

function PromptKey.make(parent: Instance, prompt: ProximityPrompt): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Tecla"
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.Position = UDim2.new(0, 9, 0.5, 0)
	frame.Size = UDim2.fromOffset(PromptKey.SIZE, PromptKey.SIZE)
	frame.ZIndex = 3
	Kit.skin(frame, "boton", Kit.STONE).SliceScale = KEY_SLICE
	frame.Parent = parent
	local letter = Style.text(frame, "Letra", 34, nil, 3)
	letter.Position = UDim2.fromScale(0.1, 0.1)
	letter.Size = UDim2.fromScale(0.8, 0.8)
	letter.ZIndex = 4
	Kit.gold(letter)
	local glyph = Instance.new("ImageLabel")
	glyph.Name = "Boton"
	glyph.BackgroundTransparency = 1
	glyph.Position = UDim2.fromScale(0.12, 0.12)
	glyph.Size = UDim2.fromScale(0.76, 0.76)
	glyph.ScaleType = Enum.ScaleType.Fit
	glyph.ZIndex = 4
	glyph.Parent = frame
	local mode = InputHints.mode()
	glyph.Visible = mode == "gamepad"
	letter.Visible = mode ~= "gamepad"
	if mode == "gamepad" then
		glyph.Image = UserInputService:GetImageForKeyCode(prompt.GamepadKeyCode)
	elseif mode == "touch" then
		letter.Text = "TOCA"
	else
		letter.Text = string.upper(UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode))
	end
	return frame
end

return PromptKey
