--!strict
--[[
	GamepadHint

	Ayuda de mando arriba de la columna derecha (solo con mando y sin nada
	marcado), en una placa de piedra (Interface/Kit): "Y  Menú" y "Select  Ratón". Select saca el cursor virtual de
	Roblox (un ratón que se mueve con el stick y aprieta con A), porque
	StarterGui.VirtualCursorMode = Enabled (default.project.json).
]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local InputHints = require(script.Parent.Parent.Interface.InputHints)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local ROW_HEIGHT = 36
local PLATE_SLICE = 0.3 -- borde de la placa más fino que en las ventanas
local ROWS: { { key: Enum.KeyCode, text: string } } = {
	{ key = Enum.KeyCode.ButtonY, text = "Menú" },
	{ key = Enum.KeyCode.ButtonSelect, text = "Ratón" },
}

local GamepadHint = {}

function GamepadHint.start(isGamepad: () -> boolean)
	local hint = Instance.new("Frame")
	hint.Name = "AyudaMando"
	hint.LayoutOrder = 0
	hint.Size = UDim2.fromOffset(Layout.RIGHT_WIDTH, ROW_HEIGHT * #ROWS + 8)
	Kit.skin(hint, "panel").SliceScale = PLATE_SLICE
	local glyphs: { [Enum.KeyCode]: ImageLabel } = {}
	for index, row in ROWS do
		local y = 4 + (index - 1) * ROW_HEIGHT
		local glyph = Instance.new("ImageLabel")
		glyph.BackgroundTransparency = 1
		glyph.Position, glyph.Size = UDim2.fromOffset(10, y + 2), UDim2.fromOffset(32, 32)
		glyph.Parent = hint
		glyphs[row.key] = glyph
		local label = Style.text(hint, `Texto{index}`, 24, nil, 2)
		label.Text = row.text
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Position = UDim2.fromOffset(48, y + 2)
		label.Size = UDim2.new(1, -56, 0, ROW_HEIGHT - 4)
	end
	hint.Parent = Layout.right()
	local function paint()
		hint.Visible = isGamepad() and GuiService.SelectedObject == nil
		for key, glyph in glyphs do
			glyph.Image = UserInputService:GetImageForKeyCode(key)
		end
	end
	InputHints.onChange(paint)
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(paint)
	paint()
end

return GamepadHint
